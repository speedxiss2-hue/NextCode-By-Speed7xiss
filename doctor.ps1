#requires -Version 5.1
# Diagnoses the three community failures: reset, WARP proxy/MITM, update feed.
# -Fix applies only safe local corrections; it never buys a token or edits a secret.
param([switch]$Fix, [string]$ApiUrl)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backup = Join-Path $root 'backup'
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$issues = [System.Collections.Generic.List[string]]::new()

function Say([string]$tag, [string]$message) {
  $colour = if ($tag -eq 'OK') { 'Green' } elseif ($tag -eq 'FAIL') { 'Red' } else { 'Yellow' }
  Write-Host ("[" + $tag + "] " + $message) -ForegroundColor $colour
}
function Warn([string]$message) { $issues.Add($message); Say 'WARN' $message }

function Find-Warp {
  if ($env:WARP_CLI -and (Test-Path -LiteralPath $env:WARP_CLI)) { return $env:WARP_CLI }
  $candidates = @(
    (Join-Path $env:ProgramFiles 'Cloudflare\Cloudflare WARP\warp-cli.exe'),
    (Join-Path $env:LOCALAPPDATA 'Cloudflare\Cloudflare WARP\warp-cli.exe')
  )
  $x86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
  if ($x86) { $candidates += (Join-Path $x86 'Cloudflare\Cloudflare WARP\warp-cli.exe') }
  foreach ($path in $candidates) { if (Test-Path -LiteralPath $path) { return $path } }
  $found = Get-Command warp-cli -ErrorAction SilentlyContinue
  if ($found) { return $found.Source }
  return $null
}

function Run-Cli([string]$cli, [string[]]$arguments, [int]$timeout = 20) {
  return & $cli --accept-tos --no-ansi -j @arguments 2>&1 | Out-String
}

Write-Host 'NextCode doctor' -ForegroundColor Cyan
Write-Host ('root: ' + $root) -ForegroundColor DarkGray

# 1. engine + CLI
$exe = Join-Path $env:LOCALAPPDATA 'NextCode\bin\opencode.exe'
if (Test-Path -LiteralPath $exe) {
  $version = & $exe --version 2>&1 | Out-String
  Say 'OK' ('engine installed: ' + $version.Trim())
} else {
  Warn 'global CLI missing - run setup.bat'
  if ($Fix) { & (Join-Path $root 'setup.ps1') }
}

# 2. WebView2 (the desktop shell will not start without it)
$webview = @(
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
  'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
)
if ($webview | Where-Object { Test-Path -LiteralPath $_ }) { Say 'OK' 'WebView2 runtime present' }
else { Warn 'WebView2 runtime missing - install Evergreen Runtime from https://developer.microsoft.com/microsoft-edge/webview2/' }

# 3. WARP
$cli = Find-Warp
if (-not $cli) {
  Warn 'WARP CLI missing - reset cannot change IP. Run install.ps1 to install it.'
} else {
  Say 'OK' ('WARP CLI: ' + $cli)
  try {
    $registration = Run-Cli $cli @('registration','show') | ConvertFrom-Json
    if ($registration.managed -eq $true) {
      Warn 'WARP registration is managed by the organisation - reset will refuse (reason: managed). Ask the network admin or use a personal WARP account.'
    } else { Say 'OK' 'WARP registration is unmanaged' }
  } catch { Say 'WARN' 'registration query unavailable (reset still works)' }

  $settings = $null
  try { $settings = (Run-Cli $cli @('settings') | ConvertFrom-Json).settings } catch {}
  $mode = if ($settings) { [string]$settings.operation_mode } else { '' }
  $portProperty = if ($settings) { $settings.PSObject.Properties['proxy_port'] } else { $null }
  $port = if ($portProperty) { [int]$portProperty.Value } else { 40000 }
  if ($mode -eq 'proxy') { Say 'OK' ("WARP proxy mode on port $port") }
  else {
    Warn "WARP operation mode is '$mode', not 'proxy'. The app expects HTTP proxy 127.0.0.1:$port."
    if ($Fix) {
      try {
        Run-Cli $cli @('mode','proxy') | Out-Null
        Run-Cli $cli @('proxy','port','40000') | Out-Null
        Say 'OK' 'enabled WARP proxy mode on port 40000'
        Run-Cli $cli @('connect') | Out-Null
        Say 'OK' 'WARP tunnel reconnected'
      } catch { Warn ('could not enable proxy mode: ' + $_.Exception.Message) }
    }
  }

  $status = $null
  try { $status = Run-Cli $cli @('status') } catch {}
  if ($status -match '"status"\s*:\s*"connected"') { Say 'OK' 'WARP tunnel connected' }
  else { Warn 'WARP tunnel disconnected - reset reconnects it; click reset usage once.' }

  # CF_HAPPY_EYEBALLS_MITM_FAILURE: TLS interception without the WARP root cert trusted.
  $proxyUrl = 'http://127.0.0.1:' + $port
  try {
    $trace = (Invoke-WebRequest -Uri 'https://www.cloudflare.com/cdn-cgi/trace' -Proxy $proxyUrl -UseBasicParsing -TimeoutSec 12).Content
    Say 'OK' ('egress via WARP: ' + (([regex]::Match($trace, '(?m)^ip=(.+)$')).Groups[1].Value.Trim()))
  } catch {
    $detail = $_.Exception.Message
    if ($detail -match 'MITM|happy|certificate|CERT|SSL') {
      Warn 'CF MITM/TLS failure through the WARP proxy: install the Cloudflare WARP certificate into the Windows Trusted Root store, or switch WARP to WireGuard mode and disable TLS inspection.'
    } else {
      Warn ('egress through the WARP proxy failed: ' + $detail)
    }
  }
}

# 4. loopback must never go through the proxy
$noProxy = [string]$env:NO_PROXY
foreach ($entry in @('127.0.0.1','localhost','::1')) {
  if ($noProxy -notlike ('*' + $entry + '*')) {
    Warn ("NO_PROXY is missing $entry - the proxy would swallow the loopback API and cause ECONNREFUSED.")
    if ($Fix) {
      $parts = @($noProxy, '127.0.0.1','localhost','::1') | Where-Object { $_ } | Select-Object -Unique
      $merged = $parts -join ','
      [Environment]::SetEnvironmentVariable('NO_PROXY', $merged, 'User')
      $env:NO_PROXY = $merged
      Say 'OK' 'NO_PROXY corrected for this user (reopen the terminal to apply everywhere)'
    }
    break
  }
}

# 5. update API
$api = $ApiUrl
if (-not $api -and $env:NEXTCODE_UPDATE_API) { $api = $env:NEXTCODE_UPDATE_API }
$config = Join-Path $root 'update-api.txt'
if (-not $api -and (Test-Path -LiteralPath $config)) { $api = (Get-Content -Raw -LiteralPath $config).Trim() }
if (-not $api) {
  Warn 'no update API configured - the app falls back to the upstream feed and shows ECONNREFUSED when it is unreachable.'
} else {
  if ($Fix) { [System.IO.File]::WriteAllText($config, $api, (New-Object System.Text.UTF8Encoding($false))) }
  try {
    $base = $api.TrimEnd('/')
    $endpoint = if ($base -match '\.json$') { $base } else { $base + '/api/version' }
    $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 15
    $data = $response.Content | ConvertFrom-Json
    Say 'OK' ('update API reachable, version ' + $data.version)
  } catch {
    Warn ('update API unreachable: ' + $_.Exception.Message)
  }
}

Write-Host ''
if ($issues.Count -eq 0) { Say 'OK' 'no issues found' }
else { Say 'WARN' ($issues.Count.ToString() + ' issue(s) found - see above') }

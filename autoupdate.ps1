#requires -Version 5.1
# Manifest-driven updater for NextCode. Polls an API you host on Vercel or Render,
# verifies SHA-256, stages the download, then swaps it in with a rollback copy.
# No local rebuild and no per-machine exe needed.
param(
  [switch]$Check,
  [switch]$Force,
  [string]$ApiUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backup = Join-Path $root 'backup'
$logPath = Join-Path $backup 'autoupdate.log'
$versionFile = Join-Path $root 'build\resources\opencode-cli.version'
$engine = Join-Path $root 'build\resources\opencode-cli.exe'
$stateFile = Join-Path $backup 'autoupdate-state.json'
$configFile = Join-Path $root 'update-api.txt'
New-Item -ItemType Directory -Path $backup -Force | Out-Null

function Log([string]$message) {
  $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $message
  Write-Host $line
  Add-Content -LiteralPath $logPath -Value $line
}

function Resolve-Api {
  if ($ApiUrl) { return $ApiUrl.TrimEnd('/') }
  if ($env:NEXTCODE_UPDATE_API) { return $env:NEXTCODE_UPDATE_API.TrimEnd('/') }
  if (Test-Path -LiteralPath $configFile) {
    $fromFile = (Get-Content -LiteralPath $configFile -Raw).Trim()
    if ($fromFile) { return $fromFile.TrimEnd('/') }
  }
  return ''
}

function Fetch-Manifest([string]$base) {
  if (-not $base) { throw 'No update API configured. Set NEXTCODE_UPDATE_API, write update-api.txt, or pass -ApiUrl.' }
  $url = if ($base -match '\.json$') { $base } else { $base + '/api/version' }
  $last = $null
  foreach ($attempt in 1..3) {
    try {
      $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20
      $data = $response.Content | ConvertFrom-Json
      if (-not $data.version) { throw 'manifest has no version' }
      if (-not $data.engine -or -not $data.engine.url) { throw 'manifest has no engine.url' }
      if (-not $data.engine.sha256 -or $data.engine.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'manifest has no valid engine.sha256' }
      return $data
    } catch {
      $last = $_.Exception.Message
      if ($attempt -lt 3) { Start-Sleep -Seconds (2 * $attempt) }
    }
  }
  throw "cannot reach $url after 3 attempts: $last"
}

function Local-Version {
  if (Test-Path -LiteralPath $versionFile) { return (Get-Content -Raw -LiteralPath $versionFile).Trim() }
  return '0.0.0'
}

function Hash-File([string]$path) {
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Download-Verified([string]$url, [string]$expected, [string]$destination) {
  New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
  $last = $null
  foreach ($attempt in 1..3) {
    try {
      Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -TimeoutSec 600
      break
    } catch {
      $last = $_.Exception.Message
      Remove-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
      if ($attempt -lt 3) { Start-Sleep -Seconds (2 * $attempt) }
    }
  }
  if (-not (Test-Path -LiteralPath $destination)) { throw "download failed: $last" }
  $actual = Hash-File $destination
  if ($actual -ne $expected.ToLowerInvariant()) {
    Remove-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    throw "sha256 mismatch: got $actual, expected $expected"
  }
  return $actual
}

function Stop-App {
  Get-CimInstance Win32_Process |
    Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase) -and $_.Name -like '*.exe' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Milliseconds 800
}

$api = Resolve-Api
$manifest = Fetch-Manifest $api
$current = Local-Version
$target = $manifest.version

Log "manifest $target (local $current) from $api"

if (-not $Force -and $target -eq $current) {
  Log 'already up to date.'
  exit 0
}

if ($Check) {
  Log ('update available: ' + $target)
  if ($manifest.notes) { Log ('notes: ' + $manifest.notes) }
  exit 0
}

$stage = Join-Path $backup ('staging-' + $target)
New-Item -ItemType Directory -Path $stage -Force | Out-Null

$newEngine = Join-Path $stage 'opencode-cli.exe'
Log 'downloading engine...'
$hash = Download-Verified $manifest.engine.url $manifest.engine.sha256 $newEngine
Log "engine verified sha256=$hash"

$oldEngine = Join-Path $backup ('opencode-cli-' + $current + '.exe')
if (Test-Path -LiteralPath $engine) { Copy-Item -LiteralPath $engine -Destination $oldEngine -Force }

try {
  Stop-App
  Copy-Item -LiteralPath $newEngine -Destination $engine -Force
  [System.IO.File]::WriteAllText($versionFile, $target, (New-Object System.Text.UTF8Encoding($false)))
  $state = [ordered]@{
    version = $target
    previous = $current
    applied_at = (Get-Date).ToUniversalTime().ToString('o')
    sha256 = $hash
    api = $api
  }
  $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile -Encoding UTF8
  Log "engine updated to $target"
} catch {
  if (Test-Path -LiteralPath $oldEngine) { Copy-Item -LiteralPath $oldEngine -Destination $engine -Force }
  [System.IO.File]::WriteAllText($versionFile, $current, (New-Object System.Text.UTF8Encoding($false)))
  Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
  throw "update failed and rolled back: $($_.Exception.Message)"
}

Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue

if ($manifest.app -and $manifest.app.url -and $manifest.app.sha256) {
  Log 'app bundle present in manifest - download and swap handled by install.ps1 with -Bundle.'
}

Log 'done.'

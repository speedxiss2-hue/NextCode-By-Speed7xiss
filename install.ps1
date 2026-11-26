#requires -Version 5.1
# One-shot installer for the community bundle.
# Usage: powershell -File install.ps1 [-Bundle zip] [-ApiUrl url] [-SkipWarp]
param(
  [string]$Bundle,
  [string]$ApiUrl,
  [switch]$SkipWarp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
function Step([string]$text) { Write-Host ('[install] ' + $text) -ForegroundColor Cyan }
function Done([string]$text) { Write-Host ('[ok] ' + $text) -ForegroundColor Green }

Step 'checking the local bundle'
if (-not (Test-Path -LiteralPath (Join-Path $root 'AGENTS.md'))) {
  throw 'AGENTS.md missing - this is not a NextCode bundle. Extract the full zip, then run install.bat.'
}
Done 'bundle found'

if ($ApiUrl) {
  $config = Join-Path $root 'update-api.txt'
  [System.IO.File]::WriteAllText($config, $ApiUrl, (New-Object System.Text.UTF8Encoding($false)))
  [Environment]::SetEnvironmentVariable('NEXTCODE_UPDATE_API', $ApiUrl, 'User')
  $env:NEXTCODE_UPDATE_API = $ApiUrl
  Done ('update API saved for this user: ' + $ApiUrl)
}

# WebView2 is the only hard prerequisite of the Electron shell.
Step 'checking WebView2 runtime'
$webviewKeys = @(
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
  'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
)
if (-not ($webviewKeys | Where-Object { Test-Path -LiteralPath $_ })) {
  Step 'installing WebView2 Evergreen Runtime'
  $bootstrap = Join-Path $env:TEMP 'MicrosoftEdgeWebView2RuntimeInstaller.exe'
  Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $bootstrap -UseBasicParsing -TimeoutSec 300
  Start-Process -FilePath $bootstrap -ArgumentList '/silent','/install' -Wait
  Remove-Item -LiteralPath $bootstrap -Force -ErrorAction SilentlyContinue
  Done 'WebView2 installed'
} else { Done 'WebView2 already present' }

if (-not $SkipWarp) {
  Step 'checking Cloudflare WARP'
  $warpCli = @(
    (Join-Path $env:ProgramFiles 'Cloudflare\Cloudflare WARP\warp-cli.exe'),
    (Join-Path $env:LOCALAPPDATA 'Cloudflare\Cloudflare WARP\warp-cli.exe')
  ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if (-not $warpCli) {
    $msi = Join-Path $env:TEMP 'Cloudflare_WARP_installer.msi'
    Step 'downloading WARP (one UAC prompt may appear)'
    Invoke-WebRequest -Uri 'https://downloads.cloudflareclient.com/v1/download/windows/ga' -OutFile $msi -UseBasicParsing -TimeoutSec 300
    $result = Start-Process msiexec -ArgumentList @('/i', ('"' + $msi + '"'), '/qn', '/norestart') -Verb RunAs -Wait -PassThru
    Remove-Item -LiteralPath $msi -Force -ErrorAction SilentlyContinue
    if (@(0,3010) -notcontains $result.ExitCode) { throw ('WARP install failed with code ' + $result.ExitCode) }
    Done 'WARP installed'
  } else { Done 'WARP already present' }
} else { Step 'WARP install skipped' }

if ($Bundle) {
  Step ('expanding bundle ' + $Bundle)
  $stage = Join-Path $env:TEMP ('nextcode-bundle-' + [guid]::NewGuid().ToString('N'))
  Expand-Archive -LiteralPath $Bundle -DestinationPath $stage -Force
  $exe = Get-ChildItem -LiteralPath $stage -Recurse -Filter 'NextCode.exe' | Select-Object -First 1
  if (-not $exe) { throw 'bundle has no NextCode.exe' }
  $source = $exe.Directory.FullName
  $destination = Join-Path $root 'build'
  Get-CimInstance Win32_Process |
    Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($destination, [System.StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Copy-Item -LiteralPath (Join-Path $source '*') -Destination $destination -Recurse -Force
  Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
  Done 'bundle installed into build\'
}

Step 'installing the global CLI, persona and subagents'
& (Join-Path $root 'setup.ps1')
if ($LASTEXITCODE -ne 0) { throw 'setup.ps1 failed' }
Done 'setup complete'

Step 'selecting the exclusive NextCode model'
& (Join-Path $root 'select-nextcode-model.ps1')
if ($LASTEXITCODE -ne 0) { throw 'model selection failed' }
Done 'exclusive model selected'

Step 'running diagnostics with safe fixes'
& (Join-Path $root 'doctor.ps1') -Fix $ApiUrl
Done 'diagnostics complete'

Step 'smoke test'
$cli = Join-Path $env:LOCALAPPDATA 'NextCode\bin\opencode.exe'
if (-not (Test-Path -LiteralPath $cli)) { throw 'CLI missing after setup' }
$version = & $cli --version 2>&1 | Out-String
if ($version -notmatch '\d+\.\d+\.\d+') { throw ('unexpected CLI version: ' + $version) }
Done ('CLI ' + $version.Trim())

$model = (Get-Content -Raw -LiteralPath (Join-Path $env:USERPROFILE '.config\opencode\opencode.json') | ConvertFrom-Json).model
if ($model -notlike 'opencode/*') { throw ('non-exclusive model configured: ' + $model) }
Done ('model ' + $model)

Write-Host ''
Write-Host 'Install finished. Next steps:' -ForegroundColor Green
Write-Host '  1. Open build\NextCode.exe'
Write-Host '  2. If the free limit appears, click reset usage in the desktop app'
Write-Host '  3. Run autoupdate.bat -Check before each build; autoupdate.bat applies updates'

#requires -Version 5.1
# Reverses setup.ps1. Only paths recorded in the install manifest are removed,
# so skills or agents the user added themselves are left alone.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$StateDir  = Join-Path $env:LOCALAPPDATA 'NextCode'
$BinDir    = Join-Path $StateDir 'bin'
$Manifest  = Join-Path $StateDir 'installed-files.txt'
$ConfigBak = Join-Path $StateDir 'opencode.json.backup'

if (-not (Test-Path -LiteralPath $Manifest)) {
  Write-Host 'Nothing to uninstall: no NextCode install manifest found.'
  exit 0
}

$paths = @(Get-Content -LiteralPath $Manifest | Where-Object { $_ })
[array]::Reverse($paths)
foreach ($path in $paths) {
  if (-not (Test-Path -LiteralPath $path)) { continue }
  $item = Get-Item -LiteralPath $path
  if ($item.PSIsContainer) {
    Remove-Item -LiteralPath $path -Recurse -Force
  } else {
    Remove-Item -LiteralPath $path -Force
  }
  Write-Host "removed $path"
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
  $kept = @($userPath -split ';' | Where-Object { $_ -and $_ -ne $BinDir })
  [Environment]::SetEnvironmentVariable('Path', ($kept -join ';'), 'User')
  Write-Host "removed $BinDir from PATH"
}

if (Test-Path -LiteralPath $ConfigBak) {
  $configPath = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
  Copy-Item -LiteralPath $ConfigBak -Destination $configPath -Force
  Remove-Item -LiteralPath $ConfigBak -Force
  Write-Host 'restored opencode.json'
}

Remove-Item -LiteralPath $Manifest -Force
if ((Test-Path -LiteralPath $BinDir) -and -not (Get-ChildItem -LiteralPath $BinDir -Force)) {
  Remove-Item -LiteralPath $BinDir -Force
}
Write-Host ''
Write-Host 'NextCode CLI uninstalled. Open a new terminal for the PATH change to apply.'

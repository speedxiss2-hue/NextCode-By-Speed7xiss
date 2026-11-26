#requires -Version 5.1
# Installs the NextCode engine as this machine's `opencode` command and wires
# NextCode's AGENTS.md, skills and subagents into the global OpenCode config.
# Re-running is safe: unchanged files are left alone and the PATH entry is not duplicated.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$Engine    = Join-Path $Root 'build\resources\opencode-cli.exe'
$StampFile = Join-Path $Root 'build\resources\opencode-cli.version'
$StateDir  = Join-Path $env:LOCALAPPDATA 'NextCode'
$BinDir    = Join-Path $StateDir 'bin'
$ConfigDir = Join-Path $env:USERPROFILE '.config\opencode'
$SkillsSrc = Join-Path $Root 'Skills'
$AgentsSrc = Join-Path $Root 'SubAgents'
$Manifest  = Join-Path $StateDir 'installed-files.txt'
$ConfigBak = Join-Path $StateDir 'opencode.json.backup'
$TargetExe = Join-Path $BinDir 'opencode.exe'
$TargetVer = Join-Path $BinDir 'opencode.version'

function Write-Step([int]$number, [string]$text) {
  Write-Host "[$number/6] $text"
}

function Add-Manifest([string]$path) {
  $lines = @()
  if (Test-Path -LiteralPath $Manifest) { $lines = @(Get-Content -LiteralPath $Manifest) }
  if ($lines -notcontains $path) { Add-Content -LiteralPath $Manifest -Value $path }
}

function Copy-Tracked([string]$from, [string]$to) {
  Copy-Item -LiteralPath $from -Destination $to -Force
  Add-Manifest $to
}

if (-not (Test-Path -LiteralPath $Engine)) {
  throw "No engine at $Engine. Run build.bat first, then run setup.bat."
}

New-Item -ItemType Directory -Path $StateDir, $BinDir, $ConfigDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ConfigDir 'agent') -Force | Out-Null

Write-Step 1 'Installing the CLI'
$sourceVersion = ''
if (Test-Path -LiteralPath $StampFile) {
  $sourceVersion = (Get-Content -Raw -LiteralPath $StampFile).Trim()
}
$installedVersion = ''
if (Test-Path -LiteralPath $TargetVer) {
  $installedVersion = (Get-Content -Raw -LiteralPath $TargetVer).Trim()
}
if (-not (Test-Path -LiteralPath $TargetExe) -or $sourceVersion -ne $installedVersion) {
  Write-Host "      engine $installedVersion -> $sourceVersion"
  Copy-Item -LiteralPath $Engine -Destination $TargetExe -Force
  if ($sourceVersion) {
    [System.IO.File]::WriteAllText($TargetVer, $sourceVersion, (New-Object System.Text.UTF8Encoding($false)))
  }
} else {
  Write-Host "      engine $installedVersion already installed"
}
Add-Manifest $TargetExe
Add-Manifest $TargetVer

Write-Step 2 'Putting the CLI on PATH'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
$entries = @($userPath -split ';' | Where-Object { $_ })
if ($entries -notcontains $BinDir) {
  [Environment]::SetEnvironmentVariable('Path', "$BinDir;$userPath", 'User')
  Write-Host "      added $BinDir"
} else {
  Write-Host '      PATH entry already present'
}
$env:Path = "$BinDir;$env:Path"

Write-Step 3 'Installing AGENTS.md'
Copy-Tracked (Join-Path $Root 'AGENTS.md') (Join-Path $ConfigDir 'AGENTS.md')
Write-Host '      global instructions installed'

Write-Step 4 'Installing subagents'
$agentsOut = Join-Path $ConfigDir 'agent'
Get-ChildItem -LiteralPath $AgentsSrc -Filter '*.md' -File | Where-Object { $_.Name -ne 'README.md' } | ForEach-Object {
  Copy-Tracked $_.FullName (Join-Path $agentsOut $_.Name)
  Write-Host "      subagent $($_.Name)"
}

Write-Step 5 'Registering the skills directory'
# Skills live in the global config, not beside the build: a moved or deleted build folder must not
# break skill discovery after the app has been installed.
$SkillsOut = Join-Path $ConfigDir 'skills'
New-Item -ItemType Directory -Path $SkillsOut -Force | Out-Null
Get-ChildItem -LiteralPath $SkillsSrc -Directory | ForEach-Object {
  $destination = Join-Path $SkillsOut $_.Name
  New-Item -ItemType Directory -Path $destination -Force | Out-Null
  Get-ChildItem -LiteralPath $_.FullName -File | ForEach-Object {
    Copy-Tracked $_.FullName (Join-Path $destination $_.Name)
  }
}
$skillsRoot = ($SkillsOut -replace '\\', '/')
$configPath = Join-Path $ConfigDir 'opencode.json'
$configObject = $null
if (Test-Path -LiteralPath $configPath) {
  if (-not (Test-Path -LiteralPath $ConfigBak)) {
    Copy-Item -LiteralPath $configPath -Destination $ConfigBak -Force
  }
  try {
    $configObject = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
  } catch {
    Write-Host '      config uses JSONC comments; registration skipped'
  }
} else {
  $configObject = [ordered]@{ '$schema' = 'https://opencode.ai/config.json' }
}

if ($null -ne $configObject) {
  $skillsDirectory = $skillsRoot
  $registered = @()
  $isDictionary = $configObject -is [System.Collections.IDictionary]
  if ($isDictionary) {
    if ($configObject.Contains('skills')) { $registered = @($configObject['skills']) }
  } elseif ($configObject.PSObject.Properties['skills']) {
    $registered = @($configObject.skills)
  }
  # Drop the old build-local registration so a moved build cannot point at a dead directory.
  $registered = @($registered | Where-Object {
    $entry = ($_ -replace '\\', '/')
    $entry -notmatch '/Skills$' -and $entry -ne $skillsDirectory
  })
  if ($registered -notcontains $skillsDirectory) {
    $registered += $skillsDirectory
    if ($isDictionary) {
      $configObject['skills'] = $registered
    } else {
      $configObject | Add-Member -NotePropertyName 'skills' -NotePropertyValue $registered -Force
    }
  }
  $json = $configObject | ConvertTo-Json -Depth 30
  [System.IO.File]::WriteAllText($configPath, "$json`n", (New-Object System.Text.UTF8Encoding($false)))
  Add-Manifest $configPath
  Write-Host '      opencode.json updated'
}

Write-Step 6 'Verifying'
$reported = & $TargetExe --version 2>&1
if ($LASTEXITCODE -ne 0) {
  throw "The installed CLI failed its version check: $reported"
}

Write-Host ''
Write-Host 'NextCode is installed like a stock OpenCode:'
Write-Host "  command : $TargetExe"
Write-Host "  version : $reported"
Write-Host '  run it  : open a new terminal, then type opencode'
Write-Host '  remove  : run uninstall.bat from this folder'

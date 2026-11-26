#requires -Version 5.1
# Picks a NextCode-exclusive opencode/* model as the global default.
# No Ollama, no local runtime, no API key.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$cli = Join-Path $env:LOCALAPPDATA 'NextCode\bin\opencode.exe'
if (-not (Test-Path -LiteralPath $cli)) {
  $found = Get-Command opencode -ErrorAction SilentlyContinue
  if ($found) { $cli = $found.Source } else { throw 'opencode.exe not found. Run setup.bat first.' }
}

Write-Host 'Fetching the NextCode model roster...'
$all = & $cli models 2>&1 | ForEach-Object { [string]$_ }
$exclusive = @($all | Where-Object { $_ -match '^opencode/' -and $_ -notmatch '\s' })
if ($exclusive.Count -eq 0) { throw 'No opencode/* models in the roster. Check the NextCode connection.' }

$preference = @(
  'opencode/nemotron-3.5-super-vl-free',
  'opencode/hy4-flash-free',
  'opencode/big-pickle',
  'opencode/iceman-free',
  'opencode/deepseek-v4.1-flash-free',
  'opencode/nemotron-3.5-lightning-free',
  'opencode/beam-free',
  'opencode/flint-40b-free',
  'opencode/mimo-v2.6-flash-free',
  'opencode/tidepool-alpha-free'
)

$chosen = $null
foreach ($id in $preference) { if ($exclusive -contains $id) { $chosen = $id; break } }
if (-not $chosen) { $chosen = $exclusive[0] }

$configPath = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
$config = if (Test-Path -LiteralPath $configPath) {
  Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
} else {
  [ordered]@{ '$schema' = 'https://opencode.ai/config.json' }
}
if ($config -is [System.Collections.IDictionary]) {
  $config['model'] = $chosen
  $json = $config | ConvertTo-Json -Depth 30
} else {
  $config | Add-Member -NotePropertyName 'model' -NotePropertyValue $chosen -Force
  $json = $config | ConvertTo-Json -Depth 30
}
[System.IO.File]::WriteAllText($configPath, "$json`n", (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host 'NextCode exclusive roster:'
$exclusive | ForEach-Object { Write-Host "  $_" }
Write-Host ''
Write-Host "Default model: $chosen"
Write-Host 'When the free limit shows up, click reset usage in the NextCode desktop app.'

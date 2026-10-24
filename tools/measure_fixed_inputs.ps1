param([string]$GodotPath = 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) { throw "Godot executable not found: $GodotPath" }
$sourceRevision = (& git -C $projectPath rev-parse HEAD).Trim()
$controllerHash = (Get-FileHash -LiteralPath (Join-Path $projectPath 'tests/replay_fixed_inputs.gd') -Algorithm SHA256).Hash
$runName = 'fixed-inputs-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6)
$reportPath = Join-Path (Split-Path $projectPath -Parent) ('verification/' + $runName)
New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
$reports = @()
foreach ($species in @('mossback','thornhorn','reedclaw','mistfrill','stormcrest')) {
    $lines = @(& $GodotPath --headless --path $projectPath --fixed-fps 60 --script res://tests/replay_fixed_inputs.gd --quit-after 6000 -- ("--species=" + $species) 2>&1 | ForEach-Object { "$_" })
    $code = $LASTEXITCODE
    $lines | Set-Content -LiteralPath (Join-Path $reportPath ($species + '.log')) -Encoding utf8
    $marker = @($lines | Where-Object { $_ -match '^FIXED_INPUT_REPLAY: ' } | Select-Object -Last 1)
    $result = $null
    if ($marker.Count -eq 1) { try { $result = ($marker[0] -replace '^FIXED_INPUT_REPLAY: ','') | ConvertFrom-Json } catch {} }
    $completed = $code -eq 0 -and $null -ne $result -and $result.completed -eq $true -and $result.species -eq $species -and -not ($lines -match 'SCRIPT ERROR:|ERROR:')
    $reports += [pscustomobject]@{ species=$species; completed=$completed; exit_code=$code; result=$result }
    Write-Output ($species + ': ' + $(if ($completed) { $result.outcome + ' at ' + $result.seconds + 's; HP ' + $result.player_health } else { 'INCOMPLETE' }))
}
$completed = @($reports | Where-Object { -not $_.completed }).Count -eq 0
[pscustomobject]@{completed=$completed;source_revision=$sourceRevision;controller_sha256=$controllerHash;scope='Fixed-input measurement, not a human difficulty acceptance gate. Defeat/victory are observations, not test pass/fail.';cases=$reports} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $reportPath 'summary.json') -Encoding utf8
Write-Output ('FIXED_INPUT_REPORT: ' + (Join-Path $reportPath 'summary.json'))
if (-not $completed) { exit 1 }

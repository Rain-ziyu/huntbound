param(
    [string]$GodotConsole = 'D:/Godot/Godot_v4.7.2-stable_win64_console.exe',
    [string]$GodotRuntime = 'D:/Godot/Godot_v4.7.2-stable_win64.exe'
)
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
foreach ($file in @($GodotConsole,$GodotRuntime)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing Godot executable: $file" }
}
$buildRoot = Join-Path (Split-Path $projectPath -Parent) 'builds'
$buildName = 'Shubian-Windows-Preview-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,6)
$packagePath = Join-Path $buildRoot $buildName
New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
$pack = Join-Path $packagePath 'Shubian.pck'
$exportLog = Join-Path $buildRoot ($buildName + '-export.log')
$exportLines = @(& $GodotConsole --headless --path $projectPath --export-pack 'Windows Preview' $pack 2>&1 | ForEach-Object { "$_" })
$exportCode = $LASTEXITCODE
$exportLines | Set-Content -LiteralPath $exportLog -Encoding utf8
if ($exportCode -ne 0 -or -not (Test-Path -LiteralPath $pack)) { throw "Pack export failed; see $exportLog" }
$runtime = Join-Path $packagePath 'Shubian.exe'
Copy-Item -LiteralPath $GodotRuntime -Destination $runtime
$noticeScript = Join-Path $PSScriptRoot 'write_runtime_notices.gd'
$noticeLines = @(& $runtime --headless --main-pack $pack --script $noticeScript -- $packagePath 2>&1 | ForEach-Object { "$_" })
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $packagePath 'GODOT-LICENSE.txt'))) { throw 'Runtime notices were not written' }
Copy-Item -LiteralPath (Join-Path $projectPath 'docs/preview-playtest.txt') -Destination (Join-Path $packagePath 'README.txt')
@'
@echo off
start "" "%~dp0Shubian.exe" --main-pack "%~dp0Shubian.pck"
'@ | Set-Content -LiteralPath (Join-Path $packagePath 'Start-Shubian.bat') -Encoding ascii
$checkScript = Join-Path $projectPath 'tools/check_packed_preview.gd'
$checkLog = Join-Path $buildRoot ($buildName + '-check.log')
Push-Location $packagePath
try {
    # A pipeline waits for the GUI-subsystem executable, even in headless mode.
    $checkLines = @(& $runtime --headless --main-pack $pack --script $checkScript --quit-after 600 2>&1 | ForEach-Object { "$_" })
    $checkCode = $LASTEXITCODE
} finally { Pop-Location }
$checkLines | Set-Content -LiteralPath $checkLog -Encoding utf8
if ($checkCode -ne 0 -or -not ($checkLines -match '^PACKED_PREVIEW_CHECKS: 9 FAILURES: 0$') -or ($checkLines -match 'SCRIPT ERROR:|^ERROR:')) { throw "Pack verification failed; see $checkLog" }
$revision = (git -C $projectPath rev-parse HEAD).Trim()
$manifest = [pscustomobject]@{
    name = 'Shubian Windows single-player prototype preview'
    source_revision = $revision
    runtime_kind = 'Bundled Godot editor executable plus exported PCK; not a release-template build'
    created_utc = [DateTime]::UtcNow.ToString('o')
    pack_sha256 = (Get-FileHash -LiteralPath $pack -Algorithm SHA256).Hash
    runtime_sha256 = (Get-FileHash -LiteralPath $runtime -Algorithm SHA256).Hash
    checks = '9 isolated packed-resource, exclusion, movement, skin and contact checks passed'
    scope = 'Pack smoke verification only; no human difficulty or final animation acceptance'
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $packagePath 'build-manifest.json') -Encoding utf8
$archive = Join-Path $buildRoot ($buildName + '.zip')
Compress-Archive -LiteralPath $packagePath -DestinationPath $archive -CompressionLevel Fastest
Write-Output ('PREVIEW_FOLDER: ' + $packagePath)
Write-Output ('PREVIEW_ARCHIVE: ' + $archive)
Write-Output ('PREVIEW_CHECK_LOG: ' + $checkLog)

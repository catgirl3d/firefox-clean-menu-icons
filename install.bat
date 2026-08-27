@echo off
setlocal
set "REPO_DIR=%~dp0"
title Firefox Clean Menu Icons Installer

echo ===================================================
echo   Firefox Clean Menu Icons - Easy Installer
echo ===================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$repoDir = $env:REPO_DIR;" ^
    "if (-not (Test-Path (Join-Path $repoDir 'css')) -or -not (Test-Path (Join-Path $repoDir 'icons'))) {" ^
    "    Write-Host '[ERROR] css/icons folders not found next to install.bat at: ' $repoDir -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$ffPath = Join-Path $env:APPDATA 'Mozilla\Firefox';" ^
    "if (-not (Test-Path $ffPath)) {" ^
    "    Write-Host '[ERROR] Firefox AppData folder not found at: ' $ffPath -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "$profilesIni = Join-Path $ffPath 'profiles.ini';" ^
    "$targetProfile = $null;" ^
    "if (Test-Path $profilesIni) {" ^
    "    $lines = Get-Content $profilesIni;" ^
    "    $res = { param($p) if ([System.IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $ffPath $p } };" ^
    "    $inInstall = $false;" ^
    "    foreach ($line in $lines) {" ^
    "        if ($line -match '^\s*\[') { $inInstall = ($line -match '^\s*\[Install'); continue };" ^
    "        if (-not $inInstall) { continue };" ^
    "        if ($line -match '^\s*Default=(.+)$') {" ^
    "            $candidate = & $res ($matches[1].Trim());" ^
    "            if (Test-Path $candidate) { $targetProfile = $candidate; break };" ^
    "        };" ^
    "    };" ^
    "}" ^
    "if ($lines -and -not $targetProfile) {" ^
    "    $isProf = $false;" ^
    "    $secP = $null;" ^
    "    $secD = $false;" ^
    "    foreach ($line in $lines) {" ^
    "        if ($line -match '^\s*\[') {" ^
    "            if ($isProf -and $secP -and $secD) {" ^
    "                $candidate = & $res $secP;" ^
    "                if (Test-Path $candidate) { $targetProfile = $candidate; break };" ^
    "            };" ^
    "            $isProf = ($line -match '^\s*\[Profile');" ^
    "            $secP = $null;" ^
    "            $secD = $false;" ^
    "            continue" ^
    "        };" ^
    "        if (-not $isProf) { continue };" ^
    "        if ($line -match '^\s*Path=(.+)$') { $secP = $matches[1].Trim() };" ^
    "        if ($line -match '^\s*Default=(.*)$') { if ($matches[1].Trim() -eq '1') { $secD = $true } };" ^
    "    };" ^
    "    if (-not $targetProfile -and $isProf -and $secP -and $secD) {" ^
    "        $candidate = & $res $secP;" ^
    "        if (Test-Path $candidate) { $targetProfile = $candidate };" ^
    "};" ^
    "};" ^
    "if (-not $targetProfile) {" ^
    "    $candidate = Get-ChildItem (Join-Path $ffPath 'Profiles') -Directory | Where-Object { $_.Name -like '*default*' } | Select-Object -First 1;" ^
    "    if ($candidate) { $targetProfile = $candidate.FullName };" ^
    "};" ^
    "if (-not $targetProfile) {" ^
    "    Write-Host '[ERROR] Could not automatically find a Firefox profile.' -ForegroundColor Red;" ^
    "    exit 1;" ^
    "};" ^
    "Write-Host ('[+] Found Firefox profile: ' + (Split-Path $targetProfile -Leaf)) -ForegroundColor Cyan;" ^
    "$chromeDir = Join-Path $targetProfile 'chrome';" ^
    "$userJs = Join-Path $targetProfile 'user.js';" ^
    "$userChrome = Join-Path $chromeDir 'userChrome.css';" ^
    "$backupStamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss');" ^
    "$backupSuffix = '.firefox-clean-menu-icons-backup-' + $backupStamp;" ^
    "$backupCount = 0;" ^
    "function Backup-File([string]$source) {" ^
    "    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw ('Cannot backup non-file: ' + $source) };" ^
    "    $backup = $source + $backupSuffix; $index = 1;" ^
    "    while (Test-Path -LiteralPath $backup) { $backup = $source + $backupSuffix + '-' + $index; $index++ };" ^
    "    try {" ^
    "        Copy-Item -LiteralPath $source -Destination $backup -Force -ErrorAction Stop;" ^
    "        $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256 -ErrorAction Stop).Hash;" ^
    "        $backupHash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256 -ErrorAction Stop).Hash;" ^
    "        if ($sourceHash -ne $backupHash) { throw ('Backup verification failed: ' + $source) };" ^
    "        $script:backupCount++;" ^
    "    } catch { Remove-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue; throw };" ^
    "    };" ^
    "try {" ^
    "    foreach ($file in @($userJs, $userChrome)) { if (Test-Path -LiteralPath $file) { Backup-File $file } };" ^
    "    foreach ($sourceDir in @((Join-Path $repoDir 'css'), (Join-Path $repoDir 'icons'))) {" ^
    "        $targetDir = Join-Path $chromeDir (Split-Path $sourceDir -Leaf);" ^
    "        Get-ChildItem -LiteralPath $sourceDir -File -Recurse -ErrorAction Stop | ForEach-Object {" ^
    "            $relative = $_.FullName.Substring($sourceDir.Length).TrimStart('\');" ^
    "            $target = Join-Path $targetDir $relative;" ^
    "            if (Test-Path -LiteralPath $target) { Backup-File $target };" ^
    "        };" ^
    "    };" ^
    "} catch {" ^
    "    Write-Host ('[ERROR] Backup failed: ' + $_.Exception.Message) -ForegroundColor Red;" ^
    "    Write-Host '[!] Installation stopped before changing the Firefox profile.' -ForegroundColor Yellow;" ^
    "    exit 1;" ^
    "};" ^
    "if (-not (Test-Path $chromeDir)) { New-Item -ItemType Directory -Path $chromeDir -Force | Out-Null };" ^
    "try {" ^
    "    Copy-Item -Path (Join-Path $repoDir 'css') -Destination $chromeDir -Recurse -Force -ErrorAction Stop;" ^
    "    Copy-Item -Path (Join-Path $repoDir 'icons') -Destination $chromeDir -Recurse -Force -ErrorAction Stop;" ^
    "    Write-Host '[+] Copied css and icons into chrome folder.' -ForegroundColor Green;" ^
    "} catch {" ^
    "    Write-Host ('[ERROR] Failed to copy css/icons: ' + $_.Exception.Message) -ForegroundColor Red;" ^
    "    Write-Host '[!] To reset, remove the chrome/css and chrome/icons folders inside this Firefox profile and run install.bat again.' -ForegroundColor Yellow;" ^
    "    exit 1;" ^
    "};" ^
    "$pref = 'user_pref(\"toolkit.legacyUserProfileCustomizations.stylesheets\", true);';" ^
    "if (Test-Path $userJs) {" ^
    "    $content = Get-Content $userJs -Raw;" ^
    "    if ($content -notmatch 'toolkit\.legacyUserProfileCustomizations\.stylesheets') {" ^
    "        Add-Content -Path $userJs -Value ('`n' + $pref);" ^
    "    };" ^
    "} else {" ^
    "    Set-Content -Path $userJs -Value $pref;" ^
    "};" ^
    "Write-Host '[+] Enabled userChrome stylesheets in user.js.' -ForegroundColor Green;" ^
    "$importLine = '@import url(\"css/clean-menu-icons.css\");';" ^
    "if (Test-Path $userChrome) {" ^
    "    $content = Get-Content $userChrome -Raw;" ^
    "    if ($content -notmatch 'clean-menu-icons\.css') {" ^
    "        $prefixBytes = [System.Text.Encoding]::ASCII.GetBytes($importLine + \"`n`n\");" ^
    "        [System.IO.File]::WriteAllBytes($userChrome, ($prefixBytes + [System.IO.File]::ReadAllBytes($userChrome)));" ^
    "        Write-Host '[+] Added clean-menu-icons import to userChrome.css.' -ForegroundColor Green;" ^
    "    } else {" ^
    "        Write-Host '[+] clean-menu-icons is already imported in userChrome.css.' -ForegroundColor Yellow;" ^
    "    };" ^
    "} else {" ^
    "    Set-Content -Path $userChrome -Value ($importLine + '`n');" ^
    "    Write-Host '[+] Created userChrome.css with clean-menu-icons import.' -ForegroundColor Green;" ^
    "};" ^
    "Write-Host '';" ^
    "Write-Host '===================================================' -ForegroundColor Green;" ^
    "Write-Host '  [OK] Installation completed successfully!' -ForegroundColor Green;" ^
    "Write-Host '  Please restart Firefox to apply the changes.' -ForegroundColor Green;" ^
    "if ($backupCount -gt 0) {" ^
    "    Write-Host ('  Verified backups created: ' + $backupCount) -ForegroundColor Green;" ^
    "    Write-Host ('  Backup suffix: ' + $backupSuffix) -ForegroundColor Green;" ^
    "    Write-Host '  Backups are located next to the original files.' -ForegroundColor Green;" ^
    "} else {" ^
    "    Write-Host '  No existing files required a backup.' -ForegroundColor Yellow;" ^
    "};" ^
    "Write-Host '===================================================' -ForegroundColor Green;"

set "INSTALL_EXIT_CODE=%ERRORLEVEL%"

echo.
pause
exit /b %INSTALL_EXIT_CODE%

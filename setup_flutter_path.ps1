# Script to find and configure Flutter PATH on Windows

Write-Host "=== Searching for Flutter ===" -ForegroundColor Cyan

$flutterPaths = @(
    "$env:LOCALAPPDATA\Android\flutter\bin",
    "C:\src\flutter\bin",
    "C:\flutter\bin",
    "D:\flutter\bin",
    "$env:USERPROFILE\flutter\bin"
)

$foundFlutter = $null

foreach ($path in $flutterPaths) {
    $flutterBat = Join-Path $path "flutter.bat"
    if (Test-Path $flutterBat) {
        Write-Host "Found Flutter at: $path" -ForegroundColor Green
        $foundFlutter = $path
        break
    }
}

if (-not $foundFlutter) {
    Write-Host "Flutter not found in common locations." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please enter Flutter installation path (or press Enter to skip):"
    $customPath = Read-Host
    
    if ($customPath -and (Test-Path (Join-Path $customPath "bin\flutter.bat"))) {
        $foundFlutter = Join-Path $customPath "bin"
        Write-Host "Found Flutter at: $foundFlutter" -ForegroundColor Green
    }
}

if ($foundFlutter) {
    Write-Host ""
    Write-Host "=== Checking PATH ===" -ForegroundColor Cyan
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -like "*$foundFlutter*") {
        Write-Host "Flutter is already in PATH!" -ForegroundColor Green
    } else {
        Write-Host "Flutter is NOT in PATH" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Add Flutter to PATH? (Y/N)"
        $addToPath = Read-Host
        
        if ($addToPath -eq "Y" -or $addToPath -eq "y") {
            try {
                $newPath = $currentPath + ";" + $foundFlutter
                [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
                Write-Host "Added Flutter to PATH!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Note: Close and reopen PowerShell for PATH to take effect." -ForegroundColor Yellow
                Write-Host "Or run this command to update PATH now:"
                Write-Host '$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")' -ForegroundColor Gray
            } catch {
                Write-Host "Error adding to PATH: $_" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Testing Flutter ===" -ForegroundColor Cyan
    & "$foundFlutter\flutter.bat" --version
    
    Write-Host ""
    Write-Host "=== Quick Fix for Current Session ===" -ForegroundColor Cyan
    Write-Host "To use Flutter in current PowerShell, run:"
    Write-Host "`$env:Path += `";$foundFlutter`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Then run:"
    Write-Host "cd quanlychitieu" -ForegroundColor Gray
    Write-Host "flutter pub get" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "=== Flutter Installation Guide ===" -ForegroundColor Cyan
    Write-Host "1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows"
    Write-Host "2. Extract to a folder (e.g., C:\src\flutter)"
    Write-Host "3. Add C:\src\flutter\bin to PATH"
    Write-Host "4. Run this script again to configure"
}

Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host

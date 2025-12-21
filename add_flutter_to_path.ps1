# Script to add Flutter to PATH permanently on Windows

$flutterPath = "D:\thanhtuan\flutter_windows_3.38.5-stable\flutter\bin"

Write-Host "=== Adding Flutter to PATH ===" -ForegroundColor Cyan
Write-Host "Flutter path: $flutterPath" -ForegroundColor Gray

# Get current user PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

# Check if already in PATH
if ($currentPath -like "*$flutterPath*") {
    Write-Host "Flutter is already in PATH!" -ForegroundColor Green
} else {
    try {
        # Add to PATH
        $newPath = $currentPath + ";" + $flutterPath
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "Successfully added Flutter to PATH!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Note: Please close and reopen PowerShell for PATH to take effect." -ForegroundColor Yellow
        Write-Host "Or run this command to update PATH in current session:" -ForegroundColor Yellow
        Write-Host "`$env:Path += `";$flutterPath`"" -ForegroundColor Gray
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual steps:" -ForegroundColor Yellow
        Write-Host "1. Press Win+R, type: sysdm.cpl" -ForegroundColor Gray
        Write-Host "2. Go to Advanced > Environment Variables" -ForegroundColor Gray
        Write-Host "3. Under User variables, select Path > Edit" -ForegroundColor Gray
        Write-Host "4. Click New and add: $flutterPath" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host



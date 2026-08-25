# AgroVision AI — Backend Server Startup Script
# ================================================
# Run this PowerShell script to start the backend server.
# Usage: Right-click > Run with PowerShell
#        Or in terminal: .\start_server.ps1
#
# The backend binds to 0.0.0.0:8000 so both desktop browser
# and physical mobile devices on the same WiFi network can connect.

$Host.UI.RawUI.WindowTitle = "AgroVision AI Backend"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "   AgroVision AI — Backend Server" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Check Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Python not found. Please install Python 3.9+." -ForegroundColor Red
    pause
    exit 1
}

# Get LAN IP
$lan_ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^127\.' -and $_.IPAddress -notmatch '^169\.' } | Select-Object -First 1).IPAddress
$port = "8000"

Write-Host "Your PC's LAN IP: $lan_ip" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend URLs:" -ForegroundColor Yellow
Write-Host "  Desktop Browser  : http://localhost:$port" -ForegroundColor White
Write-Host "  API Docs         : http://localhost:$port/docs" -ForegroundColor White
Write-Host "  Health Check     : http://localhost:$port/api/v1/health" -ForegroundColor White
Write-Host "  Mobile (WiFi)    : http://$lan_ip:$port" -ForegroundColor Cyan
Write-Host "  Android Emulator : http://10.0.2.2:$port" -ForegroundColor White
Write-Host ""
Write-Host "Flutter .env should contain:" -ForegroundColor Yellow
Write-Host "  API_BASE_URL=http://$lan_ip:$port" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting backend (model loading may take 20-30 seconds)..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Change to backend directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Activate virtualenv if available
if (Test-Path "venv\Scripts\Activate.ps1") {
    Write-Host "Activating virtual environment..." -ForegroundColor Gray
    & "venv\Scripts\Activate.ps1"
} elseif (Test-Path "..\venv\Scripts\Activate.ps1") {
    & "..\venv\Scripts\Activate.ps1"
}

# Start FastAPI server (no --reload to avoid double model loading)
python main.py

#!/usr/bin/env pwsh
# ════════════════════════════════════════════════════════════════════
# AgroVision AI — Flutter Android App Setup Script
# Run this script AFTER adding Flutter to your PATH
# ════════════════════════════════════════════════════════════════════

param(
    [string]$FlutterPath = "",    # Optional: path to flutter.bat if not in PATH
    [switch]$SkipDoctorCheck,
    [switch]$RunAfterSetup
)

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   AgroVision AI — Flutter App Setup" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# ── Step 0: Find flutter command ─────────────────────────────────────
$flutter = "flutter"
if ($FlutterPath -ne "") {
    $flutter = $FlutterPath
} elseif (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: 'flutter' command not found in PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "To fix this:" -ForegroundColor Yellow
    Write-Host "  1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows/mobile" -ForegroundColor Yellow
    Write-Host "  2. Extract to C:\flutter" -ForegroundColor Yellow
    Write-Host "  3. Add C:\flutter\bin to your System PATH" -ForegroundColor Yellow
    Write-Host "  4. Open a NEW terminal and run: flutter doctor" -ForegroundColor Yellow
    Write-Host "  5. Then run this script again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or run: .\flutter_setup.ps1 -FlutterPath 'C:\flutter\bin\flutter.bat'" -ForegroundColor Cyan
    exit 1
}

Write-Host "✅ Flutter found: $(& $flutter --version 2>&1 | Select-String 'Flutter')" -ForegroundColor Green

# ── Step 1: flutter doctor ─────────────────────────────────────────
if (-not $SkipDoctorCheck) {
    Write-Host ""
    Write-Host "── Running flutter doctor..." -ForegroundColor Cyan
    & $flutter doctor
    Write-Host ""
}

# ── Step 2: Navigate to project dir ───────────────────────────────
Set-Location $ProjectDir
Write-Host "── Working in: $ProjectDir" -ForegroundColor Cyan

# ── Step 3: flutter pub get ────────────────────────────────────────
Write-Host ""
Write-Host "── Installing Flutter packages (flutter pub get)..." -ForegroundColor Cyan
& $flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutter pub get failed. Check pubspec.yaml for errors." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Packages installed successfully." -ForegroundColor Green

# ── Step 4: Check .env ─────────────────────────────────────────────
Write-Host ""
Write-Host "── Checking .env file..." -ForegroundColor Cyan
$envFile = Join-Path $ProjectDir ".env"
if (Test-Path $envFile) {
    Write-Host "✅ .env file found." -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Edit .env and set the correct API_BASE_URL:" -ForegroundColor Yellow
    Write-Host "  For Android Emulator: API_BASE_URL=http://10.0.2.2:8000" -ForegroundColor White
    Write-Host "  For Real Device:      API_BASE_URL=http://<your-pc-ip>:8000" -ForegroundColor White
    Write-Host ""
    Write-Host "  To find your PC's local IP:" -ForegroundColor White
    Write-Host "  Run: ipconfig | Select-String 'IPv4'" -ForegroundColor White
} else {
    Write-Host "WARNING: .env file not found. Creating default..." -ForegroundColor Yellow
    @"
API_BASE_URL=http://10.0.2.2:8000
SUPABASE_URL=https://escaguxvhnwevmftqkqt.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzY2FndXh2aG53ZXZtZnRxa3F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkyMjcxODcsImV4cCI6MjA4NDgwMzE4N30.dFfPAx5SJdJK80B2_0FOtGZUi_x1lyP7Td2paiWLum4
"@ | Set-Content $envFile -Encoding UTF8
    Write-Host "✅ .env created with defaults." -ForegroundColor Green
}

# ── Step 5: Get connected devices ─────────────────────────────────
Write-Host ""
Write-Host "── Connected Android devices:" -ForegroundColor Cyan
& $flutter devices

# ── Step 6: Start backend reminder ───────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "IMPORTANT: Start the FastAPI backend before running the app!" -ForegroundColor Yellow
Write-Host ""
Write-Host "  cd 'c:\Users\gopal\OneDrive\Desktop\trail 2\backend'" -ForegroundColor White
Write-Host "  python main.py" -ForegroundColor White
Write-Host ""
Write-Host "The backend must be running at http://localhost:8000" -ForegroundColor Yellow
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Yellow

# ── Step 7: Build APK ─────────────────────────────────────────────
Write-Host ""
$buildChoice = Read-Host "Build APK now? (y/n) [recommended: test with 'flutter run' first]"

if ($buildChoice -eq "y" -or $buildChoice -eq "Y") {
    Write-Host ""
    Write-Host "── Building APK (flutter build apk --debug)..." -ForegroundColor Cyan
    & $flutter build apk --debug

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ APK built successfully!" -ForegroundColor Green
        Write-Host "   APK location: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor White
        Write-Host "   Transfer to your Android phone and install." -ForegroundColor White
    } else {
        Write-Host "ERROR: APK build failed. See errors above." -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "To run on device/emulator:" -ForegroundColor Cyan
    Write-Host "  cd '$ProjectDir'" -ForegroundColor White
    Write-Host "  flutter run" -ForegroundColor White
    Write-Host ""
    Write-Host "To build release APK:" -ForegroundColor Cyan
    Write-Host "  flutter build apk --release" -ForegroundColor White
}

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   Setup complete! AgroVision AI Flutter App is ready." -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# StockScan Pro Development Script
# Usage: .\dev.ps1 [command]

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

# Add Flutter to PATH for this session
$env:PATH += ";C:\dev\flutter\bin"

function Show-Help {
    Write-Host "StockScan Pro Development Commands:" -ForegroundColor Green
    Write-Host ""
    Write-Host "Setup Commands:" -ForegroundColor Yellow
    Write-Host "  setup     - Initial project setup"
    Write-Host "  deps      - Get dependencies (flutter pub get)"
    Write-Host "  clean     - Clean build files"
    Write-Host ""
    Write-Host "Development Commands:" -ForegroundColor Yellow
    Write-Host "  run       - Run app in debug mode"
    Write-Host "  web       - Run app in web browser"
    Write-Host "  analyze   - Analyze code for issues"
    Write-Host "  test      - Run all tests"
    Write-Host "  format    - Format all Dart files"
    Write-Host ""
    Write-Host "Build Commands:" -ForegroundColor Yellow
    Write-Host "  build-apk - Build Android APK"
    Write-Host "  build-web - Build web version"
    Write-Host "  build-ios - Build iOS version"
    Write-Host ""
    Write-Host "Git Commands:" -ForegroundColor Yellow
    Write-Host "  commit    - Add all and commit changes"
    Write-Host "  status    - Show git status"
    Write-Host ""
    Write-Host "Doctor Commands:" -ForegroundColor Yellow
    Write-Host "  doctor    - Run flutter doctor"
    Write-Host "  devices   - List available devices"
}

function Setup-Project {
    Write-Host "Setting up StockScan Pro..." -ForegroundColor Green
    flutter doctor
    flutter pub get
    Write-Host "Setup complete!" -ForegroundColor Green
}

function Get-Dependencies {
    Write-Host "Getting dependencies..." -ForegroundColor Blue
    flutter pub get
}

function Clean-Project {
    Write-Host "Cleaning project..." -ForegroundColor Blue
    flutter clean
    flutter pub get
}

function Run-App {
    Write-Host "Running StockScan Pro in debug mode..." -ForegroundColor Blue
    flutter run
}

function Run-Web {
    Write-Host "Running StockScan Pro in web browser..." -ForegroundColor Blue
    flutter run -d web-server --web-port 3000
}

function Analyze-Code {
    Write-Host "Analyzing code..." -ForegroundColor Blue
    flutter analyze
}

function Test-App {
    Write-Host "Running tests..." -ForegroundColor Blue
    flutter test
}

function Format-Code {
    Write-Host "Formatting Dart files..." -ForegroundColor Blue
    dart format lib/ test/
}

function Build-APK {
    Write-Host "Building Android APK..." -ForegroundColor Blue
    flutter build apk --release
    Write-Host "APK built: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Green
}

function Build-Web {
    Write-Host "Building web version..." -ForegroundColor Blue
    flutter build web --release
    Write-Host "Web build complete: build/web/" -ForegroundColor Green
}

function Build-iOS {
    Write-Host "Building iOS version..." -ForegroundColor Blue
    flutter build ios --release
}

function Commit-Changes {
    Write-Host "Committing changes..." -ForegroundColor Blue
    git add .
    $message = Read-Host "Enter commit message"
    git commit -m $message
}

function Show-Status {
    git status
}

function Show-Doctor {
    flutter doctor -v
}

function Show-Devices {
    flutter devices
}

# Execute command
switch ($Command.ToLower()) {
    "help" { Show-Help }
    "setup" { Setup-Project }
    "deps" { Get-Dependencies }
    "clean" { Clean-Project }
    "run" { Run-App }
    "web" { Run-Web }
    "analyze" { Analyze-Code }
    "test" { Test-App }
    "format" { Format-Code }
    "build-apk" { Build-APK }
    "build-web" { Build-Web }
    "build-ios" { Build-iOS }
    "commit" { Commit-Changes }
    "status" { Show-Status }
    "doctor" { Show-Doctor }
    "devices" { Show-Devices }
    default { 
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Show-Help 
    }
}

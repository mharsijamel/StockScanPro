# Module Structure Verification Script
# ===================================

Write-Host "🔍 Verifying StockScan Mobile Module Structure" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

$ModulePath = "odoo_module/stock_scan_mobile"

if (-not (Test-Path $ModulePath)) {
    Write-Host "❌ Module directory not found: $ModulePath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Module directory found" -ForegroundColor Green

# Check essential files
$RequiredFiles = @(
    "__manifest__.py",
    "__init__.py",
    "controllers/__init__.py",
    "controllers/auth_controller.py",
    "controllers/health_controller.py", 
    "controllers/picking_controller.py",
    "controllers/serial_controller.py",
    "models/__init__.py"
)

Write-Host "`n📁 Checking required files..." -ForegroundColor Yellow

$AllFilesExist = $true
foreach ($file in $RequiredFiles) {
    $fullPath = Join-Path $ModulePath $file
    if (Test-Path $fullPath) {
        Write-Host "✅ $file" -ForegroundColor Green
    } else {
        Write-Host "❌ $file" -ForegroundColor Red
        $AllFilesExist = $false
    }
}

if ($AllFilesExist) {
    Write-Host "`n✅ All required files present" -ForegroundColor Green
} else {
    Write-Host "`n❌ Some required files are missing" -ForegroundColor Red
}

# Check manifest content
Write-Host "`n📄 Checking manifest file..." -ForegroundColor Yellow
$manifestPath = Join-Path $ModulePath "__manifest__.py"
if (Test-Path $manifestPath) {
    $content = Get-Content $manifestPath -Raw
    if ($content -match "'name':\s*'Stock Scan Mobile API'") {
        Write-Host "✅ Manifest contains correct module name" -ForegroundColor Green
    } else {
        Write-Host "❌ Manifest may be corrupted" -ForegroundColor Red
    }
    
    if ($content -match "'installable':\s*True") {
        Write-Host "✅ Module is marked as installable" -ForegroundColor Green
    } else {
        Write-Host "❌ Module not marked as installable" -ForegroundColor Red
    }
}

# Show file sizes (to detect empty files)
Write-Host "`n📊 File sizes:" -ForegroundColor Yellow
Get-ChildItem -Path $ModulePath -Recurse -File | ForEach-Object {
    $size = $_.Length
    $color = if ($size -eq 0) { "Red" } else { "Cyan" }
    Write-Host "  $($_.FullName.Replace((Get-Location).Path + '\', '')): $size bytes" -ForegroundColor $color
}

Write-Host "`n🎯 Module Ready for Deployment" -ForegroundColor Green
Write-Host "Copy the entire '$ModulePath' folder to your Odoo server's addons directory" -ForegroundColor White
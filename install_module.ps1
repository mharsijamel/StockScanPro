# StockScan Mobile Module Installation Script (PowerShell)
# ========================================================

Write-Host "🚀 Installing StockScan Mobile API Module..." -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "odoo_module/stock_scan_mobile")) {
    Write-Host "❌ Error: Run this script from the StockScanPro root directory" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Found module directory: odoo_module/stock_scan_mobile" -ForegroundColor Green

Write-Host "📋 Module files:" -ForegroundColor Yellow
Get-ChildItem -Path "odoo_module/stock_scan_mobile" -Recurse -Include "*.py", "*.xml" | ForEach-Object {
    Write-Host "  $($_.FullName.Replace((Get-Location).Path, '.'))" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📦 Manual Installation Instructions:" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Copy the entire 'stock_scan_mobile' folder to your Odoo addons directory" -ForegroundColor White
Write-Host "   Common locations:" -ForegroundColor Gray
Write-Host "   - /opt/odoo/addons/" -ForegroundColor Gray
Write-Host "   - /usr/lib/python3/dist-packages/odoo/addons/" -ForegroundColor Gray
Write-Host "   - /var/lib/odoo/addons/" -ForegroundColor Gray
Write-Host "   - /mnt/extra-addons/" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Restart your Odoo server:" -ForegroundColor White
Write-Host "   sudo systemctl restart odoo" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Log into Odoo and install the module:" -ForegroundColor White
Write-Host "   - Go to Apps menu" -ForegroundColor Gray
Write-Host "   - Click 'Update Apps List'" -ForegroundColor Gray
Write-Host "   - Search for 'Stock Scan Mobile API'" -ForegroundColor Gray
Write-Host "   - Click Install" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Test the API:" -ForegroundColor White
Write-Host "   curl -X GET 'https://smart.webvue.tn/api/health'" -ForegroundColor Gray
Write-Host ""

# Check if running on Windows Subsystem for Linux or if we can access Linux paths
$LinuxPaths = @("/opt/odoo/addons", "/usr/lib/python3/dist-packages/odoo/addons", "/var/lib/odoo/addons", "/mnt/extra-addons")
$FoundPath = $null

foreach ($path in $LinuxPaths) {
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        Write-Host "✅ Found addons directory: $path" -ForegroundColor Green
        $FoundPath = $path
        break
    }
}

if ($FoundPath) {
    Write-Host "📦 Attempting to copy module..." -ForegroundColor Yellow
    try {
        Copy-Item -Path "odoo_module/stock_scan_mobile" -Destination "$FoundPath/" -Recurse -Force
        Write-Host "✅ Module copied successfully to: $FoundPath/stock_scan_mobile" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to copy module: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please copy manually using the instructions above." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Could not find Odoo addons directory automatically." -ForegroundColor Yellow
    Write-Host "Please follow the manual installation instructions above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Setup complete! Follow the manual steps above to finish installation." -ForegroundColor Green
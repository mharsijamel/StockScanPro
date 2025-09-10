# Complete Diagnostic Script for StockScan Pro API (PowerShell)
# ===========================================================

Write-Host "🔍 StockScan Pro API Diagnostic Script" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

$BaseUrl = "https://smart.webvue.tn"

Write-Host "`n1. Testing basic connectivity to server..." -ForegroundColor Yellow
try {
    $null = Invoke-WebRequest -Uri $BaseUrl -TimeoutSec 10 -UseBasicParsing
    Write-Host "✅ Server is reachable" -ForegroundColor Green
} catch {
    Write-Host "❌ Server is not reachable - check network connection" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Testing Odoo web interface..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/web/login" -UseBasicParsing
    Write-Host "✅ Odoo web interface is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Odoo web interface issue (Status: $($_.Exception.Response.StatusCode.value__))" -ForegroundColor Red
}

Write-Host "`n3. Testing health endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/health" -Method GET -ErrorAction Stop
    Write-Host "✅ Health endpoint working" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan
    $healthWorking = $true
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ Health endpoint failed (HTTP $statusCode)" -ForegroundColor Red
    
    if ($statusCode -eq 404) {
        Write-Host "`n🔍 404 Error Analysis:" -ForegroundColor Yellow
        Write-Host "- The /api/health endpoint does not exist" -ForegroundColor White
        Write-Host "- This means the stock_scan_mobile module is not properly installed" -ForegroundColor White
        Write-Host "- Or the module is installed but controllers are not loaded" -ForegroundColor White
    }
    $healthWorking = $false
}

Write-Host "`n4. Testing databases endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/databases" -Method GET -ErrorAction Stop
    Write-Host "✅ Databases endpoint working" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ Databases endpoint failed (HTTP $statusCode)" -ForegroundColor Red
}

Write-Host "`n5. Testing auth endpoint..." -ForegroundColor Yellow
try {
    $authData = @{
        username = "test"
        password = "test"
    }
    $headers = @{
        "Content-Type" = "application/json"
        "X-Openerp-Database" = "SMARTTEST"
    }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -Body ($authData | ConvertTo-Json) -Headers $headers -ErrorAction Stop
    Write-Host "✅ Auth endpoint accessible" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400 -or $statusCode -eq 401) {
        Write-Host "✅ Auth endpoint accessible but credentials rejected (HTTP $statusCode)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Auth endpoint failed (HTTP $statusCode)" -ForegroundColor Red
    }
}

Write-Host "`n📋 Diagnosis Summary:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

if (-not $healthWorking) {
    Write-Host "❌ PROBLEM: Module not properly installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 SOLUTIONS TO TRY:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A. Check module files are copied correctly:" -ForegroundColor White
    Write-Host "   - Verify odoo_module/stock_scan_mobile/ folder exists locally" -ForegroundColor Gray
    Write-Host "   - Check all Python files are present" -ForegroundColor Gray
    Write-Host ""
    Write-Host "B. In Odoo web interface (https://smart.webvue.tn):" -ForegroundColor White
    Write-Host "   - Login as administrator" -ForegroundColor Gray
    Write-Host "   - Go to Apps menu" -ForegroundColor Gray
    Write-Host "   - Click 'Update Apps List'" -ForegroundColor Gray
    Write-Host "   - Search for 'Stock Scan Mobile API'" -ForegroundColor Gray
    Write-Host "   - If found: Install it" -ForegroundColor Gray
    Write-Host "   - If not found: Module files not in correct location" -ForegroundColor Gray
    Write-Host ""
    Write-Host "C. Common module paths on server:" -ForegroundColor White
    Write-Host "   - /mnt/extra-addons/stock_scan_mobile/" -ForegroundColor Gray
    Write-Host "   - /opt/odoo/addons/stock_scan_mobile/" -ForegroundColor Gray
    Write-Host "   - /usr/lib/python3/dist-packages/odoo/addons/stock_scan_mobile/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "D. After copying module files:" -ForegroundColor White
    Write-Host "   - Restart Odoo server" -ForegroundColor Gray
    Write-Host "   - Update Apps List in Odoo" -ForegroundColor Gray
    Write-Host "   - Install the module" -ForegroundColor Gray
} else {
    Write-Host "✅ Module is working correctly!" -ForegroundColor Green
}

Write-Host "`n📁 Local module files check:" -ForegroundColor Yellow
if (Test-Path "odoo_module/stock_scan_mobile") {
    Write-Host "✅ Local module directory exists" -ForegroundColor Green
    
    $pythonFiles = Get-ChildItem -Path "odoo_module/stock_scan_mobile" -Recurse -Filter "*.py" | Measure-Object
    Write-Host "📄 Python files found: $($pythonFiles.Count)" -ForegroundColor Cyan
    
    if (Test-Path "odoo_module/stock_scan_mobile/__manifest__.py") {
        Write-Host "✅ Manifest file exists" -ForegroundColor Green
    } else {
        Write-Host "❌ Manifest file missing!" -ForegroundColor Red
    }
    
    Write-Host "`n📋 Module structure:" -ForegroundColor Cyan
    Get-ChildItem -Path "odoo_module/stock_scan_mobile" -Recurse | ForEach-Object {
        Write-Host "  $($_.FullName.Replace((Get-Location).Path, '.'))" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Local module directory not found!" -ForegroundColor Red
}

Write-Host "`n🎯 Next Steps:" -ForegroundColor Green
Write-Host "1. Review the diagnosis above" -ForegroundColor White
Write-Host "2. If health endpoint fails: Module needs installation" -ForegroundColor White
Write-Host "3. If files are missing: Copy them to server" -ForegroundColor White
Write-Host "4. Always restart Odoo after copying files" -ForegroundColor White
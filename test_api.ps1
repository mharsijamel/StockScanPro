# Test script to verify API endpoints
Write-Host "Testing StockScan Pro API endpoints..." -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

$BaseUrl = "https://smart.webvue.tn"

Write-Host "`n1. Testing health endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/health" -Method GET -ContentType "application/json"
    Write-Host "✅ Health endpoint accessible" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

Write-Host "`n2. Testing database list endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/databases" -Method GET -ContentType "application/json"
    Write-Host "✅ Database endpoint accessible" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Database endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

Write-Host "`n3. Testing auth endpoint..." -ForegroundColor Yellow
try {
    $authData = @{
        username = "admin"
        password = "admin"
    }
    $headers = @{
        "Content-Type" = "application/json"
        "X-Openerp-Database" = "SMARTTEST"
    }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/auth/login" -Method POST -Body ($authData | ConvertTo-Json) -Headers $headers
    Write-Host "✅ Auth endpoint accessible" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Auth endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

Write-Host "`n4. Testing pickings endpoint..." -ForegroundColor Yellow
try {
    $pickingsData = @{
        token = "dummy_token"
        type = "in"
    }
    $headers = @{
        "Content-Type" = "application/json"
        "X-Openerp-Database" = "SMARTTEST"
    }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/pickings" -Method POST -Body ($pickingsData | ConvertTo-Json) -Headers $headers
    Write-Host "✅ Pickings endpoint accessible" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Pickings endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
}

Write-Host "`nTest completed!" -ForegroundColor Green

# Check module installation status
Write-Host "`n5. Checking Odoo module status..." -ForegroundColor Yellow
Write-Host "Please check in Odoo:" -ForegroundColor Cyan
Write-Host "- Go to Apps > Search 'stock_scan_mobile'" -ForegroundColor Cyan
Write-Host "- Make sure the module is installed" -ForegroundColor Cyan
Write-Host "- Check Odoo logs for any module loading errors" -ForegroundColor Cyan
#!/bin/bash

# Complete Diagnostic Script for StockScan Pro API
# ==============================================

echo "🔍 StockScan Pro API Diagnostic Script"
echo "======================================"

BASE_URL="https://smart.webvue.tn"

echo "1. Testing basic connectivity to server..."
if curl -s --connect-timeout 10 "$BASE_URL" > /dev/null; then
    echo "✅ Server is reachable"
else
    echo "❌ Server is not reachable - check network connection"
    exit 1
fi

echo ""
echo "2. Testing Odoo web interface..."
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/web/login")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
if [ "$http_code" -eq 200 ]; then
    echo "✅ Odoo web interface is accessible (HTTP $http_code)"
else
    echo "❌ Odoo web interface issue (HTTP $http_code)"
fi

echo ""
echo "3. Testing health endpoint..."
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/api/health")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
content=$(echo $response | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')

if [ "$http_code" -eq 200 ]; then
    echo "✅ Health endpoint working (HTTP $http_code)"
    echo "Response: $content"
else
    echo "❌ Health endpoint failed (HTTP $http_code)"
    echo "Response: $content"
    
    if [ "$http_code" -eq 404 ]; then
        echo ""
        echo "🔍 404 Error Analysis:"
        echo "- The /api/health endpoint does not exist"
        echo "- This means the stock_scan_mobile module is not properly installed"
        echo "- Or the module is installed but controllers are not loaded"
    fi
fi

echo ""
echo "4. Testing databases endpoint..."
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$BASE_URL/api/databases")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
content=$(echo $response | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')

if [ "$http_code" -eq 200 ]; then
    echo "✅ Databases endpoint working (HTTP $http_code)"
    echo "Response: $content"
else
    echo "❌ Databases endpoint failed (HTTP $http_code)"
    echo "Response: $content"
fi

echo ""
echo "5. Testing auth endpoint..."
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Openerp-Database: SMARTTEST" \
    -d '{"username":"test","password":"test"}')
    
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
content=$(echo $response | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')

if [ "$http_code" -eq 200 ]; then
    echo "✅ Auth endpoint accessible (HTTP $http_code)"
    echo "Response: $content"
elif [ "$http_code" -eq 400 ] || [ "$http_code" -eq 401 ]; then
    echo "✅ Auth endpoint accessible but credentials rejected (HTTP $http_code)"
    echo "Response: $content"
else
    echo "❌ Auth endpoint failed (HTTP $http_code)"
    echo "Response: $content"
fi

echo ""
echo "📋 Diagnosis Summary:"
echo "==================="

if [ "$http_code" -eq 404 ]; then
    echo "❌ PROBLEM: Module not properly installed"
    echo ""
    echo "🔧 SOLUTIONS TO TRY:"
    echo ""
    echo "A. Check if module exists in addons directory:"
    echo "   ls -la /mnt/extra-addons/stock_scan_mobile/"
    echo "   ls -la /opt/odoo/addons/stock_scan_mobile/"
    echo ""
    echo "B. Check Odoo logs for module loading errors:"
    echo "   tail -f /var/log/odoo/odoo.log"
    echo ""
    echo "C. In Odoo interface:"
    echo "   - Go to Apps menu"
    echo "   - Click 'Update Apps List'"
    echo "   - Search for 'Stock Scan Mobile API'"
    echo "   - If found, install it"
    echo "   - If not found, check file permissions"
    echo ""
    echo "D. Restart Odoo service:"
    echo "   sudo systemctl restart odoo"
    echo ""
    echo "E. Check module manifest file exists:"
    echo "   cat /mnt/extra-addons/stock_scan_mobile/__manifest__.py"
else
    echo "✅ Basic connectivity working"
    echo "Check specific endpoint responses above for details"
fi

echo ""
echo "🔗 Next steps:"
echo "1. Copy the diagnostic output above"
echo "2. Check the file paths mentioned"
echo "3. Look at Odoo logs during server restart"
echo "4. Verify module installation in Odoo Apps"
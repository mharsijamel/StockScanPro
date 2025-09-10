#!/bin/bash

# StockScan Mobile Module Installation Script
# ==========================================

echo "🚀 Installing StockScan Mobile API Module..."

# Check if we're in the right directory
if [ ! -d "odoo_module/stock_scan_mobile" ]; then
    echo "❌ Error: Run this script from the StockScanPro root directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "📁 Found module directory: odoo_module/stock_scan_mobile"

# Find Odoo addons directories (common locations)
ADDON_PATHS=(
    "/opt/odoo/addons"
    "/usr/lib/python3/dist-packages/odoo/addons"
    "/var/lib/odoo/addons" 
    "/mnt/extra-addons"
    "/odoo/addons"
)

FOUND_PATH=""
for path in "${ADDON_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "✅ Found addons directory: $path"
        FOUND_PATH="$path"
        break
    fi
done

if [ -z "$FOUND_PATH" ]; then
    echo "❌ Could not find Odoo addons directory"
    echo "Please specify the path manually:"
    read -p "Enter Odoo addons path: " FOUND_PATH
    
    if [ ! -d "$FOUND_PATH" ]; then
        echo "❌ Directory does not exist: $FOUND_PATH"
        exit 1
    fi
fi

echo "📋 Module files to install:"
find odoo_module/stock_scan_mobile -type f -name "*.py" -o -name "*.xml"

# Copy module to addons directory
echo "📦 Copying module to: $FOUND_PATH/stock_scan_mobile"
cp -r odoo_module/stock_scan_mobile "$FOUND_PATH/"

# Set appropriate permissions
echo "🔐 Setting permissions..."
chmod -R 755 "$FOUND_PATH/stock_scan_mobile"

echo "✅ Module installed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Restart your Odoo server:"
echo "   sudo systemctl restart odoo"
echo ""
echo "2. Log into Odoo and go to Apps"
echo "3. Click 'Update Apps List'"
echo "4. Search for 'Stock Scan Mobile API'"
echo "5. Click Install"
echo ""
echo "🧪 Test the API:"
echo "curl -X GET 'https://smart.webvue.tn/api/health'"
echo ""
echo "🎉 Installation complete!"
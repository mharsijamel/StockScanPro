# Odoo Module Deployment Instructions
# =====================================

## Step 1: Copy Module to Odoo Server

### Option A: If you have direct server access
```bash
# Copy the entire module directory to your Odoo addons folder
scp -r ./odoo_module/stock_scan_mobile user@your-server:/path/to/odoo/addons/

# Or use rsync for better handling
rsync -av ./odoo_module/stock_scan_mobile/ user@your-server:/path/to/odoo/addons/stock_scan_mobile/
```

### Option B: If using Odoo.sh or hosting service
1. Upload the `stock_scan_mobile` folder to your repository
2. Push to your branch
3. Deploy through your hosting interface

### Option C: Manual upload (if using hosting panel)
1. Zip the `stock_scan_mobile` folder
2. Upload via hosting control panel
3. Extract in addons directory

## Step 2: Restart Odoo Server

```bash
sudo systemctl restart odoo
# OR
sudo service odoo restart
```

## Step 3: Install Module in Odoo

1. Login to Odoo as Administrator
2. Go to **Apps** menu
3. Click **Update Apps List** button
4. Search for "Stock Scan Mobile API"
5. Click **Install**

## Step 4: Verify Installation

Test the health endpoint:
```bash
curl -X GET "https://smart.webvue.tn/api/health"
```

Should return:
```json
{
  "success": true,
  "status": "healthy",
  "message": "Stock Scan Mobile API is running",
  "timestamp": "2025-09-07T...",
  "version": "1.0.0",
  "odoo_version": "15.0",
  "database": "SMARTTEST"
}
```

## Step 5: Test Authentication

```bash
curl -X POST "https://smart.webvue.tn/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "X-Openerp-Database: SMARTTEST" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

## Troubleshooting

### If you get 404 errors:
1. Check module is in correct addons directory
2. Verify __manifest__.py file exists
3. Check Odoo logs for module loading errors
4. Ensure module dependencies are installed

### Check Odoo logs:
```bash
tail -f /var/log/odoo/odoo.log
```

### Common paths for addons:
- `/opt/odoo/addons/`
- `/usr/lib/python3/dist-packages/odoo/addons/`
- `/var/lib/odoo/addons/`
- Custom addons path in odoo.conf

### Check your odoo.conf for addons_path:
```bash
grep addons_path /etc/odoo/odoo.conf
```
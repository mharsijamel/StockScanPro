# Quick Fix for Installation Error

## Problem
You're getting a `UniqueViolation` error because configuration parameters already exist in the database from a previous installation attempt.

## Solution Steps

### Option 1: Use the Cleaned Module (Recommended)

1. **The module has been fixed** - I removed the problematic data files
2. **Copy the updated module** to your Odoo server:
   ```bash
   cp -r odoo_module/stock_scan_mobile /mnt/extra-addons/
   ```
3. **Restart Odoo server**:
   ```bash
   sudo systemctl restart odoo
   ```
4. **Uninstall the old module** (if installed):
   - Go to Apps → Installed
   - Find "Stock Scan Mobile API" 
   - Click Uninstall
5. **Install the new module**:
   - Go to Apps → Update Apps List
   - Search "Stock Scan Mobile API"
   - Click Install

### Option 2: Database Cleanup (If Option 1 doesn't work)

If you still get errors, you may need to clean the database:

1. **Access your Odoo database** (backup first!)
2. **Run the cleanup script**:
   ```sql
   DELETE FROM ir_config_parameter WHERE key LIKE 'stock_scan_mobile.%';
   DELETE FROM ir_module_module WHERE name = 'stock_scan_mobile';
   DELETE FROM ir_model_data WHERE module = 'stock_scan_mobile';
   ```
3. **Restart Odoo** and try installing again

### Option 3: Fresh Database

If you're in development and can afford to reset:
1. Create a new database
2. Install the module in the fresh database

## Test Installation

After successful installation, test:
```bash
curl -X GET "https://smart.webvue.tn/api/health"
```

Should return:
```json
{
  "success": true,
  "status": "healthy",
  "message": "Stock Scan Mobile API is running"
}
```

## Common Issues

- **404 errors**: Module not properly installed or server not restarted
- **UniqueViolation**: Use the cleanup script above
- **Permission errors**: Check file permissions in addons directory

The module has been simplified to avoid XML data conflicts. It should install cleanly now! 🎉
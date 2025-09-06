# Installation Guide - Stock Scan Mobile API Module

## Prerequisites

- Odoo 15.0 or higher
- Python 3.8+
- PostgreSQL database
- Administrator access to Odoo instance

## Installation Steps

### 1. Copy Module Files

Copy the `stock_scan_mobile` folder to your Odoo addons directory:

```bash
# Example paths:
# /opt/odoo/addons/stock_scan_mobile/
# /usr/lib/python3/dist-packages/odoo/addons/stock_scan_mobile/
# C:\Program Files\Odoo 15.0\server\odoo\addons\stock_scan_mobile\
```

### 2. Update Addons Path

Ensure your Odoo configuration includes the addons directory:

```ini
# In odoo.conf
addons_path = /opt/odoo/addons,/opt/odoo/custom-addons
```

### 3. Restart Odoo Server

Restart your Odoo server to recognize the new module:

```bash
sudo systemctl restart odoo
# or
sudo service odoo restart
```

### 4. Update Apps List

1. Log in to Odoo as Administrator
2. Go to **Apps** menu
3. Click **Update Apps List**
4. Search for "Stock Scan Mobile API"

### 5. Install the Module

1. Find "Stock Scan Mobile API" in the Apps list
2. Click **Install**
3. Wait for installation to complete

## Post-Installation Configuration

### 1. User Groups Assignment

Assign users to appropriate groups:

1. Go to **Settings > Users & Companies > Users**
2. Edit user accounts
3. In **Access Rights** tab, assign:
   - **Mobile App User**: For regular mobile app users
   - **Mobile App Manager**: For administrators

### 2. System Parameters Configuration

Go to **Settings > Technical > Parameters > System Parameters** and configure:

#### Authentication Settings
- `stock_scan_mobile.token_expiry_hours`: `24` (Token validity in hours)
- `stock_scan_mobile.max_login_attempts`: `5` (Max failed login attempts)

#### API Settings
- `stock_scan_mobile.api_rate_limit_per_minute`: `100` (API calls per minute per user)
- `stock_scan_mobile.max_batch_size`: `100` (Max serial numbers per batch)

#### CORS Settings (Important for Production)
- `stock_scan_mobile.cors_origins`: `https://yourdomain.com` (Replace * with your domain)
- `stock_scan_mobile.cors_enabled`: `True`

#### Security Settings
- `stock_scan_mobile.debug_mode`: `False` (Set to True only for debugging)
- `stock_scan_mobile.log_api_calls`: `True` (Enable API logging)

### 3. Database Permissions

Ensure the database user has necessary permissions:

```sql
-- Grant permissions to Odoo database user
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO odoo_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO odoo_user;
```

## Testing the Installation

### 1. Test API Endpoints

Use a tool like Postman or curl to test the API:

```bash
# Test authentication endpoint
curl -X POST http://your-odoo-server/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin"
  }'
```

### 2. Check Logs

Monitor Odoo logs for any errors:

```bash
tail -f /var/log/odoo/odoo-server.log
```

### 3. Verify Module Installation

1. Go to **Apps > Installed**
2. Confirm "Stock Scan Mobile API" is listed
3. Check version and status

## Mobile App Configuration

### 1. Server URL Configuration

In your mobile app, configure the server URL:
- **Development**: `http://localhost:8069`
- **Production**: `https://your-odoo-server.com`

### 2. API Endpoints

The mobile app should use these endpoints:
- Authentication: `/api/auth/login`
- Pickings: `/api/pickings`
- Serial Check: `/api/serial/check`

## Troubleshooting

### Common Installation Issues

#### 1. Module Not Found
**Problem**: Module doesn't appear in Apps list
**Solution**: 
- Check addons path in configuration
- Restart Odoo server
- Update Apps list

#### 2. Permission Denied
**Problem**: Installation fails with permission errors
**Solution**:
- Check file permissions: `chmod -R 755 stock_scan_mobile/`
- Ensure Odoo user owns the files: `chown -R odoo:odoo stock_scan_mobile/`

#### 3. Database Errors
**Problem**: Database constraint errors during installation
**Solution**:
- Check PostgreSQL logs
- Ensure database user has sufficient permissions
- Verify database encoding (should be UTF-8)

#### 4. Python Dependencies
**Problem**: Missing Python dependencies
**Solution**:
```bash
pip3 install werkzeug
# or
pip3 install -r requirements.txt
```

### API Testing Issues

#### 1. CORS Errors
**Problem**: Mobile app can't connect due to CORS
**Solution**:
- Configure `stock_scan_mobile.cors_origins` parameter
- Set appropriate domain instead of `*`

#### 2. Authentication Failures
**Problem**: Login API returns authentication errors
**Solution**:
- Verify user credentials
- Check user has stock management permissions
- Ensure user is in Mobile App User group

#### 3. Rate Limit Exceeded
**Problem**: API calls are being blocked
**Solution**:
- Increase `stock_scan_mobile.api_rate_limit_per_minute`
- Implement proper retry logic in mobile app

## Production Deployment

### 1. Security Checklist

- [ ] Change default admin password
- [ ] Configure CORS origins (remove `*`)
- [ ] Enable HTTPS/SSL
- [ ] Set `debug_mode` to `False`
- [ ] Configure proper firewall rules
- [ ] Set up regular database backups

### 2. Performance Optimization

- [ ] Configure database connection pooling
- [ ] Set up Redis for caching
- [ ] Configure proper worker processes
- [ ] Monitor API response times

### 3. Monitoring

- [ ] Set up log rotation
- [ ] Configure monitoring alerts
- [ ] Monitor API usage statistics
- [ ] Set up database performance monitoring

## Support

For technical support:
1. Check the module logs first
2. Review this installation guide
3. Contact the development team with:
   - Odoo version
   - Error messages
   - Steps to reproduce the issue

## Uninstallation

To remove the module:

1. Go to **Apps > Installed**
2. Find "Stock Scan Mobile API"
3. Click **Uninstall**
4. Confirm the uninstallation

**Warning**: Uninstalling will remove all mobile API data and configurations.

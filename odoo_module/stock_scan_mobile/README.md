# Stock Scan Mobile API - Odoo 15 Module

## Description

This module provides REST API endpoints for mobile applications to manage stock operations with serial number scanning and tracking. It's designed to work with the StockScan Pro Flutter mobile application.

## Features

### 🔐 Authentication
- Token-based authentication system
- Secure login/logout endpoints
- Token validation and expiry management
- User permission checking

### 📦 Stock Operations
- Retrieve stock pickings (IN/OUT operations)
- Filter pickings by type, state, and date
- Batch serial number updates
- Automatic picking validation
- Mobile sync status tracking

### 🏷️ Serial Number Management
- Serial number existence verification
- Batch serial number checking
- Serial number history tracking
- Automatic lot/serial creation for incoming operations
- Mobile scan tracking and statistics

### 🛡️ Security & Access Control
- Role-based access control (Mobile User, Mobile Manager)
- CORS configuration for mobile apps
- API rate limiting
- Comprehensive logging and audit trail

## API Endpoints

### Authentication
- `POST /api/auth/login` - User authentication
- `POST /api/auth/validate` - Token validation
- `POST /api/auth/logout` - User logout

### Stock Pickings
- `GET /api/pickings` - Retrieve stock pickings
- `POST /api/pickings/{id}/update_sn` - Update serial numbers in batch

### Serial Numbers
- `POST /api/serial/check` - Check serial number existence
- `POST /api/serial/batch_check` - Batch check multiple serial numbers
- `POST /api/serial/history` - Get serial number movement history

## Installation

1. Copy the `stock_scan_mobile` folder to your Odoo addons directory
2. Update the addons list: `./odoo-bin -u all -d your_database`
3. Install the module from the Apps menu in Odoo
4. Configure the module settings in Settings > Technical > Parameters > System Parameters

## Configuration

### Required Groups
Users must be assigned to one of these groups:
- **Mobile App User**: Basic mobile app access
- **Mobile App Manager**: Full mobile app management

### System Parameters
Key configuration parameters (automatically created):

#### Authentication
- `stock_scan_mobile.token_expiry_hours`: Token validity period (default: 24)
- `stock_scan_mobile.max_login_attempts`: Maximum login attempts (default: 5)

#### API Settings
- `stock_scan_mobile.api_rate_limit_per_minute`: API rate limit (default: 100)
- `stock_scan_mobile.max_batch_size`: Maximum batch size (default: 100)

#### CORS Settings
- `stock_scan_mobile.cors_enabled`: Enable CORS (default: True)
- `stock_scan_mobile.cors_origins`: Allowed origins (default: *)

## Usage Examples

### Authentication
```json
POST /api/auth/login
{
    "username": "user@example.com",
    "password": "password123"
}
```

### Get Stock Pickings
```json
GET /api/pickings
{
    "token": "your_access_token",
    "type": "in",
    "state": "assigned",
    "limit": 20
}
```

### Update Serial Numbers
```json
POST /api/pickings/123/update_sn
{
    "token": "your_access_token",
    "serial_numbers": [
        {
            "product_id": 456,
            "move_id": 789,
            "serial_number": "SN001",
            "location": "A-01-01"
        }
    ]
}
```

### Check Serial Number
```json
POST /api/serial/check
{
    "token": "your_access_token",
    "serial_number": "SN001",
    "product_id": 456
}
```

## Mobile App Integration

This module is designed to work with the StockScan Pro Flutter mobile application. The mobile app provides:

- Barcode/QR code scanning
- Offline data storage
- Real-time synchronization
- User-friendly interface for stock operations

## Security Considerations

1. **Token Management**: Tokens expire after 24 hours by default
2. **Rate Limiting**: API calls are limited to prevent abuse
3. **CORS Configuration**: Configure allowed origins for production
4. **User Permissions**: Ensure users have appropriate stock management permissions
5. **HTTPS**: Always use HTTPS in production environments

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Check user credentials
   - Verify user has stock management permissions
   - Check if user is in Mobile App User group

2. **API Rate Limit Exceeded**
   - Reduce API call frequency
   - Increase rate limit in system parameters

3. **CORS Errors**
   - Configure `stock_scan_mobile.cors_origins` parameter
   - Ensure mobile app domain is allowed

### Logging

Enable debug logging by setting:
- `stock_scan_mobile.debug_mode`: True
- `stock_scan_mobile.log_level`: DEBUG

## Support

For support and bug reports, please contact the StockScan Pro development team.

## License

This module is licensed under LGPL-3.

## Version History

- **1.0.0**: Initial release with core functionality
  - Authentication system
  - Stock picking management
  - Serial number operations
  - Security and access control

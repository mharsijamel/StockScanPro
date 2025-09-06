# API Testing Guide - Stock Scan Mobile

## Overview

This guide provides examples and test cases for testing the Stock Scan Mobile API endpoints.

## Prerequisites

- Odoo 15 with Stock Scan Mobile module installed
- API testing tool (Postman, curl, or similar)
- Valid Odoo user credentials with stock management permissions

## Base URL

Replace `{your-odoo-server}` with your actual Odoo server URL:
- Development: `http://localhost:8069`
- Production: `https://your-odoo-server.com`

## Authentication Tests

### 1. Login Test

**Endpoint**: `POST /api/auth/login`

```bash
curl -X POST http://{your-odoo-server}/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "token": "abc123...",
  "user_id": 2,
  "username": "admin",
  "name": "Administrator",
  "expires_at": "2024-01-02T10:00:00"
}
```

### 2. Token Validation Test

**Endpoint**: `POST /api/auth/validate`

```bash
curl -X POST http://{your-odoo-server}/api/auth/validate \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here"
  }'
```

### 3. Logout Test

**Endpoint**: `POST /api/auth/logout`

```bash
curl -X POST http://{your-odoo-server}/api/auth/logout \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here"
  }'
```

## Stock Picking Tests

### 1. Get All Pickings

**Endpoint**: `GET /api/pickings`

```bash
curl -X POST http://{your-odoo-server}/api/pickings \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here",
    "limit": 10,
    "offset": 0
  }'
```

### 2. Get Incoming Pickings

```bash
curl -X POST http://{your-odoo-server}/api/pickings \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here",
    "type": "in",
    "state": "assigned",
    "limit": 20
  }'
```

### 3. Get Outgoing Pickings

```bash
curl -X POST http://{your-odoo-server}/api/pickings \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here",
    "type": "out",
    "state": "assigned",
    "limit": 20
  }'
```

### 4. Update Serial Numbers

**Endpoint**: `POST /api/pickings/{picking_id}/update_sn`

```bash
curl -X POST http://{your-odoo-server}/api/pickings/123/update_sn \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here",
    "serial_numbers": [
      {
        "product_id": 456,
        "move_id": 789,
        "serial_number": "SN001",
        "location": "A-01-01"
      },
      {
        "product_id": 456,
        "move_id": 789,
        "serial_number": "SN002",
        "location": "A-01-02"
      }
    ]
  }'
```

## Serial Number Tests

### 1. Check Single Serial Number

**Endpoint**: `POST /api/serial/check`

```bash
curl -X POST http://{your-odoo-server}/api/serial/check \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here",
    "serial_number": "SN001",
    "product_id": 456
  }'
```

### 2. Batch Check Serial Numbers

**Endpoint**: `POST /api/serial/batch_check`

```bash
curl -X POST http://{your-odoo-server}/api/serial/batch_check \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here",
    "serial_numbers": ["SN001", "SN002", "SN003"],
    "product_id": 456
  }'
```

### 3. Get Serial Number History

**Endpoint**: `POST /api/serial/history`

```bash
curl -X POST http://{your-odoo-server}/api/serial/history \
  -H "Content-Type: application/json" \
  -d '{
    "token": "your_token_here",
    "serial_number": "SN001",
    "limit": 10
  }'
```

## Test Scenarios

### Scenario 1: Complete Stock IN Flow

1. **Login**
2. **Get incoming pickings**
3. **Check serial numbers** (should not exist for new items)
4. **Update serial numbers** for the picking
5. **Verify picking state** (should be 'done' if all items scanned)

### Scenario 2: Complete Stock OUT Flow

1. **Login**
2. **Get outgoing pickings**
3. **Check serial numbers** (should exist in system)
4. **Update serial numbers** for the picking
5. **Verify picking state**

### Scenario 3: Error Handling

1. **Test invalid credentials**
2. **Test expired token**
3. **Test non-existent serial numbers**
4. **Test invalid picking ID**
5. **Test rate limiting**

## Postman Collection

### Environment Variables

Create these variables in Postman:
- `base_url`: Your Odoo server URL
- `token`: Authentication token (set after login)
- `user_id`: User ID (set after login)

### Collection Structure

```
Stock Scan Mobile API/
├── Authentication/
│   ├── Login
│   ├── Validate Token
│   └── Logout
├── Stock Pickings/
│   ├── Get All Pickings
│   ├── Get Incoming Pickings
│   ├── Get Outgoing Pickings
│   └── Update Serial Numbers
└── Serial Numbers/
    ├── Check Serial Number
    ├── Batch Check
    └── Get History
```

## Python Test Script

```python
import requests
import json

class StockScanAPITest:
    def __init__(self, base_url):
        self.base_url = base_url
        self.token = None
    
    def login(self, username, password):
        url = f"{self.base_url}/api/auth/login"
        data = {
            "username": username,
            "password": password
        }
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                self.token = result.get('token')
                print(f"Login successful. Token: {self.token[:20]}...")
                return True
        print(f"Login failed: {response.text}")
        return False
    
    def get_pickings(self, picking_type=None, limit=10):
        url = f"{self.base_url}/api/pickings"
        data = {
            "token": self.token,
            "limit": limit
        }
        if picking_type:
            data["type"] = picking_type
        
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print(f"Found {len(result.get('pickings', []))} pickings")
                return result.get('pickings', [])
        print(f"Get pickings failed: {response.text}")
        return []
    
    def check_serial(self, serial_number, product_id=None):
        url = f"{self.base_url}/api/serial/check"
        data = {
            "token": self.token,
            "serial_number": serial_number
        }
        if product_id:
            data["product_id"] = product_id
        
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                exists = result.get('exists', False)
                print(f"Serial {serial_number} exists: {exists}")
                return result
        print(f"Check serial failed: {response.text}")
        return None

# Usage example
if __name__ == "__main__":
    api = StockScanAPITest("http://localhost:8069")
    
    # Test login
    if api.login("admin", "admin"):
        # Test get pickings
        pickings = api.get_pickings("in", 5)
        
        # Test check serial
        api.check_serial("TEST001")
```

## Common Error Responses

### Authentication Errors

```json
{
  "success": false,
  "error": "Invalid username or password",
  "error_code": "INVALID_CREDENTIALS"
}
```

### Token Errors

```json
{
  "success": false,
  "error": "Invalid or expired token",
  "error_code": "INVALID_TOKEN"
}
```

### Permission Errors

```json
{
  "success": false,
  "error": "User does not have stock management permissions",
  "error_code": "INSUFFICIENT_PERMISSIONS"
}
```

### Rate Limit Errors

```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "error_code": "RATE_LIMIT_EXCEEDED"
}
```

## Performance Testing

### Load Testing with curl

```bash
# Test concurrent requests
for i in {1..10}; do
  curl -X POST http://{your-odoo-server}/api/pickings \
    -H "Content-Type: application/json" \
    -d '{"token":"your_token","limit":5}' &
done
wait
```

### Response Time Monitoring

Monitor these metrics:
- Authentication response time (< 500ms)
- Picking list response time (< 1000ms)
- Serial check response time (< 200ms)
- Batch operations response time (< 2000ms)

## Troubleshooting

### Common Issues

1. **CORS Errors**: Configure `stock_scan_mobile.cors_origins`
2. **Slow Responses**: Check database performance
3. **Authentication Failures**: Verify user permissions
4. **Token Expiry**: Implement token refresh logic

### Debug Mode

Enable debug mode for detailed logging:
```
stock_scan_mobile.debug_mode = True
stock_scan_mobile.log_level = DEBUG
```

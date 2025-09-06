# -*- coding: utf-8 -*-
{
    'name': 'Stock Scan Mobile API',
    'version': '15.0.1.0.0',
    'category': 'Inventory/Inventory',
    'summary': 'Mobile API for Stock Operations with Serial Number Management',
    'description': """
Stock Scan Mobile API
=====================

This module provides REST API endpoints for mobile applications to manage stock operations
with serial number scanning and tracking.

Features:
---------
* Authentication API with token management
* Stock picking management (IN/OUT operations)
* Serial number verification and validation
* Batch serial number updates with location tracking
* Real-time synchronization with mobile app
* Comprehensive error handling and logging

API Endpoints:
--------------
* POST /api/auth/login - User authentication
* GET /api/pickings - Retrieve stock pickings
* GET /api/serial/check - Verify serial number existence
* POST /api/pickings/{id}/update_sn - Update serial numbers in batch

Security:
---------
* Token-based authentication
* CORS configuration for mobile apps
* Rate limiting and access control
* Secure API communication
    """,
    'author': 'StockScan Pro Team',
    'website': 'https://stockscanpro.com',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'stock',
        'product',
        'web',
    ],
    'data': [
        'security/ir.model.access.csv',
        'security/security.xml',
        'data/ir_config_parameter.xml',
    ],
    'external_dependencies': {
        'python': ['werkzeug', 'json'],
    },
    'installable': True,
    'auto_install': False,
    'application': True,
    'sequence': 10,
    'post_init_hook': 'post_init_hook',
}

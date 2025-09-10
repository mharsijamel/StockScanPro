# -*- coding: utf-8 -*-
{
    'name': 'Stock Scan Mobile API',
    'version': '15.0.1.0.0',
    'category': 'Inventory/Inventory',
    'summary': 'Mobile API for Stock Management with Serial Numbers',
    'description': '''
Stock Scan Mobile API
=====================

This module provides REST API endpoints for mobile applications to manage
stock operations with serial number tracking.

Features:
---------
* Mobile authentication API
* Stock picking management  
* Serial number validation and tracking
* Real-time synchronization with mobile apps
* Offline-capable operations

API Endpoints:
--------------
* /api/auth/login - User authentication
* /api/auth/validate - Token validation
* /api/auth/logout - User logout
* /api/health - Health check
* /api/databases - Database listing
* /api/pickings - Stock picking operations
* /api/pickings/{id}/update_sn - Serial number updates
* /api/serial/check - Serial number validation

Compatible with StockScan Pro mobile application.
    ''',
    'author': 'StockScan Pro Team',
    'website': 'https://github.com/stockscanpro',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'stock',
        'product',
        'web',
    ],
    'data': [],
    'installable': True,
    'auto_install': False,
    'application': False,
    'sequence': 100,
}
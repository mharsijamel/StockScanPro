# -*- coding: utf-8 -*-

import json
import logging
from datetime import datetime

from odoo import http, fields
from odoo.http import request

_logger = logging.getLogger(__name__)


class SerialController(http.Controller):
    """Serial number controller for mobile app"""

    @http.route('/api/serial/check', type='json', auth='none', methods=['POST'], csrf=False, cors='*')
    def check_serial_number(self, **kwargs):
        """
        Check if serial number exists in the system
        
        Expected payload:
        {
            "token": "access_token_here",
            "serial_number": "SN001",
            "product_id": 456  // optional
        }
        
        Returns:
        {
            "success": true,
            "exists": true,
            "serial_info": {
                "id": 123,
                "name": "SN001",
                "product_id": 456,
                "product_name": "Product A",
                "product_code": "PROD-A",
                "current_location": "Stock/Shelf A",
                "available_quantity": 1,
                "reserved_quantity": 0,
                "last_move_date": "2024-01-01T10:00:00Z"
            }
        }
        """
        try:
            # Get request data
            data = request.jsonrequest
            token = data.get('token')
            serial_number = data.get('serial_number')
            product_id = data.get('product_id')
            
            # Authenticate user
            user_id = self._authenticate_token(token)
            if not user_id:
                return {
                    'success': False,
                    'error': 'Invalid or expired token',
                    'error_code': 'INVALID_TOKEN'
                }
            
            if not serial_number:
                return {
                    'success': False,
                    'error': 'Serial number is required',
                    'error_code': 'MISSING_SERIAL_NUMBER'
                }
            
            # Build domain for lot search
            domain = [('name', '=', serial_number)]
            if product_id:
                domain.append(('product_id', '=', product_id))
            
            # Search for lot/serial number
            lot = request.env['stock.production.lot'].sudo().search(domain, limit=1)
            
            if not lot:
                return {
                    'success': True,
                    'exists': False,
                    'serial_number': serial_number
                }
            
            # Get current stock information
            quants = request.env['stock.quant'].sudo().search([
                ('lot_id', '=', lot.id),
                ('location_id.usage', '=', 'internal')
            ])
            
            available_quantity = sum(quants.mapped('available_quantity'))
            reserved_quantity = sum(quants.mapped('reserved_quantity'))
            
            # Get current location (location with highest quantity)
            current_location = ''
            if quants:
                main_quant = max(quants, key=lambda q: q.quantity)
                current_location = main_quant.location_id.complete_name
            
            # Get last move date
            last_move_date = None
            last_move = request.env['stock.move.line'].sudo().search([
                ('lot_id', '=', lot.id)
            ], order='date desc', limit=1)
            if last_move:
                last_move_date = last_move.date.isoformat()
            
            serial_info = {
                'id': lot.id,
                'name': lot.name,
                'product_id': lot.product_id.id,
                'product_name': lot.product_id.name,
                'product_code': lot.product_id.default_code or '',
                'current_location': current_location,
                'available_quantity': available_quantity,
                'reserved_quantity': reserved_quantity,
                'last_move_date': last_move_date,
                'tracking': lot.product_id.tracking
            }
            
            _logger.info(f"Serial number check for {serial_number}: exists={True}")
            
            return {
                'success': True,
                'exists': True,
                'serial_info': serial_info
            }
            
        except Exception as e:
            _logger.error(f"Error checking serial number: {str(e)}")
            return {
                'success': False,
                'error': 'Internal server error',
                'error_code': 'SERVER_ERROR'
            }

    @http.route('/api/serial/batch_check', type='json', auth='none', methods=['POST'], csrf=False, cors='*')
    def batch_check_serial_numbers(self, **kwargs):
        """
        Check multiple serial numbers at once
        
        Expected payload:
        {
            "token": "access_token_here",
            "serial_numbers": ["SN001", "SN002", "SN003"],
            "product_id": 456  // optional
        }
        
        Returns:
        {
            "success": true,
            "results": [
                {
                    "serial_number": "SN001",
                    "exists": true,
                    "serial_info": { ... }
                },
                {
                    "serial_number": "SN002",
                    "exists": false
                }
            ]
        }
        """
        try:
            # Get request data
            data = request.jsonrequest
            token = data.get('token')
            serial_numbers = data.get('serial_numbers', [])
            product_id = data.get('product_id')
            
            # Authenticate user
            user_id = self._authenticate_token(token)
            if not user_id:
                return {
                    'success': False,
                    'error': 'Invalid or expired token',
                    'error_code': 'INVALID_TOKEN'
                }
            
            if not serial_numbers:
                return {
                    'success': False,
                    'error': 'Serial numbers list is required',
                    'error_code': 'MISSING_SERIAL_NUMBERS'
                }
            
            results = []
            
            for serial_number in serial_numbers:
                try:
                    # Build domain for lot search
                    domain = [('name', '=', serial_number)]
                    if product_id:
                        domain.append(('product_id', '=', product_id))
                    
                    # Search for lot/serial number
                    lot = request.env['stock.production.lot'].sudo().search(domain, limit=1)
                    
                    if not lot:
                        results.append({
                            'serial_number': serial_number,
                            'exists': False
                        })
                        continue
                    
                    # Get current stock information
                    quants = request.env['stock.quant'].sudo().search([
                        ('lot_id', '=', lot.id),
                        ('location_id.usage', '=', 'internal')
                    ])
                    
                    available_quantity = sum(quants.mapped('available_quantity'))
                    reserved_quantity = sum(quants.mapped('reserved_quantity'))
                    
                    # Get current location
                    current_location = ''
                    if quants:
                        main_quant = max(quants, key=lambda q: q.quantity)
                        current_location = main_quant.location_id.complete_name
                    
                    # Get last move date
                    last_move_date = None
                    last_move = request.env['stock.move.line'].sudo().search([
                        ('lot_id', '=', lot.id)
                    ], order='date desc', limit=1)
                    if last_move:
                        last_move_date = last_move.date.isoformat()
                    
                    serial_info = {
                        'id': lot.id,
                        'name': lot.name,
                        'product_id': lot.product_id.id,
                        'product_name': lot.product_id.name,
                        'product_code': lot.product_id.default_code or '',
                        'current_location': current_location,
                        'available_quantity': available_quantity,
                        'reserved_quantity': reserved_quantity,
                        'last_move_date': last_move_date,
                        'tracking': lot.product_id.tracking
                    }
                    
                    results.append({
                        'serial_number': serial_number,
                        'exists': True,
                        'serial_info': serial_info
                    })
                    
                except Exception as e:
                    _logger.error(f"Error checking serial number {serial_number}: {str(e)}")
                    results.append({
                        'serial_number': serial_number,
                        'exists': False,
                        'error': str(e)
                    })
            
            _logger.info(f"Batch serial number check completed for {len(serial_numbers)} items")
            
            return {
                'success': True,
                'results': results,
                'total_checked': len(serial_numbers)
            }
            
        except Exception as e:
            _logger.error(f"Error in batch serial number check: {str(e)}")
            return {
                'success': False,
                'error': 'Internal server error',
                'error_code': 'SERVER_ERROR'
            }

    @http.route('/api/serial/history', type='json', auth='none', methods=['POST'], csrf=False, cors='*')
    def get_serial_history(self, **kwargs):
        """
        Get movement history for a serial number
        
        Expected payload:
        {
            "token": "access_token_here",
            "serial_number": "SN001",
            "limit": 10
        }
        
        Returns:
        {
            "success": true,
            "history": [
                {
                    "date": "2024-01-01T10:00:00Z",
                    "operation": "Stock IN",
                    "from_location": "Vendors",
                    "to_location": "Stock/Shelf A",
                    "picking_name": "WH/IN/00001",
                    "reference": "PO001"
                }
            ]
        }
        """
        try:
            # Get request data
            data = request.jsonrequest
            token = data.get('token')
            serial_number = data.get('serial_number')
            limit = data.get('limit', 10)
            
            # Authenticate user
            user_id = self._authenticate_token(token)
            if not user_id:
                return {
                    'success': False,
                    'error': 'Invalid or expired token',
                    'error_code': 'INVALID_TOKEN'
                }
            
            if not serial_number:
                return {
                    'success': False,
                    'error': 'Serial number is required',
                    'error_code': 'MISSING_SERIAL_NUMBER'
                }
            
            # Find the lot
            lot = request.env['stock.production.lot'].sudo().search([
                ('name', '=', serial_number)
            ], limit=1)
            
            if not lot:
                return {
                    'success': False,
                    'error': 'Serial number not found',
                    'error_code': 'SERIAL_NOT_FOUND'
                }
            
            # Get move lines for this lot
            move_lines = request.env['stock.move.line'].sudo().search([
                ('lot_id', '=', lot.id)
            ], order='date desc', limit=limit)
            
            history = []
            for line in move_lines:
                history.append({
                    'date': line.date.isoformat(),
                    'operation': line.picking_id.picking_type_id.name if line.picking_id else 'Internal Transfer',
                    'from_location': line.location_id.complete_name,
                    'to_location': line.location_dest_id.complete_name,
                    'picking_name': line.picking_id.name if line.picking_id else '',
                    'reference': line.picking_id.origin if line.picking_id else '',
                    'quantity': line.qty_done,
                    'state': line.state
                })
            
            return {
                'success': True,
                'serial_number': serial_number,
                'product_name': lot.product_id.name,
                'history': history,
                'total_moves': len(history)
            }
            
        except Exception as e:
            _logger.error(f"Error getting serial history: {str(e)}")
            return {
                'success': False,
                'error': 'Internal server error',
                'error_code': 'SERVER_ERROR'
            }

    def _authenticate_token(self, token):
        """Authenticate request using token and return user ID"""
        if not token:
            return None
        
        try:
            # Search for token in stored tokens
            config_params = request.env['ir.config_parameter'].sudo().search([
                ('key', 'like', 'mobile_token_%')
            ])
            
            for param in config_params:
                try:
                    token_data = json.loads(param.value)
                    if token_data.get('token') == token:
                        # Check if token is expired
                        expires_at = datetime.fromisoformat(token_data['expires_at'])
                        if datetime.now() < expires_at:
                            return token_data['user_id']
                        else:
                            # Token expired, remove it
                            param.sudo().unlink()
                            return None
                except (json.JSONDecodeError, ValueError, KeyError):
                    continue
            
            return None
            
        except Exception as e:
            _logger.error(f"Token authentication error: {str(e)}")
            return None

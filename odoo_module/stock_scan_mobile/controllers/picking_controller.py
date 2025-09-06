# -*- coding: utf-8 -*-

import json
import logging
from datetime import datetime

from odoo import http, fields
from odoo.http import request
from odoo.exceptions import ValidationError, UserError

_logger = logging.getLogger(__name__)


class PickingController(http.Controller):
    """Stock picking controller for mobile app"""

    @http.route('/api/pickings', type='json', auth='none', methods=['GET'], csrf=False, cors='*')
    def get_pickings(self, **kwargs):
        """
        Get stock pickings filtered by type and status
        
        Expected parameters:
        - token: Authentication token
        - type: 'in' or 'out' (optional)
        - state: picking state filter (optional)
        - limit: number of records to return (default: 50)
        - offset: offset for pagination (default: 0)
        
        Returns:
        {
            "success": true,
            "pickings": [
                {
                    "id": 123,
                    "name": "WH/IN/00001",
                    "operation_type": "in",
                    "state": "assigned",
                    "scheduled_date": "2024-01-01T10:00:00Z",
                    "origin": "PO001",
                    "destination": "Stock",
                    "partner_name": "Supplier ABC",
                    "products": [
                        {
                            "id": 456,
                            "name": "Product A",
                            "default_code": "PROD-A",
                            "quantity": 10,
                            "quantity_done": 0,
                            "tracking": "serial"
                        }
                    ]
                }
            ],
            "total_count": 25
        }
        """
        try:
            # Get request data
            data = request.jsonrequest or {}
            token = data.get('token')
            picking_type = data.get('type')  # 'in' or 'out'
            state = data.get('state')
            limit = data.get('limit', 50)
            offset = data.get('offset', 0)
            
            # Authenticate user
            auth_controller = request.env['stock_scan_mobile.controllers.auth_controller']
            user_id = self._authenticate_token(token)
            if not user_id:
                return {
                    'success': False,
                    'error': 'Invalid or expired token',
                    'error_code': 'INVALID_TOKEN'
                }
            
            # Build domain for filtering
            domain = []
            
            # Filter by picking type
            if picking_type == 'in':
                domain.append(('picking_type_id.code', '=', 'incoming'))
            elif picking_type == 'out':
                domain.append(('picking_type_id.code', '=', 'outgoing'))
            
            # Filter by state
            if state:
                domain.append(('state', '=', state))
            else:
                # Default: only show assigned and partially available pickings
                domain.append(('state', 'in', ['assigned', 'partially_available']))
            
            # Get pickings
            pickings = request.env['stock.picking'].sudo().search(
                domain, 
                limit=limit, 
                offset=offset, 
                order='scheduled_date desc, id desc'
            )
            
            # Get total count
            total_count = request.env['stock.picking'].sudo().search_count(domain)
            
            # Format response
            picking_data = []
            for picking in pickings:
                # Get products in this picking
                products = []
                for move in picking.move_ids_without_package:
                    products.append({
                        'id': move.product_id.id,
                        'name': move.product_id.name,
                        'default_code': move.product_id.default_code or '',
                        'quantity': move.product_uom_qty,
                        'quantity_done': move.quantity_done,
                        'tracking': move.product_id.tracking,
                        'uom': move.product_uom.name,
                        'move_id': move.id
                    })
                
                picking_data.append({
                    'id': picking.id,
                    'name': picking.name,
                    'operation_type': 'in' if picking.picking_type_id.code == 'incoming' else 'out',
                    'state': picking.state,
                    'scheduled_date': picking.scheduled_date.isoformat() if picking.scheduled_date else None,
                    'origin': picking.origin or '',
                    'destination': picking.location_dest_id.complete_name or '',
                    'partner_name': picking.partner_id.name if picking.partner_id else '',
                    'products': products,
                    'total_products': len(products)
                })
            
            _logger.info(f"Retrieved {len(picking_data)} pickings for user {user_id}")
            
            return {
                'success': True,
                'pickings': picking_data,
                'total_count': total_count,
                'limit': limit,
                'offset': offset
            }
            
        except Exception as e:
            _logger.error(f"Error retrieving pickings: {str(e)}")
            return {
                'success': False,
                'error': 'Internal server error',
                'error_code': 'SERVER_ERROR'
            }

    @http.route('/api/pickings/<int:picking_id>/update_sn', type='json', auth='none', methods=['POST'], csrf=False, cors='*')
    def update_serial_numbers(self, picking_id, **kwargs):
        """
        Update serial numbers for a picking in batch
        
        Expected payload:
        {
            "token": "access_token_here",
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
        }
        
        Returns:
        {
            "success": true,
            "processed": 2,
            "errors": [],
            "picking_state": "done"
        }
        """
        try:
            # Get request data
            data = request.jsonrequest
            token = data.get('token')
            serial_numbers = data.get('serial_numbers', [])
            
            # Authenticate user
            user_id = self._authenticate_token(token)
            if not user_id:
                return {
                    'success': False,
                    'error': 'Invalid or expired token',
                    'error_code': 'INVALID_TOKEN'
                }
            
            # Get picking
            picking = request.env['stock.picking'].sudo().browse(picking_id)
            if not picking.exists():
                return {
                    'success': False,
                    'error': 'Picking not found',
                    'error_code': 'PICKING_NOT_FOUND'
                }
            
            processed = 0
            errors = []
            
            # Process each serial number
            for sn_data in serial_numbers:
                try:
                    product_id = sn_data.get('product_id')
                    move_id = sn_data.get('move_id')
                    serial_number = sn_data.get('serial_number')
                    location = sn_data.get('location', '')
                    
                    if not all([product_id, move_id, serial_number]):
                        errors.append({
                            'serial_number': serial_number or 'Unknown',
                            'error': 'Missing required fields',
                            'error_code': 'MISSING_FIELDS'
                        })
                        continue
                    
                    # Get the move
                    move = request.env['stock.move'].sudo().browse(move_id)
                    if not move.exists() or move.picking_id.id != picking_id:
                        errors.append({
                            'serial_number': serial_number,
                            'error': 'Invalid move for this picking',
                            'error_code': 'INVALID_MOVE'
                        })
                        continue
                    
                    # Create or get lot/serial number
                    lot = request.env['stock.production.lot'].sudo().search([
                        ('name', '=', serial_number),
                        ('product_id', '=', product_id)
                    ], limit=1)
                    
                    if not lot:
                        # Create new lot for incoming operations
                        if picking.picking_type_id.code == 'incoming':
                            lot = request.env['stock.production.lot'].sudo().create({
                                'name': serial_number,
                                'product_id': product_id,
                                'company_id': picking.company_id.id
                            })
                        else:
                            errors.append({
                                'serial_number': serial_number,
                                'error': 'Serial number not found in system',
                                'error_code': 'SERIAL_NOT_FOUND'
                            })
                            continue
                    
                    # Create move line
                    move_line_vals = {
                        'move_id': move_id,
                        'product_id': product_id,
                        'lot_id': lot.id,
                        'qty_done': 1,
                        'location_id': move.location_id.id,
                        'location_dest_id': move.location_dest_id.id,
                        'picking_id': picking_id,
                    }
                    
                    # Add location reference if provided
                    if location:
                        move_line_vals['location_name'] = location
                    
                    request.env['stock.move.line'].sudo().create(move_line_vals)
                    processed += 1
                    
                except Exception as e:
                    _logger.error(f"Error processing serial number {serial_number}: {str(e)}")
                    errors.append({
                        'serial_number': serial_number,
                        'error': str(e),
                        'error_code': 'PROCESSING_ERROR'
                    })
            
            # Try to validate picking if all moves are done
            try:
                if picking.state in ['assigned', 'partially_available']:
                    # Check if all moves have sufficient quantity done
                    all_done = True
                    for move in picking.move_ids_without_package:
                        if move.quantity_done < move.product_uom_qty:
                            all_done = False
                            break
                    
                    if all_done:
                        picking.button_validate()
                        _logger.info(f"Picking {picking.name} validated successfully")
            except Exception as e:
                _logger.warning(f"Could not validate picking {picking.name}: {str(e)}")
            
            _logger.info(f"Processed {processed} serial numbers for picking {picking.name}")
            
            return {
                'success': True,
                'processed': processed,
                'errors': errors,
                'picking_state': picking.state,
                'picking_name': picking.name
            }
            
        except Exception as e:
            _logger.error(f"Error updating serial numbers: {str(e)}")
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

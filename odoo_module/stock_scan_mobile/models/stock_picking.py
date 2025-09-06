# -*- coding: utf-8 -*-

from odoo import models, fields, api
import logging

_logger = logging.getLogger(__name__)


class StockPicking(models.Model):
    _inherit = 'stock.picking'

    # Add mobile-specific fields
    mobile_sync_status = fields.Selection([
        ('pending', 'Pending Sync'),
        ('synced', 'Synced'),
        ('error', 'Sync Error')
    ], string='Mobile Sync Status', default='pending')
    
    mobile_last_sync = fields.Datetime(string='Last Mobile Sync')
    mobile_sync_error = fields.Text(string='Mobile Sync Error')
    
    # Add location reference field for mobile scanning
    mobile_location_reference = fields.Char(string='Mobile Location Reference')

    @api.model
    def get_mobile_pickings(self, picking_type='all', state='assigned', limit=50, offset=0):
        """
        Get pickings formatted for mobile app consumption
        
        Args:
            picking_type (str): 'in', 'out', or 'all'
            state (str): picking state filter
            limit (int): number of records to return
            offset (int): offset for pagination
            
        Returns:
            dict: formatted picking data
        """
        domain = []
        
        # Filter by picking type
        if picking_type == 'in':
            domain.append(('picking_type_id.code', '=', 'incoming'))
        elif picking_type == 'out':
            domain.append(('picking_type_id.code', '=', 'outgoing'))
        
        # Filter by state
        if state != 'all':
            if state == 'ready':
                domain.append(('state', 'in', ['assigned', 'partially_available']))
            else:
                domain.append(('state', '=', state))
        
        # Get pickings
        pickings = self.search(domain, limit=limit, offset=offset, order='scheduled_date desc, id desc')
        total_count = self.search_count(domain)
        
        # Format for mobile
        picking_data = []
        for picking in pickings:
            picking_data.append(picking._format_for_mobile())
        
        return {
            'pickings': picking_data,
            'total_count': total_count,
            'limit': limit,
            'offset': offset
        }

    def _format_for_mobile(self):
        """Format picking data for mobile app"""
        self.ensure_one()
        
        # Get products in this picking
        products = []
        for move in self.move_ids_without_package:
            products.append({
                'id': move.product_id.id,
                'name': move.product_id.name,
                'default_code': move.product_id.default_code or '',
                'quantity': move.product_uom_qty,
                'quantity_done': move.quantity_done,
                'tracking': move.product_id.tracking,
                'uom': move.product_uom.name,
                'move_id': move.id,
                'barcode': move.product_id.barcode or ''
            })
        
        return {
            'id': self.id,
            'name': self.name,
            'operation_type': 'in' if self.picking_type_id.code == 'incoming' else 'out',
            'state': self.state,
            'scheduled_date': self.scheduled_date.isoformat() if self.scheduled_date else None,
            'origin': self.origin or '',
            'destination': self.location_dest_id.complete_name or '',
            'source': self.location_id.complete_name or '',
            'partner_name': self.partner_id.name if self.partner_id else '',
            'partner_id': self.partner_id.id if self.partner_id else None,
            'products': products,
            'total_products': len(products),
            'mobile_sync_status': self.mobile_sync_status,
            'mobile_location_reference': self.mobile_location_reference or ''
        }

    def update_mobile_sync_status(self, status, error_message=None):
        """Update mobile sync status"""
        self.ensure_one()
        vals = {
            'mobile_sync_status': status,
            'mobile_last_sync': fields.Datetime.now()
        }
        if error_message:
            vals['mobile_sync_error'] = error_message
        else:
            vals['mobile_sync_error'] = False
        
        self.write(vals)
        _logger.info(f"Updated mobile sync status for picking {self.name}: {status}")

    @api.model
    def process_mobile_serial_numbers(self, picking_id, serial_data_list):
        """
        Process serial numbers from mobile app
        
        Args:
            picking_id (int): ID of the picking
            serial_data_list (list): List of serial number data
            
        Returns:
            dict: Processing results
        """
        picking = self.browse(picking_id)
        if not picking.exists():
            return {'success': False, 'error': 'Picking not found'}
        
        processed = 0
        errors = []
        
        try:
            for sn_data in serial_data_list:
                try:
                    result = picking._process_single_serial_number(sn_data)
                    if result['success']:
                        processed += 1
                    else:
                        errors.append({
                            'serial_number': sn_data.get('serial_number', 'Unknown'),
                            'error': result['error']
                        })
                except Exception as e:
                    _logger.error(f"Error processing serial number: {str(e)}")
                    errors.append({
                        'serial_number': sn_data.get('serial_number', 'Unknown'),
                        'error': str(e)
                    })
            
            # Try to validate picking if all moves are done
            if picking.state in ['assigned', 'partially_available']:
                picking._try_auto_validate()
            
            picking.update_mobile_sync_status('synced')
            
            return {
                'success': True,
                'processed': processed,
                'errors': errors,
                'picking_state': picking.state
            }
            
        except Exception as e:
            _logger.error(f"Error processing mobile serial numbers: {str(e)}")
            picking.update_mobile_sync_status('error', str(e))
            return {'success': False, 'error': str(e)}

    def _process_single_serial_number(self, sn_data):
        """Process a single serial number entry"""
        self.ensure_one()
        
        try:
            product_id = sn_data.get('product_id')
            move_id = sn_data.get('move_id')
            serial_number = sn_data.get('serial_number')
            location_ref = sn_data.get('location', '')
            
            if not all([product_id, move_id, serial_number]):
                return {'success': False, 'error': 'Missing required fields'}
            
            # Get the move
            move = self.env['stock.move'].browse(move_id)
            if not move.exists() or move.picking_id.id != self.id:
                return {'success': False, 'error': 'Invalid move for this picking'}
            
            # Create or get lot/serial number
            lot = self.env['stock.production.lot'].search([
                ('name', '=', serial_number),
                ('product_id', '=', product_id)
            ], limit=1)
            
            if not lot:
                if self.picking_type_id.code == 'incoming':
                    # Create new lot for incoming operations
                    lot = self.env['stock.production.lot'].create({
                        'name': serial_number,
                        'product_id': product_id,
                        'company_id': self.company_id.id
                    })
                else:
                    return {'success': False, 'error': 'Serial number not found in system'}
            
            # Check if move line already exists for this lot
            existing_line = self.env['stock.move.line'].search([
                ('move_id', '=', move_id),
                ('lot_id', '=', lot.id),
                ('picking_id', '=', self.id)
            ], limit=1)
            
            if existing_line:
                return {'success': False, 'error': 'Serial number already scanned for this move'}
            
            # Create move line
            move_line_vals = {
                'move_id': move_id,
                'product_id': product_id,
                'lot_id': lot.id,
                'qty_done': 1,
                'location_id': move.location_id.id,
                'location_dest_id': move.location_dest_id.id,
                'picking_id': self.id,
            }
            
            # Add location reference if provided
            if location_ref:
                self.mobile_location_reference = location_ref
            
            self.env['stock.move.line'].create(move_line_vals)
            
            return {'success': True}
            
        except Exception as e:
            _logger.error(f"Error processing single serial number: {str(e)}")
            return {'success': False, 'error': str(e)}

    def _try_auto_validate(self):
        """Try to automatically validate picking if all moves are done"""
        self.ensure_one()
        
        try:
            # Check if all moves have sufficient quantity done
            all_done = True
            for move in self.move_ids_without_package:
                if move.quantity_done < move.product_uom_qty:
                    all_done = False
                    break
            
            if all_done:
                self.button_validate()
                _logger.info(f"Picking {self.name} auto-validated successfully")
                return True
            
            return False
            
        except Exception as e:
            _logger.warning(f"Could not auto-validate picking {self.name}: {str(e)}")
            return False

# -*- coding: utf-8 -*-

from odoo import models, fields, api
import logging

_logger = logging.getLogger(__name__)


class StockProductionLot(models.Model):
    _inherit = 'stock.production.lot'

    # Mobile-specific fields
    mobile_last_scanned = fields.Datetime(string='Last Mobile Scan')
    mobile_scan_count = fields.Integer(string='Mobile Scan Count', default=0)
    mobile_location_reference = fields.Char(string='Mobile Location Reference')
    mobile_notes = fields.Text(string='Mobile Notes')

    @api.model
    def search_serial_numbers(self, search_term, product_id=None, limit=50):
        """
        Search serial numbers for mobile app
        
        Args:
            search_term (str): Serial number search term
            product_id (int): Optional product filter
            limit (int): Maximum results
            
        Returns:
            list: List of serial number data
        """
        domain = [('name', 'ilike', search_term)]
        
        if product_id:
            domain.append(('product_id', '=', product_id))
        
        lots = self.search(domain, limit=limit, order='name')
        
        result = []
        for lot in lots:
            result.append(lot._format_for_mobile())
        
        return result

    def _format_for_mobile(self):
        """Format serial number data for mobile app"""
        self.ensure_one()
        
        # Get current stock information
        quants = self.env['stock.quant'].search([
            ('lot_id', '=', self.id),
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
        last_move = self.env['stock.move.line'].search([
            ('lot_id', '=', self.id)
        ], order='date desc', limit=1)
        if last_move:
            last_move_date = last_move.date.isoformat()
        
        return {
            'id': self.id,
            'name': self.name,
            'product_id': self.product_id.id,
            'product_name': self.product_id.name,
            'product_code': self.product_id.default_code or '',
            'current_location': current_location,
            'available_quantity': available_quantity,
            'reserved_quantity': reserved_quantity,
            'last_move_date': last_move_date,
            'tracking': self.product_id.tracking,
            'mobile_last_scanned': self.mobile_last_scanned.isoformat() if self.mobile_last_scanned else None,
            'mobile_scan_count': self.mobile_scan_count,
            'mobile_location_reference': self.mobile_location_reference or '',
            'mobile_notes': self.mobile_notes or '',
            'create_date': self.create_date.isoformat() if self.create_date else None
        }

    @api.model
    def check_serial_existence(self, serial_number, product_id=None):
        """
        Check if serial number exists in system
        
        Args:
            serial_number (str): Serial number to check
            product_id (int): Optional product filter
            
        Returns:
            dict: Existence check result
        """
        domain = [('name', '=', serial_number)]
        if product_id:
            domain.append(('product_id', '=', product_id))
        
        lot = self.search(domain, limit=1)
        
        if lot:
            return {
                'exists': True,
                'serial_info': lot._format_for_mobile()
            }
        else:
            return {
                'exists': False,
                'serial_number': serial_number
            }

    @api.model
    def batch_check_serial_existence(self, serial_numbers, product_id=None):
        """
        Check multiple serial numbers at once
        
        Args:
            serial_numbers (list): List of serial numbers to check
            product_id (int): Optional product filter
            
        Returns:
            list: List of check results
        """
        results = []
        
        for serial_number in serial_numbers:
            result = self.check_serial_existence(serial_number, product_id)
            result['serial_number'] = serial_number
            results.append(result)
        
        return results

    def get_movement_history(self, limit=20):
        """
        Get movement history for this serial number
        
        Args:
            limit (int): Maximum number of moves to return
            
        Returns:
            list: List of movement data
        """
        self.ensure_one()
        
        move_lines = self.env['stock.move.line'].search([
            ('lot_id', '=', self.id)
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
                'state': line.state,
                'user_name': line.create_uid.name if line.create_uid else ''
            })
        
        return history

    def update_mobile_scan_info(self, location_reference=None, notes=None):
        """
        Update mobile scan information
        
        Args:
            location_reference (str): Location reference from mobile scan
            notes (str): Notes from mobile scan
            
        Returns:
            dict: Update result
        """
        self.ensure_one()
        
        try:
            vals = {
                'mobile_last_scanned': fields.Datetime.now(),
                'mobile_scan_count': self.mobile_scan_count + 1
            }
            
            if location_reference:
                vals['mobile_location_reference'] = location_reference
            
            if notes:
                vals['mobile_notes'] = notes
            
            self.write(vals)
            
            _logger.info(f"Updated mobile scan info for serial {self.name}")
            
            return {'success': True, 'scan_count': vals['mobile_scan_count']}
            
        except Exception as e:
            _logger.error(f"Error updating mobile scan info for serial {self.name}: {str(e)}")
            return {'success': False, 'error': str(e)}

    @api.model
    def create_from_mobile(self, serial_number, product_id, location_reference=None, notes=None):
        """
        Create new serial number from mobile app
        
        Args:
            serial_number (str): Serial number name
            product_id (int): Product ID
            location_reference (str): Location reference
            notes (str): Notes
            
        Returns:
            dict: Creation result
        """
        try:
            # Check if serial number already exists
            existing = self.search([
                ('name', '=', serial_number),
                ('product_id', '=', product_id)
            ], limit=1)
            
            if existing:
                return {
                    'success': False,
                    'error': 'Serial number already exists',
                    'existing_id': existing.id
                }
            
            # Get product
            product = self.env['product.product'].browse(product_id)
            if not product.exists():
                return {'success': False, 'error': 'Product not found'}
            
            if product.tracking != 'serial':
                return {'success': False, 'error': 'Product does not use serial number tracking'}
            
            # Create new lot
            vals = {
                'name': serial_number,
                'product_id': product_id,
                'company_id': self.env.company.id,
                'mobile_last_scanned': fields.Datetime.now(),
                'mobile_scan_count': 1
            }
            
            if location_reference:
                vals['mobile_location_reference'] = location_reference
            
            if notes:
                vals['mobile_notes'] = notes
            
            lot = self.create(vals)
            
            _logger.info(f"Created new serial number {serial_number} for product {product.name}")
            
            return {
                'success': True,
                'lot_id': lot.id,
                'serial_info': lot._format_for_mobile()
            }
            
        except Exception as e:
            _logger.error(f"Error creating serial number from mobile: {str(e)}")
            return {'success': False, 'error': str(e)}

    @api.model
    def get_available_serials_for_product(self, product_id, location_id=None):
        """
        Get available serial numbers for a product
        
        Args:
            product_id (int): Product ID
            location_id (int): Optional location filter
            
        Returns:
            list: List of available serial numbers
        """
        domain = [('product_id', '=', product_id)]
        
        lots = self.search(domain)
        
        available_serials = []
        for lot in lots:
            quant_domain = [
                ('lot_id', '=', lot.id),
                ('available_quantity', '>', 0)
            ]
            
            if location_id:
                quant_domain.append(('location_id', '=', location_id))
            else:
                quant_domain.append(('location_id.usage', '=', 'internal'))
            
            quants = self.env['stock.quant'].search(quant_domain)
            
            if quants:
                available_serials.append(lot._format_for_mobile())
        
        return available_serials

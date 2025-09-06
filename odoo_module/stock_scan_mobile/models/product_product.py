# -*- coding: utf-8 -*-

from odoo import models, fields, api
import logging

_logger = logging.getLogger(__name__)


class ProductProduct(models.Model):
    _inherit = 'product.product'

    # Mobile-specific fields
    mobile_barcode_alt = fields.Char(string='Alternative Barcode', help='Alternative barcode for mobile scanning')
    mobile_scan_enabled = fields.Boolean(string='Mobile Scan Enabled', default=True)
    mobile_location_hint = fields.Char(string='Mobile Location Hint', help='Location hint for mobile users')

    @api.model
    def search_for_mobile(self, search_term, limit=20):
        """
        Search products for mobile app with barcode, name, and reference
        
        Args:
            search_term (str): Search term (barcode, name, or reference)
            limit (int): Maximum number of results
            
        Returns:
            list: List of product data formatted for mobile
        """
        domain = [
            ('mobile_scan_enabled', '=', True),
            '|', '|', '|',
            ('barcode', 'ilike', search_term),
            ('mobile_barcode_alt', 'ilike', search_term),
            ('name', 'ilike', search_term),
            ('default_code', 'ilike', search_term)
        ]
        
        products = self.search(domain, limit=limit)
        
        result = []
        for product in products:
            result.append(product._format_for_mobile())
        
        return result

    def _format_for_mobile(self):
        """Format product data for mobile app"""
        self.ensure_one()
        
        # Get current stock information
        stock_quants = self.env['stock.quant'].search([
            ('product_id', '=', self.id),
            ('location_id.usage', '=', 'internal')
        ])
        
        available_qty = sum(stock_quants.mapped('available_quantity'))
        reserved_qty = sum(stock_quants.mapped('reserved_quantity'))
        
        return {
            'id': self.id,
            'name': self.name,
            'default_code': self.default_code or '',
            'barcode': self.barcode or '',
            'mobile_barcode_alt': self.mobile_barcode_alt or '',
            'tracking': self.tracking,
            'uom_name': self.uom_id.name,
            'available_quantity': available_qty,
            'reserved_quantity': reserved_qty,
            'mobile_location_hint': self.mobile_location_hint or '',
            'image_url': f'/web/image/product.product/{self.id}/image_128' if self.image_1920 else None
        }

    @api.model
    def get_products_by_barcode(self, barcode):
        """
        Get product by barcode (including alternative barcode)
        
        Args:
            barcode (str): Barcode to search for
            
        Returns:
            dict: Product data or None if not found
        """
        product = self.search([
            ('mobile_scan_enabled', '=', True),
            '|',
            ('barcode', '=', barcode),
            ('mobile_barcode_alt', '=', barcode)
        ], limit=1)
        
        if product:
            return product._format_for_mobile()
        
        return None

    def get_serial_numbers(self, limit=100):
        """
        Get serial numbers for this product
        
        Args:
            limit (int): Maximum number of serial numbers to return
            
        Returns:
            list: List of serial number data
        """
        self.ensure_one()
        
        if self.tracking != 'serial':
            return []
        
        lots = self.env['stock.production.lot'].search([
            ('product_id', '=', self.id)
        ], limit=limit, order='name')
        
        result = []
        for lot in lots:
            # Get current stock for this lot
            quants = self.env['stock.quant'].search([
                ('lot_id', '=', lot.id),
                ('location_id.usage', '=', 'internal')
            ])
            
            available_qty = sum(quants.mapped('available_quantity'))
            current_location = ''
            
            if quants:
                main_quant = max(quants, key=lambda q: q.quantity)
                current_location = main_quant.location_id.complete_name
            
            result.append({
                'id': lot.id,
                'name': lot.name,
                'product_id': self.id,
                'available_quantity': available_qty,
                'current_location': current_location,
                'create_date': lot.create_date.isoformat() if lot.create_date else None
            })
        
        return result

    @api.model
    def validate_barcode_format(self, barcode):
        """
        Validate barcode format
        
        Args:
            barcode (str): Barcode to validate
            
        Returns:
            dict: Validation result
        """
        if not barcode:
            return {'valid': False, 'error': 'Barcode is empty'}
        
        # Basic validation - you can extend this based on your barcode standards
        if len(barcode) < 3:
            return {'valid': False, 'error': 'Barcode too short'}
        
        if len(barcode) > 50:
            return {'valid': False, 'error': 'Barcode too long'}
        
        # Check for invalid characters (basic check)
        import re
        if not re.match(r'^[A-Za-z0-9\-_]+$', barcode):
            return {'valid': False, 'error': 'Barcode contains invalid characters'}
        
        return {'valid': True}

    def update_mobile_settings(self, scan_enabled=None, location_hint=None, alt_barcode=None):
        """
        Update mobile-specific settings for this product
        
        Args:
            scan_enabled (bool): Enable/disable mobile scanning
            location_hint (str): Location hint for mobile users
            alt_barcode (str): Alternative barcode
            
        Returns:
            dict: Update result
        """
        self.ensure_one()
        
        try:
            vals = {}
            
            if scan_enabled is not None:
                vals['mobile_scan_enabled'] = scan_enabled
            
            if location_hint is not None:
                vals['mobile_location_hint'] = location_hint
            
            if alt_barcode is not None:
                # Validate alternative barcode
                validation = self.validate_barcode_format(alt_barcode)
                if not validation['valid']:
                    return {'success': False, 'error': validation['error']}
                
                # Check if alternative barcode is already used
                existing = self.search([
                    ('id', '!=', self.id),
                    '|',
                    ('barcode', '=', alt_barcode),
                    ('mobile_barcode_alt', '=', alt_barcode)
                ], limit=1)
                
                if existing:
                    return {
                        'success': False, 
                        'error': f'Barcode already used by product: {existing.name}'
                    }
                
                vals['mobile_barcode_alt'] = alt_barcode
            
            if vals:
                self.write(vals)
                _logger.info(f"Updated mobile settings for product {self.name}")
            
            return {'success': True, 'updated_fields': list(vals.keys())}
            
        except Exception as e:
            _logger.error(f"Error updating mobile settings for product {self.name}: {str(e)}")
            return {'success': False, 'error': str(e)}

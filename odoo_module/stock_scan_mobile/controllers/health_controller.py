# -*- coding: utf-8 -*-

from odoo import http
from odoo.http import request
import json
import logging
from datetime import datetime

_logger = logging.getLogger(__name__)


class HealthController(http.Controller):
    
    @http.route('/api/health', type='http', auth='none', methods=['GET'], csrf=False, cors='*')
    def health_check(self, **kwargs):
        """
        Health check endpoint for mobile app
        Returns basic server information and status
        """
        try:
            # Basic health check
            response_data = {
                'success': True,
                'status': 'healthy',
                'message': 'Stock Scan Mobile API is running',
                'timestamp': datetime.now().isoformat(),
                'version': '1.0.0',
                'odoo_version': '15.0',  # Fixed for Odoo 15 compatibility
                'database': request.env.cr.dbname if hasattr(request.env, 'cr') else 'unknown'
            }
            
            # Add CORS headers
            headers = {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Openerp-Database',
            }
            
            return request.make_response(
                json.dumps(response_data, ensure_ascii=False, indent=2),
                headers=headers
            )
            
        except Exception as e:
            _logger.error(f"Health check error: {str(e)}")
            
            error_response = {
                'success': False,
                'status': 'error',
                'message': 'Health check failed',
                'error': str(e)
            }
            
            headers = {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Openerp-Database',
            }
            
            response = request.make_response(
                json.dumps(error_response, ensure_ascii=False, indent=2),
                headers=headers
            )
            response.status_code = 500
            return response
    
    @http.route('/api/databases', type='http', auth='none', methods=['GET'], csrf=False, cors='*')
    def list_databases(self, **kwargs):
        """
        List available databases (if allowed by configuration)
        """
        try:
            # Check if database listing is allowed
            if not request.env['ir.config_parameter'].sudo().get_param('list_db', True):
                response = request.make_response(
                    json.dumps({
                        'success': False,
                        'message': 'Database listing is disabled'
                    }),
                    headers={'Content-Type': 'application/json'}
                )
                response.status_code = 403
                return response
            
            # Get database list
            databases = http.db_list()
            
            response_data = {
                'success': True,
                'databases': databases,
                'count': len(databases)
            }
            
            headers = {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Openerp-Database',
            }
            
            return request.make_response(
                json.dumps(response_data, ensure_ascii=False, indent=2),
                headers=headers
            )
            
        except Exception as e:
            _logger.error(f"Database list error: {str(e)}")
            
            error_response = {
                'success': False,
                'message': 'Failed to list databases',
                'error': str(e)
            }
            
            headers = {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
            }
            
            response = request.make_response(
                json.dumps(error_response, ensure_ascii=False, indent=2),
                headers=headers
            )
            response.status_code = 500
            return response

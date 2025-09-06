# -*- coding: utf-8 -*-

import json
import logging
import secrets
from datetime import datetime, timedelta
from werkzeug.exceptions import BadRequest, Unauthorized

from odoo import http, fields
from odoo.http import request
from odoo.exceptions import AccessDenied

_logger = logging.getLogger(__name__)


class AuthController(http.Controller):
    """Authentication controller for mobile app"""

    @http.route('/api/auth/login', type='json', auth='none', methods=['POST'], csrf=False, cors='*')
    def login(self, **kwargs):
        """
        Authenticate user and return access token
        
        Expected payload:
        {
            "username": "user@example.com",
            "password": "password123"
        }
        
        Returns:
        {
            "success": true,
            "token": "access_token_here",
            "user_id": 123,
            "username": "user@example.com",
            "expires_at": "2024-01-01T12:00:00Z"
        }
        """
        try:
            # Get request data
            data = request.jsonrequest
            username = data.get('username')
            password = data.get('password')
            
            if not username or not password:
                return {
                    'success': False,
                    'error': 'Username and password are required',
                    'error_code': 'MISSING_CREDENTIALS'
                }
            
            # Authenticate user
            try:
                uid = request.session.authenticate(request.session.db, username, password)
                if not uid:
                    raise AccessDenied()
            except AccessDenied:
                _logger.warning(f"Failed login attempt for username: {username}")
                return {
                    'success': False,
                    'error': 'Invalid username or password',
                    'error_code': 'INVALID_CREDENTIALS'
                }
            
            # Get user record
            user = request.env['res.users'].sudo().browse(uid)
            
            # Check if user has stock access
            if not user.has_group('stock.group_stock_user'):
                return {
                    'success': False,
                    'error': 'User does not have stock management permissions',
                    'error_code': 'INSUFFICIENT_PERMISSIONS'
                }
            
            # Generate access token
            token = self._generate_access_token()
            expires_at = datetime.now() + timedelta(hours=24)  # Token valid for 24 hours
            
            # Store token in database (you might want to create a custom model for this)
            # For now, we'll use ir.config_parameter as a simple storage
            token_key = f"mobile_token_{uid}"
            request.env['ir.config_parameter'].sudo().set_param(
                token_key, 
                json.dumps({
                    'token': token,
                    'user_id': uid,
                    'expires_at': expires_at.isoformat(),
                    'created_at': datetime.now().isoformat()
                })
            )
            
            _logger.info(f"Successful login for user: {username} (ID: {uid})")
            
            return {
                'success': True,
                'token': token,
                'user_id': uid,
                'username': user.login,
                'name': user.name,
                'expires_at': expires_at.isoformat()
            }
            
        except Exception as e:
            _logger.error(f"Login error: {str(e)}")
            return {
                'success': False,
                'error': 'Internal server error',
                'error_code': 'SERVER_ERROR'
            }

    @http.route('/api/auth/validate', type='json', auth='none', methods=['POST'], csrf=False, cors='*')
    def validate_token(self, **kwargs):
        """
        Validate access token
        
        Expected payload:
        {
            "token": "access_token_here"
        }
        
        Returns:
        {
            "success": true,
            "valid": true,
            "user_id": 123,
            "expires_at": "2024-01-01T12:00:00Z"
        }
        """
        try:
            data = request.jsonrequest
            token = data.get('token')
            
            if not token:
                return {
                    'success': False,
                    'error': 'Token is required',
                    'error_code': 'MISSING_TOKEN'
                }
            
            # Validate token
            user_data = self._validate_token(token)
            if not user_data:
                return {
                    'success': True,
                    'valid': False,
                    'error': 'Invalid or expired token',
                    'error_code': 'INVALID_TOKEN'
                }
            
            return {
                'success': True,
                'valid': True,
                'user_id': user_data['user_id'],
                'expires_at': user_data['expires_at']
            }
            
        except Exception as e:
            _logger.error(f"Token validation error: {str(e)}")
            return {
                'success': False,
                'error': 'Internal server error',
                'error_code': 'SERVER_ERROR'
            }

    @http.route('/api/auth/logout', type='json', auth='none', methods=['POST'], csrf=False, cors='*')
    def logout(self, **kwargs):
        """
        Logout user and invalidate token
        
        Expected payload:
        {
            "token": "access_token_here"
        }
        
        Returns:
        {
            "success": true,
            "message": "Logged out successfully"
        }
        """
        try:
            data = request.jsonrequest
            token = data.get('token')
            
            if token:
                # Find and remove token
                user_data = self._validate_token(token)
                if user_data:
                    token_key = f"mobile_token_{user_data['user_id']}"
                    request.env['ir.config_parameter'].sudo().set_param(token_key, False)
                    _logger.info(f"User {user_data['user_id']} logged out successfully")
            
            return {
                'success': True,
                'message': 'Logged out successfully'
            }
            
        except Exception as e:
            _logger.error(f"Logout error: {str(e)}")
            return {
                'success': False,
                'error': 'Internal server error',
                'error_code': 'SERVER_ERROR'
            }

    def _generate_access_token(self):
        """Generate a secure access token"""
        return secrets.token_urlsafe(32)

    def _validate_token(self, token):
        """Validate access token and return user data if valid"""
        try:
            # Search for token in all stored tokens
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
                            return token_data
                        else:
                            # Token expired, remove it
                            param.sudo().unlink()
                            return None
                except (json.JSONDecodeError, ValueError, KeyError):
                    continue
            
            return None
            
        except Exception as e:
            _logger.error(f"Token validation error: {str(e)}")
            return None

    def _authenticate_token(self, token):
        """Authenticate request using token and return user ID"""
        user_data = self._validate_token(token)
        if user_data:
            return user_data['user_id']
        return None

# -*- coding: utf-8 -*-

from . import controllers
from . import models

def post_init_hook(cr, registry):
    """Post-installation hook to configure the module"""
    import logging
    _logger = logging.getLogger(__name__)
    _logger.info("Stock Scan Mobile API module installed successfully")

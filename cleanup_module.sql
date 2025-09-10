-- Cleanup script for Stock Scan Mobile module
-- Run this in your Odoo database before reinstalling the module

-- Remove existing configuration parameters
DELETE FROM ir_config_parameter WHERE key LIKE 'stock_scan_mobile.%';

-- Remove module records if they exist
DELETE FROM ir_module_module WHERE name = 'stock_scan_mobile';

-- Clean up any related data
DELETE FROM ir_model_data WHERE module = 'stock_scan_mobile';

-- Note: Run this script carefully in a development environment first
-- Always backup your database before running cleanup scripts
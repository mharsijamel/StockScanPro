import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Diagnostic script to troubleshoot Odoo synchronization issues
class SyncDiagnostic {
  static const String baseUrl = 'https://smart.webvue.tn';

  static Future<void> runDiagnostics() async {
    print('🔍 === ODOO SYNCHRONIZATION DIAGNOSTICS ===\n');

    await _checkServerConnectivity();
    await _checkOdooWebInterface();
    await _checkHealthEndpoint();
    await _checkCustomModuleEndpoints();
    await _testStandardOdooEndpoints();

    print('\n✅ === DIAGNOSTICS COMPLETE ===');
    _provideSolutions();
  }

  static Future<void> _checkServerConnectivity() async {
    print('1️⃣ Testing basic server connectivity...');
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'User-Agent': 'Flutter Diagnostic Tool'},
      ).timeout(const Duration(seconds: 10));

      print('   ✅ Server reachable (HTTP ${response.statusCode})');
      if (response.statusCode == 200) {
        print('   ✅ Server responding normally');
      } else {
        print('   ⚠️  Server returned: ${response.statusCode}');
      }
    } catch (e) {
      print('   ❌ Server unreachable: $e');
      if (e.toString().contains('SocketException')) {
        print('   💡 Network issue - check internet connection');
      }
    }
    print('');
  }

  static Future<void> _checkOdooWebInterface() async {
    print('2️⃣ Testing Odoo web interface...');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/web/login'),
        headers: {'User-Agent': 'Flutter Diagnostic Tool'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.contains('odoo')) {
        print('   ✅ Odoo web interface accessible');
      } else {
        print('   ⚠️  Web interface response: ${response.statusCode}');
        print('   💡 This might not be an Odoo server');
      }
    } catch (e) {
      print('   ❌ Web interface check failed: $e');
    }
    print('');
  }

  static Future<void> _checkHealthEndpoint() async {
    print('3️⃣ Testing health endpoint...');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter Diagnostic Tool',
        },
      ).timeout(const Duration(seconds: 10));

      print('   Status: ${response.statusCode}');
      print(
          '   Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        print('   ✅ Health endpoint working');
      } else if (response.statusCode == 404) {
        print('   ❌ Health endpoint not found (404)');
        print('   💡 Custom module might not be installed');
      } else {
        print('   ⚠️  Health endpoint returned: ${response.statusCode}');
      }
    } catch (e) {
      print('   ❌ Health endpoint failed: $e');
    }
    print('');
  }

  static Future<void> _checkCustomModuleEndpoints() async {
    print('4️⃣ Testing custom module endpoints...');

    final endpoints = [
      '/api/auth/login',
      '/api/pickings',
      '/api/serial/check',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Flutter Diagnostic Tool',
          },
        ).timeout(const Duration(seconds: 5));

        print('   $endpoint: HTTP ${response.statusCode}');

        if (response.statusCode == 404) {
          print('     ❌ Endpoint not found - module not installed');
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          print('     ✅ Endpoint exists (requires auth)');
        } else if (response.statusCode == 200) {
          print('     ✅ Endpoint accessible');
        } else {
          print('     ⚠️  Unexpected response: ${response.statusCode}');
        }
      } catch (e) {
        print('   $endpoint: ❌ Failed - $e');
      }
    }
    print('');
  }

  static Future<void> _testStandardOdooEndpoints() async {
    print('5️⃣ Testing standard Odoo endpoints...');

    final endpoints = [
      '/web/session/authenticate',
      '/web/dataset/search_read',
      '/jsonrpc',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'Flutter Diagnostic Tool',
              },
              body: json.encode({
                'jsonrpc': '2.0',
                'method': 'call',
                'params': {},
              }),
            )
            .timeout(const Duration(seconds: 5));

        print('   $endpoint: HTTP ${response.statusCode}');

        if (response.statusCode == 200) {
          print('     ✅ Standard Odoo endpoint working');
        } else {
          print('     ⚠️  Response: ${response.statusCode}');
        }
      } catch (e) {
        print('   $endpoint: ❌ Failed - $e');
      }
    }
    print('');
  }

  static void _provideSolutions() {
    print('💡 === TROUBLESHOOTING SOLUTIONS ===\n');

    print('🔧 SOLUTION 1: Check Custom Module Installation');
    print(
        '   - Verify that the "stock_scan_mobile" module is installed in Odoo');
    print('   - Check: Apps > Local Modules > search "stock_scan_mobile"');
    print('   - If not found, install the module from odoo_module/ folder\n');

    print('🔧 SOLUTION 2: Verify Server Configuration');
    print('   - Confirm that https://smart.webvue.tn is the correct Odoo URL');
    print(
        '   - Test login through web browser at: https://smart.webvue.tn/web/login');
    print('   - Check that the server is running and accessible\n');

    print('🔧 SOLUTION 3: Use Demo Mode for Testing');
    print('   - Username: demo');
    print('   - Password: demo');
    print('   - This bypasses server connectivity for local testing\n');

    print('🔧 SOLUTION 4: Check Network Configuration');
    print('   - Verify internet connectivity');
    print('   - Check firewall/proxy settings');
    print('   - Try from different network if possible\n');

    print('🔧 SOLUTION 5: Alternative Server Configuration');
    print('   - If using localhost, ensure: http://localhost:8069');
    print('   - If using local network: http://192.168.x.x:8069');
    print('   - Update app_constants.dart with correct URL');
  }
}

Future<void> main() async {
  await SyncDiagnostic.runDiagnostics();
}

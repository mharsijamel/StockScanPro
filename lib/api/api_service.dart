import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../models/picking.dart';
import '../models/picking_line.dart';

class ApiService {
  // L'URL de base de votre API. À ajuster selon votre configuration.
  // Utilisez 10.0.2.2 pour l'émulateur Android si l'API tourne sur localhost
  static const String _baseUrl = 'http://192.168.1.23/stockandroid/api';

  Future<AuthResponse> login(AuthRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(json.decode(response.body));
    } else {
      // Gérer les erreurs HTTP (401, 400, etc.)
      return AuthResponse.fromJson(json.decode(response.body));
    }
  }

  Future<List<Picking>> getPickings(String token, String pickingType) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stock.php?picking_type_code=$pickingType'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['status'] == 'success') {
        List<dynamic> data = body['pickings'];
        return data.map((dynamic item) => Picking.fromJson(item)).toList();
      } else {
        throw Exception(body['message']);
      }
    }
    // En cas d'erreur, retourner une liste vide
    throw Exception('Failed to load pickings');
  }

  Future<List<PickingLine>> getPickingLines(String token, int pickingId) async {
    final response = await http.get(
      // Utilisation de la nouvelle URL propre grâce au .htaccess
      Uri.parse('$_baseUrl/picking_details.php?id=$pickingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['status'] == 'success') {
        List<dynamic> data = body['data'];
        return data.map((dynamic item) => PickingLine.fromJson(item)).toList();
      } else {
        throw Exception(body['message']);
      }
    }
    throw Exception('Failed to load picking lines');
  }
}

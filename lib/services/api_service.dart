import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/energy_history.dart';

// ─── CONFIGURA ESTA URL después de crear el API Gateway ──────────────────────
// Formato: https://xxxxxxxxxx.execute-api.us-east-2.amazonaws.com/prod
const String _apiBaseUrl = 'YOUR_API_GATEWAY_URL';
// ─────────────────────────────────────────────────────────────────────────────

class ApiService {
  // Timeout escala con el rango: 24H y 7D paginan miles de items en DynamoDB.
  static Duration _timeout(int hours) {
    if (hours <= 1)  return const Duration(seconds: 20);
    if (hours <= 24) return const Duration(seconds: 50);
    return const Duration(seconds: 100);
  }

  /// Devuelve los puntos de energía para las últimas [hours] horas.
  static Future<List<EnergyPoint>> getEnergy(int hours) async {
    final uri = Uri.parse('$_apiBaseUrl/energy?hours=$hours');
    final resp = await http.get(uri).timeout(_timeout(hours));

    if (resp.statusCode != 200) {
      throw Exception('Error API energy: ${resp.statusCode}');
    }

    final data  = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['points'] as List<dynamic>? ?? [];
    return items
        .map((e) => EnergyPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve eventos históricos de [type] (plug | ac | light)
  /// para las últimas [hours] horas.
  static Future<List<HistoricEvent>> getEvents(
      String type, int hours) async {
    final uri = Uri.parse('$_apiBaseUrl/events?type=$type&hours=$hours');
    final resp = await http.get(uri).timeout(_timeout(hours));

    if (resp.statusCode != 200) {
      throw Exception('Error API events: ${resp.statusCode}');
    }

    final data  = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['events'] as List<dynamic>? ?? [];
    return items
        .map((e) => HistoricEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static bool get configurado =>
      _apiBaseUrl != 'YOUR_API_GATEWAY_URL' && _apiBaseUrl.isNotEmpty;
}

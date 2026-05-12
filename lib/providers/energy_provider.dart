import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sensor_reading.dart';
import '../services/mqtt_service.dart';

/// Mantiene la última lectura de energía recibida del ESP32_Energy_Hub
/// y notifica a la UI cada vez que llega un nuevo mensaje PZEM.
class EnergyProvider extends ChangeNotifier {
  final MqttService _mqtt;

  SensorReading? _ultimaLectura;
  DateTime?      _ultimaActualizacion;

  StreamSubscription<SensorReading>? _sub;

  EnergyProvider(this._mqtt) {
    _sub = _mqtt.energyStream.listen(_onNuevaLectura);
  }

  // ── Getters ─────────────────────────────────────────────────────────────────

  SensorReading? get ultimaLectura       => _ultimaLectura;
  DateTime?      get ultimaActualizacion => _ultimaActualizacion;

  /// True si recibimos datos hace menos de 15 segundos.
  bool get hubOnline {
    if (_ultimaActualizacion == null) return false;
    return DateTime.now().difference(_ultimaActualizacion!).inSeconds < 15;
  }

  /// Suma de potencia activa de los 3 sensores online, en Watts.
  double get potenciaTotal => _ultimaLectura?.potenciaTotal ?? 0.0;

  /// Acceso rápido a un sensor por índice numérico (1, 2 o 3).
  SensorData? sensor(int index) => _ultimaLectura?.sensor(index);

  /// True si hay al menos una lectura disponible.
  bool get tieneDatos => _ultimaLectura != null;

  // ── Lógica interna ───────────────────────────────────────────────────────────

  void _onNuevaLectura(SensorReading lectura) {
    _ultimaLectura       = lectura;
    _ultimaActualizacion = DateTime.now();
    notifyListeners();
  }

  // ── Limpieza ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

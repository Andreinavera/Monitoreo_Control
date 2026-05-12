import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ac_event.dart';
import '../services/mqtt_service.dart';

/// Provider que une el MqttService con la UI mediante ChangeNotifier.
/// La pantalla principal escucha este provider para reconstruirse
/// automáticamente cuando cambia el estado del AC o la conexión.
class AcProvider extends ChangeNotifier {
  final MqttService _mqtt;

  // ── Estado del AC ───────────────────────────────────────────────────────────
  bool _acEncendido = false;
  bool get acEncendido => _acEncendido;

  // ── Estado de conexión MQTT ─────────────────────────────────────────────────
  EstadoConexion _estadoConexion = EstadoConexion.desconectado;
  EstadoConexion get estadoConexion => _estadoConexion;
  bool get estaConectado => _estadoConexion == EstadoConexion.conectado;

  // ── Historial de eventos ────────────────────────────────────────────────────
  final List<AcEvent> _historial = [];
  List<AcEvent> get historial => List.unmodifiable(_historial);

  // Suscripciones a los streams del servicio
  StreamSubscription<EstadoConexion>? _subEstado;
  StreamSubscription<AcEvent>? _subEventos;

  /// Recibe el MqttService compartido inyectado desde main.dart.
  AcProvider.withService(this._mqtt) {
    _suscribirse();
    _mqtt.conectar();
  }

  // ── Suscripciones a streams ─────────────────────────────────────────────────

  void _suscribirse() {
    // Escuchar cambios de estado de conexión MQTT
    _subEstado = _mqtt.estadoStream.listen((estado) {
      _estadoConexion = estado;
      notifyListeners();
    });

    // Escuchar eventos publicados por el ESP32
    _subEventos = _mqtt.eventosStream.listen((evento) {
      _acEncendido = evento.isOn;

      // Agregar al historial, manteniendo máximo 50 entradas
      _historial.insert(0, evento);
      if (_historial.length > 50) {
        _historial.removeLast();
      }

      notifyListeners();
    });
  }

  // ── Acciones ────────────────────────────────────────────────────────────────

  /// Alterna el estado del AC y publica el comando MQTT correspondiente
  Future<void> alternarAC() async {
    final accion = _acEncendido ? 'power_off' : 'power_on';
    final enviado = await _mqtt.publicarComandoAC(accion);

    if (enviado) {
      // Actualizar estado optimistamente mientras llega el evento de confirmación
      _acEncendido = !_acEncendido;
      notifyListeners();
    }
  }

  /// Reconectar manualmente al broker MQTT
  Future<void> reconectar() async {
    await _mqtt.conectar();
  }

  // ── Limpieza ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _subEstado?.cancel();
    _subEventos?.cancel();
    // No llamar _mqtt.dispose(): el servicio es compartido y lo gestiona main.dart
    super.dispose();
  }
}

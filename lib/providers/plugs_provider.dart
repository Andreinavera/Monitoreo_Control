import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/plug_event.dart';
import '../services/mqtt_service.dart';

// IPs de los enchufes Kasa registradas en el ESP32_Energy_Hub.
// Se usan como identificadores únicos hasta que exista la tabla SMART_PLUGS.
const List<String> kKasaIPs = [
  '10.3.141.10',
  '10.3.141.11',
  '10.3.141.12',
  '10.3.141.13',
];

/// Mantiene el estado actual de los 4 enchufes Kasa y permite enviar
/// comandos ON/OFF a través del MqttService.
class PlugsProvider extends ChangeNotifier {
  final MqttService _mqtt;

  // Estado de cada enchufe: IP → acción más reciente
  final Map<String, PlugAction> _estados = {
    for (final ip in kKasaIPs) ip: PlugAction.offline,
  };

  // Timestamp del último cambio por IP
  final Map<String, DateTime> _ultimoCambio = {};

  // IPs con comando en curso (para mostrar indicador de carga)
  final Set<String> _enviando = {};

  StreamSubscription<PlugEvent>? _sub;

  PlugsProvider(this._mqtt) {
    _sub = _mqtt.plugStream.listen(_onPlugEvent);
  }

  // ── Getters ─────────────────────────────────────────────────────────────────

  /// Lista ordenada de IPs registradas.
  List<String> get ips => List.unmodifiable(kKasaIPs);

  /// Estado actual de un enchufe dado su IP.
  PlugAction estadoDe(String ip) => _estados[ip] ?? PlugAction.offline;

  /// True si el enchufe está respondiendo (ON o OFF, no OFFLINE).
  bool estaOnline(String ip) => estadoDe(ip) != PlugAction.offline;

  /// Último momento en que cambió el estado de un enchufe.
  DateTime? ultimoCambioDe(String ip) => _ultimoCambio[ip];

  /// Cantidad de enchufes actualmente encendidos.
  int get enchufesEncendidos =>
      _estados.values.where((a) => a == PlugAction.on).length;

  /// True mientras se espera confirmación para ese enchufe.
  bool enviandoComandoA(String ip) => _enviando.contains(ip);

  // ── Acciones ─────────────────────────────────────────────────────────────────

  /// Envía comando ON (state=1) o OFF (state=0) al enchufe indicado.
  Future<void> toggleEnchufe(String ip) async {
    final estadoActual = estadoDe(ip);
    if (estadoActual == PlugAction.offline) return;

    final encender = estadoActual != PlugAction.on; // toggle
    final state    = encender ? 1 : 0;

    _enviando.add(ip);
    notifyListeners();

    final ok = await _mqtt.publicarComandoEnchufe(ip, state);

    _enviando.remove(ip);

    if (ok) {
      // Actualización optimista: la confirmación real llegará por plugStream
      _estados[ip]       = encender ? PlugAction.on : PlugAction.off;
      _ultimoCambio[ip]  = DateTime.now();
    }

    notifyListeners();
  }

  // ── Lógica interna ───────────────────────────────────────────────────────────

  void _onPlugEvent(PlugEvent evento) {
    if (!_estados.containsKey(evento.ip)) return;
    _estados[evento.ip]      = evento.action;
    _ultimoCambio[evento.ip] = DateTime.now();
    notifyListeners();
  }

  // ── Limpieza ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

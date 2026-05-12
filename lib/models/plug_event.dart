/// Representa un evento publicado por el ESP32_Energy_Hub
/// en el topic "home/plugs/event".
///
/// Estructura del JSON entrante:
/// {
///   "device_id": "ESP32_Energy_Hub",
///   "ip":        "192.168.10.144",
///   "action":    "ON" | "OFF" | "OFFLINE",
///   "timestamp": 1775876031
/// }
class PlugEvent {
  final String deviceId;
  final String ip;
  final PlugAction action;
  final int timestamp; // epoch Unix

  const PlugEvent({
    required this.deviceId,
    required this.ip,
    required this.action,
    required this.timestamp,
  });

  factory PlugEvent.fromJson(Map<String, dynamic> json) {
    return PlugEvent(
      deviceId:  json['device_id'] as String? ?? 'Desconocido',
      ip:        json['ip']        as String? ?? '',
      action:    PlugAction.fromString(json['action'] as String? ?? ''),
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum PlugAction {
  on,
  off,
  offline;

  static PlugAction fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ON':
        return PlugAction.on;
      case 'OFF':
        return PlugAction.off;
      default:
        return PlugAction.offline;
    }
  }

  /// Etiqueta legible para la UI.
  String get label {
    switch (this) {
      case PlugAction.on:
        return 'Encendido';
      case PlugAction.off:
        return 'Apagado';
      case PlugAction.offline:
        return 'Sin conexión';
    }
  }

  bool get isOn => this == PlugAction.on;
  bool get isOffline => this == PlugAction.offline;
}

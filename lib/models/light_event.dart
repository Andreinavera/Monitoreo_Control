/// Evento publicado por NODO_BATHROOM en "home/bathroom/light/state".
///
/// JSON entrante:
/// {
///   "device_id": "ESP32_Bathroom_Hub",
///   "state":     "ON" | "OFF",
///   "source":    "pir" | "manual" | "pir_timeout" | "sync_api",
///   "bulb_ok":   true | false,
///   "timestamp": 1775876031
/// }
class LightEvent {
  final String deviceId;
  final bool encendido;
  final LightSource source;
  final bool bulbOk;
  final int timestamp;

  const LightEvent({
    required this.deviceId,
    required this.encendido,
    required this.source,
    required this.bulbOk,
    required this.timestamp,
  });

  factory LightEvent.fromJson(Map<String, dynamic> json) {
    return LightEvent(
      deviceId:  json['device_id'] as String? ?? '',
      encendido: (json['state'] as String? ?? '').toUpperCase() == 'ON',
      source:    LightSource.fromString(json['source'] as String? ?? ''),
      bulbOk:    json['bulb_ok'] as bool? ?? true,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }
}

enum LightSource {
  pir,
  manual,
  pirTimeout,
  syncApi,
  desconocido;

  static LightSource fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pir':         return LightSource.pir;
      case 'manual':      return LightSource.manual;
      case 'pir_timeout': return LightSource.pirTimeout;
      case 'sync_api':    return LightSource.syncApi;
      default:            return LightSource.desconocido;
    }
  }

  String get etiqueta {
    switch (this) {
      case LightSource.pir:         return 'Movimiento';
      case LightSource.manual:      return 'Manual';
      case LightSource.pirTimeout:  return 'Auto-apagado';
      case LightSource.syncApi:     return 'Sincronizado';
      case LightSource.desconocido: return '';
    }
  }
}

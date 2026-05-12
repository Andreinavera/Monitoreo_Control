/// Modelo que representa un evento publicado por el ESP32
/// en el topic "home/ac/event"
class AcEvent {
  final String deviceId;
  final String action;      // "power_on" | "power_off"
  final String acState;     // "on" | "off"
  final String source;      // "button" | "remote" | "app"
  final DateTime timestamp;

  const AcEvent({
    required this.deviceId,
    required this.action,
    required this.acState,
    required this.source,
    required this.timestamp,
  });

  /// Parsea el JSON recibido desde el topic MQTT del ESP32
  factory AcEvent.fromJson(Map<String, dynamic> json) {
    return AcEvent(
      deviceId: json['device_id'] as String? ?? 'Desconocido',
      action: json['action'] as String? ?? '',
      acState: json['ac_state'] as String? ?? 'off',
      source: json['source'] as String? ?? 'unknown',
      timestamp: DateTime.now(),
    );
  }

  /// Devuelve true si el AC está encendido según este evento
  bool get isOn => acState == 'on';

  /// Etiqueta legible de la fuente del evento
  String get sourceLabel {
    switch (source) {
      case 'button':
        return 'Botón físico';
      case 'remote':
        return 'Control remoto';
      case 'app':
        return 'Aplicación';
      default:
        return source;
    }
  }

  /// Etiqueta legible de la acción
  String get actionLabel {
    switch (action) {
      case 'power_on':
        return 'Encendido';
      case 'power_off':
        return 'Apagado';
      default:
        return action;
    }
  }
}

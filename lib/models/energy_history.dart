/// Un punto de energía proveniente del historial en DynamoDB.
class EnergyPoint {
  final DateTime timestamp;
  final double sala;      // sensor_1 potencia (W)
  final double cocina;    // sensor_2 potencia (W)
  final double ac;        // sensor_3 potencia (W)
  final double total;
  final double salaKwh;   // sensor_1 energía acumulada (kWh)
  final double cocinaKwh; // sensor_2 energía acumulada (kWh)
  final double acKwh;     // sensor_3 energía acumulada (kWh)

  const EnergyPoint({
    required this.timestamp,
    required this.sala,
    required this.cocina,
    required this.ac,
    required this.total,
    required this.salaKwh,
    required this.cocinaKwh,
    required this.acKwh,
  });

  factory EnergyPoint.fromJson(Map<String, dynamic> json) {
    double pw(String key) {
      final s = json[key];
      if (s == null) return 0.0;
      return (s['power'] as num?)?.toDouble() ?? 0.0;
    }

    double en(String key) {
      final s = json[key];
      if (s == null) return 0.0;
      return (s['energy'] as num?)?.toDouble() ?? 0.0;
    }

    return EnergyPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['timestamp'] as int) * 1000),
      sala:      pw('sensor_1'),
      cocina:    pw('sensor_2'),
      ac:        pw('sensor_3'),
      total:     (json['total'] as num?)?.toDouble() ?? 0.0,
      salaKwh:   en('sensor_1'),
      cocinaKwh: en('sensor_2'),
      acKwh:     en('sensor_3'),
    );
  }
}

/// Un evento histórico de enchufe, AC o luz.
class HistoricEvent {
  final String eventType; // plug | ac | light
  final DateTime timestamp;
  final String state;     // ON | OFF
  final String source;    // manual | pir | pir_timeout | sync_api
  final String? ip;       // solo para plugs
  final String deviceId;

  const HistoricEvent({
    required this.eventType,
    required this.timestamp,
    required this.state,
    required this.source,
    this.ip,
    required this.deviceId,
  });

  factory HistoricEvent.fromJson(Map<String, dynamic> json) {
    return HistoricEvent(
      eventType: json['event_type'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['timestamp'] as int) * 1000),
      state:    json['state'] as String? ?? '',
      source:   json['source'] as String? ?? '',
      ip:       json['ip'] as String?,
      deviceId: json['device_id'] as String? ?? '',
    );
  }

  bool get isOn => state.toUpperCase() == 'ON';

  String get etiquetaFuente {
    switch (source.toLowerCase()) {
      case 'manual':       return 'Manual';
      case 'pir':          return 'Movimiento';
      case 'pir_timeout':  return 'Auto-apagado';
      case 'sync_api':     return 'Sincronizado';
      default:             return source;
    }
  }
}

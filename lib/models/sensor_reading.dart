/// Representa una lectura completa publicada por el ESP32_Energy_Hub
/// en el topic "home/energy/pzem".
///
/// Estructura del JSON entrante:
/// {
///   "device_id": "ESP32_Energy_Hub",
///   "timestamp": 1775876031,
///   "sensor_1": { "status": "online", "voltage": 110.6, ... },
///   "sensor_2": { ... },
///   "sensor_3": { ... }
/// }
class SensorReading {
  final String deviceId;
  final int timestamp; // epoch Unix

  // Los tres sensores PZEM indexados por nombre ("sensor_1", "sensor_2", "sensor_3")
  final Map<String, SensorData> sensors;

  const SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.sensors,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    final sensors = <String, SensorData>{};

    for (final key in ['sensor_1', 'sensor_2', 'sensor_3']) {
      if (json.containsKey(key) && json[key] is Map<String, dynamic>) {
        sensors[key] = SensorData.fromJson(json[key] as Map<String, dynamic>);
      }
    }

    return SensorReading(
      deviceId: json['device_id'] as String? ?? 'Desconocido',
      timestamp: json['timestamp'] as int? ?? 0,
      sensors: sensors,
    );
  }

  /// Suma de potencia activa de todos los sensores online, en Watts.
  double get potenciaTotal {
    return sensors.values
        .where((s) => s.isOnline)
        .fold(0.0, (sum, s) => sum + s.power);
  }

  /// Acceso por índice numérico (1, 2 o 3).
  SensorData? sensor(int index) => sensors['sensor_$index'];
}

// ─────────────────────────────────────────────────────────────────────────────

/// Datos de un sensor PZEM individual.
class SensorData {
  final String status;       // "online" | "offline"
  final double voltage;      // Voltios (V)
  final double current;      // Amperios (A)
  final double power;        // Potencia activa (W)
  final double reactivePower;// Potencia reactiva (VAR) — calculada en firmware
  final double energy;       // Energía acumulada (kWh)
  final double frequency;    // Frecuencia de red (Hz)
  final double pf;           // Factor de potencia (0.0 – 1.0)

  const SensorData({
    required this.status,
    required this.voltage,
    required this.current,
    required this.power,
    required this.reactivePower,
    required this.energy,
    required this.frequency,
    required this.pf,
  });

  bool get isOnline => status == 'online';

  /// Potencia aparente S = √(P² + Q²), en VA.
  double get apparentPower {
    return (power * power + reactivePower * reactivePower) > 0
        ? (power * power + reactivePower * reactivePower).toDouble().abs().let(_sqrt)
        : 0.0;
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'offline';

    // Si está offline, todos los valores numéricos son 0
    if (status != 'online') {
      return const SensorData(
        status: 'offline',
        voltage: 0,
        current: 0,
        power: 0,
        reactivePower: 0,
        energy: 0,
        frequency: 0,
        pf: 0,
      );
    }

    return SensorData(
      status: status,
      voltage:       (json['voltage']        as num?)?.toDouble() ?? 0.0,
      current:       (json['current']        as num?)?.toDouble() ?? 0.0,
      power:         (json['power']          as num?)?.toDouble() ?? 0.0,
      reactivePower: (json['reactive_power'] as num?)?.toDouble() ?? 0.0,
      energy:        (json['energy']         as num?)?.toDouble() ?? 0.0,
      frequency:     (json['frequency']      as num?)?.toDouble() ?? 0.0,
      pf:            (json['pf']             as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Valor de pf como porcentaje legible (ej: "71%")
  String get pfLabel => '${(pf * 100).toStringAsFixed(0)}%';
}

// Ayuda para calcular raíz sin importar dart:math en el modelo
double _sqrt(double x) {
  if (x <= 0) return 0.0;
  double guess = x / 2;
  for (int i = 0; i < 20; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}

extension _DoubleExt on double {
  double let(double Function(double) f) => f(this);
}

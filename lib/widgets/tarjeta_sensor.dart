import 'package:flutter/material.dart';

import '../models/sensor_reading.dart';
import 'fila_metrica.dart';

/// Tarjeta que muestra todas las métricas de un sensor PZEM individual.
/// Si el sensor está offline, muestra un estado de error claro.
class TarjetaSensor extends StatelessWidget {
  final String titulo;       // Ej: "Sensor 1"
  final SensorData? datos;   // null mientras no llegan datos del hub

  const TarjetaSensor({
    super.key,
    required this.titulo,
    required this.datos,
  });

  @override
  Widget build(BuildContext context) {
    final online = datos?.isOnline ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: online
              ? const Color(0xFF00BCD4).withAlpha(50)
              : Colors.grey.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Encabezado(titulo: titulo, online: online),
          const Divider(color: Color(0xFF21262D), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: online && datos != null
                ? _MetricasOnline(datos: datos!)
                : _EstadoOffline(sinDatos: datos == null),
          ),
        ],
      ),
    );
  }
}

// ─── Encabezado con título e indicador online/offline ────────────────────────

class _Encabezado extends StatelessWidget {
  final String titulo;
  final bool online;

  const _Encabezado({required this.titulo, required this.online});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.electrical_services,
            color: online ? const Color(0xFF00BCD4) : Colors.grey.shade600,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (online ? const Color(0xFF00BCD4) : Colors.grey)
                  .withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              online ? 'online' : 'offline',
              style: TextStyle(
                color: online ? const Color(0xFF00BCD4) : Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Métricas cuando el sensor está online ───────────────────────────────────

class _MetricasOnline extends StatelessWidget {
  final SensorData datos;

  const _MetricasOnline({required this.datos});

  @override
  Widget build(BuildContext context) {
    final pfColor = datos.pf >= 0.9
        ? Colors.greenAccent
        : datos.pf >= 0.7
            ? Colors.amberAccent
            : Colors.redAccent;

    return Column(
      children: [
        FilaMetrica(
          label: 'Voltaje',
          valor: datos.voltage.toStringAsFixed(1),
          unidad: 'V',
        ),
        FilaMetrica(
          label: 'Corriente',
          valor: datos.current.toStringAsFixed(3),
          unidad: 'A',
        ),
        FilaMetrica(
          label: 'Potencia activa',
          valor: datos.power.toStringAsFixed(1),
          unidad: 'W',
          colorValor: const Color(0xFF00BCD4),
        ),
        FilaMetrica(
          label: 'Potencia reactiva',
          valor: datos.reactivePower.toStringAsFixed(2),
          unidad: 'VAR',
        ),
        FilaMetrica(
          label: 'Energía acumulada',
          valor: datos.energy.toStringAsFixed(3),
          unidad: 'kWh',
        ),
        FilaMetrica(
          label: 'Frecuencia',
          valor: datos.frequency.toStringAsFixed(1),
          unidad: 'Hz',
        ),
        FilaMetrica(
          label: 'Factor de potencia',
          valor: datos.pfLabel,
          unidad: '',
          colorValor: pfColor,
        ),
      ],
    );
  }
}

// ─── Estado offline o sin datos ──────────────────────────────────────────────

class _EstadoOffline extends StatelessWidget {
  final bool sinDatos; // true = nunca recibimos datos; false = sensor offline

  const _EstadoOffline({required this.sinDatos});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              sinDatos ? Icons.hourglass_empty : Icons.power_off,
              color: Colors.grey.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              sinDatos ? 'Esperando datos…' : 'Sensor sin respuesta',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

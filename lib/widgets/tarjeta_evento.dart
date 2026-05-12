import 'package:flutter/material.dart';

import '../models/ac_event.dart';

/// Tarjeta que muestra un evento individual del historial del AC.
class TarjetaEvento extends StatelessWidget {
  final AcEvent evento;

  const TarjetaEvento({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    final esEncendido = evento.isOn;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esEncendido
              ? const Color(0xFF00BCD4).withAlpha(60)
              : Colors.grey.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          // Ícono de estado
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: esEncendido
                  ? const Color(0xFF00BCD4).withAlpha(30)
                  : Colors.grey.withAlpha(30),
            ),
            child: Icon(
              esEncendido ? Icons.power_settings_new : Icons.power_off,
              color: esEncendido ? const Color(0xFF00BCD4) : Colors.grey,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Acción y fuente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.actionLabel,
                  style: TextStyle(
                    color: esEncendido ? const Color(0xFF00BCD4) : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vía: ${evento.sourceLabel}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Hora del evento
          Text(
            _formatearHora(evento.timestamp),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearHora(DateTime fecha) {
    final h = fecha.hour.toString().padLeft(2, '0');
    final m = fecha.minute.toString().padLeft(2, '0');
    final s = fecha.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

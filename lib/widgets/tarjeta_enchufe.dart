import 'package:flutter/material.dart';

import '../models/plug_event.dart';

class TarjetaEnchufe extends StatelessWidget {
  final String ip;
  final String nombre;
  final PlugAction estado;
  final bool enviando;
  final VoidCallback? onToggle;

  const TarjetaEnchufe({
    super.key,
    required this.ip,
    required this.nombre,
    required this.estado,
    required this.enviando,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final encendido = estado == PlugAction.on;
    final offline   = estado == PlugAction.offline;

    final colorActivo = encendido
        ? const Color(0xFF00BCD4)
        : offline
            ? Colors.grey.shade700
            : const Color(0xFF37474F);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: encendido
              ? const Color(0xFF00BCD4).withAlpha(60)
              : Colors.grey.withAlpha(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  offline ? Icons.power_off : Icons.power,
                  color: colorActivo,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ip,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            if (offline)
              _ChipEstado(
                texto: 'Sin conexión',
                color: Colors.grey.shade700,
              )
            else
              _BotonToggle(
                encendido: encendido,
                enviando: enviando,
                onToggle: onToggle,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final String texto;
  final Color color;
  const _ChipEstado({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _BotonToggle extends StatelessWidget {
  final bool encendido;
  final bool enviando;
  final VoidCallback? onToggle;

  const _BotonToggle({
    required this.encendido,
    required this.enviando,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enviando ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: encendido
              ? const Color(0xFF00BCD4).withAlpha(30)
              : const Color(0xFF37474F).withAlpha(60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: encendido
                ? const Color(0xFF00BCD4).withAlpha(80)
                : Colors.grey.withAlpha(40),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enviando)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: encendido
                      ? const Color(0xFF00BCD4)
                      : Colors.grey.shade400,
                ),
              )
            else
              Icon(
                encendido ? Icons.toggle_on : Icons.toggle_off,
                size: 16,
                color: encendido
                    ? const Color(0xFF00BCD4)
                    : Colors.grey.shade400,
              ),
            const SizedBox(width: 6),
            Text(
              encendido ? 'Encendido' : 'Apagado',
              style: TextStyle(
                color: encendido
                    ? const Color(0xFF00BCD4)
                    : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

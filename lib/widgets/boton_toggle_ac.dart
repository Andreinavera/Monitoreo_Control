import 'package:flutter/material.dart';

/// Botón circular grande para encender/apagar el AC.
/// Muestra colores diferenciados según el estado y si hay conexión activa.
class BotonToggleAC extends StatelessWidget {
  final bool acEncendido;
  final bool habilitado;       // false cuando no hay conexión MQTT
  final VoidCallback onPressed;

  const BotonToggleAC({
    super.key,
    required this.acEncendido,
    required this.habilitado,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Color del botón según estado
    final Color colorBoton = !habilitado
        ? Colors.grey.shade700
        : acEncendido
            ? const Color(0xFF00BCD4)   // cian — encendido
            : const Color(0xFF37474F);  // gris azulado oscuro — apagado

    final Color colorIcono = !habilitado
        ? Colors.grey.shade500
        : acEncendido
            ? Colors.white
            : Colors.grey.shade400;

    return GestureDetector(
      onTap: habilitado ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorBoton,
          boxShadow: acEncendido && habilitado
              ? [
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withAlpha(100),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                acEncendido ? Icons.power_settings_new : Icons.power_off,
                key: ValueKey(acEncendido),
                size: 72,
                color: colorIcono,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              acEncendido ? 'ENCENDIDO' : 'APAGADO',
              style: TextStyle(
                color: colorIcono,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

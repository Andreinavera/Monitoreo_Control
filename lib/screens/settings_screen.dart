import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_mode_provider.dart';

/// Pantalla de ajustes accesible desde el ícono ⚙ en el AppBar.
/// Permite cambiar entre Modo Monitoreo y Modo Control con confirmación.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.watch<AppModeProvider>();
    final esControl = modeProvider.esModoControl;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajustes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MODO DE OPERACIÓN',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Tarjeta Modo Monitoreo
            _TarjetaModo(
              titulo: 'Modo Monitoreo',
              descripcion:
                  'Solo visualización de variables eléctricas. Sin acceso a controles.',
              icono: Icons.visibility_outlined,
              color: Colors.amber,
              seleccionado: !esControl,
              onTap: esControl
                  ? () => _confirmarCambio(
                        context,
                        modeProvider,
                        AppMode.monitoreo,
                        'Cambiar a Modo Monitoreo',
                        'Se ocultarán los controles de enchufes y aire acondicionado.',
                      )
                  : null,
            ),

            const SizedBox(height: 12),

            // Tarjeta Modo Control
            _TarjetaModo(
              titulo: 'Modo Control',
              descripcion:
                  'Acceso completo: monitoreo + control de enchufes y aire acondicionado.',
              icono: Icons.tune,
              color: const Color(0xFF00BCD4),
              seleccionado: esControl,
              onTap: !esControl
                  ? () => _confirmarCambio(
                        context,
                        modeProvider,
                        AppMode.control,
                        'Cambiar a Modo Control',
                        'Se habilitarán los controles de enchufes y aire acondicionado.',
                      )
                  : null,
            ),

            const SizedBox(height: 32),

            // Nota informativa
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(30)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El modo seleccionado se mantiene entre sesiones. '
                      'Cambiarlo durante una prueba activa puede afectar los resultados.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarCambio(
    BuildContext context,
    AppModeProvider provider,
    AppMode nuevoModo,
    String titulo,
    String descripcion,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          titulo,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          descripcion,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar',
                style: TextStyle(color: Color(0xFF00BCD4))),
          ),
        ],
      ),
    ).then((confirmado) {
      if (confirmado == true && context.mounted) {
        provider.setModo(nuevoModo);
        Navigator.pop(context);
      }
    });
  }
}

// ─── Tarjeta de selección de modo ────────────────────────────────────────────

class _TarjetaModo extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final bool seleccionado;
  final VoidCallback? onTap;

  const _TarjetaModo({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.seleccionado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado
              ? color.withAlpha(20)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? color.withAlpha(120) : Colors.grey.withAlpha(30),
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seleccionado ? color.withAlpha(40) : Colors.grey.withAlpha(20),
              ),
              child: Icon(icono,
                  color: seleccionado ? color : Colors.grey.shade600,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      color: seleccionado ? color : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (seleccionado)
              Icon(Icons.check_circle, color: color, size: 20)
            else
              Icon(Icons.radio_button_unchecked,
                  color: Colors.grey.shade700, size: 20),
          ],
        ),
      ),
    );
  }
}

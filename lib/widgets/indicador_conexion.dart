import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';

/// Chip pequeño que muestra el estado actual de la conexión MQTT.
/// Se coloca típicamente en la AppBar o en la parte superior de la pantalla.
class IndicadorConexion extends StatelessWidget {
  final EstadoConexion estado;
  final VoidCallback? onReconectar;

  const IndicadorConexion({
    super.key,
    required this.estado,
    this.onReconectar,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configParaEstado(estado);

    return GestureDetector(
      onTap: (estado == EstadoConexion.desconectado ||
              estado == EstadoConexion.error)
          ? onReconectar
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: config.color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Punto indicador con pulso animado si está conectado
            _PuntoEstado(color: config.color, animado: estado == EstadoConexion.conectado),
            const SizedBox(width: 6),
            Text(
              config.texto,
              style: TextStyle(
                color: config.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Icono de reintento si hay error o está desconectado
            if (estado == EstadoConexion.desconectado ||
                estado == EstadoConexion.error) ...[
              const SizedBox(width: 4),
              Icon(Icons.refresh, color: config.color, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  _ConfigEstado _configParaEstado(EstadoConexion estado) {
    switch (estado) {
      case EstadoConexion.conectado:
        return _ConfigEstado(Colors.greenAccent, 'Conectado');
      case EstadoConexion.conectando:
        return _ConfigEstado(Colors.amberAccent, 'Conectando…');
      case EstadoConexion.error:
        return _ConfigEstado(Colors.redAccent, 'Error — reintentar');
      case EstadoConexion.desconectado:
        return _ConfigEstado(Colors.grey, 'Desconectado');
    }
  }
}

class _ConfigEstado {
  final Color color;
  final String texto;
  const _ConfigEstado(this.color, this.texto);
}

/// Punto de color con animación de pulso cuando la conexión está activa
class _PuntoEstado extends StatefulWidget {
  final Color color;
  final bool animado;

  const _PuntoEstado({required this.color, required this.animado});

  @override
  State<_PuntoEstado> createState() => _PuntoEstadoState();
}

class _PuntoEstadoState extends State<_PuntoEstado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacidad;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacidad = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animado) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PuntoEstado old) {
    super.didUpdateWidget(old);
    if (widget.animado && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.animado && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacidad,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      ),
    );
  }
}

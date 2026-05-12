import 'package:flutter/material.dart';

/// Fila reutilizable que muestra una métrica con su etiqueta, valor y unidad.
/// Usada dentro de TarjetaSensor para cada variable eléctrica.
class FilaMetrica extends StatelessWidget {
  final String label;
  final String valor;
  final String unidad;
  final Color? colorValor;

  const FilaMetrica({
    super.key,
    required this.label,
    required this.valor,
    required this.unidad,
    this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              color: colorValor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 36,
            child: Text(
              unidad,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

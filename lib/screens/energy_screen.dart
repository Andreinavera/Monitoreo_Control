import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/energy_history.dart';
import '../providers/energy_provider.dart';
import '../providers/history_provider.dart';
import '../services/report_service.dart';
import '../widgets/tarjeta_sensor.dart';
import 'settings_screen.dart';

class EnergyScreen extends StatefulWidget {
  final bool mostrarAjustes;
  const EnergyScreen({super.key, this.mostrarAjustes = false});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Carga inicial del historial con 1 hora
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().cargarEnergy(1);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Text(
          widget.mostrarAjustes ? 'Smart Home' : 'Energía',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: _ChipActualizacion(provider: energy)),
          ),
          if (widget.mostrarAjustes)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            )
          else
            const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF00BCD4),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Tiempo Real'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _VistaRealTime(provider: energy),
          const _VistaHistorial(),
        ],
      ),
    );
  }
}

// ── Vista tiempo real ─────────────────────────────────────────────────────────

class _VistaRealTime extends StatelessWidget {
  final EnergyProvider provider;
  const _VistaRealTime({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        _BannerConsumoTotal(provider: provider),
        TarjetaSensor(titulo: 'Sala / Cuarto / Baño', datos: provider.sensor(1)),
        TarjetaSensor(titulo: 'Cocina',               datos: provider.sensor(2)),
        TarjetaSensor(titulo: 'Aire Acondicionado',   datos: provider.sensor(3)),
      ],
    );
  }
}

// ── Vista historial ───────────────────────────────────────────────────────────

class _VistaHistorial extends StatelessWidget {
  const _VistaHistorial();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final cargado = history.stateEnergy == HistoryState.loaded &&
        history.energyPoints.isNotEmpty;

    return Column(
      children: [
        // Selector de rango + botón descarga
        Row(
          children: [
            Expanded(
              child: _SelectorRango(
                seleccionado: history.horasEnergy,
                onChanged: (h) =>
                    context.read<HistoryProvider>().cargarEnergy(h),
              ),
            ),
            if (cargado)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: 'Exportar reporte',
                  icon: const Icon(Icons.download_outlined,
                      color: Color(0xFF00BCD4)),
                  onPressed: () => ReportService.mostrarDialogo(
                    context,
                    history.energyPoints,
                    history,
                  ),
                ),
              ),
          ],
        ),
        // Tarjetas ΔkWh (solo cuando hay datos)
        if (cargado) _ResumenDelta(history: history),
        // Contenido
        Expanded(child: _contenido(context, history)),
      ],
    );
  }

  Widget _contenido(BuildContext context, HistoryProvider history) {
    switch (history.stateEnergy) {
      case HistoryState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
        );

      case HistoryState.noConfigurado:
        return _Placeholder(
          icono: Icons.cloud_off_outlined,
          titulo: 'API no configurada',
          subtitulo:
              'Configura el API Gateway en api_service.dart para ver el historial.',
        );

      case HistoryState.error:
        return _Placeholder(
          icono: Icons.error_outline,
          titulo: 'Error al cargar datos',
          subtitulo: history.errorEnergy,
        );

      case HistoryState.idle:
        return _Placeholder(
          icono: Icons.bar_chart_outlined,
          titulo: 'Sin datos',
          subtitulo: 'Selecciona un rango para cargar el historial.',
        );

      case HistoryState.loaded:
        if (history.energyPoints.isEmpty) {
          return _Placeholder(
            icono: Icons.hourglass_empty,
            titulo: 'Sin registros',
            subtitulo:
                'No hay datos en este período. Verifica que el ESP32 esté enviando datos.',
          );
        }
        return _GraficaConsumo(puntos: history.energyPoints);
    }
  }
}

// ── Resumen ΔkWh por zona ─────────────────────────────────────────────────────

class _ResumenDelta extends StatelessWidget {
  final HistoryProvider history;
  const _ResumenDelta({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _ChipDelta(
            label: 'Sala',
            kwh: history.deltaKwhSala,
            avgW: history.avgPowerSala,
            color: const Color(0xFF00BCD4),
          ),
          const SizedBox(width: 8),
          _ChipDelta(
            label: 'Cocina',
            kwh: history.deltaKwhCocina,
            avgW: history.avgPowerCocina,
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 8),
          _ChipDelta(
            label: 'A/C',
            kwh: history.deltaKwhAc,
            avgW: history.avgPowerAc,
            color: const Color(0xFFAB47BC),
          ),
        ],
      ),
    );
  }
}

class _ChipDelta extends StatelessWidget {
  final String label;
  final double kwh;
  final double avgW;
  final Color color;

  const _ChipDelta({
    required this.label,
    required this.kwh,
    required this.avgW,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              '${kwh.toStringAsFixed(3)} kWh',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 1),
            Text(
              'Ø ${avgW.toStringAsFixed(0)} W',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selector 1H / 24H / 7D ───────────────────────────────────────────────────

class _SelectorRango extends StatelessWidget {
  final int seleccionado;
  final ValueChanged<int> onChanged;

  const _SelectorRango(
      {required this.seleccionado, required this.onChanged});

  static const _opciones = [
    (horas: 1,   label: '1H'),
    (horas: 24,  label: '24H'),
    (horas: 168, label: '7D'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _opciones.map((op) {
          final selected = seleccionado == op.horas;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(op.horas),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00BCD4).withAlpha(30)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF00BCD4)
                        : Colors.grey.withAlpha(40),
                  ),
                ),
                child: Text(
                  op.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF00BCD4)
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Gráfica de consumo ────────────────────────────────────────────────────────

class _GraficaConsumo extends StatefulWidget {
  final List<EnergyPoint> puntos;
  const _GraficaConsumo({required this.puntos});

  @override
  State<_GraficaConsumo> createState() => _GraficaConsumoState();
}

class _GraficaConsumoState extends State<_GraficaConsumo> {
  // Qué zonas mostrar
  bool _mostrarSala   = true;
  bool _mostrarCocina = true;
  bool _mostrarAC     = true;

  static const _colorSala   = Color(0xFF00BCD4);
  static const _colorCocina = Color(0xFFFF9800);
  static const _colorAC     = Color(0xFFAB47BC);

  @override
  Widget build(BuildContext context) {
    final puntos = widget.puntos;
    if (puntos.isEmpty) return const SizedBox();

    final t0 = puntos.first.timestamp.millisecondsSinceEpoch / 1000;

    List<FlSpot> spots(double Function(EnergyPoint) fn) => puntos
        .map((p) => FlSpot(
              p.timestamp.millisecondsSinceEpoch / 1000 - t0,
              fn(p),
            ))
        .toList();

    final maxY = puntos
        .map((p) => [p.sala, p.cocina, p.ac].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);

    final durSeg =
        puntos.last.timestamp.millisecondsSinceEpoch / 1000 - t0;

    return Column(
      children: [
        // Leyenda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LeyendaItem(
                  color: _colorSala,
                  label: 'Sala',
                  activo: _mostrarSala,
                  onTap: () => setState(() => _mostrarSala = !_mostrarSala)),
              const SizedBox(width: 16),
              _LeyendaItem(
                  color: _colorCocina,
                  label: 'Cocina',
                  activo: _mostrarCocina,
                  onTap: () =>
                      setState(() => _mostrarCocina = !_mostrarCocina)),
              const SizedBox(width: 16),
              _LeyendaItem(
                  color: _colorAC,
                  label: 'A/C',
                  activo: _mostrarAC,
                  onTap: () => setState(() => _mostrarAC = !_mostrarAC)),
            ],
          ),
        ),

        // Gráfica
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.15,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withAlpha(25),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}W',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: durSeg / 4,
                      getTitlesWidget: (v, _) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(
                            ((t0 + v) * 1000).toInt());
                        final h = dt.hour.toString().padLeft(2, '0');
                        final m = dt.minute.toString().padLeft(2, '0');
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$h:$m',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  if (_mostrarSala)
                    _linea(spots((p) => p.sala), _colorSala),
                  if (_mostrarCocina)
                    _linea(spots((p) => p.cocina), _colorCocina),
                  if (_mostrarAC)
                    _linea(spots((p) => p.ac), _colorAC),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF161B22),
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(0)}W',
                              TextStyle(
                                  color: s.bar.color ?? Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _linea(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withAlpha(20),
      ),
    );
  }
}

// ── Leyenda interactiva ───────────────────────────────────────────────────────

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _LeyendaItem({
    required this.color,
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: activo ? 1.0 : 0.35,
        child: Row(
          children: [
            Container(
                width: 12, height: 3, color: color,
                margin: const EdgeInsets.only(right: 6)),
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder genérico ──────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const _Placeholder(
      {required this.icono,
      required this.titulo,
      required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: Colors.grey.shade700, size: 48),
            const SizedBox(height: 16),
            Text(titulo,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Banner consumo total ──────────────────────────────────────────────────────

class _BannerConsumoTotal extends StatelessWidget {
  final EnergyProvider provider;
  const _BannerConsumoTotal({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BCD4).withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFF00BCD4), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consumo total',
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                provider.tieneDatos
                    ? '${provider.potenciaTotal.toStringAsFixed(1)} W'
                    : '— W',
                style: const TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 24,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chip de actualización ─────────────────────────────────────────────────────

class _ChipActualizacion extends StatelessWidget {
  final EnergyProvider provider;
  const _ChipActualizacion({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (!provider.tieneDatos) {
      return Text('Sin datos',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
    }
    final seg = provider.ultimaActualizacion != null
        ? DateTime.now().difference(provider.ultimaActualizacion!).inSeconds
        : null;
    final texto =
        seg == null ? '...' : seg < 5 ? 'Ahora' : 'Hace ${seg}s';
    return Text(texto,
        style: TextStyle(
            color:
                provider.hubOnline ? Colors.greenAccent : Colors.grey.shade600,
            fontSize: 12));
  }
}

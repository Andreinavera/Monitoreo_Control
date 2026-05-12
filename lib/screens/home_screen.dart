import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/energy_history.dart';
import '../providers/ac_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/boton_toggle_ac.dart';
import '../widgets/indicador_conexion.dart';
import '../widgets/tarjeta_evento.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carga el historial de AC al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().cargarEventos('ac', horas: 168);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcProvider>();
    final history  = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: _buildAppBar(provider),
      body: Column(
        children: [
          _PanelControl(provider: provider),
          _DivisorHistorial(
            hayEventos: provider.historial.isNotEmpty ||
                history.eventosde('ac').isNotEmpty,
          ),
          Expanded(
            child: _ListaEventos(
              enMemoria: provider.historial,
              enDB: history.eventosde('ac'),
              stateDB: history.stateEventos('ac'),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(AcProvider provider) {
    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      title: const Text(
        'Aire Acondicionado',
        style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: IndicadorConexion(
              estado: provider.estadoConexion,
              onReconectar: provider.reconectar,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Panel de control ──────────────────────────────────────────────────────────

class _PanelControl extends StatelessWidget {
  final AcProvider provider;
  const _PanelControl({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              provider.acEncendido ? 'Aire encendido' : 'Aire apagado',
              key: ValueKey(provider.acEncendido),
              style: TextStyle(
                color: provider.acEncendido
                    ? const Color(0xFF00BCD4)
                    : Colors.grey.shade500,
                fontSize: 22,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          BotonToggleAC(
            acEncendido: provider.acEncendido,
            habilitado: provider.estaConectado,
            onPressed: provider.alternarAC,
          ),
          const SizedBox(height: 32),
          if (!provider.estaConectado)
            Text('Sin conexión al broker MQTT',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Lista combinada: eventos en memoria + eventos de DynamoDB ─────────────────

class _ListaEventos extends StatelessWidget {
  final List<dynamic> enMemoria;
  final List<HistoricEvent> enDB;
  final HistoryState stateDB;

  const _ListaEventos({
    required this.enMemoria,
    required this.enDB,
    required this.stateDB,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay eventos en memoria de la sesión actual, los muestra primero
    if (enMemoria.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: enMemoria.length,
        itemBuilder: (_, i) => TarjetaEvento(evento: enMemoria[i]),
      );
    }

    // Sin sesión activa: muestra historial de DynamoDB
    switch (stateDB) {
      case HistoryState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
        );
      case HistoryState.noConfigurado:
      case HistoryState.idle:
        return _vacio(
          Icons.history,
          'Sin eventos aún',
          'Los eventos del ESP32 aparecerán aquí',
        );
      case HistoryState.error:
        return _vacio(
          Icons.error_outline,
          'Error al cargar historial',
          'Verifica la conexión con el API Gateway',
        );
      case HistoryState.loaded:
        if (enDB.isEmpty) {
          return _vacio(
            Icons.history,
            'Sin eventos recientes',
            'No hay registros de AC en los últimos 7 días',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: enDB.length,
          itemBuilder: (_, i) => _TarjetaEventoHistorico(evento: enDB[i]),
        );
    }
  }

  Widget _vacio(IconData icon, String titulo, String subtitulo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade800, size: 48),
          const SizedBox(height: 12),
          Text(titulo,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitulo,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Tarjeta de evento histórico de AC ─────────────────────────────────────────

class _TarjetaEventoHistorico extends StatelessWidget {
  final HistoricEvent evento;
  const _TarjetaEventoHistorico({required this.evento});

  @override
  Widget build(BuildContext context) {
    final encendido = evento.isOn;
    final color = encendido ? const Color(0xFF00BCD4) : Colors.grey.shade700;
    final h = evento.timestamp.hour.toString().padLeft(2, '0');
    final m = evento.timestamp.minute.toString().padLeft(2, '0');
    final s = evento.timestamp.second.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withAlpha(30)),
            child: Icon(Icons.ac_unit, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(encendido ? 'Encendido' : 'Apagado',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text('Vía: ${evento.etiquetaFuente}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          Text('$h:$m:$s',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

// ── Divisor del historial ─────────────────────────────────────────────────────

class _DivisorHistorial extends StatelessWidget {
  final bool hayEventos;
  const _DivisorHistorial({required this.hayEventos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Color(0xFF21262D), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Historial de eventos',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    letterSpacing: 1)),
          ),
          const Expanded(
              child: Divider(color: Color(0xFF21262D), thickness: 1)),
        ],
      ),
    );
  }
}

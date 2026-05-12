import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/energy_history.dart';
import '../models/light_event.dart';
import '../providers/bathroom_provider.dart';
import '../providers/history_provider.dart';
import '../providers/plugs_provider.dart';
import '../widgets/tarjeta_enchufe.dart';

class PlugsScreen extends StatefulWidget {
  const PlugsScreen({super.key});

  @override
  State<PlugsScreen> createState() => _PlugsScreenState();
}

class _PlugsScreenState extends State<PlugsScreen> {
  static const Map<String, String> _nombres = {
    '10.3.141.10': 'Enchufe 1',
    '10.3.141.11': 'Enchufe 2',
    '10.3.141.12': 'Enchufe 3',
    '10.3.141.13': 'Enchufe 4',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final h = context.read<HistoryProvider>();
      h.cargarEventos('plug',  horas: 24);
      h.cargarEventos('light', horas: 24);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plugs    = context.watch<PlugsProvider>();
    final bathroom = context.watch<BathroomProvider>();
    final history  = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text('Dispositivos',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Iluminación ────────────────────────────────────────────────────
          _SeccionTitulo(titulo: 'Iluminación'),
          const SizedBox(height: 10),
          _TarjetaLuz(provider: bathroom),

          const SizedBox(height: 24),

          // ── Enchufes ───────────────────────────────────────────────────────
          Row(
            children: [
              const _SeccionTitulo(titulo: 'Enchufes'),
              const Spacer(),
              Text(
                '${plugs.enchufesEncendidos} de ${plugs.ips.length} encendidos',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: plugs.ips.length,
            itemBuilder: (context, index) {
              final ip = plugs.ips[index];
              return TarjetaEnchufe(
                ip: ip,
                nombre: _nombres[ip] ?? 'Enchufe ${index + 1}',
                estado: plugs.estadoDe(ip),
                enviando: plugs.enviandoComandoA(ip),
                onToggle: () => plugs.toggleEnchufe(ip),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Actividad reciente ─────────────────────────────────────────────
          const _SeccionTitulo(titulo: 'Actividad reciente'),
          const SizedBox(height: 10),
          _ActivityFeed(
            plugEvents:  history.eventosde('plug'),
            lightEvents: history.eventosde('light'),
            state:       history.stateEventos('plug'),
          ),
        ],
      ),
    );
  }
}

// ── Feed de actividad (plugs + luz) ──────────────────────────────────────────

class _ActivityFeed extends StatelessWidget {
  final List<HistoricEvent> plugEvents;
  final List<HistoricEvent> lightEvents;
  final HistoryState state;

  const _ActivityFeed({
    required this.plugEvents,
    required this.lightEvents,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state == HistoryState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
        ),
      );
    }

    if (state == HistoryState.noConfigurado) {
      return _aviso('API no configurada — configura el API Gateway para ver actividad.');
    }

    if (state == HistoryState.error) {
      return _aviso('Error al cargar actividad reciente.');
    }

    // Mezcla y ordena por timestamp descendente
    final todos = [...plugEvents, ...lightEvents]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final visibles = todos.take(15).toList();

    if (visibles.isEmpty) {
      return _aviso('Sin actividad en las últimas 24 horas.');
    }

    return Column(
      children: visibles
          .map((e) => _TarjetaActividad(evento: e))
          .toList(),
    );
  }

  Widget _aviso(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        texto,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TarjetaActividad extends StatelessWidget {
  final HistoricEvent evento;
  const _TarjetaActividad({required this.evento});

  @override
  Widget build(BuildContext context) {
    final encendido = evento.isOn;
    final esLuz     = evento.eventType == 'light';
    final color     = encendido ? const Color(0xFF00BCD4) : Colors.grey.shade700;

    final h = evento.timestamp.hour.toString().padLeft(2, '0');
    final m = evento.timestamp.minute.toString().padLeft(2, '0');

    String titulo;
    if (esLuz) {
      titulo = 'Foco Baño';
    } else {
      final nombres = const {
        '10.3.141.10': 'Enchufe 1',
        '10.3.141.11': 'Enchufe 2',
        '10.3.141.12': 'Enchufe 3',
        '10.3.141.13': 'Enchufe 4',
      };
      titulo = nombres[evento.ip] ?? evento.ip ?? 'Enchufe';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(
            esLuz
                ? (encendido ? Icons.lightbulb : Icons.lightbulb_outline)
                : Icons.power,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$titulo — ${encendido ? "Encendido" : "Apagado"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            '$h:$m  ·  ${evento.etiquetaFuente}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta del foco ──────────────────────────────────────────────────────────

class _TarjetaLuz extends StatelessWidget {
  final BathroomProvider provider;
  const _TarjetaLuz({required this.provider});

  @override
  Widget build(BuildContext context) {
    final encendido = provider.luzEncendida;
    final fuente    = provider.ultimaFuente;
    final color     = encendido ? const Color(0xFF00BCD4) : Colors.grey.shade700;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: encendido
              ? const Color(0xFF00BCD4).withAlpha(60)
              : Colors.grey.withAlpha(25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withAlpha(30)),
            child: Icon(
              encendido ? Icons.lightbulb : Icons.lightbulb_outline,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Foco Baño',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(encendido ? 'Encendido' : 'Apagado',
                        style: TextStyle(color: color, fontSize: 12)),
                    if (fuente != LightSource.desconocido) ...[
                      Text('  ·  ${fuente.etiqueta}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _BotonToggleLuz(
            encendido: encendido,
            enviando: provider.enviando,
            onToggle: provider.toggleLuz,
          ),
        ],
      ),
    );
  }
}

class _BotonToggleLuz extends StatelessWidget {
  final bool encendido;
  final bool enviando;
  final VoidCallback onToggle;

  const _BotonToggleLuz(
      {required this.encendido,
      required this.enviando,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enviando ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: enviando
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: encendido
                      ? const Color(0xFF00BCD4)
                      : Colors.grey.shade400,
                ),
              )
            : Icon(
                encendido ? Icons.toggle_on : Icons.toggle_off,
                size: 22,
                color: encendido
                    ? const Color(0xFF00BCD4)
                    : Colors.grey.shade500,
              ),
      ),
    );
  }
}

// ── Título de sección ─────────────────────────────────────────────────────────

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  const _SeccionTitulo({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo.toUpperCase(),
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

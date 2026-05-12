import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ac_provider.dart';
import '../providers/energy_provider.dart';
import '../providers/plugs_provider.dart';
import '../services/mqtt_service.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final energy = context.watch<EnergyProvider>();
    final plugs  = context.watch<PlugsProvider>();
    final ac     = context.watch<AcProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text(
          'Smart Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: _ChipConexion(estado: ac.estadoConexion)),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SeccionTitulo(titulo: 'Dispositivos'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TarjetaDispositivo(
                  nombre: 'Energy Hub',
                  thingName: 'ESP32_Energy_Hub',
                  online: energy.hubOnline,
                  icono: Icons.electrical_services,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TarjetaDispositivo(
                  nombre: 'AC Controller',
                  thingName: 'ESP32_AC_Controller',
                  online: ac.estaConectado,
                  icono: Icons.ac_unit,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SeccionTitulo(titulo: 'Consumo eléctrico'),
          const SizedBox(height: 8),
          _TarjetaConsumo(provider: energy),

          const SizedBox(height: 24),

          _SeccionTitulo(titulo: 'Estado del hogar'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TarjetaResumen(
                  icono: Icons.power,
                  titulo: 'Enchufes',
                  valor: '${plugs.enchufesEncendidos}/${plugs.ips.length}',
                  subtitulo: 'encendidos',
                  color: plugs.enchufesEncendidos > 0
                      ? const Color(0xFF00BCD4)
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TarjetaResumen(
                  icono: Icons.ac_unit,
                  titulo: 'Aire',
                  valor: ac.acEncendido ? 'ON' : 'OFF',
                  subtitulo: ac.acEncendido ? 'encendido' : 'apagado',
                  color: ac.acEncendido ? const Color(0xFF00BCD4) : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internos ─────────────────────────────────────────────────────────

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

class _TarjetaDispositivo extends StatelessWidget {
  final String nombre;
  final String thingName;
  final bool online;
  final IconData icono;

  const _TarjetaDispositivo({
    required this.nombre,
    required this.thingName,
    required this.online,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: online
              ? const Color(0xFF00BCD4).withAlpha(50)
              : Colors.grey.withAlpha(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono,
                  color: online
                      ? const Color(0xFF00BCD4)
                      : Colors.grey.shade700,
                  size: 16),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? Colors.greenAccent : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            online ? 'En línea' : 'Sin conexión',
            style: TextStyle(
              color: online ? Colors.greenAccent : Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaConsumo extends StatelessWidget {
  final EnergyProvider provider;
  const _TarjetaConsumo({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF00BCD4).withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFF00BCD4), size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.tieneDatos
                    ? '${provider.potenciaTotal.toStringAsFixed(1)} W'
                    : '— W',
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Potencia activa total',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniSensor(label: 'Sala',   datos: provider.sensor(1)),
              _MiniSensor(label: 'Cocina', datos: provider.sensor(2)),
              _MiniSensor(label: 'A/C',    datos: provider.sensor(3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSensor extends StatelessWidget {
  final String label;
  final dynamic datos;
  const _MiniSensor({required this.label, required this.datos});

  @override
  Widget build(BuildContext context) {
    final online = datos?.isOnline ?? false;
    final valor =
        online ? '${(datos!.power as double).toStringAsFixed(0)} W' : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text('$label  ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(valor,
              style: TextStyle(
                color: online ? Colors.white70 : Colors.grey.shade700,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String subtitulo;
  final Color color;

  const _TarjetaResumen({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitulo,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ChipConexion extends StatelessWidget {
  final EstadoConexion estado;
  const _ChipConexion({required this.estado});

  @override
  Widget build(BuildContext context) {
    final conectado = estado == EstadoConexion.conectado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (conectado ? Colors.greenAccent : Colors.grey).withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: conectado ? Colors.greenAccent : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            conectado ? 'Conectado' : 'Sin conexión',
            style: TextStyle(
              color: conectado ? Colors.greenAccent : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

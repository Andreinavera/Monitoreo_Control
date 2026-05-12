import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_mode_provider.dart';
import '../services/mqtt_service.dart';
import 'dashboard_screen.dart';
import 'energy_screen.dart';
import 'home_screen.dart';
import 'plugs_screen.dart';

class RootScreen extends StatefulWidget {
  final MqttService mqttService;
  const RootScreen({super.key, required this.mqttService});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tabActual = 0;

  static const List<Widget> _pantallas = [
    DashboardScreen(),
    EnergyScreen(),
    PlugsScreen(),
    HomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Conectar MQTT siempre al arrancar, independientemente del modo de la app.
    // En modo monitoreo AcProvider nunca se instancia (lazy), por lo que sin
    // esta línea el stream de energía nunca llega datos.
    widget.mqttService.conectar();
  }

  @override
  void dispose() {
    widget.mqttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esControl = context.watch<AppModeProvider>().esModoControl;

    if (!esControl) {
      // Modo monitoreo: pantalla única sin navegación inferior
      return const EnergyScreen(mostrarAjustes: true);
    }

    // Modo control: navegación completa de 4 tabs
    return Scaffold(
      body: IndexedStack(index: _tabActual, children: _pantallas),
      bottomNavigationBar: _BarraNavegacion(
        tabActual: _tabActual,
        onTabSeleccionado: (i) => setState(() => _tabActual = i),
      ),
    );
  }
}

// ─── Barra de navegación inferior ────────────────────────────────────────────

class _BarraNavegacion extends StatelessWidget {
  final int tabActual;
  final ValueChanged<int> onTabSeleccionado;

  const _BarraNavegacion({
    required this.tabActual,
    required this.onTabSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: const Color(0xFF161B22),
      indicatorColor: const Color(0xFF00BCD4).withAlpha(40),
      selectedIndex: tabActual,
      onDestinationSelected: onTabSeleccionado,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: Color(0xFF00BCD4)),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.bolt_outlined),
          selectedIcon: Icon(Icons.bolt, color: Color(0xFF00BCD4)),
          label: 'Energía',
        ),
        NavigationDestination(
          icon: Icon(Icons.devices_outlined),
          selectedIcon: Icon(Icons.devices, color: Color(0xFF00BCD4)),
          label: 'Dispositivos',
        ),
        NavigationDestination(
          icon: Icon(Icons.ac_unit_outlined),
          selectedIcon: Icon(Icons.ac_unit, color: Color(0xFF00BCD4)),
          label: 'Aire',
        ),
      ],
    );
  }
}

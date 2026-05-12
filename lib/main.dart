import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/ac_provider.dart';
import 'providers/app_mode_provider.dart';
import 'providers/bathroom_provider.dart';
import 'providers/energy_provider.dart';
import 'providers/history_provider.dart';
import 'providers/plugs_provider.dart';
import 'screens/root_screen.dart';
import 'services/mqtt_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = MqttService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppModeProvider()),
        ChangeNotifierProvider(create: (_) => AcProvider.withService(mqtt)),
        ChangeNotifierProvider(create: (_) => EnergyProvider(mqtt)),
        ChangeNotifierProvider(create: (_) => PlugsProvider(mqtt)),
        ChangeNotifierProvider(create: (_) => BathroomProvider(mqtt)),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Home',
        debugShowCheckedModeBanner: false,
        theme: _buildTema(),
        home: RootScreen(mqttService: mqtt),
      ),
    );
  }

  ThemeData _buildTema() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00BCD4),
        surface: Color(0xFF161B22),
      ),
      fontFamily: 'sans-serif',
    );
  }
}

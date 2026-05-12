import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { monitoreo, control }

class AppModeProvider extends ChangeNotifier {
  AppMode _modo = AppMode.monitoreo;

  AppMode get modo => _modo;
  bool get esModoControl => _modo == AppMode.control;

  AppModeProvider() {
    _cargarModo();
  }

  Future<void> _cargarModo() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('app_mode') == 'control') {
      _modo = AppMode.control;
      notifyListeners();
    }
  }

  Future<void> setModo(AppMode modo) async {
    if (_modo == modo) return;
    _modo = modo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'app_mode', modo == AppMode.control ? 'control' : 'monitoreo');
  }
}

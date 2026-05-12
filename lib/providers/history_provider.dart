import 'package:flutter/foundation.dart';

import '../models/energy_history.dart';
import '../services/api_service.dart';

enum HistoryState { idle, loading, loaded, error, noConfigurado }

class HistoryProvider extends ChangeNotifier {
  // ── Energía ─────────────────────────────────────────────────────────────────
  List<EnergyPoint> _energyPoints = [];
  int _horasEnergy = 1;
  HistoryState _stateEnergy = HistoryState.idle;
  String _errorEnergy = '';

  List<EnergyPoint> get energyPoints => _energyPoints;
  int               get horasEnergy  => _horasEnergy;
  HistoryState      get stateEnergy  => _stateEnergy;
  String            get errorEnergy  => _errorEnergy;

  // ── ΔkWh por zona ────────────────────────────────────────────────────────────
  // PZEM acumula kWh desde el último reset; ΔkWh = último - primero del período.
  // Si el valor es negativo (reset del sensor durante el período) devuelve 0.

  double get deltaKwhSala {
    if (_energyPoints.length < 2) return 0;
    final d = _energyPoints.last.salaKwh - _energyPoints.first.salaKwh;
    return d < 0 ? 0 : d;
  }

  double get deltaKwhCocina {
    if (_energyPoints.length < 2) return 0;
    final d = _energyPoints.last.cocinaKwh - _energyPoints.first.cocinaKwh;
    return d < 0 ? 0 : d;
  }

  double get deltaKwhAc {
    if (_energyPoints.length < 2) return 0;
    final d = _energyPoints.last.acKwh - _energyPoints.first.acKwh;
    return d < 0 ? 0 : d;
  }

  double get deltaKwhTotal => deltaKwhSala + deltaKwhCocina + deltaKwhAc;

  double get avgPowerSala {
    if (_energyPoints.isEmpty) return 0;
    return _energyPoints.map((p) => p.sala).reduce((a, b) => a + b) /
        _energyPoints.length;
  }

  double get avgPowerCocina {
    if (_energyPoints.isEmpty) return 0;
    return _energyPoints.map((p) => p.cocina).reduce((a, b) => a + b) /
        _energyPoints.length;
  }

  double get avgPowerAc {
    if (_energyPoints.isEmpty) return 0;
    return _energyPoints.map((p) => p.ac).reduce((a, b) => a + b) /
        _energyPoints.length;
  }

  // ── Eventos ──────────────────────────────────────────────────────────────────
  final Map<String, List<HistoricEvent>> _events      = {};
  final Map<String, HistoryState>        _stateEvents = {};
  final Map<String, String>              _errorEvents = {};

  List<HistoricEvent> eventosde(String type) => _events[type] ?? [];
  HistoryState stateEventos(String type) =>
      _stateEvents[type] ?? HistoryState.idle;

  // ── Cargar energía ───────────────────────────────────────────────────────────

  Future<void> cargarEnergy(int horas) async {
    if (!ApiService.configurado) {
      _stateEnergy = HistoryState.noConfigurado;
      notifyListeners();
      return;
    }

    _horasEnergy = horas;
    _stateEnergy = HistoryState.loading;
    notifyListeners();

    try {
      _energyPoints = await ApiService.getEnergy(horas);
      _stateEnergy  = HistoryState.loaded;
    } catch (e) {
      _errorEnergy = e.toString();
      _stateEnergy = HistoryState.error;
    }

    notifyListeners();
  }

  // ── Cargar eventos ───────────────────────────────────────────────────────────

  Future<void> cargarEventos(String type, {int horas = 24}) async {
    if (!ApiService.configurado) {
      _stateEvents[type] = HistoryState.noConfigurado;
      notifyListeners();
      return;
    }

    _stateEvents[type] = HistoryState.loading;
    notifyListeners();

    try {
      _events[type]      = await ApiService.getEvents(type, horas);
      _stateEvents[type] = HistoryState.loaded;
    } catch (e) {
      _errorEvents[type] = e.toString();
      _stateEvents[type] = HistoryState.error;
    }

    notifyListeners();
  }
}

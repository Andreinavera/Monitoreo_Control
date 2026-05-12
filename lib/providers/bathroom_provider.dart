import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/light_event.dart';
import '../services/mqtt_service.dart';

class BathroomProvider extends ChangeNotifier {
  final MqttService _mqtt;

  bool _luzEncendida  = false;
  bool _enviando      = false;
  bool _hubOnline     = false;
  LightSource _ultimaFuente = LightSource.desconocido;

  StreamSubscription<LightEvent>? _sub;

  BathroomProvider(this._mqtt) {
    _sub = _mqtt.lightStream.listen(_onLightEvent);
  }

  bool get luzEncendida  => _luzEncendida;
  bool get enviando      => _enviando;
  bool get hubOnline     => _hubOnline;
  LightSource get ultimaFuente => _ultimaFuente;

  Future<void> toggleLuz() async {
    _enviando = true;
    notifyListeners();

    final accion = _luzEncendida ? 'OFF' : 'ON';
    final ok = await _mqtt.publicarComandoLuz(accion);

    if (ok) {
      // Actualización optimista; la confirmación llega por lightStream
      _luzEncendida  = !_luzEncendida;
      _ultimaFuente  = LightSource.manual;
    }

    _enviando = false;
    notifyListeners();
  }

  void _onLightEvent(LightEvent evento) {
    _luzEncendida  = evento.encendido;
    _ultimaFuente  = evento.source;
    _hubOnline     = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

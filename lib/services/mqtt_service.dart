import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/ac_event.dart';
import '../models/light_event.dart';
import '../models/plug_event.dart';
import '../models/sensor_reading.dart';

// ─── Configuración AWS IoT Core ───────────────────────────────────────────────
const String _awsEndpoint = 'YOUR_AWS_IOT_ENDPOINT';
const int    _awsPort     = 8883;
const String _clientId    = 'flutter_app_smarthome';

// Topics de escucha
const String _topicAcEvent    = 'home/ac/event';
const String _topicEnergy     = 'home/energy/pzem';
const String _topicPlugEvent  = 'home/plugs/event';
const String _topicLightState = 'home/bathroom/light/state';

// Topics de publicación
const String _topicAcCmd      = 'home/ac/cmd';
const String _topicPlugCmd    = 'home/plugs/cmd';
const String _topicPlugSync   = 'home/plugs/sync';
const String _topicLightCmd   = 'home/bathroom/light/cmd';

// Certificados
const String _rutaCertCA       = 'assets/certs/AmazonRootCA1.pem';
const String _rutaCertCliente  = 'assets/certs/certificate.pem.crt';
const String _rutaClavePrivada = 'assets/certs/private.pem.key';

// ─── Estado de conexión ───────────────────────────────────────────────────────
enum EstadoConexion { desconectado, conectando, conectado, error }

// ─── Servicio MQTT ────────────────────────────────────────────────────────────
class MqttService {
  MqttServerClient? _cliente;

  final _estadoController    = StreamController<EstadoConexion>.broadcast();
  final _acEventController   = StreamController<AcEvent>.broadcast();
  final _energyController    = StreamController<SensorReading>.broadcast();
  final _plugEventController = StreamController<PlugEvent>.broadcast();
  final _lightController     = StreamController<LightEvent>.broadcast();

  Stream<EstadoConexion> get estadoStream  => _estadoController.stream;
  Stream<AcEvent>        get eventosStream => _acEventController.stream;
  Stream<SensorReading>  get energyStream  => _energyController.stream;
  Stream<PlugEvent>      get plugStream    => _plugEventController.stream;
  Stream<LightEvent>     get lightStream   => _lightController.stream;

  EstadoConexion _estadoActual = EstadoConexion.desconectado;
  EstadoConexion get estadoActual => _estadoActual;

  Timer? _timerReconexion;
  int    _intentosReconexion = 0;
  static const int _maxIntentos = 10;
  bool   _reconectarActivo = true;

  // ── Conexión ─────────────────────────────────────────────────────────────────

  Future<void> conectar() async {
    if (_estadoActual == EstadoConexion.conectando ||
        _estadoActual == EstadoConexion.conectado) {
      return;
    }

    _actualizarEstado(EstadoConexion.conectando);

    try {
      final contextoSeguro = await _crearContextoSeguro();

      _cliente = MqttServerClient.withPort(_awsEndpoint, _clientId, _awsPort);
      _cliente!
        ..secure          = true
        ..securityContext = contextoSeguro
        ..keepAlivePeriod = 30
        ..autoReconnect   = false
        ..logging(on: false)
        ..onDisconnected  = _alDesconectarse
        ..onConnected     = _alConectarse
        ..onSubscribed    = _alSuscribirse;

      _cliente!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(_clientId)
          .withWillQos(MqttQos.atLeastOnce)
          .startClean();

      await _cliente!.connect();

      if (_cliente!.connectionStatus?.state == MqttConnectionState.connected) {
        _cliente!.subscribe(_topicAcEvent,    MqttQos.atLeastOnce);
        _cliente!.subscribe(_topicEnergy,     MqttQos.atLeastOnce);
        _cliente!.subscribe(_topicPlugEvent,  MqttQos.atLeastOnce);
        _cliente!.subscribe(_topicLightState, MqttQos.atLeastOnce);
        _cliente!.updates?.listen(_procesarMensaje);
        // Solicita el estado actual de enchufes una vez que el listener está listo
        Future.delayed(const Duration(seconds: 2), () => _publicar(_topicPlugSync, '{}'));
      } else {
        _manejarErrorConexion(
            'Estado inesperado: ${_cliente!.connectionStatus?.state}');
      }
    } catch (e) {
      _manejarErrorConexion('Error al conectar: $e');
    }
  }

  Future<SecurityContext> _crearContextoSeguro() async {
    final certCA       = await rootBundle.load(_rutaCertCA);
    final certCliente  = await rootBundle.load(_rutaCertCliente);
    final clavePrivada = await rootBundle.load(_rutaClavePrivada);

    final ctx = SecurityContext(withTrustedRoots: false);
    ctx.setTrustedCertificatesBytes(certCA.buffer.asUint8List());
    ctx.useCertificateChainBytes(certCliente.buffer.asUint8List());
    ctx.usePrivateKeyBytes(clavePrivada.buffer.asUint8List());
    return ctx;
  }

  // ── Publicación ───────────────────────────────────────────────────────────────

  Future<bool> publicarComandoAC(String accion) =>
      _publicar(_topicAcCmd, jsonEncode({'action': accion}));

  Future<bool> publicarComandoEnchufe(String ip, int state) =>
      _publicar(_topicPlugCmd, jsonEncode({'ip': ip, 'state': state}));

  /// Envía "ON" o "OFF" al foco del baño.
  Future<bool> publicarComandoLuz(String state) =>
      _publicar(_topicLightCmd, jsonEncode({'state': state}));

  Future<bool> _publicar(String topic, String payload) async {
    if (_estadoActual != EstadoConexion.conectado || _cliente == null) {
      return false;
    }
    try {
      final builder = MqttClientPayloadBuilder()..addString(payload);
      _cliente!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Procesamiento de mensajes ─────────────────────────────────────────────────

  void _procesarMensaje(List<MqttReceivedMessage<MqttMessage?>>? mensajes) {
    if (mensajes == null || mensajes.isEmpty) return;

    for (final mensaje in mensajes) {
      final pubMsg = mensaje.payload as MqttPublishMessage;
      final texto  = MqttPublishPayload.bytesToStringAsString(
          pubMsg.payload.message);

      try {
        final json = jsonDecode(texto) as Map<String, dynamic>;
        switch (mensaje.topic) {
          case _topicAcEvent:
            _acEventController.add(AcEvent.fromJson(json));
          case _topicEnergy:
            _energyController.add(SensorReading.fromJson(json));
          case _topicPlugEvent:
            _plugEventController.add(PlugEvent.fromJson(json));
          case _topicLightState:
            _lightController.add(LightEvent.fromJson(json));
        }
      } catch (_) {
        // Ignorar mensajes con formato inválido
      }
    }
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────────

  void _alConectarse() {
    _intentosReconexion = 0;
    _timerReconexion?.cancel();
    _actualizarEstado(EstadoConexion.conectado);
  }

  void _alDesconectarse() {
    _actualizarEstado(EstadoConexion.desconectado);
    if (_reconectarActivo) _programarReconexion();
  }

  void _alSuscribirse(String topic) {}

  void _manejarErrorConexion(String mensaje) {
    _actualizarEstado(EstadoConexion.error);
    _cliente?.disconnect();
    if (_reconectarActivo) _programarReconexion();
  }

  void _programarReconexion() {
    if (_intentosReconexion >= _maxIntentos) return;
    final delay = Duration(
        seconds: (_intentosReconexion < 5) ? (2 << _intentosReconexion) : 60);
    _timerReconexion = Timer(delay, () {
      _intentosReconexion++;
      conectar();
    });
  }

  void _actualizarEstado(EstadoConexion nuevoEstado) {
    _estadoActual = nuevoEstado;
    _estadoController.add(nuevoEstado);
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────────

  void desconectar() {
    _reconectarActivo = false;
    _timerReconexion?.cancel();
    _cliente?.disconnect();
    _actualizarEstado(EstadoConexion.desconectado);
  }

  void dispose() {
    desconectar();
    _estadoController.close();
    _acEventController.close();
    _energyController.close();
    _plugEventController.close();
    _lightController.close();
  }
}

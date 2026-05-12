# Monitoreo y Control Inteligente

Aplicacion Flutter para monitorear y controlar dispositivos de un entorno inteligente mediante AWS IoT Core, MQTT y servicios HTTP.

## Características

- Conexion MQTT segura con AWS IoT Core.
- Monitoreo de eventos del aire acondicionado.
- Visualizacion de consumo energetico e historicos.
- Control de enchufes y estados de iluminacion.
- Generacion y exportacion de reportes.
- Persistencia local de configuraciones de la app.

## Tecnologías

- Flutter
- Dart
- Provider
- MQTT Client
- AWS IoT Core
- HTTP API Gateway
- PDF y exportacion de reportes

## Estructura principal

```text
lib/
  models/       Modelos de datos
  providers/    Estado de la aplicacion
  screens/      Pantallas principales
  services/     Servicios MQTT, API y reportes
  widgets/      Componentes reutilizables
assets/
  certs/        Certificados locales no versionados
```

## Configuración

Este proyecto necesita certificados X.509 de AWS IoT Core para conectarse por MQTT. Por seguridad, los certificados reales no se incluyen en el repositorio.

Crea estos archivos localmente en `assets/certs/`:

```text
AmazonRootCA1.pem
certificate.pem.crt
private.pem.key
```

Tambien configura los endpoints necesarios en:

```text
lib/services/mqtt_service.dart
lib/services/api_service.dart
```

## Instalación

```bash
flutter pub get
flutter run
```

## Seguridad

No subas al repositorio:

- Claves privadas.
- Certificados de dispositivos.
- Archivos `.env`.
- Builds generados.
- Configuraciones locales del IDE.

El archivo `.gitignore` ya excluye certificados, credenciales locales y carpetas generadas por Flutter.

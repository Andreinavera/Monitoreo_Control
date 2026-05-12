# Certificados AWS IoT Core

Coloca aquí los certificados generados desde la consola de AWS IoT Core.

## Archivos requeridos

| Archivo              | Descripción                              |
|----------------------|------------------------------------------|
| `certificate.pem.crt`| Certificado del dispositivo (app)        |
| `private.pem.key`    | Clave privada del dispositivo            |
| `AmazonRootCA1.pem`  | Certificado raíz de Amazon (CA)          |

## Cómo obtenerlos

1. Ve a AWS IoT Core → Security → Certificates → Create certificate
2. Descarga los 3 archivos y renómbralos como se muestra arriba
3. Activa el certificado y adjunta la policy con permisos de pub/sub en:
   - `home/ac/cmd`
   - `home/ac/event`

## Policy de ejemplo

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["iot:Connect"],
      "Resource": "arn:aws:iot:us-east-2:*:client/flutter_app_*"
    },
    {
      "Effect": "Allow",
      "Action": ["iot:Publish"],
      "Resource": "arn:aws:iot:us-east-2:*:topic/home/ac/cmd"
    },
    {
      "Effect": "Allow",
      "Action": ["iot:Subscribe"],
      "Resource": "arn:aws:iot:us-east-2:*:topicfilter/home/ac/event"
    },
    {
      "Effect": "Allow",
      "Action": ["iot:Receive"],
      "Resource": "arn:aws:iot:us-east-2:*:topic/home/ac/event"
    }
  ]
}
```

# Contratos API — propuesta inicial

Prefijo `/api/v1`. Contrato de diseño, sin servicios implementados. La [spec central aprobada](../../codebase/backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md) adopta P-01 a P-11 como base de diseño, incluidos los cuerpos y códigos P-07/P-11 añadidos aquí. “Propuesta” conserva su origen; no implica una aprobación aún pendiente. Los detalles expresamente abiertos requieren refinamiento técnico.

Las rutas requieren autenticación y autorización; el teléfono usa una credencial limitada. Excepciones: acceso web inicial (mecanismo pendiente) y canje de vinculación, que exige código temporal válido en lugar de credencial previa. Nunca permitir al teléfono elegir un `deviceId` ajeno.

| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/devices` | Registrar dispositivo |
| `POST` | `/pairing-codes` | Administrador genera código asociado al estudiante |
| `POST` | `/device-pairings/redeem` | Android canjea código de un solo uso y queda vinculado |
| `GET` | `/devices/me/monitoring-session` | Android consulta sesión propia y detecta cierre remoto |
| `POST` | `/monitoring-sessions` | Iniciar sesión autorizada |
| `PATCH` | `/monitoring-sessions/{id}/stop` | Android detiene la propia; administrador/operador finalizan |
| `POST` | `/telemetry` | Recibir ubicación |
| `POST` | `/sos` | Emitir SOS |
| `GET` | `/devices/latest-positions` | Leer snapshots recientes |
| `GET` | `/geofences` | Listar zonas |
| `POST` | `/geofences` | Crear zona circular |
| `PUT` | `/devices/{id}/geofence-assignments` | Administrador reemplaza conjunto de zonas asignadas |
| `PATCH` | `/devices/{id}/revoke` | Propuesta: administrador revoca habilitación y cierra sesión |
| `GET` | `/alerts` | Listar alertas |
| `PATCH` | `/alerts/{id}/acknowledge` | Reconocer alerta |
| `GET` | `/events/stream` | Eventos SSE |

La anterior ruta propuesta `/device-assignments` se sustituye por generación y canje de código; la asignación estudiante-teléfono se crea en el canje. No hay clientes implementados que migrar.

## Propuestas de vinculación, sesiones y asignaciones

| Operación | Solicitud propuesta | Resultado propuesto |
|---|---|---|
| Generar código | `studentId` | `201`: `pairingCodeId`, `code`, `expiresAt`; mostrar el código solo al generar |
| Canjear código | `code`, `deviceLabel` | `201`: `deviceId`, `studentId`, `deviceCredential`; consumir código y crear asignación atómicamente |
| Iniciar sesión | `deviceId` propio | `201`: `id`, `deviceId`, `status`, `startedAt`, `expiresAt`; máximo inicial 8 h configurable |
| Consultar sesión propia | Sin cuerpo | `200`: sesión o `null` si no existe abierta; exponer cierre/vencimiento sin filtrar sesiones ajenas |
| Detener sesión | Sin cuerpo; id en ruta | `200`: sesión finalizada con `endedAt`; repetición no reabre ni cambia el cierre original |
| Asignar zonas | `geofenceIds`: lista de UUID, vacía para retirar todas | `200`: conjunto resultante; validar zonas existentes y reinicializar estados afectados |
| Revocar teléfono | Sin cuerpo; id en ruta | `200`: `deviceId`, `enabled: false`; invalidar credencial y finalizar sesión |

Un inicio repetido devuelve la sesión abierta con `200` (**P-08**). La duración máxima de sesión, inicialmente de 8 h, es configurable por administrador; la ruta de configuración del colegio se definirá en el diseño técnico. El mecanismo de login web, renovación de credenciales y administración completa de usuarios/estudiantes queda pendiente; esta tabla no es un OpenAPI completo.

Propuesta de errores: `401` credencial ausente/inválida, `403` acción no autorizada o teléfono deshabilitado, `404` recurso inexistente, `409` conflicto de estado/asignación, `422` formato/rango inválido y `429` límite de intentos. Canje con código inválido, vencido o usado responde `422` con mensaje genérico, sin revelar estudiante ni existencia del código. `503` si no puede completarse el almacenamiento/publicación requeridos por la operación. No devolver secretos ni cuerpos de códigos en logs.

## Ejemplo: posición

```json
{
  "eventId": "0cbd1df5-5c79-4d25-84ab-f4c73e43f8b1",
  "deviceId": "8b15bfa7-0b7a-4d5f-8c7d-06e3f53ab67c",
  "sessionId": "5e6e0138-87a2-4f10-95d4-ec59e6d6d36a",
  "recordedAt": "2026-11-08T16:30:00Z",
  "latitude": -12.0972,
  "longitude": -77.0365,
  "accuracyMeters": 15.0,
  "batteryPercent": null
}
```

Respuesta: `202 Accepted` si el evento se publicó correctamente para procesamiento; `401/403` sin autorización, `422` datos inválidos, `503` si la ingesta no está disponible. `deviceId` debe corresponder a la credencial y sesión autenticadas.

`sessionId` es una **propuesta** para impedir atribuir posiciones reintentadas a una sesión posterior. El servidor comprueba identidad, sesión activa/no vencida, coordenadas, precisión no negativa y ventana temporal. Antigüedad/tolerancia propuestas: P-03 en la spec. `batteryPercent` es opcional, `null` o entre 0 y 100. La deduplicación durable usa `eventId`; un `202` no acredita actualización de snapshot o geocerca. Propuesta P-08: revalidar elegibilidad al procesar.

## Propuesta de SOS

`POST /sos` admite teléfono vinculado y habilitado sin sesión activa. No exige obtener GPS ni inicia monitoreo. `sessionId` y `location` son opcionales o `null`; una ubicación debe incluir su hora original y precisión, sin afirmar que sea actual.

```json
{
  "eventId": "c3d14fca-46a3-489e-8188-1f2e1f73dcc3",
  "deviceId": "8b15bfa7-0b7a-4d5f-8c7d-06e3f53ab67c",
  "sessionId": null,
  "recordedAt": "2026-11-08T16:31:00Z",
  "location": null
}
```

Propuesta P-07: persistir idempotentemente antes de responder. `201 Created` con `alertId`, `eventId`, `receivedAt` y `deliveryStatus: RECEIVED_BY_SERVER`; repetir el mismo evento devuelve `200` con el mismo acuse. Una falla de Kafka/SSE después del commit no cambia la recepción durable. Un timeout deja recepción desconocida: reintentar el mismo `eventId`; `503` sin recepción confirmada por almacenamiento no permite afirmar que llegó. Si un `eventId` ya existe con contenido o dispositivo diferentes, rechazar con `409` sin exponer datos ajenos.

## Propuesta de alertas y SSE

Alertas: `id`, `eventId`, `deviceId`, `type`, `status`, `triggeredAt`, `receivedAt`, `geofenceId` opcional y `acknowledgedBy`/`acknowledgedAt` opcionales. Los SOS no requieren geocerca. Estados propuestos: `PENDING` y `ACKNOWLEDGED`; `PATCH /alerts/{id}/acknowledge` retorna `200` tras persistir usuario/hora; repetir conserva el primer reconocimiento. No existe contrato para “atender” o “resolver”. La clasificación de severidad queda pendiente; no inventar escalamiento.

Propuesta: SSE emite `position.updated`, `alert.created` y `alert.acknowledged` con identificador del recurso y hora. Exige acceso del personal escolar; no garantiza reproducción de eventos perdidos. Al reconectar, consultar posiciones y alertas por REST. Para cubrir fallas de publicación SOS posteriores al commit sin desconexión SSE, proponer refresco REST de alertas cada 15 s mientras la vista esté abierta (**P-11**). No prometer aviso instantáneo. Paginación, filtros, orden y estructura final de las listas se cerrarán antes de implementar.

## Tópicos Kafka

| Tópico | Key | Value |
|---|---|---|
| `kivo.telemetry.raw` | `deviceId` | Ubicación validada |
| `kivo.telemetry.processed` | `deviceId` | Ubicación + estado de zona |
| `kivo.alerts` | `deviceId` | SOS / salida de zona |

Usar `eventId` como clave de idempotencia a nivel de persistencia. No se garantiza procesamiento exactamente una vez entre Kafka y una BD externa solo por configurar Kafka Streams.

# Kivo Android Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar la app Android Flutter de Kivo con vinculación, sesiones autorizadas, seguimiento visible y SOS durable reintentable.

**Architecture:** Dos pantallas Flutter; controladores de dominio separados del adaptador Android de ubicación/foreground service. La autoridad de sesión es Quarkus; la app detiene captura al vencimiento conocido y sincroniza cierre remoto. Una cola protegida conserva SOS y solo la última posición pendiente de la sesión.

**Tech Stack:** Flutter/Dart para Android, cliente HTTPS generado desde OpenAPI, almacenamiento protegido por Android Keystore y adaptador de ubicación/ejecución a seleccionar en M1. Versiones Flutter, SDK Android y bibliotecas aún no están fijadas por la spec.

**Spec:** [Especificación central](../../../backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md), [flujo SOS/sesiones](../../../../knowledge/flows/03-sos-session.md), [contratos](../../../../knowledge/desing/03-api-contract.md), [plan backend](../../../backend/superpowers/specs/2026-11-08-kivo-backend-implementation-plan.md).

## Global Constraints

- «Android Flutter/Dart»; un colegio, identidades y coordenadas ficticias. Dos pantallas: vinculación y principal; sin cuenta estudiantil, mapa o administración.
- «Duración máxima configurable, inicialmente **8 horas**.» Usar `expiresAt` del servidor, no sumar siempre 8 h localmente.
- «Reportar GPS cada 10 s; consultar estado de sesión cada 15 s cuando hay red; antigüedad de captura máxima 60 s; tolerancia futura 30 s».
- «Reintentos a 2, 5, 10 y luego cada 30 s; persistir SOS pendientes en almacenamiento protegido, máximo 100 y 24 h; al llenar o vencer informar error visible, sin expulsión silenciosa».
- «SOS solicita ayuda; no llama a emergencias ni garantiza atención inmediata.»
- Estados de seguimiento `INACTIVA`, `ACTIVA`, `PAUSADA`, `FINALIZADA`; estados SOS `ENVIANDO`, `ENVIADO_SIN_ACUSE`, `RECIBIDO_POR_SERVIDOR`, `ERROR_REINTENTAR`.
- Notificación visible durante seguimiento autorizado, también con pantalla bloqueada/otra app. No prometer continuidad tras force stop o revocación de permisos, ni cierre remoto inmediato sin red.
- Captura solo durante sesión autorizada salvo ubicación puntual SOS permitida, opcional y sin esperar GPS. Vincular o enviar SOS no inicia captura continua.
- Ubicaciones 7 días, alertas/auditoría 30; la posición pendiente caduca a 60 s o cierre; SOS pendiente 24 h. No coordenadas/credenciales en logs ni backups automáticos Android.
- Feature branch desde `develop`, aviso antes de push y PR a `develop` aceptada por propietario.

## Review Focus

- Reloj del teléfono alterado o proceso reiniciado: no extender sesión ni revivir captura; M1/M3/M6.
- Cierre remoto mientras vuelve GPS/red: detener y descartar posición, sin iniciar sesión nueva; M3/M4.
- Timeout SOS tras persistencia remota: mismo `eventId` y una sola alerta; M5.
- Cola llena/vencida o almacenamiento protegido inaccesible: error visible sin expulsión silenciosa; M4/M5.
- Permisos denegados/GPS apagado/fuerza de cierre: no falsa captura, y SOS sigue disponible sin ubicación; M3/M5/M6.

---

## Estado y mapa de archivos

`codebase/mobile` contiene únicamente este plan; no se ha generado Flutter. La ruta se propone para el tercer proyecto bajo `codebase/`, respetando la ubicación `superpowers/specs/` solicitada. No ejecutar `flutter create` en esta entrega.

Rutas relativas a `codebase/mobile`. M1 depende de diseño de credencial/contrato B1; M2 requiere B3; M3 requiere B4; M4 requiere B5; M5 requiere B7; M6 integra con B10 y frontend. Tests pueden usar fakes de los puertos, pero aceptación final exige API real y Android físico.

| Archivos / directorio | Responsabilidad |
|---|---|
| `lib/api/` | DTO/cliente generado de contrato B1, transporte con credencial propia |
| `lib/platform/` | Puertos de ubicación, reloj monotónico y almacenamiento seguro |
| `lib/features/pairing/` | Código y credencial; sin inicio de GPS |
| `lib/features/monitoring/` | Estado local, sesión, foreground service y última posición |
| `lib/features/sos/` | Envío, cola durable, reintentos y recibos |
| `lib/app.dart`, `lib/main.dart` | Composición y las dos pantallas |
| `android/app/src/main/` | Manifest, permisos, notificación y adaptador nativo si M1 lo exige |

### Task M1: Diseño Android verificable y puertos mínimos

**Files:** Create `docs/superpowers/specs/2026-11-08-kivo-android-runtime-design.md`, `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `lib/api/kivo_api.dart`, `lib/platform/location_port.dart`, `secure_store.dart`, `session_clock.dart`, `test/platform/session_clock_test.dart`, `README.md`. Archivos generados Android/Flutter se incluyen al ejecutar esta tarea, no ahora.

**Interfaces:** Produce `KivoApi` con `redeem`, `startSession`, `currentSession`, `stopSession`, `sendTelemetry`, `sendSos` y DTOs generados B1; `LocationPort.start(): Stream<LocationFix>`, `stop(): Future<void>`, `permittedLastKnown(): Future<LocationFix?>`; `SecureStore.read(String key): Future<String?>`, `write(String key, String value): Future<void>`, `delete(String key): Future<void>`; `SessionClock.remaining(): Duration` anclado a hora servidor y tiempo monotónico.

- [ ] **Step 1:** Documentar elección de versiones Flutter/Android, permisos por API, librería mantenida de foreground service/ubicación y cifrado con Keystore (o adaptador Kotlin si ninguna cumple). Precisar ciclo de boot/reinicio, límites de batería/fabricante, alarmas de vencimiento y restricción de backups. Recuperación tras reinicio no inicia captura sin validar autorización; sin red queda detenida hasta validarla. Diseñar protección frente a cambios de reloj con ancla monotónica y revalidación del servidor. Registrar comportamiento si GPS/permiso desaparecen y si el servicio pierde su notificación.
- [ ] **Step 2:** Generar proyecto Flutter Android y tests de puertos. `session_clock_test`: `expect(remainingAfterWallClockRollback, originalRemaining - elapsedMonotonic)`; `expect(canCaptureAfterOfflineRestart, isFalse)`; `expect(remainingAtExpiry, Duration.zero)`. Fijar versiones y lockfile en la tarea; el diseño debe permitir CA-05 sin prometer force stop.
- [ ] **Step 3:** Ejecutar `flutter test test/platform/session_clock_test.dart`; esperar FAIL por lógica ausente después de validar que runner funciona.
- [ ] **Step 4:** Implementar puertos/inyectables y reloj definidos, cliente generado desde B1 y configuración HTTPS sin secretos compilados. En `README.md` documentar SDKs exactos elegidos y comandos Android. No habilitar cleartext global; entorno local debe proporcionar HTTPS conforme diseño.
- [ ] **Step 5:** Ejecutar test y `flutter analyze`; esperar PASS. Probar prototipo de servicio/notificación en teléfono con pantalla bloqueada antes de comprometer una librería; si no cumple CA-05, ajustar diseño dentro del stack, no afirmar validación por emulador.
- [ ] **Step 6:** Commit `feat(mobile): define Android runtime and platform ports`.

### Task M2: Vinculación sin cuenta ni seguimiento

**Files:** Create `lib/features/pairing/pairing_controller.dart`, `pairing_screen.dart`, `credential_repository.dart`, `test/pairing/pairing_test.dart`; Modify `lib/app.dart`.

**Interfaces:** Produce `PairingController.redeem(String code, String deviceLabel): Future<void>` y `CredentialRepository.load(): Future<DeviceIdentity?>`, `save(DeviceIdentity identity): Future<void>`, `clear(): Future<void>`. `DeviceIdentity` contiene `deviceId`, `studentId`, credencial privada; no se imprime ni se expone al widget. Consume canje/recuperación definidos B1 y `SecureStore` M1.

- [ ] **Step 1:** Escribir CA-01/02: `expect(request.code, '01234567')`; `expect(identity.deviceId, response.deviceId)`; `expect(location.startCalls, 0)`; código vencido/usado `422` no almacena credencial; `429` permite reintentar según servidor. Ante timeout de canje no fingir vinculación: usar recuperación segura B1 o nuevo código administrado si B1 así lo decide.
- [ ] **Step 2:** Ejecutar `flutter test test/pairing/pairing_test.dart`; esperar FAIL.
- [ ] **Step 3:** Implementar formulario de ocho dígitos preservando ceros iniciales, errores genéricos y credencial protegida. Permisos solo cuando se necesiten para seguimiento, no como efecto del canje. Revocación invalida identidad y limpia secretos/cola conforme M4/M5 con aviso visible sobre solicitudes no entregadas; nunca reenviar una cola de otra identidad.
- [ ] **Step 4:** Ejecutar test y prueba de canje contra B3; esperar PASS sin sesión creada ni acceso al GPS.
- [ ] **Step 5:** Commit `feat(mobile): pair Android device securely`.

### Task M3: Sesión y captura visible con pausa segura

**Files:** Create `lib/features/monitoring/monitoring_controller.dart`, `monitoring_screen.dart`, `session_repository.dart`, `tracking_service.dart`, `test/monitoring/session_test.dart`; Modify `android/app/src/main/AndroidManifest.xml` y adaptadores concretos seleccionados M1.

**Interfaces:** Produce `MonitoringController.start(): Future<void>`, `stop(): Future<void>`, `synchronize(): Future<void>` y estado observable con `session`, `trackingStatus`, `communicationStatus`, `permissionStatus`. `TrackingService.start(MonitoringSession session): Future<void>`, `stop(): Future<void>` consume reloj M1 y emite fixes cada 10 s solo cuando elegible. Consultar sesión cada 15 s con red.

- [ ] **Step 1:** Escribir CA-04/06/17: `expect(capturesAfterExpiry, isEmpty)`; `expect(statusWithGpsDisabled, PAUSADA)`; `expect(expiresAtAfterPause, originalExpiresAt)`; `expect(capturesAfterRemoteStopAndGpsReturn, isEmpty)`; `expect(startSessionApiCallsFromSos, 0)`. Si consulta devuelve `null` para sesión local conocida, finalizar; nunca inferir que comienza otra.
- [ ] **Step 2:** Ejecutar `flutter test test/monitoring/session_test.dart`; esperar FAIL.
- [ ] **Step 3:** Implementar interfaces, estados y foreground service visible con acción detener y texto Kivo. Iniciar captura solo tras autorización servidor y permisos; cambio de app/pantalla bloqueada mantiene servicio sujeto a Android. Denegar permiso/GPS pausa sin extender vencimiento. Al recibir cierre/vencimiento, detener productor antes de vaciar pendientes M4. Sin red mostrar cierre remoto desconocido; detener al vencimiento local conocido. Si parada local no llega al servidor, dejar de capturar inmediatamente y reintentar cierre idempotente.
- [ ] **Step 4:** Ejecutar tests; en dispositivo verificar notificación, permiso revocado y cierre remoto al sincronizar contra B4. Esperar PASS; registrar restricciones de fabricante/Android, no suponer igualdad entre equipos.
- [ ] **Step 5:** Commit `feat(mobile): track only within authorized sessions`.

### Task M4: Última posición pendiente y cola protegida

**Files:** Create `lib/features/monitoring/pending_position_store.dart`, `telemetry_sender.dart`, `lib/features/sos/sos_queue.dart`, `lib/platform/retry_schedule.dart`, `test/offline/offline_test.dart`.

**Interfaces:** Produce `PendingPositionStore.replace(TelemetryEvent event): Future<void>`, `eligible(MonitoringSession session): Future<TelemetryEvent?>`, `clear(): Future<void>`; `SosQueue.enqueue(SosRequest request): Future<void>`, `pending(): Future<List<SosRequest>>`, `confirm(String eventId): Future<void>`; `RetrySchedule.delay(int attempt): Duration` devuelve 2/5/10/30 s y luego 30 s. `TelemetrySender.flush(): Future<void>` consulta elegibilidad y conserva `eventId` al reintentar. Consumen puertos M1, sesión M3 y credencial M2.

- [ ] **Step 1:** Escribir CA-07: `expect(pendingPosition.eventId, thirdFix.eventId)` tras tres capturas offline; `expect(pendingCount, 1)`; `expect(pendingAfterSessionClose, isNull)`; `expect(retryEventId, originalEventId)`. Cola SOS: `expect(lengthAfter100, 100)`; en 101 `expect(error, isA<QueueFull>())`; en 24 h `expect(visibleExpiredError, isTrue)`; no expulsar silenciosamente ni transmitir expirados. Prueba de fallo de almacenamiento: no declarar que el SOS quedó guardado.
- [ ] **Step 2:** Ejecutar `flutter test test/offline/offline_test.dart`; esperar FAIL.
- [ ] **Step 3:** Implementar posición pendiente única ligada a `sessionId`, reemplazando la anterior, con descarte a 60 s/cierre/vencimiento. Cola SOS cifrada durable sobrevive reinicio, mantiene hora/evento/payload original, prioriza SOS y está separada de telemetría. Expirados salen de datos transmitibles y dejan mensaje visible sin coordenadas; límites y purga se verifican en cada apertura y ejecución. Al reconectar sincronizar sesión antes de telemetría; conservar SOS elegibles aunque se cierre GPS.
- [ ] **Step 4:** Ejecutar tests con reloj/almacenamiento fake y reinicio del repositorio; esperar PASS en sustitución, errores y cola persistida. No usar cola de histórico de posiciones.
- [ ] **Step 5:** Commit `feat(mobile): retain only eligible offline events`.

### Task M5: SOS independiente de GPS y acuse durable

**Files:** Create `lib/features/sos/sos_controller.dart`, `sos_panel.dart`, `test/sos/sos_test.dart`; Modify `lib/features/monitoring/monitoring_screen.dart`.

**Interfaces:** Produce `SosController.send(): Future<void>`, `retry(String eventId): Future<void>` y estado por evento con `deliveryStatus`, `recordedAt`, `error`. Consume `SosQueue` M4, `KivoApi.sendSos` M1, credencial M2 y `LocationPort.permittedLastKnown` sin iniciar stream ni esperar una nueva fijación GPS.

- [ ] **Step 1:** Escribir CA-12/13/14: `expect(request.location, isNull)` sin permiso; `expect(request.sessionId, isNull)` sin sesión; `expect(trackingService.startCalls, 0)`; timeout `expect(status, ENVIADO_SIN_ACUSE)`; respuesta `201` o duplicado `200` con acuse válido `expect(status, RECIBIDO_POR_SERVIDOR)`; `503` no recibido. `expect(retryPayload, originalPayload)` y `expect(sendCallsAfterConfirmed, 0)`. Revocación bloquea nuevos envíos; no renovar coordenadas en reintentos.
- [ ] **Step 2:** Ejecutar `flutter test test/sos/sos_test.dart`; esperar FAIL.
- [ ] **Step 3:** Implementar creación de un UUID/hora por pulsación y guardar antes de envío. Adjuntar solo ubicación puntual previamente disponible y permitida, sin bloquear solicitud ni arrancar GPS; si llamada de ubicación no puede responder inmediatamente, enviar sin ella. Mapeo de timeout, offline y rechazo distingue recepción desconocida de error/reintentar; nunca afirmar atención humana. Al llegar acuse durable retirar pendiente protegido; mostrar error visible si falla guardado/cola llena, sin afirmar entrega. Conservar texto exacto SOS de la spec y hora original por evento.
- [ ] **Step 4:** Ejecutar test y escenario real B7 con respuesta perdida después de commit; esperar un solo `alertId`, mismo evento y recepción confirmada solo tras `200/201` válido. Cerrar sesión no elimina SOS pendiente; revocación no permite enviarlo con otra identidad.
- [ ] **Step 5:** Commit `feat(mobile): send SOS with durable server receipts`.

### Task M6: Validación Android real y entrega reproducible

**Files:** Create `integration_test/kivo_session_test.dart`, `integration_test/kivo_sos_test.dart`, `docs/validation/android-device-matrix.md`; Modify `README.md` y checklist compartida creada en B10.

**Interfaces:** Consume M1–M5, entorno ficticio B10 y dashboard F6. Produce APK de demo y evidencia por modelo/API de Android, permisos, batería, pantalla bloqueada, cambio de app, GPS, red y reinicio. No publicar en tienda ni desplegar por esta tarea.

- [ ] **Step 1:** Escribir CA-05 integrado: `expect(serverPositionAfterLockedScreen, isNotNull)` durante sesión elegible; `expect(visibleTrackingNotification, isTrue)`; `expect(positionsAfterStop, isEmpty)`. SOS sin GPS/sesión aparece una vez en REST/dashboard; reconexión envía última posición elegible y ningún dato de sesión anterior.
- [ ] **Step 2:** Ejecutar `flutter test integration_test -d <device-id>` con API/HTTPS de demo configurados según README; al principio esperar fallos de integración verificables, no simular notificación con widget fake.
- [ ] **Step 3:** Completar configuración Android de M1 y documentación de instalación/permisos, límites observados y rotación/revocación. Ejecutar manualmente pantalla bloqueada y otra app, revocación de permiso, GPS apagado, cierre remoto con/sin red, cambio de reloj, reinicio y force stop. Force stop se registra como limitación, nunca como continuidad garantizada. Revisar logs/backup extraído para ausencia de secretos y coordenadas persistidas fuera de colas protegidas.
- [ ] **Step 4:** Ejecutar `flutter pub get`, `flutter analyze`, `flutter test`, `flutter test integration_test -d <device-id>` y `flutter build apk --debug`. Esperar exit 0 y registrar evidencias reales en matriz. Si CA-05 no puede comprobarse sin dispositivo físico, dejarlo pendiente y no declarar MVP validado.
- [ ] **Step 5:** Commit `test(mobile): verify Android tracking and SOS lifecycle`; aviso antes de push, PR a `develop` y aceptación del propietario.

## Cobertura y autorrevisión

| Requisitos / decisiones / aceptación | Tareas |
|---|---|
| RF-01/02, P-01/02, CA-01/02/03 | M1/M2; servidor B3 |
| RF-03/04/05, P-03/08, CA-04/05/06/17 | M1/M3/M6 |
| RF-06, P-06, CA-07/08 | M4/M5; deduplicación servidor B5/B7 |
| RF-10/11, P-07, CA-12/13/14 | M5/M6 |
| RF-12, P-09/10, CA-16 | M1/M4/M6; borrado de servidores B9 |

RF-07/08/09 y CA-09/10/11/15 corresponden al backend/dashboard; móvil no evalúa geocercas ni reconoce alertas. Revisados puertos, dependencias y cinco riesgos con pruebas asignadas. CA-05 y comportamiento del sistema operativo requieren dispositivo real; la elección de bibliotecas/versiones permanece como entregable técnico de M1, sin presentarla como aprobada o instalada. El plan no acredita pruebas ejecutadas.

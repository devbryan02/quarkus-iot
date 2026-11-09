# Kivo Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar la API autorizada, procesamiento de telemetría, geocercas, SOS durable y retención del MVP de Kivo.

**Architecture:** Monolito modular Quarkus organizado por dominio en `pe.kivo`. PostgreSQL es la fuente de verdad; Kafka/Streams procesa posiciones y geocercas, y Redis acelera lecturas recuperables. REST recupera las notificaciones SSE perdidas.

**Tech Stack:** Java 25 LTS, Quarkus 3.40.1.1 LTS, Maven Wrapper, PostgreSQL 18, Flyway, Kafka 4.1.1, Kafka Streams, Redis 8, JUnit y REST Assured.

**Spec:** [Especificación central aprobada](../../docs/superpowers/specs/2026-11-08-kivo-mvp-design.md), especialmente secciones 4–10. Leer también [REST/Kafka](../../../../knowledge/desing/03-api-contract.md), [modelo](../../../../knowledge/desing/02-data-model.md) y [reglas Gitflow](../../../../knowledge/rules/01-gitflow.md).

## Global Constraints

- «Un colegio, identidades y coordenadas ficticias, cinco pantallas web y dos Android.»
- «Duración máxima configurable, inicialmente **8 horas**.»
- «Código aleatorio de 8 dígitos, 10 minutos, almacenado mediante hash protegido; máximo 5 intentos por origen en 10 minutos y límite global configurable».
- «Reportar GPS cada 10 s; consultar estado de sesión cada 15 s cuando hay red; antigüedad de captura máxima 60 s; tolerancia futura 30 s».
- «Comunicación reciente hasta 30 s; desactualizada entre 30 y 60 s; sin comunicación después de 60 s».
- «Precisión aceptable hasta 50 m; histéresis de 20 m y 2 mediciones confiables consecutivas».
- «SOS durable sincrónico con `201`; duplicado con `200`; Kafka/SSE posteriores no condicionan recepción; alertas solo pendientes/reconocidas».
- «Usar reloj servidor UTC; ubicación expira desde `recordedAt`, alerta desde `triggeredAt`, auditoría desde su creación; depurar cada hora y excluir vencidos de toda lectura inmediatamente».
- Ubicaciones 7 días; alertas/auditoría 30 días; coordenadas SOS separables a 7 días. Tópicos con prefijo `kivo.`. Sin coordenadas, códigos ni credenciales en logs.
- P-01 a P-11 están adoptadas; los mecanismos abiertos no están resueltos por esa aprobación. No cambiar esos valores durante la ejecución sin actualizar la spec.
- Trabajar en `feature/<funcionalidad>` desde `develop` vigente; commits por tarea; avisar antes de cada push; PR a `develop`, aceptada solo por el propietario.

## Review Focus

- Canjes y comienzos simultáneos: una vinculación y una sesión abierta; pruebas B3/B4.
- Cierre concurrente con eventos en vuelo: ningún evento posterior al cierre actualiza estado; pruebas B5/B6.
- Reasignación de teléfono: no atribuir snapshots ni alertas del estudiante anterior al nuevo; pruebas B3/B8.
- Reutilizar `eventId` con otro cuerpo o dispositivo: conflicto sin filtrar datos; pruebas B5/B7.
- Borrado con Redis, changelog o backup antiguos: no reaparecen coordenadas vencidas; pruebas B9/B10.

---

## Estado, rutas y orden

Solo existen `/hello`, health y sus pruebas generadas. No hay drivers, autenticación, entidades ni consumidores. Este documento es un plan, no evidencia de implementación. Se guarda en `superpowers/specs/` por preferencia del propietario, conservando intacta la spec central en `docs/superpowers/specs/`.

Rutas de las tareas relativas a `../../..`, salvo prefijo `../`. Cada paquete tiene DTOs/records públicos en archivos propios; no agrupar toda la aplicación en un recurso. Los tipos de DTO definitivos se fijan en B1, antes de generar clientes. Extensiones previstas para B2: JDBC PostgreSQL, Hibernate ORM, Flyway, Hibernate Validator, Redis Client, Messaging Kafka, Kafka Streams, Scheduler y el mecanismo de seguridad elegido en B1; respetar el BOM actual.

| Área / archivos | Responsabilidad |
|---|---|
| `src/main/resources/openapi/kivo.yaml` | Contrato REST/SSE fuente de clientes y pruebas |
| `docs/superpowers/specs/2026-11-08-kivo-security-design.md` | Diseño técnico de autenticación y credenciales |
| `src/main/java/pe/kivo/shared/TimeConfiguration.java` | `Clock` UTC inyectable |
| `.../identity/`, `.../devices/`, `.../sessions/` | Roles, administración, vinculación y autoridad de sesiones |
| `.../telemetry/`, `.../geofences/` | Ingesta, persistencia idempotente y topología |
| `.../alerts/`, `.../monitoring/`, `.../retention/` | SOS/acuse, consulta/SSE y vencimiento |
| `src/main/resources/db/migration/` | Migraciones incrementales, sin datos reales |

Orden: B1 → B2 → B3 → B4 → B5 → B6; B7 requiere B4/B2; B8 requiere B6/B7; B9 requiere B8; B10 integra todo. Frontend y móvil pueden trabajar con fixtures desde B1; sus pruebas integradas requieren B8.

### Task B1: Cerrar contratos y diseños técnicos abiertos

**Files:** Create `src/main/resources/openapi/kivo.yaml`, `docs/superpowers/specs/2026-11-08-kivo-security-design.md`, `docs/superpowers/specs/2026-11-08-kivo-processing-design.md`, `src/test/java/pe/kivo/contracts/ContractTest.java`; Modify `pom.xml`, `../../knowledge/desing/03-api-contract.md`, `../../knowledge/desing/02-data-model.md` y `../../knowledge/arquitecture/03-decisions.md`.

**Interfaces:** Consume secciones 9/10 y contratos existentes. Produce esquemas `PairingCode`, `PairingResult`, `Device`, `Student`, `User`, `MonitoringSession`, `TelemetryEvent`, `SosRequest`, `SosReceipt`, `LatestPosition`, `Alert`, `Geofence`, `ApiError`, `CurrentUser`, `SchoolSettings` y listas paginadas para generación Java/TS/Dart. Mantener campos y códigos ya aprobados.

- [ ] **Step 1:** Escribir `ContractTest` con assertions sobre el documento parseado: `assertEquals("/api/v1", serverPath)`, `assertTrue(telemetryResponses.contains("202"))`, `assertTrue(sosResponses.containsAll(Set.of("200", "201", "409", "503")))`; canje público, stream solo personal, `sessionId` obligatorio en telemetría y opcional en SOS. Incorporar parser OpenAPI como dependencia de pruebas.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=ContractTest`; esperar fallo por contrato ausente, no por configuración rota.
- [ ] **Step 3:** Especificar en los dos diseños autenticación web (sesión/cookie, CSRF, logout, usuarios/roles), emisión/rotación/revocación de credencial Android y protección de códigos (HMAC con secreto externo, límites atómicos y origen detrás de proxy). Documentar recuperación del canje cuya respuesta se pierde sin permitir dos teléfonos. Fijar bootstrap del administrador ficticio sin secretos en Git. Registrar elecciones como propuestas técnicas, sin atribuir aprobación nueva al propietario.
- [ ] **Step 4:** Completar OpenAPI con login/logout/me, gestión de usuarios/estudiantes y edición de zonas, listado de teléfonos y configuración de duración máxima. Precisar cuerpos, paginación, filtros, orden estable, estados y mensajes genéricos; conservar rutas existentes. Definir SSE `{resourceId, occurredAt}` y refresco REST de alertas cada 15 s. Resolver consulta de sesión propia `null` frente a cierre mediante estado terminal local; precisar recuperación tras reinstalación/reinicio. El diseño de procesamiento debe fijar orden entre cierre/consumidor, cambios de versión, igualdad de timestamps, radio mínimo e histéresis, y recuperación tras caída entre estado Streams y escritura PostgreSQL. No dar por decididos estos mecanismos antes de documentarlos.
- [ ] **Step 5:** Ejecutar `./mvnw -B -ntp test -Dtest=ContractTest`; esperar PASS. Revisar diseños contra CA-01–CA-17 y RF-01–RF-12. No iniciar implementación dependiente con contradicciones abiertas; si cambia una regla de producto, actualizar y obtener aprobación de la spec afectada.
- [ ] **Step 6:** Commit `docs: define Kivo implementation contracts` incluyendo exclusivamente los archivos de esta tarea.

### Task B2: Persistencia y reloj verificables

**Files:** Modify `pom.xml`, `src/main/resources/application.properties`; Create `src/main/resources/db/migration/V1__identity_devices_sessions.sql`, `V2__telemetry_geofences_alerts.sql`, `src/main/java/pe/kivo/shared/TimeConfiguration.java`, `src/test/java/pe/kivo/storage/SchemaTest.java`.

**Interfaces:** Produce `Clock` UTC CDI y esquema de las entidades del modelo más versiones de asignación, ubicaciones SOS separadas y registros de idempotencia sin coordenadas. Los paquetes propietarios de cada entidad se crean en sus tareas de dominio.

- [ ] **Step 1:** Crear `SchemaTest`: `assertEquals(1, activeAssignmentCount(deviceId))` tras dos inserciones concurrentes; `assertThrows(SQLException.class, () -> insertSecondOpenSession(deviceId))`; `assertEquals(0, orphanSosLocations())`. Helpers de prueba usan JDBC contra PostgreSQL de pruebas, nunca H2.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=SchemaTest`; esperar ausencia de tablas/restricciones.
- [ ] **Step 3:** Agregar extensiones del mapa y migraciones con índices únicos parciales para asignación/sesión abierta, FKs, `timestamptz`, unicidad de eventos y snapshot con contexto de asignación. Datos ficticios separados en fixtures de test. Producir `TimeConfiguration.clock(): Clock` y permitir reemplazo en tests. No usar `Instant.now()` directamente en lógica de negocio.
- [ ] **Step 4:** Ejecutar `./mvnw -B -ntp test -Dtest=SchemaTest`; esperar PASS tanto desde BD vacía como aplicando V2 sobre V1. No editar después migraciones aplicadas.
- [ ] **Step 5:** Commit `feat(backend): add durable Kivo schema`.

### Task B3: Identidad, administración y vinculación atómica

**Files:** Create `src/main/java/pe/kivo/identity/IdentityResource.java`, `IdentityService.java`, `DeviceAuthenticator.java` dentro del mismo paquete; `src/main/java/pe/kivo/devices/DeviceResource.java`, `PairingResource.java`, `PairingService.java`, `StudentResource.java`, `DeviceRepository.java`; Test `src/test/java/pe/kivo/devices/PairingTest.java`, `src/test/java/pe/kivo/identity/AuthorizationTest.java`.

**Interfaces:** Consume B1/B2. Produce `PairingService.issue(UUID studentId, UUID administratorId): PairingCode`, `redeem(String code, String deviceLabel): PairingResult`; `DeviceAuthenticator.requireEnabled(): UUID`; recursos de administración según OpenAPI. Identidad del operador viene de contexto autenticado, nunca de un campo editable del cuerpo.

- [ ] **Step 1:** Escribir pruebas CA-01/02/03: `assertEquals(1, successfulConcurrentRedemptions(code))`; `assertEquals(422, redeemExpiredCode())`; `assertEquals(429, sixthAttemptSameOrigin())`; `assertFalse(logOutput.contains(code))`; `assertEquals(403, operatorCreatesStudent())`. Añadir expiración exacta a 10 min, límite global, revocación/códigos pendientes y reasignación sin recuperar snapshots antiguos.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=PairingTest,AuthorizationTest`; esperar fallos de comportamiento/recursos ausentes.
- [ ] **Step 3:** Implementar las interfaces anteriores con generación criptográfica preservando ceros iniciales, hash protegido, consumo transaccional y bloqueo/constraint en PostgreSQL. Aplicar login, gestión de usuarios y estudiantes, rotación/revocación y controles de origen conforme B1. Comparar credencial/dispositivo en cada operación; nunca retornar hash. Vincular no inicia sesión.
- [ ] **Step 4:** Ejecutar el comando anterior; esperar PASS, incluyendo carreras reales contra PostgreSQL y credencial revocada inmediatamente inválida.
- [ ] **Step 5:** Commit `feat(backend): authorize identities and pair devices`.

### Task B4: Sesiones con cierre y vencimiento autoritativos

**Files:** Create `src/main/java/pe/kivo/sessions/SessionResource.java`, `SessionService.java`, `SessionRepository.java`, `SchoolSettingsResource.java`; Test `src/test/java/pe/kivo/sessions/SessionTest.java`.

**Interfaces:** Produce `SessionService.start(UUID deviceId): MonitoringSession`, `stop(UUID sessionId, UUID actorId): MonitoringSession`, `current(UUID deviceId): Optional<MonitoringSession>`, `requireEligible(UUID deviceId, UUID sessionId, Instant receivedAt): void`. Consume identidad B3 y reloj B2. El resultado HTTP distingue inicio nuevo `201` y repetido `200`.

- [ ] **Step 1:** Escribir CA-04/06/17: `assertEquals(startedAt.plus(Duration.ofHours(8)), session.expiresAt())`; `assertEquals(first.id(), concurrentStart.id())`; `assertEquals(firstStop.endedAt(), repeatedStop.endedAt())`; `assertThrows(ForbiddenException.class, () -> requireEligible(otherDevice, sessionId, now))`. A las 8 h rechazar, aunque el job de expiración no haya corrido. Solo admin modifica duración; no alterar `expiresAt` de sesiones ya iniciadas.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=SessionTest`; esperar FAIL.
- [ ] **Step 3:** Implementar interfaces y recursos B1 con serialización por dispositivo, cierre al revocar y distinción entre pausa local y sesión del servidor. Personal puede detener, nunca iniciar desde dashboard. Cerrar repetidamente conserva primer actor/hora/motivo.
- [ ] **Step 4:** Repetir comando; esperar PASS para inicio/cierre concurrentes, sesión ajena y consulta sin sesión `null`.
- [ ] **Step 5:** Commit `feat(backend): enforce monitoring session lifecycle`.

### Task B5: Ingesta Kafka y última posición durable

**Files:** Create `src/main/java/pe/kivo/telemetry/TelemetryResource.java`, `TelemetryPublisher.java`, `TelemetryProcessor.java`, `TelemetryRepository.java`; Test `src/test/java/pe/kivo/telemetry/TelemetryTest.java`.

**Interfaces:** Consume `TelemetryEvent` B1, `requireEligible` B4. Produce `TelemetryPublisher.publish(TelemetryEvent event): CompletionStage<Void>` y `TelemetryProcessor.apply(TelemetryEvent event): boolean` (true solo cuando aplica estado nuevo). Key Kafka `deviceId`; histórico y snapshot en transacción con deduplicación.

- [ ] **Step 1:** Escribir CA-07/08/17: `assertEquals(202, publishConfirmed())`; `assertEquals(503, brokerUnavailable())`; `assertEquals(1, countEvent(retriedEventId))`; `assertEquals(newer.recordedAt(), snapshot.recordedAt())`; `assertFalse(applyAfterSessionClosed())`. Verificar límites inclusivos edad 60 s/futuro 30 s y rechazo fuera, latitud ±90, longitud ±180, precisión negativa, NaN/infinito y batería fuera de 0–100. `eventId` con contenido diferente retorna conflicto sin datos previos.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=TelemetryTest`; esperar FAIL.
- [ ] **Step 3:** Implementar `POST /api/v1/telemetry`, validar antes de publicar y esperar confirmación del broker para `202`. Revalidar sesión al aplicar usando el mecanismo de concurrencia B1. Escritura condicional de snapshot sin retroceder; empates siguen orden determinista B1. No volver a rejuvenecer comunicación usando `recordedAt`: registrar recepción autenticada separadamente. No confirmar offset de mensaje cuya transacción falló.
- [ ] **Step 4:** Ejecutar comando; esperar PASS con Kafka/PostgreSQL de pruebas, caída tras commit y antes de confirmar offset, y reentrega sin duplicación. No atribuir atomicidad Kafka↔BD a `exactly_once`.
- [ ] **Step 5:** Commit `feat(backend): ingest and persist session telemetry`.

### Task B6: Zonas asignadas y transición confirmada

**Files:** Create `src/main/java/pe/kivo/geofences/GeofenceResource.java`, `GeofenceService.java`, `GeofenceTopology.java`, `ZoneEvaluator.java`, `ZoneState.java`; Test `src/test/java/pe/kivo/geofences/GeofenceTopologyTest.java`.

**Interfaces:** Produce `ZoneEvaluator.evaluate(ZoneState previous, TelemetryEvent event, Geofence zone): ZoneState`, `GeofenceService.replaceAssignments(UUID deviceId, Set<UUID> geofenceIds): Set<Geofence>`. `ZoneState` conserva sesión, zona, versión de zona/asignación, última hora aplicada, estado confirmado, candidato y contador; B1 fija umbrales exactos. Produce `kivo.telemetry.processed` y `kivo.alerts` con identidad derivada estable `(evento, zona, versiones)`.

- [ ] **Step 1:** Escribir CA-10/11: `assertEquals(0, exits(firstReliableOutside))`; `assertEquals(0, exits(oneOutsideMeasurement))`; `assertEquals(1, exits(twoConfirmedOutside))`; `assertEquals(0, exits(accuracyAbove50))`; `assertEquals(Set.of(zoneA), exitZoneIds(outsideAInsideB))`. Reiniciar sesión o cambiar solo A reinicializa A sin salida y conserva B; evento atrasado/duplicado y desconexión no incrementan contador.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=GeofenceTopologyTest`; esperar FAIL.
- [ ] **Step 3:** Implementar distancia circular, histéresis 20 m, precisión hasta 50 m y dos mediciones consecutivas según diseño B1. Streams recupera por changelog sin Redis; recargar versiones de configuración explícitamente. Validar radio mínimo B1. CRUD y asignación solo admin; zonas inactivas/no asignadas no se evalúan.
- [ ] **Step 4:** Ejecutar comando con TopologyTestDriver y prueba de reinicio/restore del diseño B1; esperar una sola salida por transición, también tras fallo entre cambio de estado y persistencia. Revalidar elegibilidad antes de aplicar estado/alerta.
- [ ] **Step 5:** Commit `feat(backend): evaluate assigned circular geofences`.

### Task B7: SOS durable y reconocimiento idempotente

**Files:** Create `src/main/java/pe/kivo/alerts/SosResource.java`, `SosService.java`, `AlertResource.java`, `AlertService.java`, `AlertRepository.java`; Test `src/test/java/pe/kivo/alerts/SosTest.java`, `AcknowledgementTest.java` en el mismo directorio de pruebas.

**Interfaces:** Produce `SosService.receive(UUID authenticatedDeviceId, SosRequest request): SosReceipt` con indicador de nuevo/duplicado para HTTP y acuse aprobado; `AlertService.acknowledge(UUID alertId, UUID actorId): Alert`. Consume identidad habilitada B3; SOS no llama `requireEligible` para exigir sesión abierta.

- [ ] **Step 1:** Escribir CA-12/13/14/15: `assertEquals(201, first.status())`; `assertEquals(200, retry.status())`; `assertEquals(first.alertId(), retry.alertId())`; `assertEquals(503, databaseFailure.status())`; `assertEquals(201, kafkaFailsAfterCommit.status())`; `assertEquals(firstAck, secondAck)`. Sin sesión ni ubicación funciona; conflicto de cuerpo/dispositivo da `409` sin fuga. Conservar `recordedAt` original de SOS retrasado y ubicar coordenadas opcionales en tabla separada.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=SosTest,AcknowledgementTest`; esperar FAIL.
- [ ] **Step 3:** Persistir alerta/acuse en transacción antes de responder. Notificar Kafka/SSE después del commit sin convertir una recepción durable en fallo. Comparar reintentos con identidad y contenido canónico sin prolongar coordenadas después de retención. Reconocimiento conserva primer usuario/hora usando actualización condicional. Estados wire `PENDING`/`ACKNOWLEDGED` y `RECEIVED_BY_SERVER`; no introducir resolución.
- [ ] **Step 4:** Ejecutar comando; esperar PASS incluyendo dos reconocimientos y SOS simultáneos, timeout tras commit y REST que recupera la alerta aun sin notificación.
- [ ] **Step 5:** Commit `feat(backend): persist SOS before server receipt`.

### Task B8: Consultas recuperables, comunicación y SSE

**Files:** Create `src/main/java/pe/kivo/monitoring/MonitoringResource.java`, `MonitoringQueryService.java`, `EventStreamResource.java`, `CommunicationStatus.java`; Test `src/test/java/pe/kivo/monitoring/MonitoringTest.java`.

**Interfaces:** Produce `MonitoringQueryService.latestPositions(CurrentUser actor): List<LatestPosition>` y listados de alertas B1, `CommunicationStatus.from(Instant lastAuthenticatedAt, Instant now): CommunicationStatus`. SSE autenticado emite los tres nombres aprobados; no almacena historial para replay.

- [ ] **Step 1:** Escribir CA-09 y reasignación: `assertEquals(beforeRedisFlush, restAfterRedisFlush)`; `assertFalse(newAssignmentView.contains(oldAssignmentPosition))`; `assertEquals(RECENT, statusAt30s)`; `assertEquals(STALE, statusAt60s)`; `assertEquals(OFFLINE, statusAfter60s)`. Ubicación vieja no se presenta actual aunque haya comunicación reciente; teléfono no puede leer stream/listas del colegio.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=MonitoringTest`; esperar FAIL.
- [ ] **Step 3:** Implementar consultas autorizadas con filtros de vencimiento inmediatos y contexto histórico de asignación; usar Redis solo como caché con TTL restante desde captura, reconstruida desde snapshot PostgreSQL. Stream informa identificador/hora y requiere REST inicial/reconexión; liberar suscripciones al desconectar. Auditar acceso sin coordenadas ni secretos.
- [ ] **Step 4:** Ejecutar comando; esperar PASS con Redis ausente, alertas sin SSE, paginación estable y usuario revocado durante stream según B1.
- [ ] **Step 5:** Commit `feat(backend): recover monitoring state through REST`.

### Task B9: Retención en almacenes y diseño operativo

**Files:** Create `src/main/java/pe/kivo/retention/RetentionJob.java`, `RetentionService.java`, `src/test/java/pe/kivo/retention/RetentionTest.java`, `docs/superpowers/specs/2026-11-08-kivo-retention-design.md`; Modify `../compose.yaml`, `../../knowledge/arquitecture/02-deployment.md`.

**Interfaces:** Produce `RetentionService.purge(Instant now): PurgeResult` (conteos por almacén sin contenido sensible). Consume reloj B2 y expiración lógica B8. Diseño operativo detalla todos los tópicos internos, changelogs, réplicas, discos, snapshots y backups.

- [ ] **Step 1:** Escribir CA-16: `assertFalse(readLocationAt(recordedAt.plus(7, DAYS)).isPresent())`; `assertTrue(readAlertAt(triggeredAt.plus(7, DAYS)).isPresent())`; `assertFalse(readAlertAt(triggeredAt.plus(30, DAYS)).isPresent())`; `assertEquals(0, restoredExpiredCoordinates())`. Incluir un SOS recibido 24 h después para no contar retención desde recepción; prueba de lectura con job aún pendiente y Redis antiguo.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp test -Dtest=RetentionTest`; esperar FAIL.
- [ ] **Step 3:** Diseñar primero el mecanismo físico P-10 con presupuesto temporal de segmentos/limpieza dentro de 7/30 días, tratamiento de compactación/changelogs y saneamiento antes de servir una restauración. Si no permite acreditar el máximo, registrar bloqueo de CA-16 físico; configurar solo `retention.ms` no lo resuelve. Establecer cifrado, expiración y responsables de copias; revisar este diseño antes de habilitar backups con datos.
- [ ] **Step 4:** Implementar job horario, expiración en todas las consultas y TTL de caché, borrar coordenadas de alertas separadamente y evitar copiarlas en métricas/logs/errores. Conservar solo huellas no reversibles de deduplicación por el período definido en B1 sin retener datos de ubicación. Agregar procedimiento de verificación física del diseño a despliegue.
- [ ] **Step 5:** Ejecutar pruebas y simulacro aislado de restauración/segmentos con reloj y evidencia por almacén; esperar cero coordenadas vencidas recuperables. No declarar CA-16 íntegro si solo se probaron consultas o PostgreSQL.
- [ ] **Step 6:** Commit `feat(backend): enforce data retention boundaries`.

### Task B10: Integración reproducible y demo verificable

**Files:** Create `src/test/java/pe/kivo/acceptance/KivoAcceptanceIT.java`, `src/test/resources/fixtures/kivo-demo.sql`, `../../knowledge/validation/2026-11-08-kivo-mvp-checklist.md`; Modify `../../../../../README.md`, `../README.md`, `../compose.yaml`, `../.env.example`.

**Interfaces:** Consume B1–B9 y clientes frontend/móvil. Produce entorno local con fixtures ficticios, checklist y resultados por CA con fecha/versión; no confundir escenarios previstos con ejecutados.

- [ ] **Step 1:** Crear `KivoAcceptanceIT`: vincular → iniciar → publicar → consultar snapshot → salir de zona → reconocer → cerrar. Assertions: `assertEquals(1, exitAlerts)` y `assertEquals(403, telemetryAfterClosure)` según código de sesión cerrada fijado B1; agregar SOS sin sesión y pérdida de Redis/Kafka. CA-05/06 se registran como pendientes del dispositivo real, nunca simuladas como superadas.
- [ ] **Step 2:** Ejecutar `./mvnw -B -ntp verify -DskipITs=false`; esperar fallo por integración aún ausente y distinguir errores de ambiente.
- [ ] **Step 3:** Conectar contenedores a la aplicación, health/readiness y migraciones antes de tráfico; actualizar setup con variables sin secretos y comandos efectivos. Documentar VPS/HTTPS/Caddy como despliegue separado de la demo local; ningún despliegue queda autorizado por este plan. Completar evidencias CA-01–CA-17 con frontend/móvil y documentar resultados de restauración.
- [ ] **Step 4:** Ejecutar `./mvnw -B -ntp verify -DskipITs=false` (Windows: `./mvnw.cmd`), `docker compose config --quiet` y `docker compose --profile infra up --build -d --wait` desde `codebase`. Esperar exit 0 y servicios saludables; adjuntar resultados reales y limitaciones. No afirmar capacidad de producción: no hay objetivo numérico acordado.
- [ ] **Step 5:** Commit `test(backend): verify Kivo MVP integration`. Avisar antes de publicar la rama y abrir PR a `develop`; dejar aceptación al propietario.

## Cobertura y revisión del plan

| Requisitos / decisiones | Tareas |
|---|---|
| RF-01/02, P-01/02, CA-01/02/03 | B1–B3 |
| RF-03, P-03/08, CA-04/06/17 | B4/B5 y plan móvil |
| RF-04/06, CA-05/07 | B5/B10 y plan móvil (captura/cola/notificación) |
| RF-05/07, P-03/04/11, CA-08/09 | B5/B8 |
| RF-08/09, P-05/08, CA-10/11 | B6 |
| RF-10/11, P-06/07, CA-12/13/14/15 | B7 y plan móvil (reintentos/cola) |
| RF-12, P-09/10, CA-16 | B9/B10 y limpieza de clientes |

Autorrevisión: los cinco riesgos de Review Focus tienen pruebas asignadas; contratos abiertos se cierran en B1 antes de generar consumidores. No quedan requisitos funcionales sin tarea, pero CA-05 exige Android real y CA-16 exige evidencia física adicional a tests de aplicación. Los nombres de DTO son del contrato B1; su generación evita redefinir estructuras distintas en cada cliente. Los resultados aún no se han ejecutado.

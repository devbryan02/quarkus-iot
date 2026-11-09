# Kivo — Especificación central del MVP

Fecha: 2026-11-08. Estado: **aprobada por el propietario como base del MVP**, incluida la adopción de P-01 a P-11 como decisiones de diseño. Aprobación registrada por instrucción explícita en esta conversación. Los detalles técnicos expresamente abiertos en las secciones 9 y 10 requieren refinamiento antes de su implementación; esta aprobación no acredita funcionamiento ni autoriza despliegue a producción.

## 1. Propósito y fuentes

Kivo permite al personal de un colegio consultar la última ubicación reportada por teléfonos Android durante sesiones autorizadas, detectar salidas de geocercas circulares asignadas y reconocer solicitudes SOS. El objetivo de esta versión es demostrar y verificar estos comportamientos con datos ficticios.

Esta especificación reúne los acuerdos del refinamiento y los requisitos verificables. Los detalles se mantienen en sus documentos especializados:

| Tema | Fuente |
|---|---|
| Arquitectura y límites Android | [Arquitectura general](../../../arquitecture/01-overview.md) |
| Infraestructura y operación | [Despliegue](../../../arquitecture/02-deployment.md) |
| Decisiones arquitectónicas | [ADR](../../../arquitecture/03-decisions.md) |
| Roles y pantallas | [Diseño funcional](../../../desing/01-product-ui.md) |
| Entidades y persistencia | [Modelo de datos](../../../desing/02-data-model.md) |
| REST, SSE y Kafka | [Contratos](../../../desing/03-api-contract.md) |
| Telemetría | [Flujo de telemetría](../../../flows/01-telemetry.md) |
| Geocercas | [Flujo de geocerca](../../../flows/02-geofence.md) |
| Sesiones y SOS | [Flujo de sesiones y SOS](../../../flows/03-sos-session.md) |
| Referencias visuales | [Pantallas de Stitch](../../../desing/04-stitch-screens.md) |

**Convención:** “acordado” identifica decisiones elegidas durante el refinamiento o ya documentadas en la base; “propuesta” conserva el origen de recomendaciones del redactor, adoptadas con la aprobación de este documento. Los identificadores P-01 a P-11 se conservan para trazabilidad. Si una fuente contradice estos acuerdos, debe actualizarse antes de implementar. Las exportaciones de Stitch son referencias visuales y pueden representar estados anteriores.

## 2. Alcance, objetivos y exclusiones

### Objetivos

- Demostrar vinculación administrada y control de sesiones desde Android y el colegio.
- Presentar ubicación, antigüedad y precisión sin afirmar posición exacta en vivo.
- Evaluar salidas de zonas asignadas sin confundir desconexión con salida.
- Distinguir SOS pendiente, recepción durable por servidor y reconocimiento del operador.
- Verificar autorización, idempotencia, recuperación de lectura y borrado por retención.

### Alcance acordado

Un colegio, identidades y coordenadas ficticias, cinco pantallas web y dos Android. Dashboard Next.js + PrimeReact + mapcn; Android Flutter/Dart; Quarkus con Java 21, Kafka y Kafka Streams; PostgreSQL con Flyway y Redis como caché. Docker Compose en un VPS, sin alta disponibilidad.

### Fuera del MVP

Múltiples colegios, hardware dedicado, app iOS, PWA como cliente de seguimiento, polígonos, visualización de rutas históricas, llamadas automáticas a emergencias y garantías de atención inmediata. Un piloto con estudiantes reales exige revisión posterior de consentimiento, responsabilidades, acceso, retención y borrado.

### Resultados inaceptables

Capturar ubicaciones fuera de una sesión, salvo la ubicación puntual de un SOS solicitado; exponer ubicaciones a usuarios no autorizados; marcar un SOS como recibido sin persistencia; mostrar una posición antigua como actual; iniciar rastreo continuo al enviar SOS; afirmar atención humana solo por un acuse técnico.

## 3. Enfoques considerados

| Enfoque | Ventaja | Costo |
|---|---|---|
| **Spec central enlazada — elegido** | Una entrada para acuerdos y aceptación; reutiliza la base | Requiere mantener alineadas las fuentes |
| Specs por módulo | Revisión independiente de cada dominio | Más documentos y referencias para un único MVP |

Se eligió la spec central por el alcance acotado. No se replantea el stack ni se agregan módulos de producto ajenos a la base.

## 4. Roles y autorización

| Acción | Administrador escolar | Operador | Teléfono vinculado |
|---|---|---|---|
| Gestionar estudiantes ficticios, usuarios y teléfonos | Sí | No | No |
| Generar código y habilitar vinculación | Sí | No | Canjear su código |
| Configurar geocercas y asignarlas | Sí | No | No |
| Consultar ubicaciones y alertas | Sí | Sí | Solo su estado local |
| Iniciar sesión GPS | No desde dashboard | No desde dashboard | Sí, estando habilitado |
| Detener sesión | Sí | Sí | Solo la propia |
| Reconocer alerta | Sí | Sí | No |
| Enviar SOS | No | No | Sí, incluso sin sesión GPS |

La administración gestiona configuración y el operador monitorea y reconoce alertas, según la base. El acceso del administrador a funciones operativas fue propuesto en P-02 y queda adoptado con la aprobación de esta matriz de permisos.

El teléfono usa una credencial limitada a su identidad. Vincularlo no inicia una sesión ni concede permisos del sistema Android. Habilitación técnica no equivale a consentimiento para un piloto real.

## 5. Requisitos y reglas de negocio

| ID | Requisito |
|---|---|
| RF-01 | El administrador selecciona un estudiante ficticio y genera un código temporal de un solo uso para vincular el teléfono. No se exige cuenta al estudiante. |
| RF-02 | El canje válido entrega una credencial de dispositivo; un código vencido, usado o inválido no habilita otro teléfono. El consumo y la vinculación deben ser atómicos. |
| RF-03 | Un teléfono habilitado inicia y detiene su sesión; administrador y operador pueden finalizarla. Duración máxima configurable, inicialmente **8 horas**. |
| RF-04 | El seguimiento continúa durante una sesión con pantalla bloqueada u otra app visible, sujeto a permisos y restricciones Android y con notificación de seguimiento. |
| RF-05 | Capturar y enviar telemetría únicamente durante la sesión autorizada. Rechazar credenciales ajenas, sesiones cerradas o vencidas y posiciones inválidas. |
| RF-06 | Al perder red, conservar solo la posición pendiente más reciente y los SOS pendientes. Reintentar; descartar la posición pendiente al terminar su sesión. |
| RF-07 | Mostrar última ubicación reportada, hora, precisión y estado de comunicación. Al reconectar SSE, recuperar el estado por REST. |
| RF-08 | El administrador asigna geocercas circulares a cada dispositivo. Evaluar cada zona por separado e identificar la zona en cada alerta. |
| RF-09 | Emitir `ZONE_EXIT` solo tras transición confirmada dentro → fuera. Inicializar estado sin alerta de salida; precisión insuficiente mantiene el estado previo como incierto. |
| RF-10 | Permitir SOS desde teléfonos vinculados y habilitados con o sin sesión GPS; no iniciar seguimiento continuo. Adjuntar ubicación puntual si está disponible y autorizada, sin bloquear el envío esperando GPS. |
| RF-11 | Persistir SOS de forma idempotente antes de indicar recepción del servidor. Reconocer la alerta registra usuario y hora; reconocer no significa atender ni resolver. |
| RF-12 | Borrar ubicaciones a los **7 días** y alertas y auditoría a los **30 días**. No conservar copias de coordenadas en alertas o logs más allá de 7 días. |

### Vinculación y ciclo del teléfono

El código se genera asociado al estudiante; no contiene credenciales permanentes ni información personal visible. No registrar códigos o credenciales en logs. La expiración y la protección frente a intentos repetidos se proponen en la sección 9.

**Propuestas:** una asignación vigente por teléfono; un estudiante puede tener varios teléfonos de demo; el administrador puede revocar un teléfono y sus códigos pendientes, invalidando la credencial y finalizando su sesión. Reasignar requiere cerrar la asignación anterior y generar una nueva vinculación. Las ubicaciones antiguas no deben presentarse como si pertenecieran al nuevo estudiante.

### Sesiones y estados

El servidor es autoridad sobre inicio, expiración y finalización. Los estados del seguimiento son `INACTIVA`, `ACTIVA`, `PAUSADA` y `FINALIZADA`. La pausa indica un impedimento local de GPS o permisos; no extiende el vencimiento ni habilita capturas sin permiso. Una caída de red es un estado de comunicación separado y no implica salida de geocerca.

**Propuesta:** solo una sesión abierta por teléfono; repetir el inicio devuelve la sesión existente. Al restablecer GPS y permisos, reanudar solo si la sesión sigue autorizada. Consultar el estado del servidor periódicamente para aplicar el cierre remoto; sin red, ese cierre no puede conocerse de inmediato. La app detiene localmente al alcanzar el vencimiento conocido y al recibir un cierre, descarta posiciones pendientes y el servidor rechaza telemetría posterior al cierre. No se promete detención remota instantánea sin conexión.

### Telemetría e idempotencia

Cada evento conserva `eventId`, `deviceId`, `sessionId`, `recordedAt`, coordenadas y precisión. El servidor comprueba la relación entre credencial, dispositivo y sesión. Un reintento conserva el mismo `eventId`; no duplica persistencia ni alertas. Eventos antiguos no reemplazan la última posición ni alteran el estado actual de geocerca.

`202 Accepted` confirma publicación en Kafka para procesamiento; no confirma persistencia final ni visualización. PostgreSQL es fuente de verdad; la última posición durable permite reconstruir Redis. Kafka Streams mantiene su estado mediante changelog y no depende de Redis.

**Propuesta:** revalidar la sesión al procesar y descartar eventos que ya no sean elegibles tras su cierre, aunque la ingesta los haya aceptado antes. La aceptación asíncrona no garantiza que un evento llegue a aplicarse.

### Geocercas

Varias zonas asignadas se evalúan **independientemente**; no representan la unión de un área segura. Si un teléfono sale de A y sigue dentro de B, puede generarse una salida de A. No evaluar zonas inactivas ni no asignadas. Un teléfono sin zonas puede enviar telemetría y SOS, pero no genera alertas de zona.

**Propuesta:** cada sesión nueva reinicializa los estados de zona del dispositivo; su primera posición confiable establece dentro/fuera sin alerta de salida. No comparar con una posición de una sesión anterior ni alertar por un desplazamiento ocurrido fuera del monitoreo. Cambiar centro, radio o asignación reinicializa el estado de la zona afectada sin producir una salida artificial. Versionar la configuración y conservar el resto de estados de la sesión. Los parámetros antirruido de la sección 9 siguen pendientes de validación.

### SOS y comunicación

Estados Android: `ENVIANDO`, `ENVIADO_SIN_ACUSE`, `RECIBIDO_POR_SERVIDOR`, `ERROR_REINTENTAR`. Un timeout deja recepción desconocida y exige reintentar con el mismo `eventId`. La persistencia durable permite confirmar recepción incluso si luego falla Kafka o SSE; el dashboard recupera alertas por REST.

**Propuesta:** estados de alerta `PENDIENTE` y `RECONOCIDA`; no incluir una acción “Atender” o “Resolver” en esta versión. Reconocimiento repetido conserva el primer usuario y fecha. No enviar de nuevo un SOS ya confirmado por el servidor.

El SOS pendiente puede reintentarse tras terminar la sesión GPS, siempre que el teléfono siga habilitado. No capturar nuevas ubicaciones para esos reintentos. Mostrar la hora original para no confundir una solicitud retrasada con una nueva. La caducidad y el límite de la cola se proponen en la sección 9.

Texto de interfaz: **“SOS solicita ayuda; no llama a emergencias ni garantiza atención inmediata.”**

## 6. Interfaces y persistencia

El [contrato REST](../../../desing/03-api-contract.md) distingue acuerdos y propuestas. Añade código de vinculación, canje sin credencial previa, consulta de sesión propia y asignación de zonas. La finalización remota reutiliza el cierre existente. El canje es la excepción a la autenticación previa del dispositivo: exige código temporal válido y controles de intentos.

La telemetría incorpora `sessionId` para impedir que una posición pendiente se atribuya a una sesión posterior. SOS admite `sessionId` y ubicación opcionales. Los cambios de esquema son diseños; no se crean migraciones ejecutables en esta entrega.

El [modelo de datos](../../../desing/02-data-model.md) incorpora vinculación temporal, habilitación, vencimiento de sesión, asignaciones de zona y trazabilidad SOS. No guardar credenciales en texto plano. La retención alcanza históricos, snapshots, Redis, colas locales, Kafka y copias de datos sensibles; las propuestas operativas se indican en la sección 9.

## 7. Pantallas

Se conservan login, dashboard, dispositivos, geocercas, alertas, vinculación Android y principal Android. Agregar estados de código temporal, sesión vencida/cerrada remotamente, zonas asignadas, SOS sin sesión y recepción desconocida. No crear cuentas de estudiantes ni pantallas de rutas.

Las exportaciones existentes de Stitch no se modifican en esta entrega. Los textos que presentan la vinculación como pendiente deben sustituirse por el contrato acordado cuando se adapte la interfaz para implementación.

## 8. Criterios de aceptación y trazabilidad

Estos escenarios describen validaciones futuras del producto; **no son pruebas ejecutadas**. Los valores de P-01 a P-11 quedan adoptados como base de diseño con esta aprobación; las verificaciones en campo y los mecanismos técnicos abiertos siguen siendo trabajo posterior.

| ID | Requisitos | Escenario y resultado esperado |
|---|---|---|
| CA-01 | RF-01, RF-02 | Código válido: vincula al estudiante elegido una sola vez; canjes simultáneos no habilitan dos teléfonos. |
| CA-02 | RF-02 | Código inválido, vencido o reutilizado: rechazo sin entregar credencial. |
| CA-03 | RF-03, RF-05 | Credencial ajena o teléfono no habilitado: no iniciar sesión ni enviar ubicación o SOS autorizado. |
| CA-04 | RF-03 | Android inicia y detiene; el personal escolar finaliza; al vencer el máximo la app deja de capturar y el servidor deja de aceptar posiciones. |
| CA-05 | RF-04 | En teléfono Android real, pantalla bloqueada y cambio de app mantienen reportes durante sesión, con notificación visible; documentar restricciones observadas. |
| CA-06 | RF-04, RF-05 | Permiso revocado o GPS desactivado: estado pausado, sin afirmar ubicación actual; restablecer no revive sesión cerrada. |
| CA-07 | RF-05, RF-06 | Caída de red: sustituir posiciones pendientes; al reconectar enviar solo la última elegible con su `sessionId`; al cerrar descartarla. |
| CA-08 | RF-05, RF-09 | Duplicados y eventos fuera de orden no duplican alertas ni retroceden snapshots o estado de zona. |
| CA-09 | RF-07 | SSE interrumpido y Redis vacío: recuperar snapshots/alertas por REST desde persistencia, conservando hora y precisión. |
| CA-10 | RF-08, RF-09 | Evaluar solo zonas activas asignadas; dos zonas se evalúan por separado. Primera posición confiable de cada sesión y cambios de configuración no generan salida artificial; terminar dentro e iniciar otra sesión fuera no emite salida por el intervalo sin monitoreo. |
| CA-11 | RF-09 | Mala precisión o falta de comunicación no producen `ZONE_EXIT`; una transición confiable confirmada genera una sola alerta identificando zona. |
| CA-12 | RF-10 | SOS con sesión inactiva y sin permiso GPS: enviar sin ubicación y sin iniciar rastreo continuo. |
| CA-13 | RF-06, RF-11 | SOS sin red o con timeout: no mostrar recibido; reintentar con mismo `eventId` crea una sola alerta, incluso si la respuesta anterior se perdió. |
| CA-14 | RF-11 | Falla de BD impide confirmar recepción SOS; falla posterior de Kafka/SSE no elimina el SOS durable, que es consultable por REST. |
| CA-15 | RF-11 | Reconocer registra usuario/hora y muestra reconocida; repetir no afirma atención ni duplica el reconocimiento. |
| CA-16 | RF-12 | Con reloj de prueba, eliminar coordenadas al cumplir 7 días y alertas/auditoría al cumplir 30; verificar que snapshots, caché y copias no permitan recuperarlas tras su plazo. |
| CA-17 | RF-03, RF-05 | Cierre remoto sin red: no prometer recepción inmediata; al sincronizar detener y rechazar posiciones de la sesión cerrada. |

## 9. Decisiones técnicas adoptadas y refinamientos abiertos

P-01 a P-11 fueron recomendaciones del redactor y el propietario las adopta al aprobar esta spec. La columna de refinamiento conserva las tareas aún necesarias para concretar y validar los mecanismos; aprobar el diseño no equivale a resolver esos detalles ni a verificar el producto.

| ID | Decisión adoptada | Motivo / refinamiento técnico abierto |
|---|---|---|
| P-01 | Código aleatorio de 8 dígitos, 10 minutos, almacenado mediante hash protegido; máximo 5 intentos por origen en 10 minutos y límite global configurable | Concretar expiración, protección frente a enumeración y recuperación; validar suficiencia de controles antes de implementación |
| P-02 | Una asignación vigente por teléfono; revocación administrativa; administrador con permisos operativos | Confirmar cardinalidad, reasignación, revocación y matriz de roles de las secciones 4 y 5 |
| P-03 | Reportar GPS cada 10 s; consultar estado de sesión cada 15 s cuando hay red; antigüedad de captura máxima 60 s; tolerancia futura 30 s | Definir carga, consumo, cierre remoto y ventana temporal usando hora de captura y de recepción por separado |
| P-04 | Comunicación reciente hasta 30 s; desactualizada entre 30 y 60 s; sin comunicación después de 60 s | Mantener estados separados de GPS y sesión; usar última comunicación autenticada, no una posición antigua reenviada |
| P-05 | Precisión aceptable hasta 50 m; histéresis de 20 m y 2 mediciones confiables consecutivas | Los valores de la base son ejemplos; ajustar con pruebas. Validar radio mínimo compatible con la banda de histéresis |
| P-06 | Reintentos a 2, 5, 10 y luego cada 30 s; persistir SOS pendientes en almacenamiento protegido, máximo 100 y 24 h; al llenar o vencer informar error visible, sin expulsión silenciosa | Concretar comportamiento tras reiniciar Android y ante solicitudes muy retrasadas; mantener hora original y prioridad SOS |
| P-07 | SOS durable sincrónico con `201`; duplicado con `200`; Kafka/SSE posteriores no condicionan recepción; alertas solo pendientes/reconocidas | Cerrar semántica API, sincronización de alertas y reconocimiento idempotente; REST recupera fallas de notificación, sin promesa de aviso inmediato |
| P-08 | Sesión única abierta; revalidar antes de aplicar telemetría; reinicializar geocerca al iniciar sesión y tras editar/asignar | Aprobar reglas de concurrencia, cierre frente a eventos en vuelo y actualización de estado |
| P-09 | Usar reloj servidor UTC; ubicación expira desde `recordedAt`, alerta desde `triggeredAt`, auditoría desde su creación; depurar cada hora y excluir vencidos de toda lectura inmediatamente | Definir borrado físico frente a vencimiento lógico; filas de alerta pueden durar 30 días, sus coordenadas no más de 7 |
| P-10 | Kafka con retención de ubicaciones no mayor de 7 días y alertas no mayor de 30; cifrar copias y definir expiración y saneamiento al restaurar | El borrado debe abarcar segmentos, changelogs, réplicas y backups; el mecanismo exacto y su verificación son bloqueantes antes de aprobar retención física |
| P-11 | Detalles REST, SSE y entidades marcados como propuestas en los documentos especializados | Revisar códigos, cuerpos, paginación y sincronización de alertas; no confundir diseño de contrato con servicio existente |

No hay objetivo numérico acordado de teléfonos concurrentes, latencia o recuperación. La demo no promete capacidad o disponibilidad de producción; un piloto requiere fijarlos y medirlos.

## 10. Qué queda al implementador y revisión

Con la spec aprobada, el implementador puede elegir organización de paquetes, bibliotecas compatibles, pruebas y mecanismos Android dentro del stack acordado. No puede cambiar autorización, retención, alcance SOS o criterios de aceptación sin actualizar esta spec. Autenticación web, ciclo de credenciales del dispositivo, biblioteca Android y estrategia operativa de borrado requieren un diseño técnico posterior; no se consideran resueltos por esta aprobación.

La entrega documental valida enlaces locales, JSON, Mermaid y consistencia entre fuentes; no acredita comportamiento Android, seguridad implementada ni rendimiento. Una revisión independiente comprueba omisiones y contradicciones antes de entregar el borrador. No se crean aplicaciones, dependencias, infraestructura o cambios remotos en Stitch.

### Registro de revisión del borrador

La revisión independiente identificó el riesgo de comparar posiciones de sesiones diferentes y emitir una salida por movimiento sin monitoreo autorizado. Se incorporó a P-08 la propuesta de reinicializar el estado por sesión y se amplió CA-10. El ajuste quedó adoptado posteriormente con la aprobación del documento por el propietario.

### Gestión del repositorio

Remoto autorizado: `git@github.com:devbryan02/quarkus-oit.git`. El avance se publica en `develop`. La integración y publicación en `main` se realizarán en una etapa posterior, cuando el producto funcione y se hayan completado las validaciones correspondientes; no forman parte de esta publicación documental.

La comprobación documental incluyó resolución de enlaces relativos, análisis JSON de ejemplos, identificación de RF/CA/P y renderizado de los nueve diagramas Mermaid con Mermaid CLI 12.2.0 y Edge headless. Los archivos de renderizado son temporales, fuera del repositorio. Se corrigió un separador de mensaje inválido en la secuencia de telemetría detectado al renderizar. No se ejecutaron pruebas de aplicación: aún no existe código de producto.

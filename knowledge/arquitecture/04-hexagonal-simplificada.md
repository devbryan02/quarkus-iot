# Arquitectura hexagonal simplificada de Kivo

## Propósito y alcance

Kivo adopta una arquitectura hexagonal ligera dentro del monolito modular Quarkus y una separación equivalente en los clientes. Organizar por funcionalidad y separar las reglas que merecen pruebas de los detalles de entrada/salida. La [especificación central](../../codebase/backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md) conserva la autoridad sobre requisitos, permisos y retención.

Esta guía define la organización del desarrollo futuro. Los ejemplos REST generados y el esqueleto Flutter no implementan todavía los casos de uso del MVP. No requiere convertir cada clase en una interfaz ni crear módulos Maven o paquetes vacíos para cumplir un patrón.

## Regla práctica de dependencias

Una entrada (REST, consumidor Kafka, tarea programada o widget) delega el caso de uso a un servicio/controlador de aplicación. Este aplica reglas y usa adaptadores para persistencia, red, reloj o plataforma. Las reglas de geocerca, elegibilidad temporal y reintentos deben poder probarse sin arrancar HTTP, una base de datos o un teléfono.

| Elemento | Responsabilidad | Ejemplos |
|---|---|---|
| Entrada | Autenticar, convertir y validar formato; delegar | `SessionResource`, `TelemetryResource`, pantalla Flutter |
| Aplicación | Coordinar autorización de negocio, transacción y secuencia | `SessionService`, `SosService`, `MonitoringController` |
| Dominio | Reglas de estado y valores, sin transporte ni almacenamiento | `ZoneEvaluator`, vencimiento, `RetrySchedule` |
| Puerto | Contrato pequeño en una frontera que necesitamos sustituir | `LocationPort`, repositorio, reloj, publicador |
| Adaptador | Hablar con la herramienta concreta | PostgreSQL, Kafka, Redis, HTTPS, Keystore y ubicación Android |

El dominio no importa recursos REST, Hibernate, Kafka, widgets o plugins. Los adaptadores dependen de los contratos del caso de uso; las reglas no conocen la implementación concreta. Los servicios pueden usar CDI y `@Transactional`: se permite ese acoplamiento consciente al framework en la capa de aplicación.

## Backend: paquetes por funcionalidad

Ejemplo orientativo al implementar sesiones:

```text
pe/kivo/sessions/
  SessionResource.java       # adaptador REST de entrada
  SessionService.java        # caso de uso y transacción
  SessionPolicy.java         # reglas puras, si justifican extraerse
  MonitoringSession.java     # modelo de negocio
  SessionRepository.java     # acceso durable; contrato solo si hace falta
```

Mantener `identity`, `devices`, `sessions`, `telemetry`, `geofences`, `alerts`, `monitoring` y `retention` como funcionalidades. Al crecer una, extraer subpaquetes `domain`, `application` y `adapters` dentro de ella; no crear tres árboles globales que separen todos los archivos de una misma funcionalidad. Las rutas exactas iniciales están en el [plan backend](../../codebase/backend/docs/superpowers/plans/2026-11-08-kivo-backend-implementation-plan.md).

Una interfaz se justifica si permite aislar infraestructura en pruebas del caso de uso, si hay implementaciones distintas, o si protege un límite entre funcionalidades. No exigir pares `Service`/`ServiceImpl`, `Repository`/`RepositoryImpl`, puertos de entrada para cada método o mappers sin transformación real. Un repositorio concreto puede ser suficiente para CRUD sencillo, verificado contra PostgreSQL en integración.

En CRUD simple, una entidad JPA puede permanecer dentro de su funcionalidad sin modelo duplicado. No exponerla por REST: usar DTOs del contrato. Extraer modelos puros cuando las reglas necesiten independencia del ORM, especialmente el evaluador de geocercas. `shared` se limita a utilidades transversales justificadas, como el reloj; no es un depósito de lógica de negocio.

## Flujos que la separación debe preservar

- Telemetría: entrada autorizada → confirmación de publicación Kafka (`202`) → consumidor que revalida sesión → persistencia idempotente y snapshot. Un `202` no confirma almacenamiento final.
- SOS: entrada de dispositivo habilitado → transacción PostgreSQL → acuse durable (`201`, duplicado `200`) → Kafka/SSE posteriores. Una falla posterior de notificación no revierte la recepción.
- Geocercas: adaptador Streams → evaluador puro por sesión/zona/versiones → salida con identidad estable → persistencia idempotente. El estado Streams se recupera con changelog, sin depender de Redis.
- Lecturas: consulta autorizada con retención inmediata → caché recuperable desde PostgreSQL. Redis no decide identidad, retención ni autoridad de sesión.

Los adaptadores no modifican estas garantías. Los límites de transacción, concurrencia y recuperación entre Kafka y PostgreSQL deben concretarse en los diseños técnicos B1/B9; la forma hexagonal no aporta atomicidad distribuida por sí sola.

## Frontend y Android

En Next.js, mantener `src/features/<funcionalidad>/`: componentes de presentación, hooks/controladores y acceso al cliente tipado. Los componentes no redefinen reglas de autorización ni evalúan geocercas. Extraer lógica de comunicación, reconexión y descarte de respuestas obsoletas a funciones/controladores comprobables. No añadir una interfaz por componente o hook.

En Flutter, mantener `lib/features/<funcionalidad>/` y crear puertos para capacidades externas con efectos: ubicación, almacenamiento protegido, reloj y API. Los widgets presentan estado y acciones; el controlador coordina sesión, permisos y cola. Los plugins Android quedan detrás del adaptador correspondiente. No crear esos paquetes antes de implementar el caso de uso: el esqueleto inicial solo compone la aplicación y una pantalla de arranque.

## Pruebas y criterio de revisión

Probar reglas puras con tests rápidos de límites, estados y orden de eventos. Probar casos de uso con sustitutos de fronteras cuando aporten valor. Probar SQL, restricciones, REST, Kafka y caché con integración real; un mock no demuestra atomicidad, retención física ni recuperación de Streams. El seguimiento con pantalla bloqueada requiere Android real.

Aceptar una simplificación si reduce archivos sin mezclar transporte con una regla crítica y conserva pruebas claras. Extraer una frontera cuando un cambio de plugin, transporte o almacenamiento obligue a cambiar reglas de negocio, o cuando un test de una regla pura necesite infraestructura. No añadir un framework de arquitectura ni comprobaciones automáticas hasta que exista código suficiente para justificarlo.

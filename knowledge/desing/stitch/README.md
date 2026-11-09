# Pantallas generadas de Kivo

Referencia histórica de exportaciones. La [spec central](../../../codebase/backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md) incorpora acuerdos posteriores: código temporal, sesiones con máximo configurable inicial de 8 horas, asignación de zonas y SOS sin sesión. No se regeneraron estos HTML/PNG/JSON ni el proyecto remoto; los estados anteriores de vinculación pendiente no definen el contrato actual.

Proyecto privado: [Kivo MVP - Dashboard y Android Flutter](https://stitch.withgoogle.com/projects/1713403711180977197).

Abrir [la galeria local](index.html) para comparar las siete pantallas. Son propuestas visuales con datos ficticios, sin conexion al backend.

| Archivo | Vista HTML | Imagen | ID de pantalla en Stitch |
|---|---|---|---|
| 01-login | [Kivo Escolar — Inicio de Sesión](01-login.html) | [PNG](01-login.png) | `8f0fe3b164c3485cab4d34f8e9e0fd70` |
| 02-dashboard | [Kivo Escolar — Dashboard de Monitoreo](02-dashboard.html) | [PNG](02-dashboard.png) | `38422650a9b04c1786d8fa895554f25b` |
| 03-dispositivos | [Kivo Escolar — Dispositivos GPS](03-dispositivos.html) | [PNG](03-dispositivos.png) | `ce6f0003845841c4999f269f83459ccd` |
| 04-geocercas | [Kivo Escolar — Geocercas Escolares](04-geocercas.html) | [PNG](04-geocercas.png) | `f5e8403da1954e8dba889c45c8ae2b44` |
| 05-alertas | [Kivo Escolar — Historial de Alertas](05-alertas.html) | [PNG](05-alertas.png) | `81281a7a159546c19b26d050571af98a` |
| 06-vinculacion | [Kivo Móvil — Vinculación y Permisos](06-vinculacion.html) | [PNG](06-vinculacion.png) | `4a9ed77c3c5d46dfa9b2d411997c349c` |
| 07-android-principal | [Kivo Móvil — Principal (Sesión y SOS)](07-android-principal.html) | [PNG](07-android-principal.png) | `c9e646582861465fba33bd62d4e22b11` |

## Procedencia y revision

Las siete pantallas se generaron mediante el MCP de Stitch. Los JSON numerados del 01 al 07 conservan los metadatos de cada pantalla. Las revisiones estan registradas en `08-revision-web.json` y `09-revision-android.json`.

Stitch devolvio la revision web como operaciones sobre el DOM, sin actualizar sus archivos de exportacion. Esas operaciones se aplicaron al HTML local: `revision-local.json` registra las coincidencias. La version local contiene estas correcciones; el archivo original remoto puede diferir. Las dos pantallas Android usan los nuevos disenos devueltos por la revision, con ajustes locales de ancho y del control SOS de demostracion para asegurar su visibilidad.

Las imagenes PNG locales se renderizaron desde los HTML mediante Chrome, para representar la version entregada. Los HTML pueden cargar estilos, iconos o fuentes externas y requerir Internet. Son referencias para adaptar a PrimeReact y mapcn en web, y Flutter en Android; no son aplicaciones implementadas.

Se revisaron vinculacion pendiente sin QR ni codigos inventados, sesiones autorizadas, estados de comunicacion, ultima ubicacion reportada, geocercas circulares y SOS sin llamadas automaticas. Los controles de simulacion son ayudas de la propuesta visual. Los detalles visuales y textos siguen sujetos a revision de producto antes de implementar.

No se guardaron claves API en esta carpeta. La configuracion MCP pertenece al archivo de usuario de Codex, fuera del repositorio.

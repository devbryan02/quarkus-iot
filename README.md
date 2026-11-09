# Kivo — Documentación del MVP

MVP para **un colegio**, utilizando teléfonos con GPS como dispositivos de prueba. No incluye Kubernetes ni hardware dedicado.

## Contenido

- [**Especificación central de Kivo**](docs/superpowers/specs/2026-11-08-kivo-mvp-design.md): base aprobada del MVP, requisitos y criterios de aceptación; distingue decisiones adoptadas de refinamientos técnicos abiertos.
- [`arquitecture/`](arquitecture/): arquitectura, stack, despliegue y decisiones.
- [`flows/`](flows/): flujos de telemetría, geocercas, SOS y sesiones.
- [`desing/`](desing/): diseño funcional, pantallas, contratos y modelo de datos.
- [`codebase/`](codebase/README.md): esqueletos Quarkus y Next.js, Dockerfiles, Compose local y comandos de desarrollo.

Los diagramas están escritos en **Mermaid** dentro de Markdown, compatibles con GitHub y editores con soporte Mermaid.

## Stack y diseño

- **Dashboard web:** Next.js, PrimeReact y mapcn.
- **App Android:** Flutter con Dart e interfaz mínima; envío de ubicación durante sesiones autorizadas, incluso con pantalla bloqueada o al usar otra aplicación.
- **Backend:** Quarkus LTS con Java 25 LTS; Kafka y Kafka Streams previstos por la arquitectura.
- **Datos:** PostgreSQL con migraciones Flyway; Redis como caché.
- **Pantallas y flujos:** Google Stitch, con PrimeReact como referencia del dashboard.

El repositorio contiene documentación de diseño y los esqueletos compilables de backend y frontend en `codebase/`. Las funcionalidades del MVP, las integraciones de datos y la app Android aún no están implementadas. El Compose disponible es local; no representa el despliegue de producción.

## Flujo de Git

Remoto: `git@github.com:devbryan02/quarkus-oit.git`. Publicar los avances en `develop`; integrar a `main` en una etapa posterior, cuando el producto funcione y se completen sus validaciones. La aprobación de la spec no significa que el sistema esté implementado o probado.

> **Límite importante:** el seguimiento Android depende de permisos, disponibilidad de GPS, conectividad y restricciones del sistema; debe validarse en teléfonos reales. Para pruebas con menores se requiere consentimiento y controles de privacidad; usar datos ficticios en las demos iniciales.

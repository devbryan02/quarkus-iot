# Kivo — Documentación del MVP

MVP para **un colegio**, utilizando teléfonos con GPS como dispositivos de prueba. No incluye Kubernetes ni hardware dedicado.

## Contenido

- [**Especificación central de Kivo**](codebase/backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md): base aprobada del MVP, requisitos y criterios de aceptación; distingue decisiones adoptadas de refinamientos técnicos abiertos.
- [`knowledge/`](knowledge/README.md): índice de la documentación compartida y las reglas del proyecto.
- [`knowledge/arquitecture`](knowledge/arquitecture/): arquitectura, stack, despliegue y decisiones.
- [`knowledge/flows`](knowledge/flows/): flujos de telemetría, geocercas, SOS y sesiones.
- [`knowledge/desing`](knowledge/desing/): diseño funcional, pantallas, contratos y modelo de datos.
- [`codebase/`](codebase/README.md): esqueletos Quarkus, Next.js y Flutter Android, Dockerfiles, Compose local y comandos de desarrollo.
- [`knowledge/rules`](knowledge/rules/README.md): reglas persistentes de trabajo, Gitflow y revisión de cambios.

Los diagramas están escritos en **Mermaid** dentro de Markdown, compatibles con GitHub y editores con soporte Mermaid.

## Estructura

```text
knowledge/
  arquitecture/
  desing/
    stitch/
  flows/
  rules/
codebase/
  backend/
    docs/superpowers/specs/
    docs/superpowers/plans/
  frontend/
    docs/superpowers/specs/
    docs/superpowers/plans/
  mobile/
    docs/superpowers/specs/
    docs/superpowers/plans/
  compose.yaml
```

La documentación compartida vive en `knowledge/`, la spec central en `codebase/backend/docs/` y los comandos de ejecución en [codebase/README.md](codebase/README.md).

## Stack y diseño

- **Dashboard web:** Next.js, PrimeReact y mapcn.
- **App Android:** Flutter con Dart e interfaz mínima; envío de ubicación durante sesiones autorizadas, incluso con pantalla bloqueada o al usar otra aplicación.
- **Backend:** Quarkus LTS con Java 25 LTS; Kafka y Kafka Streams previstos por la arquitectura.
- **Datos:** PostgreSQL con migraciones Flyway; Redis como caché.
- **Pantallas y flujos:** Google Stitch, con PrimeReact como referencia del dashboard.

El repositorio contiene documentación de diseño y esqueletos de backend, frontend y Flutter Android en `codebase/`. Las funcionalidades del MVP y las integraciones de datos aún no están implementadas. La app móvil solo muestra una pantalla de arranque; los requisitos de SDK y dispositivo están en su [setup](codebase/mobile/README.md). El Compose disponible es local; no representa el despliegue de producción.

## Flujo de Git

Remoto: `git@github.com:devbryan02/quarkus-iot.git`. Trabajar en `feature/<funcionalidad>` y avisar antes de cada push. Integrar siempre mediante MR/PR a `develop`, aceptada por el propietario; no hacer push directo ni merge automático. Ver [reglas de Gitflow](knowledge/rules/01-gitflow.md).

La promoción a `main` queda para una etapa posterior, por instrucción explícita del propietario, cuando el producto funcione y se completen sus validaciones. La aprobación de la spec no significa que el sistema esté implementado o probado.

> **Límite importante:** el seguimiento Android depende de permisos, disponibilidad de GPS, conectividad y restricciones del sistema; debe validarse en teléfonos reales. Para pruebas con menores se requiere consentimiento y controles de privacidad; usar datos ficticios en las demos iniciales.

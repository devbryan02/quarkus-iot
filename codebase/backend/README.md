# Kivo — Backend

Esqueleto generado con el plugin Maven oficial de Quarkus 3.40.1.1 LTS. Requiere Java 25 LTS; Maven Wrapper fija Maven 3.9.16. Incluye REST Jackson, SmallRye Health y el ejemplo técnico `/hello`, con sus pruebas generadas. No implementa los contratos de negocio ni integra todavía PostgreSQL, Kafka o Redis.

La [spec central de Kivo](docs/superpowers/specs/2026-11-08-kivo-mvp-design.md) se encuentra en `docs/` de este proyecto y cubre el MVP completo. Arquitectura, diseño, flujos y reglas compartidos están en [`knowledge/`](../../knowledge/README.md).

Desde esta carpeta, en Windows:

```powershell
.\mvnw.cmd quarkus:dev
.\mvnw.cmd -B -ntp verify -DskipITs=false
```

En Linux/macOS usar `./mvnw` y tener `unzip` disponible para verificar la distribución ZIP con el checksum configurado. Health: `http://localhost:8080/q/health/ready`. Dev UI, solo en desarrollo: `http://localhost:8080/q/dev/`.

El Dockerfile de esta carpeta compila desde fuente y ejecuta el JAR con Java 25. Los Dockerfiles de `src/main/docker/` son referencias conservadas del generador, no validadas; requieren empaquetado previo y adaptar `.dockerignore` para incluir sus artefactos de `target/`. Consultar [setup y Compose](../README.md) y [guía oficial Quarkus](https://quarkus.io/guides/getting-started/).

# Kivo — Esqueletos de desarrollo

Todo el código y la configuración de contenedores están en esta carpeta. Incluye esqueletos backend, frontend y Android Flutter. No implementa autenticación, sesiones, telemetría, geocercas, SOS ni pantallas funcionales del MVP.

La documentación compartida está en [`knowledge/`](../knowledge/README.md). La [spec central aprobada](backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md), ubicada en la documentación del backend, define el alcance del MVP completo. Consultar también las [reglas de Gitflow](../knowledge/rules/01-gitflow.md).

## Planes de implementación del MVP

Cada proyecto usa `docs/superpowers/specs/` para diseños y especificaciones y `docs/superpowers/plans/` para planes de implementación. La spec central permanece en backend, sin copias divergentes. Los planes describen trabajo futuro; no acreditan funcionalidades ni pruebas ejecutadas. La [guía hexagonal simplificada](../knowledge/arquitecture/04-hexagonal-simplificada.md) orienta la organización por funcionalidad.

- [Backend: contratos, autorización, sesiones, telemetría, geocercas, SOS y retención](backend/docs/superpowers/plans/2026-11-08-kivo-backend-implementation-plan.md).
- [Frontend: cinco pantallas, administración, mapa y alertas](frontend/docs/superpowers/plans/2026-11-08-kivo-frontend-implementation-plan.md).
- [Android Flutter: vinculación, seguimiento autorizado y SOS](mobile/docs/superpowers/plans/2026-11-08-kivo-android-implementation-plan.md). El [setup móvil](mobile/README.md) describe el esqueleto y los requisitos para probarlo localmente.

Primero se cierran los contratos y diseños técnicos de la tarea B1 del backend; después los clientes pueden usar fixtures del contrato y finalmente integrarse contra servicios reales. Los planes mantienen la especificación central como autoridad y distinguen decisiones adoptadas de mecanismos técnicos aún abiertos.

## Versiones y generación

- Backend: Java **25 LTS**, Quarkus **3.40.1.1 LTS**, Maven Wrapper **3.9.16**. Generador oficial `io.quarkus.platform:quarkus-maven-plugin:3.40.1.1:create`, extensiones `rest-jackson,smallrye-health` y `javaVersion=25`.
- Frontend: `npx create-next-app@latest frontend --ts --eslint --app --src-dir --no-tailwind --use-npm --import-alias "@/*" --empty --disable-git --no-agents-md --no-agent-feedback --yes`. Next.js **16.4.5**, React **19.3.0**, Node **24 LTS** y npm **12.2.2** durante la generación. Conservar `package-lock.json` y usar `npm ci`.
- Android: Flutter **3.47.9 stable**, Dart **3.13.7** incluido. Generación oficial: `flutter create --empty --platforms=android --org pe.kivo --project-name kivo_mobile --description "Esqueleto Android de Kivo." --no-pub codebase/mobile` desde la raíz, seguida de `flutter pub get` dentro del proyecto. El identificador Android generado es `pe.kivo.kivo_mobile` y el nombre visible es **Kivo**. Conservar `pubspec.lock`; no regenerar para implementar funcionalidades. Ver [setup Android](mobile/README.md).
- Se usa CSS sin Tailwind para no añadir otro sistema visual antes de integrar PrimeReact. PrimeReact y mapcn aún no se instalan: pertenecen al desarrollo del dashboard.
- Seguridad npm: override limitado a `minimatch` versiones `>=7.0.0 <11.0.1`, fijado en **11.0.5**, por [GHSA-g3hv-75wg-m249](https://github.com/advisories/GHSA-g3hv-75wg-m249). Es una actualización mayor transitiva explícita: requiere Node 24 y se valida con instalación limpia, lint, TypeScript y build. No cambia las ramas antiguas de `minimatch` que usan APIs distintas. Retirar el override cuando los dependientes incorporen una versión corregida. Se conserva ESLint 9 del generador para compatibilidad de plugins; la migración a ESLint 10 se difiere hasta validar el conjunto de plugins.
- [Quarkus LTS](https://quarkus.io/releases/) y [generación oficial](https://quarkus.io/guides/getting-started/); [create-next-app](https://nextjs.org/docs/app/getting-started/installation) y [salida standalone](https://nextjs.org/docs/app/api-reference/config/next-config-js/output).

## Desarrollo local

Backend, desde `codebase/backend`:

```powershell
.\mvnw.cmd quarkus:dev
.\mvnw.cmd -B -ntp verify -DskipITs=false
```

En Linux/macOS usar `./mvnw`. El ejemplo técnico del generador está en `http://localhost:8080/hello` y health en `http://localhost:8080/q/health/ready`. No son contratos del MVP. El frontend no consume todavía al backend.

El wrapper verifica el SHA-256 de la distribución Maven ZIP. En Linux se requiere `unzip` para usar ese mismo archivo; el Dockerfile ya lo instala y no desactiva el checksum.

Frontend, desde `codebase/frontend`:

```powershell
npm ci
npm run dev
npm run lint
npx tsc --noEmit
npm run build
npm audit
```

Abrir `http://localhost:3000`. Para servir el build localmente usar `npm start`. Para comprobar vulnerabilidades solo de dependencias de producción usar `npm audit --omit=dev`; esta auditoría no cubre Java ni imágenes de contenedores.

## Docker Compose local

Android no forma parte de Compose. Desde `codebase/mobile`, validar con `flutter analyze` y `flutter test`; para ejecutar usar `flutter devices` y `flutter run -d <device-id>` tras instalar Android SDK y preparar teléfono/emulador. Las instrucciones completas están en el [README móvil](mobile/README.md).

Desde `codebase`, con Docker Desktop/Engine activo y Compose:

```powershell
Copy-Item .env.example .env
# Editar POSTGRES_PASSWORD en .env antes de iniciar.
docker compose config --quiet
docker compose up --build -d --wait
docker compose ps
docker compose down
```

Los Dockerfiles multietapa compilan desde código fuente; no requieren `target/` o `.next/` locales. Ejecutan las aplicaciones con usuarios sin privilegios. Backend y frontend se publican únicamente en `127.0.0.1`, puertos 8080 y 3000 configurables en `.env`. No copiar secretos al contexto de build.

Para incluir infraestructura opcional:

```powershell
docker compose --profile infra up --build -d --wait
docker compose --profile infra down
```

PostgreSQL 18, Redis 8 y Kafka 4.1.1 solo son accesibles en la red de Compose: `postgres:5432`, `redis:6379` y `kafka:9092`. No se exponen a Internet ni al host. Todavía no hay drivers, migraciones, consumidores o conexiones configurados en el backend. PostgreSQL y Kafka usan volúmenes; `down` los conserva. Redis es efímero.

Este Compose es **de desarrollo**, con un broker KRaft y sin TLS/autenticación entre servicios. Caddy, secretos de producción, copias, retención del MVP y alta disponibilidad no están implementados. Los tags de imágenes fijan la línea y reciben parches; reconstruir con `docker compose build --pull` y validar antes de actualizar. Los Dockerfiles de `backend/src/main/docker/` se conservan como referencias del generador y no se validaron; para usarlos hay que adaptar el contexto porque `.dockerignore` excluye `target/`. Compose usa únicamente `backend/Dockerfile`.

## Validación de esta entrega

Durante la creación del esqueleto se verificaron Maven con la prueba de integración del JAR, instalación limpia npm, lint, TypeScript, build de Next.js, construcción de ambas imágenes y arranque saludable de los cinco servicios de Compose. Las auditorías npm completa y de producción reportaron 0 vulnerabilidades en esa ejecución; no es una garantía sobre auditorías futuras ni cubre Java o imágenes. Las pruebas conservadas en backend son las generadas para `/hello`, no pruebas de requisitos del producto.

El plan histórico de creación se retiró al reorganizar las carpetas. Los comandos reproducibles permanecen en este README; las decisiones funcionales y sus límites están en la spec central.

En la entrega del esqueleto móvil se ejecutaron `flutter analyze` sin hallazgos y `flutter test` con una prueba de widget aprobada. El intento de `flutter build apk --debug` no compiló porque falta Android SDK en este equipo; `flutter doctor -v` lo confirmó y no detectó dispositivos Android. Eso no invalida las pruebas Dart, pero deja pendientes la compilación APK y la ejecución Android. No se han verificado GPS, SOS ni los criterios de aceptación del MVP.

# Repository Guidelines

## Project Structure & Module Organization

This repository contains the Kivo MVP documentation for one school and backend/frontend skeletons. Business features have not been implemented.

El nombre oficial del producto es **Kivo**. Usar este nombre en la documentación, las interfaces y las respuestas sobre el proyecto; mantener `kivo.` como prefijo de los tópicos Kafka.

Consultar la [especificación central](docs/superpowers/specs/2026-11-08-kivo-mvp-design.md) aprobada por el propietario para requisitos y criterios de aceptación. P-01 a P-11 se adoptan como base del diseño; distinguirlas de los refinamientos técnicos expresamente abiertos. La aprobación no acredita implementación ni validaciones de producto.

- `README.md`: scope, navigation, and operational limitations.
- `arquitecture/`: architecture overview, deployment topology, and architectural decisions.
- `desing/`: product screens, data model, REST contracts, and Kafka topics.
- `flows/`: Mermaid sequences for telemetry, geofences, SOS, and monitoring sessions.
- `codebase/backend/`: Quarkus 3.40.1.1 LTS, Java 25 LTS, Maven Wrapper, generated REST example and tests.
- `codebase/frontend/`: Next.js generated with create-next-app, TypeScript, App Router, ESLint and npm lockfile; Node 24 LTS.
- `codebase/compose.yaml`: local application containers and optional `infra` profile for PostgreSQL, Redis and Kafka. All future application projects belong under `codebase/`.

Preserve the existing directory spellings so links remain valid.

## Build, Test, and Development Commands

See [codebase setup](codebase/README.md) for full commands. Backend: from `codebase/backend`, run `.\mvnw.cmd -B -ntp verify -DskipITs=false` on Windows or `./mvnw -B -ntp verify -DskipITs=false` on Linux/macOS, with Java 25 LTS. Frontend: from `codebase/frontend`, run `npm ci`, `npm run lint`, `npx tsc --noEmit` and `npm run build`, with Node 24 LTS. Compose: copy `codebase/.env.example` to `.env` in the same folder, set a local password, then run `docker compose up --build -d --wait` from `codebase/`.

Useful inspection commands from the repository root:

- `rg --files`: list documentation files.
- `rg -n 'api/v1|telemetry|eventId' arquitecture desing flows`: compare related contracts and flows.

Preview Markdown in an editor with Mermaid support. When implementation begins, document actual setup, build, test, and run commands alongside the code.

## Documentation Style & Naming Conventions

Continue the existing Spanish documentation. Use descriptive Markdown headings, short paragraphs, tables for contracts, and fenced blocks labeled `mermaid` or `json`. Use two-space indentation in JSON examples and Mermaid statements, following nearby documents.

Name numbered documents with the existing pattern, such as `04-topic-name.md`. Keep field names such as `deviceId` and `recordedAt` consistent across examples. No formatter, linter, or application coding standard is configured.

## Validation Guidelines

Backend has generated Quarkus/JUnit and REST Assured example tests, including a packaged application integration test; no coverage threshold is configured. Frontend checks are ESLint, TypeScript and production build. Run `npm audit` for npm dependency findings; it does not scan Java or container images. For documentation changes, check relative links, render affected Mermaid diagrams, validate JSON examples, and compare API paths, event fields, and persistence behavior across documents. Update related architecture decisions and flows together when a contract changes.

## Commit & Pull Request Guidelines

Remote: `git@github.com:devbryan02/quarkus-oit.git`. Work and publish progress on `develop`. Integrate into `main` only in a later stage once the product works and its validations are complete; do not push to `main` as part of ordinary progress updates. Use concise, imperative commit messages, for example `docs: clarify telemetry acceptance semantics`.

Pull requests should explain the change, list affected documents, link relevant issues when available, and describe validation performed. Include rendered diagrams or screenshots when visual changes need review.

## Security & Scope

Use fictitious identities and coordinates in examples; never commit credentials or real student location data. Preserve the single-school demo scope, authorized monitoring sessions, and Android Flutter tracking with a visible notification during active sessions, including when the screen is locked. SOS may attach a permitted one-time location outside a session without enabling continuous tracking. Respect documented Android limitations; do not promise tracking after a force stop or permission revocation.

# Kivo Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar las cinco pantallas web de Kivo con autorización, mapa de última posición reportada, administración y reconocimiento de alertas.

**Architecture:** Next.js App Router con componentes PrimeReact y mapa mapcn aislado como componente cliente. Los contratos generados desde OpenAPI evitan divergencia con Quarkus, que conserva autorización y lógica de negocio. REST es la fuente de recuperación y SSE invalida consultas.

**Tech Stack:** Node 24 LTS, npm 12.2.2, Next.js 16.4.5, React 19.3.0, TypeScript, ESLint 9, PrimeReact y mapcn. Añadir Vitest/Testing Library para comportamiento y Playwright para integración.

**Spec:** [Especificación central](../../../backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md), [pantallas](../../../../knowledge/desing/01-product-ui.md), [contratos](../../../../knowledge/desing/03-api-contract.md) y [plan backend](../../../backend/superpowers/specs/2026-11-08-kivo-backend-implementation-plan.md), tarea B1.

## Global Constraints

- «Un colegio, identidades y coordenadas ficticias, cinco pantallas web y dos Android.»
- «Dashboard Next.js + PrimeReact + mapcn».
- «Comunicación reciente hasta 30 s; desactualizada entre 30 y 60 s; sin comunicación después de 60 s».
- «Al reconectar SSE, recuperar el estado por REST.»
- «SOS solicita ayuda; no llama a emergencias ni garantiza atención inmediata.»
- Ubicaciones 7 días; alertas/auditoría 30 días; no persistir coordenadas en almacenamiento web, logs o cachés de páginas. Mostrar hora y precisión de la captura, separadas de comunicación.
- Administrador configura; administrador/operador monitorean, detienen sesiones y reconocen alertas. El dashboard no inicia GPS. No hay cuentas de estudiantes ni rutas históricas.
- Alertas wire `PENDING`/`ACKNOWLEDGED`, interfaz «Pendiente»/«Reconocida». No presentar reconocimiento como atención ni resolución; severidad sigue abierta en la spec y no se inventa.
- `feature/<funcionalidad>`, aviso antes de cada push, PR a `develop` aceptada por propietario. No implementación en esta entrega documental.

## Review Focus

- SSE se reconecta mientras llegan respuestas REST antiguas: prevalece estado reciente; F3.
- Logout/cambio de usuario con mapa abierto: limpiar coordenadas y cancelar solicitudes/suscripciones; F1/F3.
- Teléfono reasignado o posición vencida: eliminar marcador anterior; F3/F4.
- Doble clic o timeout al reconocer: no inventar usuario/hora ni afirmar éxito sin respuesta; F6.
- Fallo de mapa/red o fechas inválidas: lista accesible, estados desconocidos y errores recuperables; F2/F3.

---

## Estado, estructura y dependencias

El proyecto tiene solo `src/app/layout.tsx` y `page.tsx` generados. PrimeReact/mapcn y pruebas de producto aún no existen. Rutas de archivos relativas a `codebase/frontend`. Plan guardado en `superpowers/specs/` por instrucción del propietario; no es otra especificación de producto.

Ejecutar F1 después de B1; puede desarrollarse contra respuestas ficticias fieles al contrato, pero eso no demuestra backend. F3–F6 se integran contra B8 antes de cerrar aceptación. F2 valida versiones compatibles de PrimeReact/mapcn y registra dependencias exactas en lockfile; no migrar React/Next ni añadir otro kit visual por conveniencia. Si mapcn exige utilidades CSS adicionales, aislarlas en el mapa y documentar la decisión, sin sustituir PrimeReact.

| Archivos / directorio | Responsabilidad |
|---|---|
| `src/lib/api/schema.d.ts`, `client.ts` | Tipos generados y transporte autenticado según B1 |
| `src/features/auth/` | Estado de usuario, login/logout y acceso |
| `src/components/providers.tsx`, `app-shell.tsx` | Tema PrimeReact y navegación |
| `src/features/monitoring/` | Snapshot, comunicación, SSE y mapa |
| `src/features/devices/`, `geofences/`, `alerts/` | Pantallas y acciones por dominio |
| `tests/fixtures/`, `tests/e2e/` | Respuestas ficticias y validación real separadas |

### Task F1: Acceso autenticado y transporte contractual

**Files:** Modify `package.json`, `package-lock.json`, `src/app/layout.tsx`; Create `vitest.config.ts`, `src/lib/api/schema.d.ts`, `src/lib/api/client.ts`, `src/features/auth/auth-provider.tsx`, `src/features/auth/login-form.tsx`, `src/app/login/page.tsx`, `src/app/(school)/layout.tsx`, `tests/auth.test.tsx`.

**Interfaces:** Consume OpenAPI/diseño de seguridad B1. Produce `api<T>(path: string, init?: RequestInit): Promise<T>` con error tipado `ApiError` generado; `useAuth(): { user: CurrentUser | null; logout(): Promise<void> }`. Credenciales/cookies y CSRF siguen B1; nunca exponer credenciales del teléfono o secretos del servidor a Next público.

- [ ] **Step 1:** Instalar/configurar runner y generar tipos del contrato B1; añadir scripts `test: vitest run`, `test:e2e: playwright test`, `generate:api` reproducible. Escribir `tests/auth.test.tsx`: `expect(screen.getByRole('alert')).toHaveTextContent('Credenciales inválidas')` al recibir 401; `expect(screen.queryByRole('navigation')).not.toBeInTheDocument()` sin usuario; `expect(location.pathname).toBe('/login')` tras logout y `expect(cachedPositions()).toEqual([])`. Fixtures incluyen admin, operador y anónimo sin datos reales.
- [ ] **Step 2:** Ejecutar `npm run test -- tests/auth.test.tsx`; esperar FAIL por acceso/limpieza ausentes.
- [ ] **Step 3:** Implementar las interfaces y formulario accesible con errores contractuales, sesión según B1, cancelación en logout y bloqueo de grupo `(school)`. Tratar 401 como sesión terminada, 403 como permiso insuficiente; validación del backend sigue obligatoria para URL directa y mutaciones. No guardar tokens en localStorage.
- [ ] **Step 4:** Ejecutar comando anterior y `npx tsc --noEmit`; esperar PASS y exit 0. Prueba de integración verifica URL protegida con sesión expirada contra backend, no solo ocultación de controles.
- [ ] **Step 5:** Commit `feat(frontend): add authorized Kivo access` con archivos de la tarea.

### Task F2: Navegación, componentes y mapa base

**Files:** Create `src/components/providers.tsx`, `app-shell.tsx`, `src/app/globals.css`, `src/features/monitoring/device-map.tsx`, `tests/shell.test.tsx`; Modify `src/app/layout.tsx`, `src/app/(school)/layout.tsx`, `package.json`, `package-lock.json`.

**Interfaces:** Produce `AppShell({children}: {children: React.ReactNode})` con rutas `/dashboard`, `/devices`, `/geofences`, `/alerts`; `DeviceMap({positions, zones}: {positions: LatestPosition[]; zones: Geofence[]}): React.JSX.Element`. Consume DTOs B1 y `useAuth` F1. Mapa se importa solo en cliente sin dependencia DOM durante SSR.

- [ ] **Step 1:** Escribir `tests/shell.test.tsx`: `expect(screen.getByRole('navigation')).toHaveAccessibleName('Navegación principal')`; `expect(screen.getByText('Kivo')).toBeVisible()`; ante error de mapa `expect(screen.getByRole('table', {name: 'Últimas ubicaciones'})).toBeVisible()`. Probar uso con teclado y viewport móvil sin ocultar la acción de salir.
- [ ] **Step 2:** Ejecutar `npm run test -- tests/shell.test.tsx`; esperar FAIL.
- [ ] **Step 3:** Integrar versiones compatibles PrimeReact/mapcn, provider, tema y shell. Adaptar [referencias Stitch](../../../../knowledge/desing/04-stitch-screens.md) sin copiar contratos/textos obsoletos ni editar exportaciones. Renderizar círculos y marcadores sin rutas; fallback accesible ante fallo de tiles/WebGL. Registrar origen/licencia/atribución del mapa y variables públicas sin claves privadas.
- [ ] **Step 4:** Ejecutar prueba, `npm run lint`, `npx tsc --noEmit`, `npm run build`; esperar exit 0, sin error de hidratación. Revisar visualmente las cinco pantallas al completarlas; adjuntar capturas de escritorio/móvil a la PR.
- [ ] **Step 5:** Commit `feat(frontend): add Kivo shell and map foundation`.

### Task F3: Dashboard recuperable sin falsa ubicación actual

**Files:** Create `src/app/(school)/dashboard/page.tsx`, `src/features/monitoring/monitoring-store.ts`, `use-monitoring.ts`, `communication-status.ts`, `position-list.tsx`; Modify `src/features/monitoring/device-map.tsx`; Test `tests/monitoring.test.tsx`.

**Interfaces:** Produce `communicationStatus(lastAuthenticatedAt: string | null, now: Date): 'RECENT' | 'STALE' | 'OFFLINE' | 'UNKNOWN'`; `useMonitoring(): {positions: LatestPosition[]; alerts: Alert[]; loading: boolean; error: string | null; refresh(): Promise<void>}`. Usa `api` F1. Store genera una secuencia por solicitud para descartar respuestas obsoletas y se destruye al logout.

- [ ] **Step 1:** Escribir pruebas CA-09: `expect(statusAt(30)).toBe('RECENT')`; `expect(statusAt(60)).toBe('STALE')`; `expect(statusAt(61)).toBe('OFFLINE')`; `expect(statusWithInvalidDate()).toBe('UNKNOWN')`. Reconexión solicita snapshots y alertas; respuesta vieja que llega última no reemplaza la nueva; posición caducada/reasignada desaparece; logout cierra stream y vacía store. Hora GPS antigua con heartbeat reciente sigue mostrando antigüedad real.
- [ ] **Step 2:** Ejecutar `npm run test -- tests/monitoring.test.tsx`; esperar FAIL.
- [ ] **Step 3:** Implementar REST inicial y recuperación tras cada apertura/reconexión SSE; eventos `position.updated`, `alert.created`, `alert.acknowledged` invalidan consulta. Refrescar alertas cada 15 s mientras su vista esté abierta, aun con SSE conectado. Limpiar timers/AbortControllers/listeners al desmontar. Mostrar «Última ubicación reportada», fecha/hora, precisión, comunicación, sesión y GPS separados; si no hay captura, mostrar ausencia de datos. Ninguna página ni service worker debe persistir respuestas sensibles.
- [ ] **Step 4:** Ejecutar prueba y validar con B8 apagando SSE y vaciando Redis. Esperar restauración por REST sin fabricar posiciones/alertas; servidor rechaza usuario sin permisos. No hay garantía de aviso inmediato.
- [ ] **Step 5:** Commit `feat(frontend): recover monitoring snapshots and alerts`.

### Task F4: Administración de teléfonos y códigos

**Files:** Create `src/app/(school)/devices/page.tsx`, `src/features/devices/device-table.tsx`, `pairing-dialog.tsx`, `student-editor.tsx`, `user-editor.tsx`, `school-settings.tsx`; Test `tests/devices.test.tsx`.

**Interfaces:** Consume DTOs/client F1 y operaciones de B1/B3/B4. Produce `PairingDialog({studentId, onClose}: {studentId: string; onClose(): void})`, `DeviceTable({devices, refresh}: {devices: Device[]; refresh(): Promise<void>})`; usar esquema `Device` agregado por B1 para listado. Gestión de estudiantes/usuarios y duración en paneles de esta pantalla para mantener cinco pantallas principales.

- [ ] **Step 1:** Escribir pruebas RF-01/03: `expect(screen.getByText('01234567')).toBeVisible()` solo tras generar; `expect(codeVisibleAfterCloseAndReopen()).toBe(false)`; `expect(screen.queryByRole('button', {name: 'Iniciar seguimiento'})).not.toBeInTheDocument()`. Operador ve finalizar pero no generar/revocar/configurar; tras revocar/reasignar no se reutiliza ubicación anterior. Error 429 conserva mensaje y no muestra código ficticio; vencimiento a 10 min se calcula desde `expiresAt`.
- [ ] **Step 2:** Ejecutar `npm run test -- tests/devices.test.tsx`; esperar FAIL.
- [ ] **Step 3:** Implementar lista y edición autorizadas, selección explícita de estudiante, generación de código solo visible en resultado y expiración. Cierre remoto comunica que el teléfono sin red lo aplicará al sincronizar. Revocación invalida credencial/códigos/sesión según servidor; mostrar resultado confirmado, no anticipado. Duración máxima inicial 8 h configurable solo por admin según B1; no modificar sesión ya iniciada.
- [ ] **Step 4:** Ejecutar prueba; integrar con B3/B4 y verificar acceso directo de operador a mutación admin retorna 403. Esperar PASS.
- [ ] **Step 5:** Commit `feat(frontend): manage Kivo devices and pairing`.

### Task F5: Geocercas circulares y asignación independiente

**Files:** Create `src/app/(school)/geofences/page.tsx`, `src/features/geofences/geofence-editor.tsx`, `assignment-editor.tsx`; Test `tests/geofences.test.tsx`.

**Interfaces:** Produce `GeofenceEditor({zone, onSaved}: {zone: Geofence | null; onSaved(zone: Geofence): void})` y `AssignmentEditor({deviceId}: {deviceId: string})`. Consume B1/B6 y `DeviceMap` F2. Reemplazo de asignaciones envía `geofenceIds: string[]`, incluyendo `[]`.

- [ ] **Step 1:** Escribir pruebas RF-08/09: `expect(lastAssignmentBody()).toEqual({geofenceIds: []})` al retirar todas; `expect(savedZoneIds()).toEqual([zoneA, zoneB])`; `expect(screen.getByText('Las zonas se evalúan por separado')).toBeVisible()`. Coordenadas fuera de rango/radio menor al mínimo B1 bloquean guardado; error 422 permanece editable; operador solo consulta.
- [ ] **Step 2:** Ejecutar `npm run test -- tests/geofences.test.tsx`; esperar FAIL.
- [ ] **Step 3:** Implementar centro/radio/nombre/actividad y selección por dispositivo. Usar mínimo de radio definido B1, no inventar otro en UI. Explicar reinicialización de la zona afectada al editar/asignar; no unir círculos en un área segura ni emitir alertas desde el navegador. Conservar resto de asignaciones según contrato de reemplazo.
- [ ] **Step 4:** Ejecutar prueba e integración con B6, editar A manteniendo B. Esperar PASS; marcadores y círculos coinciden con respuestas backend.
- [ ] **Step 5:** Commit `feat(frontend): configure assigned circular geofences`.

### Task F6: Alertas, reconocimiento y validación completa

**Files:** Create `src/app/(school)/alerts/page.tsx`, `src/features/alerts/alert-table.tsx`, `acknowledge-button.tsx`, `tests/alerts.test.tsx`, `tests/e2e/kivo.spec.ts`, `playwright.config.ts`; Modify `src/app/page.tsx`, `README.md`.

**Interfaces:** Produce `AcknowledgeButton({alert, onUpdated}: {alert: Alert; onUpdated(alert: Alert): void})`. Consume `api`, `useMonitoring`, paginación/filtros B1 y B7. `/` redirige a login/dashboard conforme estado autenticado.

- [ ] **Step 1:** Escribir CA-13/14/15 web: `expect(screen.getByText('Reconocida')).toBeVisible()` solo tras respuesta persistida; `expect(acknowledgedByAfterRetry).toBe(firstActor)`; `expect(screen.queryByText('Resuelta')).not.toBeInTheDocument()`. Timeout conserva estado recuperable y permite refrescar; doble clic no altera primer acuse. Hora original de SOS retrasado visible; alerta sin ubicación renderiza sin marcador. E2E usa usuarios ficticios de B10 y verifica operador sin administración, cierre remoto, REST tras SSE perdido y reconocimiento visible tras recargar.
- [ ] **Step 2:** Ejecutar `npm run test -- tests/alerts.test.tsx` y `npm run test:e2e`; esperar FAIL por flujo aún ausente. Separar fixtures de pruebas integradas reales.
- [ ] **Step 3:** Implementar tabla accesible con tipo, zona cuando corresponda, hora original/recepción, estado y usuario/hora de reconocimiento. Recuperar REST ante respuesta perdida, sin reconocimiento optimista. Incluir texto SOS exacto de la spec. Documentar variables, generación de tipos, pruebas y dependencias; adjuntar capturas con datos ficticios.
- [ ] **Step 4:** Ejecutar `npm ci`, `npm run lint`, `npx tsc --noEmit`, `npm run test`, `npm run build`, `npm run test:e2e` contra B10 y `npm audit`. Esperar checks exit 0; registrar hallazgos reales de audit y corregir o documentar sin afirmar que cubre Java/imágenes. No ocultar fallos bajo mocks.
- [ ] **Step 5:** Commit `feat(frontend): recognize alerts and verify Kivo dashboard`. Avisar antes de push y abrir PR a `develop`; propietario acepta.

## Cobertura y autorrevisión

| Requisitos / aceptación | Tareas |
|---|---|
| Matriz roles; RF-01/02; CA-01/02/03 | F1/F4; atomicidad pertenece B3 |
| RF-03; CA-04/17 | F4; captura/cierre efectivo pertenece móvil/backend |
| RF-07; P-04/11; CA-09 | F2/F3 |
| RF-08/09; CA-10/11 | F5; evaluación pertenece B6 |
| RF-10/11; CA-13/14/15 | F3/F6; emisión SOS pertenece móvil/B7 |
| RF-12; CA-16 | F1/F3 limpian memoria/caché; borrado durable B9 |

Revisados nombres de DTO y consumidores: son generados desde B1, incluyendo `Device` y formatos de listas finales. Los cinco riesgos tienen prueba asignada. RF-04/05/06 y CA-05/06/07/08/12 se cubren en planes backend/móvil, no se atribuyen a una prueba de interfaz web. Dependencias exactas se fijan al validar compatibilidad en F2; no se presentan como ya instaladas.

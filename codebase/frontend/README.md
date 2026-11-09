# Kivo — Frontend

Esqueleto generado con `npx create-next-app@latest`: Next.js 16.4.5, TypeScript, App Router y npm. Requiere Node 24 LTS. Aún no implementa pantallas ni consume la API.

Consultar la [spec central de Kivo](../backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md) y la [documentación compartida](../../knowledge/README.md) para alcance, pantallas, contratos y reglas.

El [índice de desarrollo](docs/superpowers/README.md) separa `specs/` y `plans/`, igual que backend. La [guía hexagonal simplificada](../../knowledge/arquitecture/04-hexagonal-simplificada.md) orienta la separación entre componentes, controladores y transporte.

Desde esta carpeta:

```powershell
npm ci
npm run dev
```

Abrir `http://localhost:3000`. La página inicial es `src/app/page.tsx` y el layout es `src/app/layout.tsx`.

Validación:

```powershell
npm run lint
npx tsc --noEmit
npm run build
npm audit
```

`next.config.ts` habilita salida standalone para el Dockerfile multietapa. Consultar [setup, Compose y alcance de auditoría](../README.md) y [documentación oficial de Next.js](https://nextjs.org/docs).

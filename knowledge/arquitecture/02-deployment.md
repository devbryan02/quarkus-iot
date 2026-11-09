# Despliegue — VPS con Docker Compose

## Topología

```mermaid
flowchart TB
  Internet((Internet)) --> Caddy["Caddy · HTTPS 443"]
  subgraph VPS["VPS único · Ubuntu · Docker Compose"]
    Caddy --> Web["Next.js · Dashboard web"]
    Caddy --> App["Quarkus · REST + SSE + Kafka Streams"]
    App <--> Kafka[("Kafka · KRaft single node")]
    App <--> Redis[("Redis · caché")]
    App <--> PG[("PostgreSQL · volumen persistente")]
  end
  Backup["Copia cifrada externa"] <-. "Backup programado" .- PG
```

## Contenedores

| Servicio | Exposición | Datos persistentes |
|---|---|---|
| Caddy | 80/443 públicos | Certificados TLS |
| Next.js | Solo red interna Docker | No obligatorio |
| Quarkus | Solo red interna Docker | No, salvo archivos temporales |
| Kafka (KRaft) | Solo red interna Docker | Log de eventos |
| PostgreSQL | Solo red interna Docker | Volumen de BD |
| Redis | Solo red interna Docker | No obligatorio (caché reconstruible) |

## Recomendaciones

- Punto de partida: VPS de **12 GB RAM** si se ejecutan Kafka, JVM, Redis y PostgreSQL juntos; dimensionar con métricas reales.
- Configurar `restart`, health checks, límites de memoria y monitoreo de disco.
- HTTPS obligatorio para el dashboard y la comunicación de la app Android; nunca exponer Kafka, Redis ni PostgreSQL a Internet.
- Rotar secretos y credenciales; usar firewall, SSH por claves y copias de seguridad cifradas **fuera** del VPS.
- Retención acordada para demo: ubicaciones 7 días; alertas y auditoría 30 días. Las coordenadas adjuntas a alertas no pueden sobrevivir al plazo de ubicación. Configurar también snapshots, Redis, colas locales, Kafka y backups; el mecanismo de depuración y saneamiento al restaurar sigue como propuesta P-09/P-10 en la [spec](../../codebase/backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md). La retención de un tópico por sí sola no acredita borrado físico puntual de segmentos o changelogs.
- Kafka y base de datos en el mismo VPS = **punto único de fallo**. No presentarlo como sistema de seguridad de alta disponibilidad.

## Migraciones de PostgreSQL

Flyway gestionará el esquema desde el backend Quarkus. Aplicar las migraciones antes de servir tráfico de una versión que las requiera y detener el despliegue si fallan. Probar cada cambio contra una base vacía y una base con la versión anterior; respaldar los datos antes de actualizar producción.

La app Android desarrollada con Flutter y Dart se instala en los teléfonos y consume la API por HTTPS; no forma parte de los contenedores del VPS.

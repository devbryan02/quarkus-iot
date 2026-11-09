# Pantallas de Kivo para Google Stitch

## Estado

Siete pantallas generadas y exportadas en [la galería local](stitch/index.html). El [inventario](stitch/README.md) registra los identificadores, las revisiones y las diferencias entre archivos locales y originales remotos. Proyecto privado: [Kivo MVP - Dashboard y Android Flutter](https://stitch.withgoogle.com/projects/1713403711180977197).

## Conexión MCP

Nota de vigencia: la [spec central](../docs/superpowers/specs/2026-11-08-kivo-mvp-design.md) define ahora código temporal de un solo uso, sesiones de máximo inicial configurable de 8 horas, asignación de zonas por dispositivo y SOS sin sesión. Los prompts siguientes se ajustan para una adaptación futura. **Las exportaciones HTML/PNG/JSON y el proyecto remoto no se modificaron** y pueden conservar estados anteriores.

Servidor remoto: `https://stitch.googleapis.com/mcp`. La configuración local de Codex usa el encabezado `X-Goog-Api-Key` en su archivo de usuario, por elección del propietario; la clave no se guarda en este repositorio.

La autenticación y el catálogo de herramientas se verificaron mediante llamadas MCP. Reiniciar la sesión de Codex permite cargar el servidor configurado en el catálogo del IDE. En esta sesión se accedió al mismo servidor mediante su protocolo HTTP MCP.

Referencias: [configuración MCP de Stitch](https://stitch.withgoogle.com/docs/mcp/setup), [guía de Google](https://codelabs.developers.google.com/design-to-code-with-antigravity-stitch) y [configuración MCP de Codex](https://learn.chatgpt.com/docs/extend/mcp).

## Dirección visual propuesta

Usar una interfaz clara y sobria, en español, con fondo gris claro, superficies blancas y azul como color principal. Reservar rojo para SOS y alertas críticas; combinar color con texto e iconos. Mantener contraste legible, foco visible y controles táctiles grandes en Android. Esta dirección es una propuesta inicial para revisar con las pantallas generadas.

El alcance funcional procede de [pantallas y reglas UX](01-product-ui.md). Crear cinco pantallas web y dos Android con variantes de estado, sin agregar funcionalidades al MVP.

## Instrucción para el dashboard web

```text
Diseña cinco pantallas coherentes de alta fidelidad para Kivo, un MVP de
monitoreo escolar para un solo colegio. Todo el texto debe estar en español.
Usa exclusivamente identidades, colegio y ubicaciones ficticias, con una
etiqueta visible de demostración. El usuario es personal escolar autorizado.

La implementación será Next.js con PrimeReact y mapas con mapcn. Toma como
referencia visual los formularios, tablas, diálogos y menús de PrimeReact.
No incluyas nombres de tecnologías en la interfaz del producto.
Propón escritorio de 1440 px y adaptación responsive. Estilo claro: fondo
gris muy suave, tarjetas blancas, azul principal, tipografía legible,
espaciado generoso e iconos sencillos. Rojo reservado para SOS y alertas
críticas. Los estados siempre deben tener texto además del color.

1. Inicio de sesión: marca Kivo, nombre de colegio ficticio, credenciales,
   botón Acceder y variante de credenciales incorrectas.
2. Dashboard: navegación lateral a Mapa, Dispositivos, Geocercas y Alertas;
   mapa principal con marcadores y zonas circulares; lista de dispositivos,
   filtro por estado y detalle de la última posición seleccionada. Mostrar
   última actualización, precisión GPS, sesión activa y estado
   conectado/desactualizado/sin comunicación. Llamar a la posición
   “Última ubicación reportada”. El mapa es una representación de demo,
   no un mapa con ubicaciones reales de menores. Incluir variantes sin datos,
   cargando y error de conexión. No prometer posición exacta en vivo.
3. Dispositivos: tabla con identificador, estudiante ficticio asociado,
   sesión y última comunicación; búsqueda y acción Vincular teléfono.
   El administrador selecciona un estudiante ficticio y genera un código
   temporal de un solo uso para ingresarlo en Android. Mostrar errores de
   código vencido o usado; no inventar QR. Permitir finalizar una sesión.
4. Geocercas: mapa de demo con zona circular editable; formulario de nombre,
   centro y radio en metros, botón Guardar zona y validación de campos.
   Asignar zonas por dispositivo y evaluarlas por separado. No incluir polígonos.
5. Alertas: lista de SOS y salida de zona con tipo, severidad, hora y estado;
   detalle con última ubicación reportada y acción Reconocer alerta.
   Distinguir recibido por servidor de reconocido por operador. No agregar
   una acción de atender o resolver. Mostrar variante sin
   alertas y error al reconocer. No prometer atención inmediata.

Mantén navegación, componentes, colores y ejemplos consistentes entre
pantallas. No agregues seguimiento fuera de sesiones, múltiples colegios,
rutas históricas ni llamadas automáticas a emergencias.
```

## Instrucción para Android

```text
Diseña dos pantallas Android de alta fidelidad para Kivo, coherentes con
el dashboard escolar Kivo. La app se implementará en Flutter con Dart.
Todo el texto en español. Propón un teléfono de 390 px de ancho, fondo claro,
azul principal, controles grandes, contraste legible y estados con texto.
Usa únicamente información ficticia identificada como demostración.
No muestres tecnologías ni detalles del backend al usuario.

1. Vinculación y permisos: marca Kivo, explicación breve de sesión autorizada
   y privacidad, estado de vinculación y permiso de ubicación. El método
   de vinculación usa un código temporal de un solo uso generado por el
   administrador para un estudiante ficticio. Incluye variantes de código
   inválido, vencido y utilizado, y variantes
   de permiso pendiente y denegado con una acción clara para resolverlo.
2. Principal: una sola pantalla sencilla sin mapas, tablas ni menús
   administrativos. Mostrar sesión inactiva, activa o pausada, estado del GPS,
   última ubicación enviada y estado de comunicación. Incluir iniciar/detener
   monitoreo y botón SOS destacado. Solo capturar ubicación continua durante
   una sesión autorizada; SOS permite ubicación puntual autorizada sin sesión.
   En sesión activa explicar que el seguimiento continúa con
   pantalla bloqueada y que Android muestra una notificación de seguimiento.
   Mostrar variantes de GPS desactivado, permiso revocado, sin conexión y
   sesión finalizada, vencida y cierre remoto recibido. Máximo inicial de
   8 horas configurable; no prometer cierre remoto instantáneo sin red ni
   continuidad tras detención forzada.

Para SOS mostrar variantes de envío pendiente, enviado, recibido y error
con reintento; no confirmar recepción si no hay respuesta del servidor.
SOS también está disponible sin sesión en teléfonos vinculados y habilitados;
no inicia rastreo ni espera GPS. Ubicación puntual opcional y autorizada.
Indicar que SOS solicita ayuda y no llama automáticamente a emergencias.
No prometer atención inmediata ni mostrar seguimiento fuera de sesión.
```

## Revisión de resultados

- Guardar enlaces e identificadores reales de proyectos y pantallas cuando Stitch los genere.
- Revisar las siete pantallas y sus variantes contra las reglas UX y los contratos existentes.
- Exportar vistas previas y recursos a una subcarpeta de `desing/` cuando estén disponibles.
- El diseño de Stitch debe adaptarse a PrimeReact en web y Flutter en Android durante la implementación.

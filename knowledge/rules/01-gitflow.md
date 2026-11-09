# Gitflow y merge requests

## Política acordada

El repositorio usa Gitflow adaptado al flujo indicado por el propietario. Los cambios de código, documentación, configuración y dependencias se trabajan en ramas separadas y se integran **siempre mediante MR a `develop`**. En GitHub, la MR se llama **pull request (PR)**.

El propietario revisa y acepta cada MR. El agente no debe aprobar en su nombre, hacer merge, activar auto-merge ni usar permisos de administrador para evitar la revisión. Una aprobación de diseño o de un plan no constituye aprobación de la MR.

Una instrucción directa posterior del propietario puede autorizar una excepción puntual para una publicación concreta, como el push directo a `develop` de esta reorganización documental. Se debe avisar igualmente antes del push. Esa excepción no se extiende a trabajos futuros ni elimina el flujo habitual de MR.

## Ramas

| Rama | Uso | Regla |
|---|---|---|
| `develop` | Base de integración | No trabajar, hacer commits nuevos ni push directo aquí; recibir cambios por MR aceptada por el propietario |
| `feature/<funcionalidad>` | Trabajo habitual, incluidos ajustes y documentación | Crear desde `develop` actualizado; nombres descriptivos como `feature/vinculacion-dispositivos` o `feature/gitflow-rules` |
| `main` | Versión estable futura | No modificar ni publicar directamente; promoción posterior solo por instrucción explícita del propietario cuando el producto funcione y esté validado |
| `release/<version>` / `hotfix/<correccion>` | Preparación de versión o corrección urgente de Gitflow | Usar solo cuando el propietario lo solicite; no omiten MR a `develop` ni aceptación del propietario |

No crear una rama Gitflow adicional ni preparar una promoción a `main` si la tarea no lo requiere. El flujo descrito es una convención de trabajo; no requiere instalar la extensión CLI `git flow`.

## Antes de trabajar

1. Revisar el estado local y conservar los cambios existentes del usuario.
2. Actualizar referencias del remoto y basar la nueva rama en `develop` vigente. Si hay cambios locales o divergencia, resolverlos sin reset destructivo ni sobrescritura.
3. Crear `feature/<funcionalidad>` antes de editar. Si ya se está en la rama de la tarea, continuar allí.
4. Implementar solo el alcance autorizado, validar y crear commits descriptivos.

## Antes de cada push

**Avisar al propietario en la conversación antes de ejecutar cada push**, incluidos pushes de actualización a una MR existente. El aviso debe identificar la rama, el remoto y resumir los cambios o commits que se publicarán, indicando que el destino de integración es `develop` por MR.

Avisar no equivale a afirmar que el push ya ocurrió. Un aviso anterior no cubre publicaciones futuras. Si el propietario pide esperar o solicita autorización explícita para una publicación, detener ese push hasta recibir su respuesta. No usar `--force` ni `--force-with-lease` sin autorización explícita para reescribir el historial afectado.

Publicar únicamente la rama de trabajo, por ejemplo:

```shell
git push -u origin feature/vinculacion-dispositivos
```

## MR hacia develop

Después de publicar, abrir una MR/PR con la rama de trabajo como origen y **`develop` como destino**. Describir el problema, los cambios, las validaciones y los límites relevantes; enlazar issues si existen. Las imágenes o diagramas se adjuntan cuando ayudan a revisar cambios visuales.

Entregar al propietario el enlace y esperar su aceptación. No integrar localmente a `develop` para luego hacer push, no autoaprobar, no cerrar la MR como sustituto de revisión y no borrar la rama remota sin indicación del propietario. Un nuevo push a la misma MR también requiere aviso previo y revisión del propietario.

El progreso puede estar publicado y listo para revisión sin estar integrado. Distinguir ese estado del merge completado. Las restricciones aquí documentadas no configuran por sí solas protección de ramas en GitHub.

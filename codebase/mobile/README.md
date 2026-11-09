# Kivo — Android Flutter

Esqueleto Android con pantalla de arranque. No captura ubicación, no pide permisos GPS y no consume aún la API. Vinculación, sesiones, notificación de seguimiento y SOS se implementarán según el [plan Android](docs/superpowers/plans/2026-11-08-kivo-android-implementation-plan.md) y la [spec central](../backend/docs/superpowers/specs/2026-11-08-kivo-mvp-design.md).

## Herramientas

Flutter estable **3.47.9**, Dart **3.13.7** incluido en Flutter. El SDK se instala fuera del repositorio; conservar `pubspec.lock` y la versión indicada en `.flutter-version`. No instalar Dart por separado. Las versiones de Gradle y del plugin Android se conservan en los archivos generados de `android/`.

En este equipo el SDK está en `C:\Users\bcardenas\development\flutter` y su `bin` se añadió al PATH del usuario. Reabrir terminal/IDE para recibir el cambio. Para habilitarlo también en una terminal PowerShell ya abierta:

```powershell
$env:Path = 'C:\Users\bcardenas\development\flutter\bin;' + $env:Path
flutter --version
```

Otro equipo debe instalar esa misma versión desde el [archivo oficial](https://docs.flutter.dev/install/archive) y añadir su carpeta `bin` al PATH.

## Qué instalar para ejecutar Android en local

Instalar [Android Studio](https://developer.android.com/studio/install) y completar su asistente de SDK. En **SDK Manager** instalar la plataforma Android requerida por Flutter, Build-Tools, Command-line Tools y Platform-Tools; agregar NDK/CMake según la configuración generada y la [guía Android de Flutter](https://docs.flutter.dev/platform-integration/android/setup). Para emulador, instalar Android Emulator y una imagen de sistema compatible, crear un dispositivo desde Device Manager y habilitar aceleración/virtualización.

Usar el JDK compatible que trae Android Studio para Gradle. El Java 25 del backend no determina el JDK de Android; no cambiar el Java global del backend para solucionar el móvil. Si doctor detecta un JDK incompatible, configurar Flutter con la ruta `jbr` de Android Studio:

```powershell
flutter config --jdk-dir 'C:\Program Files\Android\Android Studio\jbr'
flutter doctor -v
flutter doctor --android-licenses
```

Revisar y aceptar las licencias personalmente. Si usas teléfono, habilitar opciones de desarrollador y depuración USB, conectar con cable de datos y aceptar la autorización RSA. En Windows puede hacer falta el driver USB del fabricante. Un teléfono físico evita instalar una imagen de emulador, pero sigue requiriendo el SDK para compilar y desplegar.

## Validar y ejecutar

Desde `codebase/mobile`, con Flutter en PATH:

```powershell
flutter pub get
flutter analyze
flutter test
flutter doctor -v
flutter devices
flutter run -d <device-id>
flutter build apk --debug
```

Sustituir `<device-id>` por el identificador que devuelva `flutter devices`. `flutter test` y el análisis de Dart pueden ejecutarse sin Android SDK; `run` sobre Android y el APK sí requieren el toolchain Android. El APK de depuración queda en `build/app/outputs/flutter-apk/app-debug.apk`. La app Android no se ejecuta dentro de Compose ni es un cliente web de seguimiento.

## Organización

`lib/main.dart` inicia la aplicación; `lib/app.dart` compone el tema y `lib/features/startup/startup_screen.dart` muestra el estado del esqueleto. La prueba de widget está en `test/widget_test.dart`. Aplicar la [arquitectura hexagonal simplificada](../../knowledge/arquitecture/04-hexagonal-simplificada.md) al implementar funcionalidades; no generar carpetas o interfaces sin uso.

Diseños en `docs/superpowers/specs/` y planes en `docs/superpowers/plans/`, como backend y frontend. El esqueleto no da por completada M1: faltan selección de plugins, diseño de ejecución, seguridad, puertos y pruebas de plataforma.

La aceptación del seguimiento con pantalla bloqueada y notificación visible requiere un teléfono Android real. Un test de widget o un emulador no demuestra continuidad en equipos reales ni tras un force stop.

## Validación de este esqueleto

En este equipo se ejecutaron `dart format lib test`, `flutter analyze` (sin hallazgos) y `flutter test` (1 prueba aprobada). Se observó primero el fallo de la prueba porque la plantilla no mostraba Kivo, y después pasó con la pantalla de arranque.

`flutter doctor -v` detectó ausencia de Android SDK y no encontró un dispositivo Android. El intento de `flutter build apk --debug` terminó con `No Android SDK found`; no se generó APK ni se ejecutó la aplicación en Android. Los avisos sobre Visual Studio se refieren al objetivo Windows desktop y no son un requisito para este proyecto Android.

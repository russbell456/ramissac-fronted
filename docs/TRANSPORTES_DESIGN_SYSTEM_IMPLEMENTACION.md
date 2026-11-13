# Transportes: adopción del sistema visual Ramis

Fecha: 12 de noviembre de 2026. Rama de entrega: `feature/transportes`.

## Alcance

Las vistas de Transportes adoptan los componentes, Inter local, temas claro/oscuro y tokens semánticos definidos en `RAMIS_DESIGN_SYSTEM_REPORT.md`. Se conserva la arquitectura del frontend integrado: pantallas y widgets → providers Riverpod → repositorios/servicios existentes.

| Área | Adaptación |
| --- | --- |
| Conductor | Mi jornada, seguimiento, incidencias, subacciones, cierre, historial y documentos. Se conservan los tres destinos de navegación. |
| Administración | Jornadas, flota, observaciones, mantenimientos, GPS y conductores. Se conservan las seis pestañas y el estado informativo de GPS; no se implementa rastreo nuevo. |
| Documentación | Detalle del vehículo, ficha técnica PDF, carga y revisión de documentos, versiones, pendientes y sincronización sin conexión. |
| Formularios | Asignación, registro de actividad, checklist, combustible, grúa, mantenimiento, inspección, cocada, torque y trabajos externos. |
| Vistas anteriores | Pantallas de inicio, operación, formularios e historial que todavía forman parte del módulo, para evitar una segunda apariencia al navegar. |

Se usan `RamisScaffold`, `RamisAppBar`, `RamisCard`, `RamisButton`, `RamisTextField`, `RamisStatusChip` y estados compartidos de carga, vacío y error. Los controles Material especializados —selectores, fechas, tabs, menús y navegación— heredan el tema general. Las firmas conservan tinta negra y fondo blanco para mantener legibles los archivos exportados.

La capa de datos, entidades, modelos, providers, servicios, endpoints, permisos y dependencias no se modifica. Tampoco se modifica el backend.

## Extensiones reutilizables

- `RamisScaffold`: parámetros opcionales `drawer` y `maxContentWidth`. Transportes limita el contenido a 1200 px en pantallas grandes.
- `RamisAppBar`: soporte de `bottom` y navegación automática opcional, conservando los valores anteriores por defecto.
- `RamisTextField`: compatibilidad con decoraciones, valores iniciales, guardado, formato de entrada, lectura y validación usados por los formularios existentes.
- `RamisButton`: altura mínima y etiqueta flexible para admitir varias líneas y texto ampliado. Se conserva el bloqueo durante envío.

Estas extensiones mantienen compatibles los consumidores anteriores. La suite completa incluye pruebas de los componentes y del módulo Almacén.

## Validación ejecutada

| Comprobación | Resultado |
| --- | --- |
| Análisis de `lib/core/design_system`, presentación/pantallas de Transportes y `test` | Sin incidencias |
| Suite completa de Flutter | 60 pruebas aprobadas |
| Compilación web de producción | Correcta |
| Compilación Android APK de depuración | Correcta |
| Revisión de diff | Sin errores de espacios; sin cambios en la capa de datos o configuración de dependencias |
| Revisión visual | Capturas renderizadas con Inter e iconos reales; jornada y detalle de vehículo, claro/oscuro, 360 y 1280 px |

Se recuperaron nueve archivos de pruebas de Transportes del frontend anterior y se ajustaron sus usuarios de prueba al contrato actual (`activo`). Cubren selección de vehículo, jornadas, subacciones, incidencias, documentos, formularios y cola sin conexión. Las pruebas de tema esperan la transición visual; la prueba de arranque simula almacenamiento vacío y verifica el login actual.

`test/transportes_design_system_test.dart` añade 13 casos: jornadas y documentos en ambos temas y tamaños, navegación por las seis pestañas, carga/error/reintento/vacío, botones y combustible con texto al 200%, y alta de vehículo con teclado abierto. Las pantallas principales se comprueban con texto al 150%.

Comandos reproducibles desde la raíz del frontend:

```sh
dart analyze lib/core/design_system lib/features/transportes/presentation lib/features/transportes/screens test
flutter test --no-pub
flutter build web --no-pub
flutter build apk --debug --no-pub
```

Para regenerar evidencia visual con datos de prueba:

```sh
flutter test --no-pub --dart-define=TRANSPORTES_SCREENSHOTS=true test/transportes_design_system_test.dart
```

Las capturas se generan en `build/transportes-review/`, la web en `build/web/` y la APK en `build/app/outputs/flutter-apk/app-debug.apk`. Los artefactos de compilación no se versionan.

## Límites y revisión antes de integrar en general

Las verificaciones de flujos utilizan repositorios simulados y respuestas HTTP controladas. No equivalen a una prueba con el servidor y un teléfono físico. El backend configurado en `ApiConfig` no respondió desde este entorno al intentar consultar su OpenAPI; por eso no se afirma una validación extremo a extremo contra datos reales.

Antes de incorporar en `feature/general`, instalar la APK y comprobar con el backend accesible: acceso de conductor y administrador, apertura y cierre de jornada, incidencia con foto, carga y revisión documental, descarga de PDF, pérdida/recuperación de conexión y notificaciones. Esas comprobaciones dependen de credenciales, red y permisos del dispositivo.

Las compilaciones muestran avisos previos de compatibilidad futura de Kotlin/Gradle y plugins. El build web estándar funciona; el análisis preliminar de WebAssembly advierte sobre dependencias que todavía usan `dart:html`/`dart:js_util`. Esta entrega no actualiza dependencias ni afirma compatibilidad Wasm.

La entrega se prepara para `feature/transportes`; la integración en `feature/general` queda para la revisión acordada con el equipo.

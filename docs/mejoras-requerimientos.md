# Cambios solicitados por el ingeniero — 1 de octubre de 2026

Se corrigieron las pantallas de requerimientos, catálogo y revisión logística en la aplicación de `oficial/mobile`, con sus servicios en `oficial/backend`.

## Comportamiento

- Inicio con accesos útiles, navegación inferior coherente y menú sin entradas duplicadas. Se retiraron indicadores de ejemplo y acciones sin comportamiento del inicio.
- Formularios con secciones compactas, ancho limitado, botones de tamaño uniforme y acción principal en el pie.
- Obra obligatoria seleccionada por ID entre las obras activas existentes. Los borradores antiguos conservan sus productos y solicitan elegir una obra válida.
- Catálogo con búsqueda y filtros de stock y tipo. Los artículos con stock cero pueden incorporarse al requerimiento.
- Producto no registrado con nombre, tipo, unidad, cantidad decimal, medidas, especificaciones, descripción, observación, fecha requerida y adjuntos. Los insumos admiten un vencimiento de referencia opcional que se conserva en la descripción emitida; no representa control de lotes.
- Catálogo editable por Almacén y Logística, con ficha técnica PDF y galería de fotos. La solicitud conserva una copia de la información de referencia.
- Revisión antes de firmar, stock actual y cantidad faltante por producto. Firma única y reintento de correo conservando el mismo ID del requerimiento.
- Vista previa, impresión y descarga del PDF. Las fotos aparecen en un mosaico A4 y las fichas originales se adjuntan al correo.
- Borradores web guardados en el servidor y recuperables al volver a iniciar sesión; historial combinado sin duplicar registros locales y remotos.
- Vista logística conectada a solicitudes enviadas. La consulta no reserva existencias ni registra una entrega.

La validación del jefe se implementará cuando tenga su panel, según la aclaración del usuario. Los módulos anteriores de préstamos y compras mantienen sus procesos; esta modificación no crea aprobaciones, recepciones o entregas nuevas.

## Verificación

- Backend: 14 pruebas del flujo RQ y los cambios del ingeniero aprobadas. Incluyen obra activa/cerrada, stock cero, cantidades decimales, archivos inválidos, límites, conservación de fichas y adjuntos originales del correo.
- Flutter: 7 pruebas aprobadas, incluida selección de obra y catálogo a 320 y 800 píxeles, edición de cantidades y reintento sin duplicar el RQ.
- Análisis Flutter: sin errores de compilación; permanecen avisos e información de estilo de la aplicación existente.
- Compilación web y macOS de depuración verificadas.
- Revisión visual con SQLite en memoria y datos sintéticos. Comprobados formulario, catálogo sin stock, revisión, galería, vista previa y archivo PDF descargado de dos páginas.
- El PDF de prueba se renderizó e inspeccionó. También se revisó un anexo de ocho fotos distribuido en dos páginas.

La suite histórica de catálogo tiene ocho fallos previos, reproducidos antes de estos cambios: pruebas de importación Excel y contratos antiguos, y llamadas a `upsert_articulo` ausente. El resultado anterior no afirma que toda la suite histórica esté aprobada. El ensayo de correo usa un SMTP simulado; no se enviaron correos reales ni se desplegó una versión de producción.

## Capturas con datos de prueba

![Formulario compacto](/Users/danm/Mina/oficial/mobile/docs/preview/requerimiento.jpg)

![Revisión con ficha y fotografías](/Users/danm/Mina/oficial/mobile/docs/preview/revision-con-adjuntos.jpg)

## Ejecución de comprobaciones

En `oficial/backend`:

```sh
.venv/bin/python -m pytest app/test/test_rq_campo.py app/test/test_rq_engineer_changes.py -q
```

En `oficial/mobile`:

```sh
flutter test
flutter analyze --no-pub
flutter build web
flutter build macos --debug
```

El backend debe reiniciarse para crear las tablas nuevas mediante su inicialización existente. El envío real utiliza los destinatarios y la configuración SMTP del servidor.

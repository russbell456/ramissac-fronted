# UI 02: Usabilidad de RamissApp

Fecha: 17/10/2026.

## Criterios

- Tipografia estable, texto legible y respeto al tamano de letra del sistema.
- Controles tactiles de al menos 48 dp, etiquetas y tooltips.
- Espaciado consistente, bordes de 8 px y superficies sin sombras decorativas.
- Una sola cabecera por pantalla; acciones principales diferenciadas de las secundarias.
- Navegacion inferior en celular y lateral desde 840 px.

Referencias: [Accesibilidad de Flutter](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling),
[Patrones de navegacion de Android](https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns).

## Cambios

- Acceso sin panel ornamental, validacion por campo, autofill y mostrar/ocultar contrasena.
- El acceso conserva los datos mientras espera la respuesta y muestra errores sin borrar los campos.
- Inicio con accesos directos por rol y creacion de requerimientos.
- Listas de solicitudes y catalogo con busqueda compacta, filtros y actualizacion.
- RQs con referencia, obra, estado, fecha y cantidad; apertura desde toda la fila.
- Creacion de RQ accesible desde un unico boton principal.
- Productos del RQ desplegables: cantidad, stock y estado visibles sin expandir.
- Formularios sin doble margen; unidades frecuentes en un menu que permite entrada libre.
- Selector del catalogo desplazable con teclado abierto y letras grandes.
- Ordenes sin cabecera duplicada, estado vacio y confirmacion antes de quitar una orden local.

## Verificacion

- Pruebas de widgets y flujo en 320, 384, 800 y 1024 px, segun pantalla.
- Texto al 100 %, 110 %, 130 % y 160 %, segun prueba.
- Busqueda, limpieza de busqueda, filtros, roles y navegacion adaptativa.
- Teclado abierto, selector del catalogo, pie de acciones y detalle desplegable.
- API de accesibilidad de Flutter: objetivos tactiles Android, contraste y etiquetas del acceso.
- Revision visual en Samsung SM-A546E conectado por USB.

No se modificaron las APIs, la generacion del PDF ni el envio de correo.
No se enviaron solicitudes ni correos reales durante esta revision de interfaz.

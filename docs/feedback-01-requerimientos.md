# Feedback 01 - Flujo de requerimientos RamissApp

Fecha: 2026-10-08  
Fuente: reunion de feedback con ingenieria/operaciones  
Alcance: modulo de requerimientos, catalogo/stock, logistica, compras y PDF/correo.

## Resumen ejecutivo

El flujo de requerimientos debe priorizar agilidad para el supervisor, trazabilidad para logistica y control de avance para compras. El requerimiento debe manejar materiales, equipos y herramientas, permitiendo seleccionar productos del catalogo o registrar productos no catalogados sin bloquear el proceso.

El identificador principal operativo no debe ser el nombre libre de la obra/proyecto, sino un codigo de obra con formato tipo `010-2026`. La descripcion de obra puede variar o corregirse, pero el codigo debe mantenerse como clave de agrupacion y busqueda.

## Roles y perspectivas

### Supervisor / solicitante

- Puede crear requerimientos.
- Puede consultar catalogo y stock.
- Puede registrar productos catalogados o no catalogados.
- Puede ver el estado de sus requerimientos y de cada item.
- No debe quedar bloqueado por listas rigidas de obras, unidades o productos.

### Logistica

- Puede crear requerimientos si es necesario.
- Puede consultar catalogo y stock.
- Gestiona requerimientos recibidos.
- Decide que items se atienden con stock y que items pasan a compra.
- Puede modificar/verificar informacion del requerimiento antes de derivarlo a compras.

### Compras

- Normalmente no crea requerimientos.
- Puede consultar catalogo y stock.
- Gestiona items derivados a compra.
- Puede marcar items como pendiente, en proceso, comprado o cerrado/no comprado.
- Puede actualizar evidencia real de compra, fotos o descripcion si corresponde.

## Clasificacion de items

Todo item debe clasificarse en una de tres categorias:

- Material
- Equipo
- Herramienta

Esta clasificacion aplica tanto para productos del catalogo como para productos no catalogados.

## Registro de obra/proyecto

### Regla principal

La obra/proyecto debe identificarse principalmente por codigo, no por descripcion.

Formato esperado:

- Tres digitos numericos.
- Guion.
- Anio.

Ejemplos:

- `001-2026`
- `010-2026`
- `011-2026`

### Comportamiento esperado

- El usuario debe poder escribir libremente el codigo de obra.
- Si el codigo no existe, se debe permitir registrar una descripcion breve en el momento.
- Si el codigo ya existe, la app debe sugerir/seleccionar la obra existente.
- La descripcion puede corregirse o mejorarse, pero el codigo debe mantenerse estable.
- La busqueda y agrupacion de requerimientos debe funcionar por codigo de obra.

### Motivo

El nombre de obra puede variar entre usuarios, por ejemplo:

- "canales"
- "limpieza de canales"
- "mantenimiento de canales"

Pero el codigo `010-2026` debe ser el dato confiable para agrupar y reportar.

## Numeracion de requerimientos

Cada requerimiento debe tener un correlativo automatico.

La numeracion debe considerar la obra para evitar duplicados ambiguos:

- Requerimiento 01 de la obra `010-2026`
- Requerimiento 02 de la obra `010-2026`
- Requerimiento 01 de la obra `011-2026`

El codigo de obra mas el numero de requerimiento permite identificar un requerimiento de forma clara.

## Estados de requerimientos

La pantalla de requerimientos debe permitir ver y filtrar por estados.

Estados/pestanas sugeridas:

- Todos
- Pendientes / borradores / en edicion
- Enviados / en atencion
- Finalizados / atendidos / cerrados

Tambien debe existir busqueda por:

- Numero de requerimiento.
- Codigo de obra.
- Descripcion/titulo del requerimiento.
- Nombre/descripion de obra.

## Estado por item y trazabilidad

Cada item del requerimiento debe tener seguimiento individual.

Estados sugeridos por item:

- Pendiente
- En proceso
- Comprado
- Atendido con stock
- Cerrado sin compra

La app debe mostrar un semaforo o indicador visual para que supervisor, logistica y compras puedan ver el avance.

El objetivo operativo es conocer por obra:

- Que materiales/equipos/herramientas estan pendientes.
- Que items estan en proceso de compra.
- Que items ya fueron comprados.
- Que items fueron atendidos desde stock.
- Que requerimientos ya se cerraron.

## Producto no catalogado

El registro de producto no catalogado debe ser simple y rapido.

Campos esperados:

- Nombre de referencia.
- Categoria: material, equipo o herramienta.
- Cantidad.
- Unidad de medida.
- Detalle/comentario referencial.
- Fecha requerida o fecha estimada de llegada/requerimiento.
- Adjuntos opcionales.

### Unidad de medida

La unidad debe permitir dos modos:

- Seleccionar una unidad existente.
- Escribir una unidad libre si no existe en la lista.

Esto evita bloquear al supervisor si la unidad aun no esta registrada.

Ejemplos:

- UND
- PZA
- piezas
- kg
- glb

## Informacion tecnica del item

Se debe simplificar la seccion de informacion tecnica.

Los campos actuales como medidas, especificaciones tecnicas, descripcion de uso, observacion y justificacion se perciben repetitivos.

Decision de feedback:

- Unificar todo en un solo cuadro de texto.
- Nombre sugerido: `Detalle de la solicitud`, `Detalle del producto` o `Comentario referencial`.
- En ese campo el usuario puede escribir medidas, uso, especificaciones, observaciones o justificacion.
- Agregar un boton para adjuntar foto, ficha tecnica, cotizacion u otro archivo referencial.

Los adjuntos son opcionales, no obligatorios.

## Adjuntos

Cada material/equipo/herramienta puede tener adjuntos referenciales.

Tipos esperados:

- Foto referencial.
- Ficha tecnica.
- Cotizacion.
- Otro archivo que facilite la compra.

Debe poder adjuntarse tanto en:

- Producto nuevo/no catalogado.
- Producto tomado del catalogo.

## Flujo de seleccion desde catalogo

El catalogo debe funcionar como herramienta rapida de seleccion.

Flujo esperado:

1. Buscar producto por nombre o palabra clave.
2. Seleccionar producto si el usuario ya esta seguro.
3. Pedir cantidad directamente.
4. Agregar al requerimiento.
5. Volver al buscador para seguir agregando items.

Debe existir un boton de detalle/informacion para ver informacion completa del producto solo cuando el usuario lo necesite.

Tambien debe existir opcion de `Nuevo` si el producto no se encuentra en catalogo.

## Duplicado de producto

Se acepta la idea de duplicar un producto existente para crear uno nuevo con datos similares.

Uso recomendado:

- Principalmente para equipos o productos con varias caracteristicas tecnicas.
- No necesariamente para materiales simples.

Objetivo:

- Evitar registrar desde cero cuando se requiere una variacion del mismo producto.

## Catalogo y stock

El catalogo debe mostrar stock actual.

Consideracion de largo plazo:

- El catalogo idealmente debe conectarse al ERP/RRP de la empresa mediante una API.
- Esa API debe alimentar productos, stock y eventualmente costos.

Para el desarrollo actual:

- Se puede simular una API o dejar un conector preparado.
- El objetivo es que cuando exista la API oficial, la app solo consuma datos reales.

## PDF y correo

El PDF debe representar el requerimiento enviado y ser lo mismo que llega al correo.

Puntos observados:

- Debe poder visualizarse como vista previa.
- Debe permitir zoom.
- Debe mantener legibles los campos similares a la plantilla Excel.
- Debe mostrar firma del solicitante.
- Debe diferenciar materiales, equipos y herramientas.
- Debe incluir cantidades y unidad de medida.

Despues de firmar y enviar:

- El requerimiento ya no debe permitir edicion para el solicitante.
- Debe enviarse a los encargados definidos.

## Flujo general del requerimiento

1. Supervisor crea requerimiento.
2. Ingresa codigo de obra y descripcion breve.
3. Agrega items desde catalogo o como no catalogados.
4. Define cantidad, unidad, categoria y detalle referencial.
5. Adjunta archivos opcionales.
6. Guarda como borrador o revisa.
7. Visualiza PDF.
8. Firma.
9. Envia a encargados/logistica.
10. Logistica revisa y decide stock vs compra.
11. Compras gestiona items derivados.
12. Se actualizan estados por item y por requerimiento.
13. Supervisor puede hacer seguimiento del avance.

## Requerimientos funcionales priorizados

### Alta prioridad

- Unificar informacion tecnica en un solo campo de detalle/comentario.
- Permitir adjuntos opcionales por item.
- Liberar registro de obra mediante codigo obligatorio y descripcion editable.
- Permitir unidad de medida libre ademas de seleccionada.
- Crear filtros de requerimientos por estados: todos, pendientes, enviados y finalizados.
- Agregar busqueda por codigo de obra, numero de RQ, titulo o descripcion.
- Mostrar trazabilidad/estado por item.

### Media prioridad

- Agilizar seleccion desde catalogo: seleccionar producto, pedir cantidad y volver al buscador.
- Agregar boton de detalle del producto en catalogo.
- Permitir duplicar producto para equipos o items con varias caracteristicas.
- Mejorar vista previa PDF con zoom.
- Diferenciar vistas por rol: supervisor, logistica y compras.

### Largo plazo

- Integracion con API ERP/RRP para catalogo, stock y costos.
- Reporteria por obra con resumen de requerimientos y estados.
- Semaforo global por obra/requerimiento/item.

## Preguntas abiertas

- Confirmar nombre final del campo unificado: `Detalle de la solicitud`, `Detalle del producto` o `Comentario referencial`.
- Definir estados exactos finales para requerimiento y para item.
- La implementacion utiliza correlativo por obra: `RQ-001-010-2026`. Los RQ anteriores conservan su numero.
- Definir quienes son exactamente los destinatarios de correo por rol/obra.
- Confirmar si el codigo de obra siempre sera `NNN-YYYY` o si habra excepciones.

## Notas de implementacion

- Evitar bloquear el flujo por falta de catalogo, obra preexistente o unidad predefinida.
- El codigo de obra debe tener validacion, pero permitir alta rapida si no existe.
- El nombre/descripcion de obra debe ser editable y secundario.
- Los adjuntos deben ser opcionales.
- La app debe priorizar velocidad de registro para usuarios en campo.
- La trazabilidad debe ser visible para todos los roles, aunque las acciones disponibles cambien por rol.

## Implementacion del Feedback 01

- Obra por codigo `NNN-YYYY`, alta inmediata y sugerencia de descripcion existente. El codigo se guarda separado del nombre editable.
- Correlativo por obra para nuevos registros; compatibilidad con obras y RQ anteriores.
- Un solo campo `Detalle de la solicitud`, con recuperacion de los campos de borradores anteriores.
- Categorias Material, Equipo y Herramienta; unidad libre con sugerencias.
- Seleccion de catalogo con cantidad directa, informacion opcional, producto nuevo y duplicado como nuevo.
- Busqueda por codigo, numero y descripcion; filtros Todos, Pendientes, Enviados y Finalizados.
- Seguimiento individual: Pendiente, Por comprar, En proceso, Comprado, Atendido con stock y Cerrado sin compra.
- Logistica deriva a compra; compras actualiza los items derivados. Cierre sin compra requiere motivo.
- Vistas de inicio, navegacion y acciones segun supervisor, logistica y compras. El backend verifica los permisos.
- Detalle y evidencia de seguimiento separados de la solicitud firmada; fotos y PDF opcionales.
- Vista PDF con zoom por gesto desde la primera vista y paginas deslizables; texto multilinea y unidades libres sin salir de la tabla.
- Tablas nuevas del backend creadas al inicio y migracion local de borradores a version 3.

### Limites actuales

- El catalogo consume la API de almacen actual. La conexion al ERP y la sincronizacion de costos requieren la API oficial de la empresa.
- `Atendido con stock` registra la decision de logistica; no reserva ni descuenta inventario automaticamente.
- Los filtros y la busqueda agrupan operativamente por obra; la reportería consolidada y exportable por obra sigue siendo una ampliacion posterior.
- El envio usa la configuracion SMTP y los destinatarios existentes. Las pruebas de envio utilizan un correo simulado, sin enviar mensajes reales.

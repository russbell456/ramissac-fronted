import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/widgets/app_ui.dart';
import 'package:signature/signature.dart';
import 'package:sistema_ocs/core/database/db_helper.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_local_model.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_item_data.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_status.dart';
import 'package:sistema_ocs/features/rq_urgente/non_catalogued_product_form_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/services/urgent_rq_service.dart';
import 'package:sistema_ocs/features/rq_urgente/urgent_rq_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/document_preview_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_attachments.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_widgets.dart';

class RqReviewScreen extends StatefulWidget {
  final RQLocal? local;
  final int? servidorId;
  final UrgentRQService? service;
  const RqReviewScreen({super.key, this.local, this.servidorId, this.service});
  @override
  State<RqReviewScreen> createState() => _RqReviewScreenState();
}

class _RqReviewScreenState extends State<RqReviewScreen> {
  late final _service = widget.service ?? UrgentRQService();
  RQLocal? _local;
  Map<String, dynamic>? _remote;
  List<Map<String, dynamic>> _stock = [];
  bool _busy = false;
  String? _error;
  String _rol = '';
  int? get _id => _local?.servidorId ?? widget.servidorId;

  @override
  void initState() {
    super.initState();
    _local = widget.local;
    if (_id != null || _local?.tieneObra == true) _cargar();
  }

  Future<void> _persistir() async {
    if (_local == null) return;
    if (_local!.id == null) {
      _local!.id = await DBHelper.insertarRQ(_local!);
    } else {
      await DBHelper.actualizarRQ(_local!);
    }
  }

  List<Map<String, dynamic>> _productosServidor(Map<String, dynamic> data) =>
      (data['items'] as List)
          .map((raw) => <String, dynamic>{
                ...raw as Map<String, dynamic>,
                'nombre': raw['nombre_producto'],
                'unidad': raw['unidad_medida'],
                'categoria': RegExp(r'^Tipo: (.+)$', multiLine: true)
                    .firstMatch(raw['descripcion']?.toString() ?? '')
                    ?.group(1),
                'fecha_vencimiento': RegExp(
                        r'^Vencimiento de referencia: (\d{4}-\d{2}-\d{2})$',
                        multiLine: true)
                    .firstMatch(raw['descripcion']?.toString() ?? '')
                    ?.group(1),
                'descripcion': (raw['descripcion']?.toString() ?? '')
                    .replaceAll(
                        RegExp(
                            r'^(?:Tipo: .+|Vencimiento de referencia: \d{4}-\d{2}-\d{2})\n?',
                            multiLine: true),
                        '')
                    .trim(),
              })
          .toList();

  Future<void> _cargar() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _rol = await const SessionStorage().read(key: 'user_role') ?? '';
      if (_id == null && _local != null) {
        await _service.guardarEnServidor(_local!);
        await _persistir();
      }
      final data = await _service.obtener(_id!);
      final stock = await _service.stock(_id!);
      if (_local == null && data['estado'] != 'ENVIADO') {
        final userJson = await const SessionStorage().read(key: 'user_data');
        final user = userJson == null
            ? <String, dynamic>{}
            : jsonDecode(userJson) as Map<String, dynamic>;
        if (data['creador_id'] == user['id']) {
          _local = RQLocal(
              obraId: data['obra_id'] as int,
              obraCodigo: data['obra_codigo'] as String?,
              obraDescripcion: data['obra_descripcion'] as String?,
              servidorId: data['id'] as int,
              numero: data['numero'] as String,
              estadoServidor: data['estado'] as String,
              servicio: data['nombre_proyecto'] as String,
              productosJson: jsonEncode(_productosServidor(data)),
              fecha: data['fecha_requerimiento'] as String);
        }
      }
      if (_local != null) {
        _local!.estadoServidor =
            (data['estado_gestion'] ?? data['estado']) as String;
        _local!.numero = data['numero'] as String;
        _local!.obraId = data['obra_id'] as int;
        _local!.obraCodigo = data['obra_codigo'] as String?;
        _local!.obraDescripcion = data['obra_descripcion'] as String?;
        _local!.servicio = data['nombre_proyecto'] as String;
        _local!.enviado = data['estado'] == 'ENVIADO' ? 1 : 0;
        await _persistir();
      }
      if (mounted) {
        setState(() {
          _remote = data;
          _stock = stock;
          if (data['estado'] == 'FIRMADO' && data['error_envio'] != null) {
            _error =
                'El requerimiento quedó firmado, pero el correo no se pudo enviar. Puede reintentar el envío.';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = UrgentRQService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editar() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => UrgentRQScreen(rqExistente: _local)));
    if (!mounted) return;
    final rows = await DBHelper.obtenerRQs();
    final matches = rows.where((r) => r.id == _local!.id);
    if (matches.isNotEmpty && mounted) setState(() => _local = matches.first);
    if (_id != null) await _cargar();
  }

  Future<void> _pdf() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_local != null && _local!.editable) {
        await _service.guardarEnServidor(_local!);
        await _persistir();
      }
      final bytes = await _service.pdf(_id!);
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DocumentPreviewScreen(
                  bytes: bytes,
                  filename:
                      '${_local?.numero ?? _remote?['numero'] ?? 'Requerimiento'}.pdf')));
    } catch (e) {
      if (mounted) setState(() => _error = UrgentRQService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List?> _firma() async {
    final controller = SignatureController(
        penStrokeWidth: 3,
        penColor: AppTheme.primaryDark,
        exportBackgroundColor: Colors.white);
    try {
      final firmado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
                insetPadding: const EdgeInsets.all(16),
                title: const Text('Firmar y enviar'),
                content: SizedBox(
                    width: 420,
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text(
                              'El requerimiento y sus adjuntos se enviarán a los destinatarios configurados. Después de firmarlo no podrá editarlo.'),
                          const SizedBox(height: 16),
                          Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Signature(
                                      controller: controller,
                                      height: 160,
                                      backgroundColor: Colors.white))),
                          TextButton(
                              onPressed: controller.clear,
                              child: const Text('Limpiar firma')),
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar')),
                  AnimatedBuilder(
                      animation: controller,
                      builder: (context, value) => FilledButton(
                          onPressed: controller.isEmpty
                              ? null
                              : () => Navigator.pop(c, true),
                          child: const Text('Firmar y enviar')))
                ],
              ));
      return firmado == true ? await controller.toPngBytes() : null;
    } finally {
      controller.dispose();
    }
  }

  Future<void> _enviar() async {
    if (_busy || _local == null || !_local!.tieneObra) return;
    Uint8List? firma;
    if (_local!.estadoServidor != 'FIRMADO') {
      firma = await _firma();
      if (firma == null || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.enviar(_local!, firma, _persistir);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Requerimiento enviado')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = UrgentRQService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_id != null && mounted) await _cargar();
  }

  Future<void> _gestionar(Map<String, dynamic> item) async {
    final actual = (item['estado_gestion'] ?? 'PENDIENTE').toString();
    final opciones = <String>{
      if (esLogistica(_rol)) ...[
        'PENDIENTE',
        'POR_COMPRAR',
        'ATENDIDO_STOCK',
        'CERRADO_SIN_COMPRA'
      ],
      if (esCompras(_rol) &&
          (_rol == 'admin' ||
              ['POR_COMPRAR', 'EN_PROCESO'].contains(actual))) ...[
        'EN_PROCESO',
        'COMPRADO',
        'CERRADO_SIN_COMPRA'
      ],
    }.toList();
    if (opciones.isEmpty) return;
    var estado = opciones.contains(actual) ? actual : opciones.first;
    final nota =
        TextEditingController(text: item['nota_gestion']?.toString() ?? '');
    final form = GlobalKey<FormState>();
    final guardar = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, actualizar) => AlertDialog(
                    title: const Text('Seguimiento del ítem'),
                    content: Form(
                        key: form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          DropdownButtonFormField<String>(
                              initialValue: estado,
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Estado'),
                              items: opciones
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(estadosRqItem[e]!)))
                                  .toList(),
                              onChanged: (v) => actualizar(() => estado = v!)),
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: nota,
                              maxLines: 3,
                              maxLength: 2000,
                              decoration: const InputDecoration(
                                  labelText: 'Comentario o motivo',
                                  counterText: ''),
                              validator: (v) =>
                                  estado == 'CERRADO_SIN_COMPRA' &&
                                          (v ?? '').trim().isEmpty
                                      ? 'Ingrese el motivo del cierre'
                                      : null),
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () {
                            if (form.currentState!.validate()) {
                              Navigator.pop(c, true);
                            }
                          },
                          child: const Text('Guardar'))
                    ])));
    final texto = nota.text.trim();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nota.dispose();
    if (guardar != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.gestionarItem(_id!, item['id'] as int, estado, texto);
      await _cargar();
    } catch (e) {
      if (mounted) setState(() => _error = UrgentRQService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _evidencia(Map<String, dynamic> item) async {
    final producto = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                NonCataloguedProductFormScreen(soloEvidencia: true, producto: {
                  ...item,
                  'nombre': item['nombre_producto'],
                  'unidad': item['unidad_medida'],
                  'detalle': item['detalle_gestion'] ?? detalleProducto(item),
                  'adjuntos': item['adjuntos_gestion'] ?? [],
                  'foto_base64': null,
                })));
    if (producto == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.gestionarItem(_id!, item['id'] as int,
          item['estado_gestion'].toString(), item['nota_gestion']?.toString(),
          detalle: detalleProducto(producto),
          adjuntos: (producto['adjuntos'] as List)
              .map((a) => <String, dynamic>{
                    'nombre': a['nombre'],
                    'tipo_mime': a['tipo_mime'],
                    'contenido_base64': a['contenido_base64']
                  })
              .toList());
      await _cargar();
    } catch (e) {
      if (mounted) setState(() => _error = UrgentRQService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = _local;
    final estado = local?.estadoServidor ??
        _remote?['estado_gestion'] ??
        _remote?['estado'] ??
        'BORRADOR';
    final editable = local?.editable == true;
    final items = local != null && (editable || _remote == null)
        ? (jsonDecode(local.productosJson) as List).cast<Map<String, dynamic>>()
        : (_remote?['items'] as List? ?? [])
            .map((raw) => <String, dynamic>{
                  ...raw as Map<String, dynamic>,
                  'nombre': raw['nombre_producto'],
                  'unidad': raw['unidad_medida']
                })
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Requerimiento'), actions: [
        if (editable)
          IconButton(
              onPressed: _busy ? null : _editar,
              tooltip: 'Editar borrador',
              icon: const Icon(LucideIcons.pencil, size: 20)),
        IconButton(
            onPressed: _busy || (_id == null && local?.tieneObra != true)
                ? null
                : _pdf,
            tooltip: 'Vista previa del PDF',
            icon: const Icon(LucideIcons.fileText, size: 20)),
      ]),
      body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    if (_busy) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 16)
                    ],
                    if (_error != null) ...[
                      Text(_error!,
                          style: const TextStyle(color: AppTheme.error)),
                      const SizedBox(height: 12)
                    ],
                    RqSection(
                        title: local?.numero ??
                            _remote?['numero']?.toString() ??
                            'Borrador',
                        subtitle: estado == 'FIRMADO'
                            ? 'Firmado · pendiente de envío. Puede reintentar sin volver a firmar.'
                            : null,
                        action: AppStatusBadge(
                            label: etiquetaRq(estado.toString()),
                            color: colorEstadoRq(estado.toString())),
                        child: Text(
                            local?.servicio ??
                                _remote?['nombre_proyecto']?.toString() ??
                                'Cargando obra…',
                            style: AppTheme.titleMedium)),
                    if (local != null && !local.tieneObra) ...[
                      const SizedBox(height: 12),
                      const Text(
                          'Ingrese el código de obra para continuar con este borrador.',
                          style: TextStyle(color: AppTheme.error))
                    ],
                    const SizedBox(height: 8),
                    ...items.asMap().entries.map((entry) {
                      final serverItems = _remote?['items'] as List? ?? [];
                      final remoteItem = serverItems
                          .where((raw) => raw['numero_item'] == entry.key + 1)
                          .firstOrNull;
                      final p = <String, dynamic>{
                        ...entry.value,
                        for (final field in [
                          'medidas',
                          'especificaciones',
                          'descripcion',
                          'observacion'
                        ])
                          if ((entry.value[field] ?? '').toString().isEmpty &&
                              remoteItem?[field] != null)
                            field: remoteItem[field],
                        if ((entry.value['adjuntos'] as List? ?? []).isEmpty &&
                            remoteItem != null)
                          'adjuntos': remoteItem['adjuntos'],
                      };
                      final files = (p['adjuntos'] as List? ?? [])
                          .cast<Map<String, dynamic>>();
                      final foto = p['foto_base64'];
                      final rowStock = _stock
                          .where((s) => s['numero_item'] == entry.key + 1)
                          .toList();
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: AppTheme.surface,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              shape: const Border(),
                              collapsedShape: const Border(),
                              title: Text('${entry.key + 1}. ${p['nombre']}',
                                  style: AppTheme.titleSmall),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child:
                                    Wrap(spacing: 8, runSpacing: 4, children: [
                                  Text('${p['cantidad']} ${p['unidad'] ?? ''}',
                                      style: AppTheme.bodySmall),
                                  if (rowStock.isNotEmpty)
                                    StockLabel(
                                        stock: rowStock.first['stock_actual']
                                            as num,
                                        unit: p['unidad']?.toString() ?? ''),
                                  if (rowStock.isNotEmpty &&
                                      (rowStock.first['faltante'] as num) > 0)
                                    Text(
                                        'Por conseguir: ${rowStock.first['faltante']}',
                                        style: AppTheme.bodySmall
                                            .copyWith(color: AppTheme.warning)),
                                  if (remoteItem != null &&
                                      _remote?['estado'] == 'ENVIADO')
                                    AppStatusBadge(
                                        label: etiquetaRq(
                                            remoteItem['estado_gestion']
                                                    ?.toString() ??
                                                'PENDIENTE'),
                                        color: colorEstadoRq(
                                            remoteItem['estado_gestion']
                                                    ?.toString() ??
                                                'PENDIENTE')),
                                  if (p['articulo_id'] == null)
                                    const Text('No registrado',
                                        style: AppTheme.bodySmall),
                                ]),
                              ),
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (detalleProducto(p).isNotEmpty)
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Text(detalleProducto(p))),
                                      if (p['fecha_requerida'] != null)
                                        Text(
                                            'Fecha requerida: ${p['fecha_requerida'].toString().split('T').first}',
                                            style: AppTheme.bodySmall),
                                      if (_remote?['estado'] == 'ENVIADO' &&
                                          remoteItem != null) ...[
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  etiquetaRq(remoteItem[
                                                              'estado_gestion']
                                                          ?.toString() ??
                                                      'PENDIENTE'),
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: colorEstadoRq(
                                                          remoteItem['estado_gestion']
                                                                  ?.toString() ??
                                                              'PENDIENTE'),
                                                      fontWeight:
                                                          FontWeight.w600))),
                                          if (esLogistica(_rol) ||
                                              esCompras(_rol))
                                            IconButton(
                                                tooltip:
                                                    'Actualizar seguimiento',
                                                onPressed: _busy
                                                    ? null
                                                    : () => _gestionar(Map<
                                                            String,
                                                            dynamic>.from(
                                                        remoteItem)),
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18)),
                                        ]),
                                        if (remoteItem['nota_gestion'] != null)
                                          Text(
                                              remoteItem['nota_gestion']
                                                  .toString(),
                                              style: AppTheme.bodySmall),
                                        if (remoteItem['detalle_gestion'] !=
                                            null)
                                          Text(
                                              remoteItem['detalle_gestion']
                                                  .toString(),
                                              style: AppTheme.bodySmall),
                                        if ((remoteItem['adjuntos_gestion']
                                                    as List? ??
                                                [])
                                            .isNotEmpty)
                                          RqAttachments(
                                              files: (remoteItem[
                                                          'adjuntos_gestion']
                                                      as List)
                                                  .cast<
                                                      Map<String, dynamic>>()),
                                        if (esLogistica(_rol) ||
                                            esCompras(_rol))
                                          TextButton.icon(
                                              onPressed: _busy
                                                  ? null
                                                  : () => _evidencia(
                                                      Map<String, dynamic>.from(
                                                          remoteItem)),
                                              icon: const Icon(
                                                  Icons.attach_file,
                                                  size: 18),
                                              label: const Text(
                                                  'Detalle y evidencia')),
                                      ],
                                      if (rowStock.isNotEmpty) ...[
                                        StockLabel(
                                            stock: rowStock
                                                .first['stock_actual'] as num,
                                            unit:
                                                p['unidad']?.toString() ?? ''),
                                        if ((rowStock.first['faltante']
                                                as num) >
                                            0)
                                          Text(
                                              'Por conseguir: ${rowStock.first['faltante']} ${p['unidad'] ?? ''}',
                                              style: AppTheme.bodySmall),
                                        const SizedBox(height: 8)
                                      ],
                                      if (files.isNotEmpty)
                                        RqAttachments(files: files)
                                      else if (foto != null)
                                        RqAttachments(files: [
                                          {
                                            'nombre': 'Foto referencial',
                                            'tipo_mime': 'image/png',
                                            'contenido_base64':
                                                foto.toString().split(',').last
                                          }
                                        ]),
                                    ])
                              ],
                            ),
                          ));
                    }),
                    if (_stock.isNotEmpty)
                      const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                              'El stock mostrado es el disponible al consultar. La solicitud no reserva existencias.',
                              style: AppTheme.bodySmall)),
                  ]))),
      bottomNavigationBar: local == null || local.enviado == 1
          ? null
          : RqFooter(
              label:
                  estado == 'FIRMADO' ? 'Reintentar envío' : 'Firmar y enviar',
              busy: _busy,
              onPressed: local.tieneObra ? _enviar : null,
              secondary:
                  Text('${items.length} productos', style: AppTheme.bodySmall)),
    );
  }
}

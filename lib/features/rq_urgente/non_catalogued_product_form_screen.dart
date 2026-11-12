import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_attachments.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_widgets.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_item_data.dart';

class NonCataloguedProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? producto;
  final bool soloEvidencia;
  const NonCataloguedProductFormScreen(
      {super.key, this.producto, this.soloEvidencia = false});
  @override
  State<NonCataloguedProductFormScreen> createState() => _ProductFormState();
}

class _ProductFormState extends State<NonCataloguedProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  final _unidades = ['UND', 'M', 'M2', 'M3', 'KG', 'LT', 'GLB', 'JGO', 'PZA'];
  String _categoria = 'Material';
  DateTime? _fecha;
  List<Map<String, dynamic>> _adjuntos = [];
  bool _seleccionando = false;
  bool get _catalogado => widget.producto?['articulo_id'] != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto ?? {};
    _fields = {
      for (final key in ['nombre', 'cantidad', 'unidad', 'detalle'])
        key: TextEditingController(
            text: key == 'detalle'
                ? detalleProducto(p)
                : p[key]?.toString() ??
                    (key == 'cantidad'
                        ? '1'
                        : key == 'unidad'
                            ? 'UND'
                            : ''))
    };
    _categoria = categoriaProducto(p);
    _fecha = DateTime.tryParse(p['fecha_requerida']?.toString() ?? '');
    _adjuntos =
        (p['adjuntos'] as List? ?? []).cast<Map<String, dynamic>>().toList();
    // Borradores antiguos: conservar también la foto única.
    if (_adjuntos.isEmpty && p['foto_base64'] != null) {
      final foto = p['foto_base64'].toString();
      _adjuntos.add({
        'nombre': 'Foto referencial.png',
        'tipo_mime':
            foto.startsWith('data:image/jpeg') ? 'image/jpeg' : 'image/png',
        'contenido_base64': foto.split(',').last
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _campo(String key, String label, {int lines = 1, int? maxLength}) =>
      TextFormField(
        controller: _fields[key],
        maxLength: maxLength,
        minLines: lines,
        maxLines: lines == 1 ? 1 : 8,
        readOnly: _catalogado && key == 'nombre',
        decoration: InputDecoration(labelText: label, counterText: ''),
        textCapitalization: TextCapitalization.sentences,
        validator: key == 'nombre'
            ? (v) => v == null || v.trim().isEmpty
                ? 'Ingrese el nombre del producto'
                : null
            : null,
      );

  Future<void> _fechaRequerida() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final fecha = await showDatePicker(
        context: context,
        initialDate: _fecha != null && !_fecha!.isBefore(now) ? _fecha! : now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 730)));
    if (fecha != null && mounted) setState(() => _fecha = fecha);
  }

  Future<void> _adjuntar() async {
    setState(() => _seleccionando = true);
    try {
      final result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          withData: true,
          type: FileType.custom,
          allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf']);
      if (result == null || !mounted) return;
      var rechazados = 0;
      for (final file in result.files) {
        if (_adjuntos.length >= 5 ||
            file.bytes == null ||
            file.size > 5 * 1024 * 1024 ||
            file.size == 0) {
          rechazados++;
          continue;
        }
        final ext = file.extension?.toLowerCase();
        if (!['png', 'jpg', 'jpeg', 'pdf'].contains(ext)) {
          rechazados++;
          continue;
        }
        _adjuntos.add({
          'nombre': file.name,
          'tipo_mime': ext == 'pdf'
              ? 'application/pdf'
              : ext == 'png'
                  ? 'image/png'
                  : 'image/jpeg',
          'contenido_base64': base64Encode(file.bytes!)
        });
      }
      setState(() {});
      if (rechazados > 0) {
        _mensaje(
            'No se agregaron $rechazados archivos. Máximo 5 adjuntos de 5 MB cada uno.');
      }
    } catch (_) {
      if (mounted) {
        _mensaje('No se pudieron abrir los archivos. Intente nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _seleccionando = false);
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final p = <String, dynamic>{
      ...widget.producto ?? {},
      for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      'cantidad':
          double.parse(_fields['cantidad']!.text.trim().replaceAll(',', '.')),
      'categoria': _categoria,
      'medidas': null,
      'especificaciones': null,
      'descripcion': null,
      'observacion': null,
      'fecha_vencimiento': null,
      'fecha_requerida': _fecha?.toIso8601String(),
      'adjuntos': _adjuntos,
      'foto_base64': null,
      'no_catalogado': !_catalogado
    };
    Navigator.pop(context, p);
  }

  void _mensaje(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.producto == null
                ? 'Producto no registrado'
                : 'Detalles del producto')),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                    key: _formKey,
                    child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          if (!widget.soloEvidencia)
                            RqSection(
                                title: 'Producto solicitado',
                                child: Column(children: [
                                  _campo('nombre', 'Nombre o referencia *',
                                      maxLength: 200),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                      initialValue: _categoria,
                                      decoration: const InputDecoration(
                                          labelText: 'Tipo'),
                                      items: [
                                        'Material',
                                        'Equipo',
                                        'Herramienta'
                                      ]
                                          .map((v) => DropdownMenuItem(
                                              value: v, child: Text(v)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _categoria = v!)),
                                  const SizedBox(height: 12),
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: TextFormField(
                                                controller: _fields['cantidad'],
                                                keyboardType:
                                                    const TextInputType
                                                        .numberWithOptions(
                                                        decimal: true),
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Cantidad *'),
                                                validator: (v) {
                                                  final value = double.tryParse(
                                                      (v ?? '')
                                                          .trim()
                                                          .replaceAll(
                                                              ',', '.'));
                                                  if (value == null ||
                                                      !value.isFinite ||
                                                      value <= 0 ||
                                                      value >= 10000000000) {
                                                    return 'Ingrese una cantidad válida';
                                                  }
                                                  if (!RegExp(
                                                          r'^\d+(?:[.,]\d{1,2})?$')
                                                      .hasMatch(v!.trim())) {
                                                    return 'Use hasta 2 decimales';
                                                  }
                                                  return null;
                                                })),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: TextFormField(
                                                controller: _fields['unidad'],
                                                readOnly: _catalogado,
                                                maxLength: 50,
                                                decoration: InputDecoration(
                                                    labelText: 'Unidad *',
                                                    counterText: '',
                                                    suffixIcon: _catalogado
                                                        ? null
                                                        : PopupMenuButton<
                                                            String>(
                                                            tooltip:
                                                                'Unidades frecuentes',
                                                            icon: const Icon(
                                                                LucideIcons
                                                                    .chevronDown,
                                                                size: 18),
                                                            onSelected: (v) =>
                                                                _fields['unidad']!
                                                                    .text = v,
                                                            itemBuilder: (_) => _unidades
                                                                .map((u) =>
                                                                    PopupMenuItem(
                                                                        value:
                                                                            u,
                                                                        child: Text(
                                                                            u)))
                                                                .toList(),
                                                          )),
                                                validator: (v) =>
                                                    (v ?? '').trim().isEmpty
                                                        ? 'Ingrese la unidad'
                                                        : null)),
                                      ]),
                                ])),
                          const SizedBox(height: 8),
                          RqSection(
                              title: 'Detalle de la solicitud',
                              child: Column(children: [
                                _campo('detalle', 'Detalle', lines: 3),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                      child: TextButton.icon(
                                          onPressed: _fechaRequerida,
                                          icon: const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18),
                                          label: Text(_fecha == null
                                              ? 'Fecha requerida'
                                              : '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'))),
                                  if (_fecha != null)
                                    IconButton(
                                        tooltip: 'Quitar fecha',
                                        onPressed: () =>
                                            setState(() => _fecha = null),
                                        icon: const Icon(Icons.close, size: 18))
                                ]),
                              ])),
                          const SizedBox(height: 8),
                          RqSection(
                              title: 'Fotos y ficha técnica',
                              subtitle:
                                  'Hasta 5 archivos PNG, JPG o PDF, de 5 MB cada uno.',
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OutlinedButton.icon(
                                        onPressed: _seleccionando ||
                                                _adjuntos.length >= 5
                                            ? null
                                            : _adjuntar,
                                        icon: const Icon(Icons.attach_file,
                                            size: 18),
                                        label: Text(_seleccionando
                                            ? 'Abriendo archivos…'
                                            : 'Adjuntar')),
                                    if (_adjuntos.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      RqAttachments(
                                          files: _adjuntos,
                                          onRemove: (i) => setState(
                                              () => _adjuntos.removeAt(i)))
                                    ],
                                  ])),
                        ])))),
        bottomNavigationBar: RqFooter(
            label: widget.producto == null
                ? 'Agregar producto'
                : 'Guardar detalles',
            onPressed: _guardar),
      );
}

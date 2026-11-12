import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/data/models/articulo_model.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulo_provider.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_widgets.dart';

class ArticuloFormScreen extends ConsumerStatefulWidget {
  final ArticuloModel? articulo;
  const ArticuloFormScreen({super.key, this.articulo});
  @override
  ConsumerState<ArticuloFormScreen> createState() => _ArticuloFormScreenState();
}

class _ArticuloFormScreenState extends ConsumerState<ArticuloFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late String _tipo;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final a = widget.articulo;
    _fields = {
      for (final e in <String, String?>{
        'nombre': a?.nombre,
        'unidad_medida': a?.unidadMedida ?? 'UND',
        'codigo_excel': a?.codigoExcel,
        'serie': a?.serie,
        'marca': a?.marca,
        'modelo': a?.modelo,
        'categoria': a?.categoria,
        'descripcion': a?.descripcion,
        'medidas': a?.medidas,
        'especificaciones': a?.especificaciones,
        'observacion': a?.observacion,
      }.entries)
        e.key: TextEditingController(text: e.value ?? '')
    };
    _tipo = a?.tipo.toUpperCase() ?? 'CONSUMIBLE';
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(String key, String label,
          {bool required = false, int lines = 1, int? maxLength}) =>
      TextFormField(
          controller: _fields[key],
          minLines: lines,
          maxLines: lines == 1 ? 1 : 4,
          maxLength: maxLength,
          decoration: InputDecoration(labelText: label, counterText: ''),
          validator: (v) => required &&
                  (v == null || v.trim().length < (key == 'nombre' ? 2 : 1))
              ? 'Complete este campo'
              : null);
  Future<void> _guardar() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      for (final e in _fields.entries)
        e.key: e.value.text.trim().isEmpty ? null : e.value.text.trim(),
      'tipo': _tipo
    };
    try {
      final notifier = ref.read(articulosListProvider.notifier);
      if (widget.articulo == null) {
        await notifier.crear(data);
      } else {
        await notifier.actualizar(widget.articulo!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo guardar el producto: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              widget.articulo == null ? 'Nuevo producto' : 'Editar producto')),
      body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                  key: _form,
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    RqSection(
                        title: 'Identificación',
                        child: Column(children: [
                          _field('nombre', 'Nombre *',
                              required: true, maxLength: 150),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              initialValue: _tipo,
                              decoration:
                                  const InputDecoration(labelText: 'Tipo *'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'CONSUMIBLE',
                                    child: Text('Consumible')),
                                DropdownMenuItem(
                                    value: 'EQUIPO', child: Text('Equipo')),
                                DropdownMenuItem(
                                    value: 'HERRAMIENTA',
                                    child: Text('Herramienta')),
                              ],
                              onChanged: (v) => setState(() => _tipo = v!)),
                          const SizedBox(height: 12),
                          _field('unidad_medida', 'Unidad de medida *',
                              required: true, maxLength: 50),
                          const SizedBox(height: 12),
                          _field('codigo_excel', 'Código', maxLength: 100),
                          const SizedBox(height: 12),
                          _field('categoria', 'Categoría', maxLength: 100),
                        ])),
                    const SizedBox(height: 16),
                    RqSection(
                        title: 'Ficha del producto',
                        child: Column(children: [
                          _field('descripcion', 'Descripción', lines: 2),
                          const SizedBox(height: 12),
                          _field('medidas', 'Medidas', maxLength: 150),
                          const SizedBox(height: 12),
                          _field(
                              'especificaciones', 'Especificaciones técnicas',
                              lines: 2),
                          const SizedBox(height: 12),
                          _field('observacion', 'Observación', lines: 2),
                          const SizedBox(height: 12),
                          _field('marca', 'Marca', maxLength: 100),
                          const SizedBox(height: 12),
                          _field('modelo', 'Modelo', maxLength: 150),
                          const SizedBox(height: 12),
                          _field('serie', 'Número de serie', maxLength: 150),
                        ])),
                  ])))),
      bottomNavigationBar: RqFooter(
          label: 'Guardar producto', busy: _saving, onPressed: _guardar));
}

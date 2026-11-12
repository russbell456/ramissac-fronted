import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/widgets/app_ui.dart';
import 'package:sistema_ocs/core/database/db_helper.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_local_model.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_item_data.dart';
import 'package:sistema_ocs/features/rq_urgente/non_catalogued_product_form_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/services/urgent_rq_service.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_widgets.dart';

class UrgentRQScreen extends StatefulWidget {
  final RQLocal? rqExistente;
  final UrgentRQService? service;
  const UrgentRQScreen({super.key, this.rqExistente, this.service});
  @override
  State<UrgentRQScreen> createState() => _UrgentRQScreenState();
}

class _UrgentRQScreenState extends State<UrgentRQScreen> {
  late final UrgentRQService _service = widget.service ?? UrgentRQService();
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _descripcion = TextEditingController();
  List<Map<String, dynamic>> _obras = [];
  List<Map<String, dynamic>> _productos = [];
  int? _obraId;
  String? _obraNombreSeleccionada;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rq = widget.rqExistente;
    if (rq != null) {
      _obraId = rq.obraId;
      _codigo.text = rq.obraCodigo ??
          RegExp(r'^\d{3}-\d{4}').stringMatch(rq.servicio) ??
          '';
      _descripcion.text = rq.obraDescripcion ??
          rq.servicio.replaceFirst(RegExp(r'^\d{3}-\d{4}\s*-?\s*'), '');
      _productos =
          (jsonDecode(rq.productosJson) as List).cast<Map<String, dynamic>>();
    }
    _cargarObras();
  }

  @override
  void dispose() {
    _codigo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _buscarObra(String codigo) {
    String cleanCode = codigo.trim();
    if (RegExp(r'^\d{1,2}-\d{4}$').hasMatch(cleanCode)) {
      final partes = cleanCode.split('-');
      cleanCode = '${partes[0].padLeft(3, '0')}-${partes[1]}';
    }

    final match = _obras.where((o) {
      final nom = o['nombre'].toString();
      final cod = RegExp(r'^\d{3}-\d{4}').stringMatch(nom);
      return cod == cleanCode || nom.toLowerCase().contains(cleanCode.toLowerCase());
    }).firstOrNull;

    setState(() {
      _obraId = match?['id'] as int?;
      if (match != null) {
        final cod = RegExp(r'^\d{3}-\d{4}').stringMatch(match['nombre'].toString());
        if (cod != null && _codigo.text != cod) {
          _codigo.text = cod;
        }
        _obraNombreSeleccionada = match['nombre'].toString();
        _descripcion.text = (match['descripcion'] ??
                match['nombre'].toString().replaceFirst(RegExp(r'^\d{3}-\d{4}\s*-?\s*'), ''))
            .toString();
      } else {
        _obraNombreSeleccionada = null;
      }
    });
  }

  Future<void> _seleccionarObraModal() async {
    if (_obras.isEmpty && !_cargando) {
      await _cargarObras();
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalCtx) {
        String filtro = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtradas = _obras.where((o) {
              final nombre = (o['nombre'] ?? '').toString().toLowerCase();
              final desc = (o['descripcion'] ?? '').toString().toLowerCase();
              final cli = (o['cliente'] ?? '').toString().toLowerCase();
              final f = filtro.toLowerCase().trim();
              return f.isEmpty || nombre.contains(f) || desc.contains(f) || cli.contains(f);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.building2, size: 20, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      const Text('Seleccionar Obra Registrada', style: AppTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Buscar por código, nombre o cliente...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) => setModalState(() => filtro = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtradas.isEmpty
                        ? const Center(
                            child: Text('No se encontraron obras registradas',
                                style: AppTheme.bodySmall),
                          )
                        : ListView.separated(
                            itemCount: filtradas.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final o = filtradas[i];
                              final nombreCompleto = o['nombre']?.toString() ?? '';
                              final codigoMatch = RegExp(r'^\d{3}-\d{4}').stringMatch(nombreCompleto);
                              final descLimpia = nombreCompleto.replaceFirst(RegExp(r'^\d{3}-\d{4}\s*-?\s*'), '');
                              final cliente = o['cliente']?.toString();
                              final ubicacion = o['ubicacion']?.toString();

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    codigoMatch ?? 'OBRA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  descLimpia.isNotEmpty ? descLimpia : nombreCompleto,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  [
                                    if (cliente != null && cliente.isNotEmpty) cliente,
                                    if (ubicacion != null && ubicacion.isNotEmpty) ubicacion,
                                  ].join(' • '),
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                onTap: () {
                                  Navigator.pop(modalCtx);
                                  setState(() {
                                    _obraId = o['id'] as int?;
                                    _obraNombreSeleccionada = nombreCompleto;
                                    if (codigoMatch != null) {
                                      _codigo.text = codigoMatch;
                                    }
                                    _descripcion.text = (o['descripcion'] ?? descLimpia).toString();
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cargarObras() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final obras = await _service.obrasActivas();
      if (!mounted) return;
      setState(() {
        _obras = obras;
        if (!_obras.any((obra) => obra['id'] == _obraId)) _obraId = null;
        _cargando = false;
      });
      if (_codigo.text.isNotEmpty && _descripcion.text.isEmpty) {
        _buscarObra(_codigo.text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = UrgentRQService.mensajeError(e);
      });
    }
  }

  Future<void> _catalogo() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (_) => _CatalogoSelector(
        service: _service,
        seleccionados:
            _productos.map((p) => p['articulo_id']).whereType<int>().toSet(),
        onAgregar: (producto) => setState(() => _productos.add({
              'articulo_id': producto['id'],
              'nombre': producto['nombre'],
              'unidad': producto['unidad_medida'],
              'cantidad': producto['cantidad'] ?? 1,
              'categoria': categoriaProducto(producto),
              'descripcion': producto['descripcion'],
              'stock_actual': producto['stock_actual'],
              'medidas': producto['medidas'],
              'especificaciones': producto['especificaciones'],
              'observacion': producto['observacion'],
              'adjuntos': producto['adjuntos'] ?? [],
            })),
        onNuevo: () async {
          Navigator.pop(context);
          await _editarProducto();
        },
      ),
    );
  }

  Future<void> _editarProducto([int? index]) async {
    final producto = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
            builder: (_) => NonCataloguedProductFormScreen(
                producto: index == null ? null : _productos[index])));
    if (producto == null || !mounted) return;
    setState(() {
      if (index == null) {
        _productos.add(producto);
      } else {
        _productos[index] = producto;
      }
    });
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    if (_productos.isEmpty) {
      _mensaje('Agregue al menos un producto');
      return;
    }
    final anterior = widget.rqExistente;
    final rq = RQLocal(
        id: anterior?.id,
        obraId: _obraId,
        obraCodigo: _codigo.text.trim(),
        obraDescripcion: _descripcion.text.trim(),
        servidorId: anterior?.servidorId,
        numero: anterior?.numero,
        estadoServidor: anterior?.estadoServidor ?? 'BORRADOR',
        servicio: '${_codigo.text.trim()} - ${_descripcion.text.trim()}',
        productosJson: jsonEncode(_productos),
        fecha: anterior?.fecha ?? DateTime.now().toIso8601String());
    setState(() => _guardando = true);
    try {
      if (rq.servidorId != null || kIsWeb) {
        await _service.guardarEnServidor(rq);
        if (!rq.editable) {
          await DBHelper.actualizarRQ(rq);
          throw StateError(
              'Este requerimiento ya fue firmado. Sus cambios no se enviaron.');
        }
      }
      if (rq.id == null) {
        await DBHelper.insertarRQ(rq);
      } else {
        await DBHelper.actualizarRQ(rq);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _mensaje(UrgentRQService.mensajeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String texto) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.rqExistente == null
                ? 'Nuevo requerimiento'
                : 'Editar borrador')),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      Form(
                          key: _formKey,
                          child: RqSection(
                              title: 'Obra o servicio',
                              action: TextButton.icon(
                                onPressed: _guardando ? null : _seleccionarObraModal,
                                icon: const Icon(LucideIcons.listFilter, size: 16),
                                label: const Text('Elegir de la lista',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_cargando)
                                      const LinearProgressIndicator(),
                                    if (_obraId != null) ...[
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF81C784)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 18, color: Color(0xFF2E7D32)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _obraNombreSeleccionada ?? 'Obra existente vinculada',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF1B5E20),
                                                    fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => setState(() {
                                                _obraId = null;
                                                _obraNombreSeleccionada = null;
                                              }),
                                              child: const Icon(Icons.close, size: 16, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    TextFormField(
                                        controller: _codigo,
                                        textInputAction: TextInputAction.next,
                                        enabled: !_guardando,
                                        maxLength: 8,
                                        decoration: const InputDecoration(
                                            labelText: 'Código de obra *',
                                            hintText: '010-2026',
                                            counterText: ''),
                                        validator: (v) =>
                                            RegExp(r'^\d{3}-\d{4}$')
                                                    .hasMatch((v ?? '').trim())
                                                ? null
                                                : 'Use el formato 010-2026',
                                        onChanged: _buscarObra),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                        controller: _descripcion,
                                        enabled: !_guardando,
                                        maxLength: 180,
                                        minLines: 1,
                                        maxLines: 3,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: const InputDecoration(
                                            labelText: 'Descripción de obra *',
                                            counterText: ''),
                                        validator: (v) => (v ?? '')
                                                .trim()
                                                .isEmpty
                                            ? 'Ingrese una descripción breve'
                                            : null),
                                    if (_error != null)
                                      TextButton.icon(
                                          onPressed: _cargarObras,
                                          icon: const Icon(Icons.refresh,
                                              size: 18),
                                          label:
                                              const Text('Actualizar obras')),
                                  ]))),
                      const SizedBox(height: 8),
                      RqSection(
                          title: 'Productos (${_productos.length})',
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  OutlinedButton.icon(
                                      onPressed: _guardando ? null : _catalogo,
                                      icon: const Icon(LucideIcons.search,
                                          size: 18),
                                      label: const Text('Buscar en catálogo')),
                                  TextButton.icon(
                                      onPressed: _guardando
                                          ? null
                                          : () => _editarProducto(),
                                      icon: const Icon(LucideIcons.plus,
                                          size: 18),
                                      label: const Text('No registrado')),
                                ]),
                                const SizedBox(height: 12),
                                if (_productos.isEmpty)
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Text('Sin productos agregados',
                                          style: AppTheme.bodySmall)),
                                ..._productos.asMap().entries.map((entry) {
                                  final p = entry.value;
                                  return Column(children: [
                                    ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        onTap: _guardando
                                            ? null
                                            : () => _editarProducto(entry.key),
                                        title: Text(p['nombre'].toString(),
                                            style: AppTheme.titleSmall),
                                        subtitle: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      '${p['cantidad']} ${p['unidad'] ?? ''} · ${p['articulo_id'] == null ? 'No registrado' : 'Catálogo'}',
                                                      style:
                                                          AppTheme.bodySmall),
                                                  if (p['stock_actual'] != null)
                                                    StockLabel(
                                                        stock: p['stock_actual']
                                                            as num),
                                                  if ((p['observacion'] ?? '')
                                                      .toString()
                                                      .isNotEmpty)
                                                    Text(
                                                        p['observacion']
                                                            .toString(),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                ])),
                                        trailing: PopupMenuButton<String>(
                                            tooltip: 'Opciones del producto',
                                            enabled: !_guardando,
                                            onSelected: (v) {
                                              if (v == 'editar') {
                                                _editarProducto(entry.key);
                                              } else if (v == 'duplicar') {
                                                final original =
                                                    Map<String, dynamic>.from(
                                                        _productos[entry.key])
                                                      ..remove('articulo_id')
                                                      ..remove('id');
                                                Navigator.push<
                                                        Map<String, dynamic>>(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            NonCataloguedProductFormScreen(
                                                                producto:
                                                                    original))).then(
                                                    (p) {
                                                  if (p != null && mounted) {
                                                    setState(() =>
                                                        _productos.add(p));
                                                  }
                                                });
                                              } else {
                                                setState(() => _productos
                                                    .removeAt(entry.key));
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                      value: 'duplicar',
                                                      child: Text(
                                                          'Duplicar como nuevo')),
                                                  PopupMenuItem(
                                                      value: 'editar',
                                                      child: Text(
                                                          'Editar cantidad y detalles')),
                                                  PopupMenuItem(
                                                      value: 'quitar',
                                                      child: Text(
                                                          'Quitar del requerimiento'))
                                                ])),
                                    if (entry.key < _productos.length - 1)
                                      const Divider(height: 1),
                                  ]);
                                }),
                              ])),
                    ]))),
        bottomNavigationBar: RqFooter(
            label: 'Guardar borrador',
            busy: _guardando,
            onPressed: _productos.isEmpty ? null : _guardar,
            secondary: Text('${_productos.length} productos',
                style: AppTheme.bodySmall)),
      );
}

class _CatalogoSelector extends StatefulWidget {
  final UrgentRQService service;
  final Set<int> seleccionados;
  final ValueChanged<Map<String, dynamic>> onAgregar;
  final VoidCallback onNuevo;
  const _CatalogoSelector(
      {required this.service,
      required this.seleccionados,
      required this.onAgregar,
      required this.onNuevo});
  @override
  State<_CatalogoSelector> createState() => _CatalogoSelectorState();
}

class _CatalogoSelectorState extends State<_CatalogoSelector> {
  List<Map<String, dynamic>> _productos = [];
  String _query = '';
  String _filtro = 'Todos';
  bool _loading = true;
  String? _error;

  Future<void> _agregar(Map<String, dynamic> producto) async {
    final cantidad = TextEditingController(text: '1');
    final form = GlobalKey<FormState>();
    final valor = await showDialog<double>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(producto['nombre'].toString(),
                    style: AppTheme.titleSmall),
                content: Form(
                    key: form,
                    child: TextFormField(
                        controller: cantidad,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText:
                                'Cantidad (${producto['unidad_medida'] ?? 'UND'})'),
                        validator: (v) {
                          final n =
                              double.tryParse((v ?? '').replaceAll(',', '.'));
                          return n == null ||
                                  !n.isFinite ||
                                  n <= 0 ||
                                  n >= 10000000000 ||
                                  !RegExp(r'^\d+(?:[.,]\d{1,2})?$')
                                      .hasMatch(v!.trim())
                              ? 'Ingrese una cantidad válida (hasta 2 decimales)'
                              : null;
                        })),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(c,
                              double.parse(cantidad.text.replaceAll(',', '.')));
                        }
                      },
                      child: const Text('Agregar'))
                ]));
    // El diálogo termina su animación antes de desechar el controlador.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    cantidad.dispose();
    if (valor == null || !mounted) return;
    widget.onAgregar({...producto, 'cantidad': valor});
    setState(() => widget.seleccionados.add(producto['id'] as int));
  }

  Future<void> _detalle(Map<String, dynamic> producto) async {
    await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(producto['nombre'].toString(),
                    style: AppTheme.titleSmall),
                content: SingleChildScrollView(
                    child: Text(
                        '${producto['codigo_excel'] ?? ''}\nStock: ${producto['stock_actual'] ?? 0} ${producto['unidad_medida'] ?? ''}\n${detalleProducto(producto)}')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cerrar'))
                ]));
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final productos = await widget.service.buscarProductos('');
      if (mounted) {
        setState(() {
          _productos = productos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = UrgentRQService.mensajeError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _productos.where((p) {
      final coincide =
          '${p['nombre']} ${p['codigo_excel'] ?? ''} ${p['marca'] ?? ''}'
              .toLowerCase()
              .contains(_query.toLowerCase());
      final stock = (p['stock_actual'] as num? ?? 0) > 0;
      return coincide &&
          (_filtro == 'Todos' || (_filtro == 'Con stock' ? stock : !stock));
    }).toList();
    return FractionallySizedBox(
      heightFactor: .92,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
            child: Row(children: [
              const Expanded(
                  child: Text('Catálogo', style: AppTheme.titleLarge)),
              IconButton(
                  onPressed: widget.onNuevo,
                  tooltip: 'Producto nuevo',
                  icon: const Icon(LucideIcons.plus, size: 20)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar catálogo',
                  icon: const Icon(LucideIcons.x, size: 20)),
            ]),
          ),
          Expanded(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Column(children: [
                      AppSearchField(
                          hint: 'Nombre, código o marca',
                          onChanged: (v) => setState(() => _query = v.trim())),
                      AppFilterBar(
                          options: const ['Todos', 'Con stock', 'Sin stock'],
                          selected: _filtro,
                          onSelected: (v) => setState(() => _filtro = v)),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider(height: 1)),
                if (_loading)
                  const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                        icon: LucideIcons.wifiOff,
                        title: _error!,
                        action: TextButton(
                            onPressed: _cargar,
                            child: const Text('Reintentar'))),
                  )
                else if (visibles.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                        icon: LucideIcons.packageSearch,
                        title: 'No se encontraron productos',
                        action: TextButton.icon(
                            onPressed: widget.onNuevo,
                            icon: const Icon(LucideIcons.plus, size: 18),
                            label: const Text('Producto no registrado'))),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((_, index) {
                      final p = visibles[index];
                      final agregado = widget.seleccionados.contains(p['id']);
                      return Column(children: [
                        ListTile(
                          onTap: agregado ? null : () => _agregar(p),
                          contentPadding: const EdgeInsets.only(
                              left: 16, right: 4, top: 4, bottom: 4),
                          title: Text(p['nombre'].toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.titleSmall),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${p['codigo_excel'] ?? 'Sin código'} · ${p['unidad_medida'] ?? ''}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.bodySmall),
                                StockLabel(
                                    stock: p['stock_actual'] as num? ?? 0),
                              ]),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                                tooltip: 'Ver detalle del producto',
                                onPressed: () => _detalle(p),
                                icon: const Icon(LucideIcons.info, size: 20)),
                            IconButton(
                                tooltip:
                                    agregado ? 'Agregado' : 'Agregar producto',
                                onPressed: agregado ? null : () => _agregar(p),
                                icon: Icon(
                                    agregado
                                        ? LucideIcons.circleCheck
                                        : LucideIcons.circlePlus,
                                    size: 22,
                                    color: agregado
                                        ? AppTheme.success
                                        : AppTheme.primary)),
                          ]),
                        ),
                        const Divider(height: 1, indent: 16),
                      ]);
                    }, childCount: visibles.length),
                  ),
              ],
            ),
          ),
          RqFooter(
              label: 'Listo',
              onPressed: () => Navigator.pop(context),
              secondary: Text('${widget.seleccionados.length} seleccionados',
                  style: AppTheme.bodySmall)),
        ]),
      ),
    );
  }
}

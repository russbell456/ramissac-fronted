import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/articulo_model.dart';
import 'package:sistema_ocs/data/services/articulo_service.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulo_form_screen.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulo_provider.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/document_preview_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_widgets.dart';

class ArticuloDetailScreen extends ConsumerStatefulWidget {
  final ArticuloModel articulo;
  final bool canManage;
  const ArticuloDetailScreen(
      {super.key, required this.articulo, this.canManage = true});
  @override
  ConsumerState<ArticuloDetailScreen> createState() =>
      _ArticuloDetailScreenState();
}

class _ArticuloDetailScreenState extends ConsumerState<ArticuloDetailScreen> {
  late ArticuloModel _articulo = widget.articulo;
  bool _busy = false;
  ArticuloService get _service => ref.read(articuloServiceProvider);
  Future<void> _reload() async {
    final articulo = await _service.obtenerArticulo(_articulo.id);
    if (mounted) setState(() => _articulo = articulo);
  }

  Future<void> _editar() async {
    final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => ArticuloFormScreen(articulo: _articulo)));
    if (result == true) await _accion(_reload);
  }

  Future<void> _accion(Future<void> Function() accion) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await accion();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo completar la acción: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _adjuntar(bool pdf) async {
    final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: pdf ? ['pdf'] : ['png', 'jpg', 'jpeg']);
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null || file.size > 5 * 1024 * 1024 || file.size == 0)
      throw Exception('Seleccione un archivo de hasta 5 MB');
    if (pdf) {
      await _service.subirFicha(_articulo.id, file.name, file.bytes!);
    } else {
      await _service.subirImagenBytes(_articulo.id, file.name, file.bytes!);
    }
    await _reload();
  }

  Future<void> _verFicha() async {
    final bytes = await _service.descargarFicha(_articulo.id);
    if (mounted)
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DocumentPreviewScreen(
                  bytes: bytes,
                  filename:
                      _articulo.fichaTecnicaNombre ?? 'Ficha-tecnica.pdf')));
  }

  Future<void> _toggle() async {
    final articulo = _articulo.activo
        ? await _service.desactivarArticulo(_articulo.id)
        : await _service.activarArticulo(_articulo.id);
    if (mounted) setState(() => _articulo = articulo);
    await ref.read(articulosListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ficha del producto'), actions: [
          if (widget.canManage)
            IconButton(
                tooltip: 'Editar producto',
                onPressed: _busy ? null : _editar,
                icon: const Icon(Icons.edit_outlined)),
        ]),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  if (_busy) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16)
                  ],
                  RqSection(
                      title: _articulo.nombre,
                      subtitle:
                          '${_articulo.tipoLabel} · ${_articulo.codigoExcel ?? 'Sin código'}',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StockLabel(
                                stock: _articulo.stockActual,
                                unit: _articulo.unidadMedida ?? ''),
                            if (_articulo.enPrestamo > 0)
                              Text('En préstamo: ${_articulo.enPrestamo}',
                                  style: AppTheme.bodySmall),
                            if (!_articulo.activo)
                              const Text('Producto inactivo',
                                  style: TextStyle(color: AppTheme.error)),
                          ])),
                  const SizedBox(height: 16),
                  RqSection(
                      title: 'Información técnica',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final e in <String, String?>{
                              'Descripción': _articulo.descripcion,
                              'Medidas': _articulo.medidas,
                              'Especificaciones': _articulo.especificaciones,
                              'Observación': _articulo.observacion,
                              'Marca': _articulo.marca,
                              'Modelo': _articulo.modelo,
                              'Serie': _articulo.serie,
                              'Categoría': _articulo.categoria,
                              'Unidad de medida': _articulo.unidadMedida,
                            }.entries)
                              if (e.value?.isNotEmpty == true)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e.key,
                                              style: AppTheme.bodySmall),
                                          const SizedBox(height: 2),
                                          SelectableText(e.value!),
                                        ])),
                            if (widget.canManage)
                              TextButton.icon(
                                  onPressed: _busy ? null : _editar,
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Editar información')),
                          ])),
                  const SizedBox(height: 16),
                  RqSection(
                      title: 'Ficha técnica',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_articulo.fichaTecnicaNombre != null)
                              TextButton.icon(
                                  onPressed:
                                      _busy ? null : () => _accion(_verFicha),
                                  icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 20),
                                  label: Text(_articulo.fichaTecnicaNombre!))
                            else
                              const Text(
                                  'No se ha adjuntado una ficha técnica.',
                                  style: AppTheme.bodySmall),
                            if (widget.canManage)
                              TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _accion(() => _adjuntar(true)),
                                  icon: const Icon(Icons.attach_file, size: 18),
                                  label: Text(
                                      _articulo.fichaTecnicaNombre == null
                                          ? 'Adjuntar PDF'
                                          : 'Reemplazar PDF')),
                          ])),
                  const SizedBox(height: 16),
                  RqSection(
                      title: 'Fotos referenciales',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_articulo.imagenes.isEmpty)
                              const Text('No hay fotos referenciales.',
                                  style: AppTheme.bodySmall),
                            Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _articulo.imagenes.map((img) {
                                  final url = img.ruta.startsWith('http')
                                      ? img.ruta
                                      : '${ApiConfig.baseUrl}${img.ruta}';
                                  final image = Image.network(url,
                                      width: 140,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          const SizedBox(
                                              width: 140,
                                              height: 110,
                                              child: Icon(Icons
                                                  .broken_image_outlined)));
                                  return SizedBox(
                                      width: 140,
                                      child: Column(children: [
                                        InkWell(
                                            onTap: () => showDialog<void>(
                                                context: context,
                                                builder: (c) => Dialog(
                                                        child: Stack(children: [
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(24),
                                                          child:
                                                              InteractiveViewer(
                                                                  child: Image
                                                                      .network(
                                                                          url))),
                                                      Positioned(
                                                          top: 0,
                                                          right: 0,
                                                          child: IconButton(
                                                              tooltip:
                                                                  'Cerrar foto',
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      c),
                                                              icon: const Icon(
                                                                  Icons
                                                                      .close))),
                                                    ]))),
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: image)),
                                        if (widget.canManage)
                                          TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () => _accion(() async {
                                                        await _service
                                                            .eliminarImagen(
                                                                img.id);
                                                        await _reload();
                                                      }),
                                              child: const Text('Quitar foto')),
                                      ]));
                                }).toList()),
                            if (widget.canManage)
                              TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _accion(() => _adjuntar(false)),
                                  icon: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 18),
                                  label: const Text('Agregar foto')),
                          ])),
                  if (widget.canManage) ...[
                    const SizedBox(height: 16),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                            onPressed: _busy || _articulo.enPrestamo > 0
                                ? null
                                : () => _accion(_toggle),
                            icon:
                                const Icon(Icons.visibility_outlined, size: 18),
                            label: Text(_articulo.activo
                                ? 'Desactivar producto'
                                : 'Activar producto')))
                  ],
                ]))),
      );
}

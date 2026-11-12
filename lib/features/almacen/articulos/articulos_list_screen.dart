import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/widgets/app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/articulo_model.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulo_detail_screen.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulo_form_screen.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulo_provider.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_widgets.dart';

class ArticulosListScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const ArticulosListScreen({super.key, this.embedded = false});
  @override
  ConsumerState<ArticulosListScreen> createState() =>
      _ArticulosListScreenState();
}

class _ArticulosListScreenState extends ConsumerState<ArticulosListScreen> {
  String _query = '';
  String _stock = 'Todos';
  String _tipo = 'Todos';
  bool _manage = false;
  @override
  void initState() {
    super.initState();
    _rol();
  }

  Future<void> _rol() async {
    final role = await const SessionStorage().read(key: 'user_role');
    if (mounted) {
      setState(
          () => _manage = ['admin', 'almacenero', 'logistica'].contains(role));
    }
  }

  Future<void> _form() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ArticuloFormScreen()));
    if (mounted) ref.read(articulosListProvider.notifier).refresh();
  }

  Future<void> _detalle(ArticuloModel a) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ArticuloDetailScreen(articulo: a, canManage: _manage)));
    if (mounted) ref.read(articulosListProvider.notifier).refresh();
  }

  Widget _filter({
    required String label,
    required String selected,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final active = selected != 'Todos';
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: label,
      itemBuilder: (_) => options
          .map((value) => PopupMenuItem<String>(
                value: value,
                child: Row(children: [
                  Expanded(child: Text(value == 'Todos' ? 'Todos' : value)),
                  if (selected == value)
                    const Icon(LucideIcons.check,
                        size: 18, color: AppTheme.secondaryDark),
                ]),
              ))
          .toList(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: active ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(children: [
          Expanded(
              child: Text(
            active ? selected : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppTheme.primary : AppTheme.textSecondary),
          )),
          const Icon(LucideIcons.chevronDown,
              size: 18, color: AppTheme.primary),
        ]),
      ),
    );
  }

  Widget _header(int? count) => ColoredBox(
        color: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: AppSearchField(
                      hint: 'Buscar producto',
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()))),
              const SizedBox(width: 4),
              IconButton(
                  tooltip: 'Actualizar catálogo',
                  onPressed: () =>
                      ref.read(articulosListProvider.notifier).refresh(),
                  icon: const Icon(LucideIcons.refreshCw, size: 20)),
              if (_manage)
                IconButton.filled(
                    tooltip: 'Nuevo producto',
                    style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white),
                    onPressed: _form,
                    icon: const Icon(LucideIcons.plus, size: 20)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _filter(
                      label: 'Disponibilidad',
                      selected: _stock,
                      options: const ['Todos', 'Con stock', 'Sin stock'],
                      onChanged: (v) => setState(() => _stock = v))),
              const SizedBox(width: 8),
              Expanded(
                  child: _filter(
                      label: 'Tipo de producto',
                      selected: _tipo,
                      options: const [
                        'Todos',
                        'Consumible',
                        'Equipo',
                        'Herramienta'
                      ],
                      onChanged: (v) => setState(() => _tipo = v))),
            ]),
          ]),
        ),
      );

  Widget _product(ArticuloModel a) => Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _detalle(a),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(
                    a.esEquipo
                        ? LucideIcons.settings
                        : a.esHerramienta
                            ? LucideIcons.wrench
                            : LucideIcons.package,
                    size: 18,
                    color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(a.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark)),
                    const SizedBox(height: 4),
                    Text('${a.tipoLabel} · ${a.codigoExcel ?? 'Sin código'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 7),
                    StockLabel(
                        stock: a.stockActual, unit: a.unidadMedida ?? ''),
                  ])),
              const Padding(
                  padding: EdgeInsets.only(top: 10, left: 4),
                  child: Icon(LucideIcons.chevronRight,
                      size: 18, color: AppTheme.textSecondary)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(articulosListProvider);
    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: data.when(
          loading: () => Column(children: [
            _header(null),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ]),
          error: (e, _) => Column(children: [
            _header(null),
            Expanded(
                child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('No se pudo cargar el catálogo'),
              TextButton(
                  onPressed: () =>
                      ref.read(articulosListProvider.notifier).refresh(),
                  child: const Text('Reintentar')),
            ]))),
          ]),
          data: (rows) {
            final visibles = rows
                .where((a) =>
                    '${a.nombre} ${a.codigoExcel ?? ''} ${a.marca ?? ''} ${a.serie ?? ''}'
                        .toLowerCase()
                        .contains(_query) &&
                    (_stock == 'Todos' ||
                        (_stock == 'Con stock'
                            ? a.stockActual > 0
                            : a.stockActual == 0)) &&
                    (_tipo == 'Todos' || _tipo == a.tipoLabel))
                .toList();
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(articulosListProvider.notifier).refresh(),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _header(rows.length)),
                  SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Text('${visibles.length} resultados',
                        style: AppTheme.bodySmall),
                  )),
                  if (visibles.isEmpty)
                    const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'No hay productos que coincidan con los filtros',
                                    textAlign: TextAlign.center))))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _product(visibles[i])),
                        childCount: visibles.length,
                      )),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Catálogo y stock')), body: body);
  }
}

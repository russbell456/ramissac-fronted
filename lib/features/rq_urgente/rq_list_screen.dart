import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/database/db_helper.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_status.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_local_model.dart';
import 'package:sistema_ocs/features/rq_urgente/rq_review_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/services/urgent_rq_service.dart';
import 'package:sistema_ocs/features/rq_urgente/urgent_rq_screen.dart';

class RQListScreen extends StatefulWidget {
  final String? flujo;
  final UrgentRQService? service;
  final Future<List<RQLocal>> Function()? loadDrafts;
  const RQListScreen({super.key, this.flujo, this.service, this.loadDrafts});
  @override
  State<RQListScreen> createState() => _RQListScreenState();
}

class _RQListScreenState extends State<RQListScreen> {
  late final UrgentRQService _service = widget.service ?? UrgentRQService();
  List<RQLocal> _locales = [];
  List<Map<String, dynamic>> _remotos = [];
  bool _loading = true;
  String? _error;
  String _filtro = 'Todos';
  String _query = '';
  String _rol = '';
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _rol = await const SessionStorage().read(key: 'user_role') ?? '';
      final locales =
          await (widget.loadDrafts?.call() ?? DBHelper.obtenerRQs());
      if (mounted) setState(() => _locales = locales);
      try {
        final remotos = await _service.listar();
        final ids = locales.map((r) => r.servidorId).whereType<int>().toSet();
        final vistos = <int>{};
        final sincronizados = <RQLocal>[];
        for (final local in locales) {
          final matches = remotos.where((r) => r['id'] == local.servidorId);
          if (matches.isNotEmpty) {
            final remoto = matches.first;
            local.estadoServidor =
                (remoto['estado_gestion'] ?? remoto['estado']) as String;
            local.enviado = remoto['estado'] == 'ENVIADO' ? 1 : 0;
            local.numero = remoto['numero'] as String;
            local.obraId = remoto['obra_id'] as int;
            local.obraCodigo = remoto['obra_codigo'] as String?;
            local.obraDescripcion = remoto['obra_descripcion'] as String?;
            if (!local.editable) {
              local.servicio = remoto['nombre_proyecto'] as String;
              local.productosJson = jsonEncode((remoto['items'] as List)
                  .map((i) => {
                        ...i as Map<String, dynamic>,
                        'nombre': i['nombre_producto'],
                        'unidad': i['unidad_medida'],
                      })
                  .toList());
            }
            await DBHelper.actualizarRQ(local);
            if (!vistos.add(local.servidorId!)) {
              continue;
            }
          }
          // Un RQ enviado ausente del listado ya no está disponible para esta sesión.
          if (local.enviado == 1 &&
              local.servidorId != null &&
              matches.isEmpty) {
            continue;
          }
          sincronizados.add(local);
        }
        if (mounted) {
          setState(() {
            _locales = sincronizados;
            _remotos = remotos
                .where((r) => widget.flujo != null || !ids.contains(r['id']))
                .toList();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _error =
              'No se pudo actualizar el historial. ${UrgentRQService.mensajeError(e)}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar los borradores.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _nuevo() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const UrgentRQScreen()));
    if (mounted) await _refresh();
  }

  Future<void> _abrir({RQLocal? local, int? servidorId}) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                RqReviewScreen(local: local, servidorId: servidorId)));
    if (mounted) await _refresh();
  }

  bool _visible(String estado, String texto) =>
      coincideEstadoRq(estado, _filtro) &&
      texto.toLowerCase().contains(_query) &&
      (widget.flujo == null ||
          ['ENVIADO', 'EN_PROCESO', 'FINALIZADO'].contains(estado));
  Widget _fila({
    required String nombre,
    required String estado,
    required String referencia,
    required int cantidad,
    required String fecha,
    required VoidCallback onTap,
  }) {
    final parsed = DateTime.tryParse(fecha);
    final date = parsed == null ? '' : DateFormat('dd/MM/yyyy').format(parsed);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusSmall,
            side: const BorderSide(color: AppTheme.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(referencia,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall)),
                const SizedBox(width: 8),
                Flexible(
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: AppStatusBadge(
                            label: etiquetaRq(estado),
                            color: colorEstadoRq(estado)))),
              ]),
              const SizedBox(height: 6),
              Text(nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleSmall),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                    child: Text(
                        '$cantidad ${cantidad == 1 ? 'producto' : 'productos'}${date.isEmpty ? '' : ' · $date'}',
                        style: AppTheme.bodySmall)),
                const Icon(LucideIcons.chevronRight,
                    size: 18, color: AppTheme.textDisabled),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locales = _locales
        .where((r) =>
            widget.flujo == null &&
            _visible(
                r.estadoServidor, '${r.numero} ${r.servicio} ${r.obraCodigo}'))
        .toList();
    final remotos = _remotos
        .where((r) =>
            _visible((r['estado_gestion'] ?? r['estado']) as String,
                '${r['numero']} ${r['nombre_proyecto']} ${r['obra_codigo']}') &&
            (widget.flujo != 'compras' ||
                (r['items'] as List).any((i) => [
                      'POR_COMPRAR',
                      'EN_PROCESO',
                      'COMPRADO',
                      'CERRADO_SIN_COMPRA'
                    ].contains(i['estado_gestion']))))
        .toList();
    final total = locales.length + remotos.length;
    final canCreate =
        widget.flujo == null && (!esCompras(_rol) || esLogistica(_rol));
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: canCreate && !keyboardOpen
          ? SizedBox(
              height: 48,
              child: FloatingActionButton.extended(
                heroTag: 'nuevo-rq-${widget.flujo ?? 'solicitudes'}',
                onPressed: _nuevo,
                icon: const Icon(LucideIcons.plus, size: 20),
                label: const Text('Nuevo RQ'),
              ))
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: ColoredBox(
                  color: AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: AppSearchField(
                                hint: 'Buscar RQ u obra',
                                onChanged: (v) => setState(
                                    () => _query = v.trim().toLowerCase()))),
                        const SizedBox(width: 4),
                        IconButton(
                            onPressed: _loading ? null : _refresh,
                            tooltip: 'Actualizar solicitudes',
                            icon: const Icon(LucideIcons.refreshCw, size: 20)),
                      ]),
                      AppFilterBar(
                          options: const [
                            'Todos',
                            'Pendientes',
                            'Enviados',
                            'Finalizados'
                          ],
                          selected: _filtro,
                          onSelected: (v) => setState(() => _filtro = v)),
                    ]),
                  ),
                )),
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: 2,
                        child: _loading
                            ? const LinearProgressIndicator(minHeight: 2)
                            : const Divider(height: 1))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Text(
                            '$total ${total == 1 ? 'requerimiento' : 'requerimientos'}',
                            style: AppTheme.bodySmall))),
                if (_error != null)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(children: [
                            const Icon(LucideIcons.wifiOff,
                                size: 18, color: AppTheme.warning),
                            const SizedBox(width: 8),
                            Expanded(
                                child:
                                    Text(_error!, style: AppTheme.bodySmall)),
                            TextButton(
                                onPressed: _refresh,
                                child: const Text('Reintentar')),
                          ]))),
                if (!_loading && total == 0)
                  SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                          icon: LucideIcons.fileSearch,
                          title: _query.isNotEmpty || _filtro != 'Todos'
                              ? 'No hay coincidencias'
                              : 'Todavía no hay requerimientos')),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((_, index) {
                      if (index < locales.length) {
                        final r = locales[index];
                        return _fila(
                            nombre: r.servicio,
                            estado: r.estadoServidor,
                            referencia: r.numero ?? 'Borrador local',
                            cantidad:
                                (jsonDecode(r.productosJson) as List).length,
                            fecha: r.fecha,
                            onTap: () => _abrir(local: r));
                      }
                      final r = remotos[index - locales.length];
                      return _fila(
                          nombre: r['nombre_proyecto'] as String,
                          estado:
                              (r['estado_gestion'] ?? r['estado']) as String,
                          referencia: r['numero'] as String,
                          cantidad: (r['items'] as List).length,
                          fecha: (r['fecha_requerimiento'] ?? '').toString(),
                          onTap: () => _abrir(servidorId: r['id'] as int));
                    }, childCount: total),
                  ),
                ),
                SliverToBoxAdapter(
                    child: SizedBox(height: canCreate ? 88 : 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

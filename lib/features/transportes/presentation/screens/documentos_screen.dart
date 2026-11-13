import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/documento_transporte.dart';
import '../../providers/documentos_provider.dart';
import '../../providers/jornadas_provider.dart';
import '../../data/save_download.dart';
import '../widgets/documento_upload_form.dart';

Color colorDocumento(BuildContext context, String estado) => switch (estado) {
      'verde' => context.ramis.success,
      'amarillo' => context.ramis.warning,
      'rojo' || 'vencido' => context.ramis.error,
      _ => context.ramis.textSecondary,
    };

class MisDocumentosScreen extends ConsumerWidget {
  const MisDocumentosScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(currentUserForTransportProvider).when(
          loading: () => RamisLoading(),
          error: (e, _) =>
              Center(child: Text('No se pudo identificar al conductor: $e')),
          data: (user) => user == null
              ? Center(child: Text('Inicie sesión para ver sus documentos.'))
              : DocumentosScreen(
                  entidad: 'conductor',
                  titularId: user.id,
                  titulo: 'Mis Documentos',
                  embedded: embedded));
}

class DocumentosScreen extends ConsumerStatefulWidget {
  const DocumentosScreen(
      {super.key,
      required this.entidad,
      required this.titularId,
      this.titulo = 'Documentación',
      this.administrar = false,
      this.embedded = false});
  final String entidad, titulo;
  final int titularId;
  final bool administrar, embedded;
  @override
  ConsumerState<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends ConsumerState<DocumentosScreen> {
  bool _ocupado = false;
  String? _mensaje;
  int _pendientes = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _actualizarPendientes();
    _timer = Timer.periodic(Duration(seconds: 30), (_) async {
      try {
        await _actualizarPendientes();
        await _refresh();
      } catch (_) {/* La consola mantiene los datos locales. */}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _actualizarPendientes() async {
    try {
      final count = await ref
          .read(transporteRepositoryProvider)
          .queue
          .pendingDocuments(widget.entidad, widget.titularId);
      if (mounted) setState(() => _pendientes = count);
    } catch (_) {/* Sin sesión no se consultan documentos de otras cuentas. */}
  }

  TitularDocumento get titular =>
      (entidad: widget.entidad, id: widget.titularId);
  Future<void> _refresh() async {
    ref.invalidate(documentosProvider(titular));
    ref.invalidate(conductoresV3Provider);
    await ref.read(documentosProvider(titular).future);
  }

  Future<void> _subir([String? tipo]) async {
    final enviada = await mostrarCargaDocumento(
        context, widget.entidad, widget.titularId,
        tipo: tipo);
    if (enviada == null || !mounted) return;
    setState(() => _mensaje = enviada
        ? 'Documento enviado correctamente.'
        : 'Documento guardado sin conexión. Se enviará automáticamente al recuperar señal.');
    await _actualizarPendientes();
    if (enviada) await _refresh();
  }

  Future<void> _ver(String path) async {
    setState(() => _ocupado = true);
    try {
      final bytes =
          await ref.read(transporteRepositoryProvider).descargarArchivo(path);
      if (!mounted) return;
      final name = Uri.parse(path).pathSegments.last;
      if (!name.toLowerCase().endsWith('.pdf')) {
        await Navigator.push<void>(
            context,
            MaterialPageRoute(
                builder: (_) => RamisScaffold(
                    maxContentWidth: 1200,
                    appBar: RamisAppBar(
                      title: 'Documento adjunto',
                      automaticallyImplyLeading: true,
                    ),
                    body: Center(
                        child: InteractiveViewer(
                            child: Image.memory(Uint8List.fromList(bytes)))))));
      } else if (kIsWeb) {
        await FilePicker.platform
            .saveFile(fileName: name, bytes: Uint8List.fromList(bytes));
      } else {
        await openDownloadedFile(name, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir el archivo: $e')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _revisar(DocumentoTransporte documento, bool aprobar) async {
    final motivo = TextEditingController();
    final form = GlobalKey<FormState>();
    final aceptado = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                scrollable: true,
                title:
                    Text(aprobar ? 'Aprobar documento' : 'Rechazar documento'),
                content: aprobar
                    ? Text(
                        'Confirme que revisó el archivo, la categoría y el vencimiento.')
                    : Form(
                        key: form,
                        child: RamisTextField(
                            controller: motivo,
                            maxLines: 3,
                            decoration: InputDecoration(
                                labelText: 'Motivo del rechazo',
                                helperText: 'Mínimo 10 caracteres'),
                            validator: (v) => (v ?? '').trim().length < 10
                                ? 'Explique el motivo (mínimo 10 caracteres)'
                                : null)),
                actions: [
                  RamisButton(
                    label: 'Volver',
                    onPressed: () => Navigator.pop(ctx, false),
                    variant: RamisButtonVariant.text,
                  ),
                  RamisButton(
                    label: aprobar ? 'Aprobar' : 'Confirmar rechazo',
                    onPressed: () {
                      if (aprobar || form.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    variant: RamisButtonVariant.primary,
                  )
                ]));
    final razon = motivo.text.trim();
    motivo.dispose();
    if (aceptado != true || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await ref.read(transporteRepositoryProvider).revisarDocumento(
          documento.id!, aprobar ? 'aprobado' : 'rechazado', razon);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentos = ref.watch(documentosProvider(titular));
    final catalogo = widget.entidad == 'conductor'
        ? documentosConductor
        : documentosVehiculo;
    return RamisScaffold(
      maxContentWidth: 1200,
      appBar: widget.embedded
          ? null
          : RamisAppBar(
              title: widget.titulo,
              automaticallyImplyLeading: true,
              actions: [
                IconButton(onPressed: _refresh, icon: Icon(Icons.refresh))
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _ocupado ? null : _subir,
          icon: Icon(Icons.upload_file),
          label: Text('Subir documento')),
      body: documentos.when(
          loading: () => RamisLoading(),
          error: (e, _) => ListView(children: [
                RamisErrorView(
                  description: 'No se pudieron cargar los documentos: $e',
                  onRetry: () => ref.invalidate(documentosProvider(
                      (entidad: widget.entidad, id: widget.titularId))),
                ),
                Padding(
                    padding: RamisSpacing.screenPadding,
                    child: RamisButton(
                      label: 'Subir documento sin conexión',
                      onPressed: () => _subir(),
                      variant: RamisButtonVariant.outlined,
                    )),
              ]),
          data: (items) => RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                  padding: EdgeInsets.fromLTRB(RamisSpacing.medium,
                      RamisSpacing.mediumSmall, RamisSpacing.medium, 110),
                  children: [
                    if (_pendientes > 0)
                      RamisCard(
                          padding: EdgeInsets.zero,
                          child: Padding(
                              padding: EdgeInsets.all(RamisSpacing.mediumSmall),
                              child: Text(
                                  '$_pendientes documento(s) guardado(s) · Pendiente de sincronización'))),
                    if (_mensaje != null)
                      RamisCard(
                          padding: EdgeInsets.zero,
                          child: Padding(
                              padding: EdgeInsets.all(RamisSpacing.mediumSmall),
                              child: Text(_mensaje!))),
                    if (_ocupado) LinearProgressIndicator(),
                    for (final entry in catalogo.entries)
                      _card(
                          entry.key,
                          entry.value,
                          items.where((d) => d.tipo == entry.key).firstOrNull ??
                              DocumentoTransporte.fromJson(
                                  {'tipo': entry.key})),
                    ExpansionTile(
                        title: Text('Historial de versiones'),
                        children: [
                          RamisButton(
                            label: 'Consultar historial',
                            onPressed: () async {
                              try {
                                final rows = await ref
                                    .read(transporteRepositoryProvider)
                                    .historialDocumentos(
                                        widget.entidad, widget.titularId);
                                if (!context.mounted) return;
                                await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => RamisScaffold(
                                            maxContentWidth: 1200,
                                            appBar: RamisAppBar(
                                              title: 'Historial documental',
                                              automaticallyImplyLeading: true,
                                            ),
                                            body: ListView(children: [
                                              for (final row in rows)
                                                ListTile(
                                                    title: Text(
                                                        '${catalogo[row['tipo']] ?? row['tipo']} · Versión ${row['version']}'),
                                                    subtitle: Text(
                                                        '${row['estado']} · ${row['archivado'] == true ? 'Archivado' : 'Actual'}'),
                                                    trailing:
                                                        row['archivo_url'] ==
                                                                null
                                                            ? null
                                                            : Icon(Icons
                                                                .open_in_new),
                                                    onTap: row['archivo_url'] ==
                                                            null
                                                        ? null
                                                        : () => _ver(
                                                            row['archivo_url']
                                                                as String))
                                            ]))));
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')));
                                }
                              }
                            },
                            variant: RamisButtonVariant.text,
                          ),
                        ]),
                  ]))),
    );
  }

  Widget _card(String tipo, String titulo, DocumentoTransporte d) => RamisCard(
      margin: const EdgeInsets.only(bottom: RamisSpacing.mediumSmall),
      padding: EdgeInsets.zero,
      child: Padding(
          padding: EdgeInsets.all(RamisSpacing.medium),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: RamisSpacing.small),
            Wrap(spacing: 8, children: [
              RamisStatusChip(
                label: d.semaforo.toUpperCase(),
                foregroundColor: colorDocumento(context, d.semaforo),
              ),
              RamisStatusChip(
                label: 'Estado: ${d.estado}',
              )
            ]),
            if (tipo == 'licencia')
              Text('Categoría: ${d.categoria ?? 'Pendiente'}'),
            Text('Vencimiento: ${d.vencimiento}'),
            if (d.dias != null)
              Text(d.dias! < 0
                  ? 'Vencido hace ${-d.dias!} días'
                  : 'Días restantes: ${d.dias}'),
            if (d.motivo != null)
              Text('Motivo: ${d.motivo}',
                  style: TextStyle(color: context.ramis.error)),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (d.archivo != null)
                RamisButton(
                  label: 'Ver archivo',
                  onPressed: _ocupado ? null : () => _ver(d.archivo!),
                  variant: RamisButtonVariant.text,
                  icon: Icons.visibility,
                ),
              RamisButton(
                label: d.archivo == null
                    ? 'Subir documento'
                    : 'Actualizar documento',
                onPressed: _ocupado ? null : () => _subir(tipo),
                variant: RamisButtonVariant.outlined,
              ),
              if (widget.administrar &&
                  d.id != null &&
                  d.estado == 'pendiente') ...[
                RamisButton(
                  label: 'Aprobar',
                  onPressed: _ocupado ? null : () => _revisar(d, true),
                  variant: RamisButtonVariant.primary,
                ),
                RamisButton(
                  label: 'Rechazar',
                  onPressed: _ocupado ? null : () => _revisar(d, false),
                  variant: RamisButtonVariant.text,
                ),
              ],
            ]),
          ])));
}

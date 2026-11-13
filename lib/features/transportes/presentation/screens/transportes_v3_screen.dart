import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/save_download.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:dio/dio.dart';
import '../../../../data/network/dio_client.dart';
import '../../providers/jornadas_provider.dart';
import '../widgets/observacion_fields.dart';
import '../widgets/checklist_form.dart';

class TransportesV3Screen extends ConsumerStatefulWidget {
  const TransportesV3Screen({super.key});
  @override
  ConsumerState<TransportesV3Screen> createState() =>
      _TransportesV3ScreenState();
}

class _TransportesV3ScreenState extends ConsumerState<TransportesV3Screen> {
  List<dynamic> _avisos = [],
      _vehiculos = [],
      _mantenimientos = [],
      _inactivos = [];
  List<dynamic> _cierres = [];
  String? _error;
  int _pendientes = 0;
  Timer? _timer;
  bool _admin = false;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final usuario = await ref.read(currentUserForTransportProvider.future);
      final repo = ref.read(transporteRepositoryProvider);
      final avisos =
          await repo.getV3('/api/transportes/notificaciones') as List;
      final vehiculos = await repo.listarVehiculos();
      final admin = usuario?.role == 'admin';
      final mantenimientos =
          admin ? await repo.listarMantenimientos() : <dynamic>[];
      final inactivos = admin
          ? await repo.getV3('/api/transportes/inactivos') as List
          : <dynamic>[];
      final pendientes = await repo.queue.pending();
      final jornadas =
          admin ? await repo.getV3('/api/jornadas/') as List : <dynamic>[];
      if (mounted) {
        setState(() {
          _admin = admin;
          _cierres = jornadas
              .where((j) => ['pendiente_de_cierre', 'cerrada_por_sistema']
                  .contains(j['estado']))
              .toList();
          _avisos = avisos;
          _vehiculos = vehiculos;
          _mantenimientos = mantenimientos;
          _inactivos = inactivos;
          _pendientes = pendientes;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<String?> _texto(String titulo,
      {String? inicial, bool secreto = false}) async {
    final controller = TextEditingController(text: inicial);
    final value = await showDialog<String>(
        context: context,
        builder: (ctx) => _FullPage(
                title: Text(titulo),
                content: RamisTextField(
                    controller: controller, obscureText: secreto),
                actions: [
                  RamisButton(
                    label: 'Volver',
                    onPressed: () => Navigator.pop(ctx),
                    variant: RamisButtonVariant.text,
                  ),
                  RamisButton(
                    label: 'Guardar',
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    variant: RamisButtonVariant.primary,
                  )
                ]));
    controller.dispose();
    return value;
  }

  Future<String?> _foto() async {
    final file = await ref.read(elegirFotoProvider)(ImageSource.gallery);
    if (file == null) return null;
    return ref
        .read(transporteRepositoryProvider)
        .subirFoto(await file.readAsBytes(), file.name);
  }

  Future<String?> _pdf() async {
    final files = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (files == null) return null;
    final file = files.files.single;
    if (file.bytes == null || file.size > 10 * 1024 * 1024) {
      throw StateError('Máximo 10 MB por informe.');
    }
    final response = await ref.read(dioProvider).post(
        '/api/transportes/archivos',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(file.bytes!, filename: file.name)
        }));
    return response.data['url'] as String;
  }

  @override
  Widget build(BuildContext context) => RamisScaffold(
        maxContentWidth: 1200,
        appBar: RamisAppBar(
          title: 'Documentos y alertas',
          automaticallyImplyLeading: true,
          actions: [IconButton(onPressed: _load, icon: Icon(Icons.refresh))],
        ),
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
                padding: EdgeInsets.all(RamisSpacing.medium),
                children: [
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: context.ramis.error)),
                  ListTile(
                      title: Text(
                          'Reportes pendientes de sincronizar: $_pendientes'),
                      subtitle: Text(ref
                              .read(transporteRepositoryProvider)
                              .queue
                              .lastError ??
                          'Reintento automático al recuperar conexión'),
                      trailing: IconButton(
                          icon: Icon(Icons.sync),
                          onPressed: () => _run(() async {
                                await ref
                                    .read(transporteRepositoryProvider)
                                    .queue
                                    .flush();
                              }))),
                  for (final aviso in _avisos)
                    RamisCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                            leading: Icon(aviso['persistente'] == true
                                ? Icons.warning_amber
                                : Icons.notifications),
                            title: Text('${aviso['titulo']}'),
                            subtitle: Text('${aviso['mensaje']}'),
                            trailing: RamisButton(
                              label: aviso['persistente'] == true
                                  ? 'Leída · Activa'
                                  : 'Marcar leída',
                              onPressed: () => _run(() async {
                                await ref.read(transporteRepositoryProvider).postV3(
                                    '/api/transportes/notificaciones/${aviso['id']}/leer',
                                    {});
                              }),
                              variant: RamisButtonVariant.text,
                            ))),
                  if (_admin)
                    Wrap(spacing: 8, children: [
                      RamisButton(
                        label: 'Alta rápida de vehículo',
                        onPressed: () => _run(_altaVehiculo),
                        variant: RamisButtonVariant.outlined,
                      ),
                      RamisButton(
                        label: 'Alta rápida de conductor',
                        onPressed: () => _run(_altaConductor),
                        variant: RamisButtonVariant.outlined,
                      ),
                      RamisButton(
                        label: 'Documentos de conductores',
                        onPressed: () => _run(() async {
                          final conductores = await ref
                              .read(transporteRepositoryProvider)
                              .listarTrabajadores();
                          if (!context.mounted) return;
                          await showDialog<void>(
                              context: context,
                              builder: (ctx) => _FullPage(
                                  title: Text('Documentos de conductores'),
                                  content: SizedBox(
                                      width: double.infinity,
                                      child:
                                          ListView(shrinkWrap: true, children: [
                                        for (final c in conductores.where(
                                            (c) => c['role'] == 'conductor'))
                                          ListTile(
                                              title: Text(
                                                  '${c['nombre']} ${c['apellidos']}'),
                                              subtitle: Text('${c['dni']}'),
                                              trailing: RamisButton(
                                                label: 'Configurar acceso',
                                                onPressed: () => _run(() async {
                                                  final correo = await _texto(
                                                      'Correo de acceso del conductor',
                                                      inicial: c['email']
                                                          as String?);
                                                  if (correo == null) {
                                                    return;
                                                  }
                                                  final password = await _texto(
                                                      'Contraseña inicial (mínimo 8 caracteres)',
                                                      secreto: true);
                                                  if (password == null) {
                                                    return;
                                                  }
                                                  await ref.read(dioProvider).put(
                                                      '/api/transportes/conductores/${c['id']}/acceso',
                                                      data: {
                                                        'email': correo,
                                                        'password': password
                                                      });
                                                }),
                                                variant:
                                                    RamisButtonVariant.text,
                                              ),
                                              onTap: () => _run(() =>
                                                  _documentos(
                                                      'conductor',
                                                      (c['id'] as num)
                                                          .toInt())))
                                      ]))));
                        }),
                        variant: RamisButtonVariant.outlined,
                      ),
                      RamisButton(
                        label: 'Mi firma administrativa',
                        onPressed: () => _run(_firma),
                        variant: RamisButtonVariant.outlined,
                      ),
                      RamisButton(
                        label: 'Auditoría',
                        onPressed: () => _run(() async {
                          final eventos = await ref
                              .read(transporteRepositoryProvider)
                              .getV3('/api/transportes/auditoria') as List;
                          if (!context.mounted) return;
                          await showDialog<void>(
                              context: context,
                              builder: (ctx) => _FullPage(
                                  title: Text('Bitácora de auditoría'),
                                  content: SizedBox(
                                      width: double.infinity,
                                      child:
                                          ListView(shrinkWrap: true, children: [
                                        for (final e in eventos)
                                          ListTile(
                                              title: Text(
                                                  '${e['accion']} · ${e['entidad']} #${e['registro_id']}'),
                                              subtitle: Text(
                                                  '${e['fecha']} · Usuario ${e['usuario_id']}\n${e['motivo'] ?? ""}'))
                                      ]))));
                        }),
                        variant: RamisButtonVariant.outlined,
                      ),
                    ]),
                  Text('Flota y documentación', style: TextStyle(fontSize: 20)),
                  for (final v in _vehiculos)
                    RamisCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                            title: Text('${v['placa']} · ${v['modelo']}'),
                            subtitle: Text(
                                '${v['kilometraje_actual']} km · ${v['estado_semaforo']}'),
                            onTap: () => _run(
                                () => _detalle(v as Map<String, dynamic>)))),
                  if (_admin) ...[
                    Text('Odómetros pendientes de regularizar',
                        style: TextStyle(fontSize: 20)),
                    for (final j in _cierres)
                      ListTile(
                          title: Text(
                              'Jornada #${j['id']} · Conductor ${j['conductor_id']}'),
                          subtitle: Text('${j['estado']}'),
                          trailing: RamisButton(
                            label: 'Regularizar cierre',
                            onPressed: () => _regularizar(j as Map),
                            variant: RamisButtonVariant.text,
                          )),
                    Text('Aprobación de mantenimientos',
                        style: TextStyle(fontSize: 20)),
                    for (final m in _mantenimientos)
                      ListTile(
                          title: Text(
                              'Mantenimiento #${m['id']} · ${m['estado']}'),
                          subtitle: Text('${m['descripcion_falla']}'),
                          trailing: m['estado'] == 'en_taller'
                              ? RamisButton(
                                  label: 'Aprobar y cerrar',
                                  onPressed: () => _run(
                                      () => _cerrarMantenimiento(m as Map)),
                                  variant: RamisButtonVariant.text,
                                )
                              : RamisButton(
                                  label: 'Acta firmada PDF',
                                  onPressed: () => _run(() => _descargarPdf(
                                      '/api/mantenimientos/${m['id']}/acta-pdf',
                                      'mantenimiento-${m['id']}.pdf')),
                                  variant: RamisButtonVariant.text,
                                )),
                    Text('Unidades inactivas', style: TextStyle(fontSize: 20)),
                    for (final v in _inactivos)
                      ListTile(
                          title: Text('${v['placa']} · Inactivo'),
                          subtitle: Text('Baja: ${v['fecha_baja']}')),
                  ],
                  RamisButton(
                    label: 'Mis documentos personales',
                    onPressed: () => _run(() async {
                      final usuario = await ref
                          .read(currentUserForTransportProvider.future);
                      if (usuario != null) {
                        await _documentos('conductor', usuario.id);
                      }
                    }),
                    variant: RamisButtonVariant.text,
                  ),
                ])),
      );

  Future<void> _altaVehiculo() async {
    final placa = await _texto('Placa del vehículo');
    if (placa == null || placa.isEmpty) return;
    final nombre = await _texto('Nombre o modelo');
    if (nombre == null || nombre.isEmpty) return;
    await ref
        .read(dioProvider)
        .post('/api/vehiculos/', data: {'placa': placa, 'modelo': nombre});
  }

  Future<void> _altaConductor() async {
    final nombre = await _texto('Nombre del conductor');
    if (nombre == null) return;
    final dni = await _texto('DNI (8 dígitos)');
    if (dni == null) return;
    final result = await ref.read(transporteRepositoryProvider).postV3(
        '/api/transportes/conductores/alta-rapida',
        {'nombre': nombre, 'dni': dni});
    await _documentos('conductor', (result['id'] as num).toInt());
  }

  Future<void> _firma() async {
    final controller = SignatureController(
        penStrokeWidth: 3,
        penColor: Colors.black,
        exportBackgroundColor: Colors.white);
    final bytes = await showDialog<Uint8List>(
        context: context,
        builder: (ctx) => _FullPage(
                title: Text('Firma autenticada del administrador'),
                content: SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Signature(
                        controller: controller, backgroundColor: Colors.white)),
                actions: [
                  RamisButton(
                    label: 'Limpiar',
                    onPressed: controller.clear,
                    variant: RamisButtonVariant.text,
                  ),
                  RamisButton(
                    label: 'Guardar firma',
                    onPressed: () async {
                      final image = await controller.toPngBytes();
                      if (ctx.mounted && image != null) {
                        Navigator.pop(ctx, image);
                      }
                    },
                    variant: RamisButtonVariant.primary,
                  )
                ]));
    controller.dispose();
    if (bytes == null) return;
    final url = await ref
        .read(transporteRepositoryProvider)
        .subirFoto(bytes, 'firma.png');
    await ref
        .read(dioProvider)
        .put('/api/transportes/firma', data: {'firma_url': url});
  }

  Future<void> _detalle(Map<String, dynamic> vehiculo) async {
    final id = (vehiculo['id'] as num).toInt();
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (ctx) => _FullPage(
            title: Text('Hoja de vida · ${vehiculo['placa']}'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                  '${vehiculo['kilometraje_actual']} km · Estado ${vehiculo['estado']}'),
              RamisButton(
                label: 'Vigencias e historial documental',
                onPressed: () => _run(() => _documentos('vehiculo', id)),
                variant: RamisButtonVariant.text,
              ),
              RamisButton(
                label: 'Descargar reporte PDF',
                onPressed: () => _run(() => _reporte(id)),
                variant: RamisButtonVariant.text,
              ),
              RamisButton(
                label: 'Observaciones y reparaciones',
                onPressed: () => _run(() => _observaciones(id)),
                variant: RamisButtonVariant.text,
              ),
              if (_admin) ...[
                RamisButton(
                  label: 'Corregir odómetro · 72 horas',
                  onPressed: () => _run(() async {
                    final km = await _texto('Corrección de odómetro (km)');
                    if (km == null) return;
                    final motivo = await _texto(
                        'Motivo de corrección (mínimo 15 caracteres)');
                    if (motivo == null) return;
                    await ref.read(transporteRepositoryProvider).postV3(
                        '/api/vehiculos/$id/corregir-kilometraje', {
                      'kilometraje': double.parse(km.replaceAll(',', '.')),
                      'motivo': motivo
                    });
                  }),
                  variant: RamisButtonVariant.text,
                ),
                RamisButton(
                  label: 'Dar de baja',
                  onPressed: () => _run(() async {
                    final confirmar = await _texto(
                        'Escriba la placa para confirmar la baja lógica');
                    if (confirmar != vehiculo['placa']) return;
                    await ref.read(dioProvider).delete('/api/vehiculos/$id');
                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                  variant: RamisButtonVariant.text,
                ),
              ],
            ])));
  }

  Future<void> _documentos(String entidad, int id) async {
    final repo = ref.read(transporteRepositoryProvider);
    final vigencias = await repo
        .getV3('/api/transportes/documentos/$entidad/$id/vigencias') as List;
    final historial = await repo.getV3(
        '/api/transportes/documentos/$entidad/$id?historial=true') as List;
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (ctx) => _FullPage(
            title: Text('Documentación y versiones'),
            content: SizedBox(
                width: double.infinity,
                child: ListView(shrinkWrap: true, children: [
                  for (final doc in vigencias)
                    ListTile(
                        leading: Icon(Icons.description,
                            color: doc['estado'] == 'verde'
                                ? context.ramis.success
                                : doc['estado'] == 'amarillo'
                                    ? context.ramis.warning
                                    : context.ramis.error),
                        title: Text('${doc['tipo']} · ${doc['estado']}'),
                        subtitle:
                            Text('${doc['fecha_vencimiento'] ?? 'Pendiente'}'),
                        trailing: _admin
                            ? RamisButton(
                                label: 'Renovar',
                                onPressed: () => _run(() async {
                                  final fecha = await _texto(
                                      'Fecha de vencimiento AAAA-MM-DD');
                                  if (fecha == null) return;
                                  final archivo = await _pdf();
                                  if (archivo == null) return;
                                  await repo.postV3(
                                      '/api/transportes/documentos/$entidad/$id',
                                      {
                                        'tipo': doc['tipo'],
                                        'archivo_url': archivo,
                                        if (fecha.isNotEmpty)
                                          'fecha_vencimiento': fecha
                                      });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                }),
                                variant: RamisButtonVariant.text,
                              )
                            : null),
                  Divider(),
                  Text('Historial archivado'),
                  for (final doc in historial)
                    ListTile(
                        title:
                            Text('${doc['tipo']} · Versión ${doc['version']}'),
                        subtitle: Text(
                            '${doc['fecha_vencimiento'] ?? ''} · ${doc['archivado'] == true ? 'Archivado' : 'Actual'}')),
                ]))));
  }

  Future<void> _reporte(int id) async {
    final estado =
        await _texto('Filtro: pendientes o todas', inicial: 'pendientes');
    if (estado == null) return;
    final desde = await _texto('Desde AAAA-MM-DD (opcional)');
    if (desde == null) return;
    final hasta = await _texto('Hasta AAAA-MM-DD (opcional)');
    if (hasta == null) return;
    final bytes = await ref.read(transporteRepositoryProvider).reportePdf(
        id, estado, desde.isEmpty ? null : desde, hasta.isEmpty ? null : hasta);
    final destino = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar hoja de vida',
        fileName: 'vehiculo-$id.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: Uint8List.fromList(bytes));
    if (destino != null &&
        !kIsWeb &&
        [TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux]
            .contains(defaultTargetPlatform)) {
      await writeDownloadedFile(destino, bytes);
    }
  }

  Future<void> _descargarPdf(String path, String nombre) async {
    final respuesta = await ref
        .read(dioProvider)
        .get(path, options: Options(responseType: ResponseType.bytes));
    final bytes = Uint8List.fromList(List<int>.from(respuesta.data as List));
    final destino =
        await FilePicker.platform.saveFile(fileName: nombre, bytes: bytes);
    if (destino != null &&
        !kIsWeb &&
        [TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux]
            .contains(defaultTargetPlatform)) {
      await writeDownloadedFile(destino, bytes);
    }
  }

  Future<void> _cerrarMantenimiento(Map m) async {
    final km = await _texto('Odómetro de cierre (km)');
    if (km == null) return;
    final descripcion = await _texto('Descripción detallada de los trabajos');
    if (descripcion == null) return;
    final informe = await _pdf();
    final fotos = <String>[];
    for (var i = 0; i < 3; i++) {
      final foto = await _foto();
      if (foto == null) break;
      fotos.add(foto);
    }
    await ref
        .read(transporteRepositoryProvider)
        .postV3('/api/mantenimientos/${m['id']}/cerrar', {
      'km_cierre': double.parse(km.replaceAll(',', '.')),
      'descripcion': descripcion,
      if (informe != null) 'informe_url': informe,
      'fotos_cierre': fotos,
    });
  }

  Future<void> _regularizar(Map j) async {
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => ChecklistForm(
            jornadaId: (j['id'] as num).toInt(),
            tipo: 'final',
            kilometrajeBase: (j['km_inicial'] as num?)?.toDouble() ?? 0,
            kmInicial: (j['km_inicial'] as num?)?.toDouble(),
            onSubmit: (request) async {
              await ref
                  .read(transporteRepositoryProvider)
                  .registrarChecklistFinal((j['id'] as num).toInt(), request);
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
            }));
  }

  Future<void> _observaciones(int id) async {
    final lista = await ref
        .read(transporteRepositoryProvider)
        .getV3('/api/transportes/observaciones?vehiculo_id=$id') as List;
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (ctx) => _FullPage(
            title: Text('Observaciones del vehículo'),
            content: SizedBox(
                width: double.infinity,
                child: ListView(shrinkWrap: true, children: [
                  for (final obs in lista)
                    ListTile(
                        title: Text(
                            '${obs['severidad']} · ${obs['resuelta'] == true ? 'Resuelta' : 'Pendiente'}'),
                        subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${obs['descripcion']}'),
                              for (final foto in obs['fotos'] as List)
                                FotoObservacion(url: foto as String)
                            ]),
                        trailing: _admin && obs['resuelta'] != true
                            ? RamisButton(
                                label: 'Aprobar reparación',
                                onPressed: () => _run(() async {
                                  final descripcion = await _texto(
                                      'Descripción detallada de la reparación');
                                  if (descripcion == null) return;
                                  final foto = await _foto();
                                  if (foto == null) return;
                                  await ref
                                      .read(transporteRepositoryProvider)
                                      .postV3(
                                          '/api/transportes/observaciones/${obs['origen']}/${obs['id']}/resolver',
                                          {
                                        'descripcion': descripcion,
                                        'foto_url': foto
                                      });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                }),
                                variant: RamisButtonVariant.text,
                              )
                            : null)
                ]))));
  }
}

class _FullPage extends StatelessWidget {
  const _FullPage(
      {required this.title, required this.content, this.actions = const []});
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => RamisScaffold(
      maxContentWidth: 1200,
      appBar: AppBar(title: title),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: EdgeInsets.all(RamisSpacing.medium), child: content)),
      bottomNavigationBar: actions.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                  padding: EdgeInsets.all(RamisSpacing.mediumSmall),
                  child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions))));
}

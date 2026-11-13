import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/jornada_transporte.dart';
import '../../providers/jornadas_provider.dart';
import '../widgets/checklist_form.dart';
import '../widgets/observacion_fields.dart';
import '../widgets/registro_accion_form.dart';
import '../../data/repositories/transporte_repository_impl.dart';
import '../widgets/subaccion_controls.dart';

class MiJornadaScreen extends ConsumerStatefulWidget {
  const MiJornadaScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<MiJornadaScreen> createState() => _MiJornadaScreenState();
}

class _MiJornadaScreenState extends ConsumerState<MiJornadaScreen> {
  JornadaTransporte? _cerrada;

  Future<void> _actualizar() async {
    ref.invalidate(accionesRegistradasProvider);
    ref.invalidate(vehiculosDisponiblesProvider);
    final refreshed = ref.refresh(miJornadaProvider.future);
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    final jornada = ref.watch(miJornadaProvider);
    final body = jornada.when(
      loading: () => RamisLoading(),
      error: (e, _) => RamisErrorView(
        title: 'No se pudo cargar la jornada',
        description: '$e',
        onRetry: () => ref.invalidate(miJornadaProvider),
      ),
      data: (j) => RefreshIndicator(
          onRefresh: _actualizar,
          child: j == null ? _sinJornada() : _consola(j)),
    );
    return widget.embedded
        ? body
        : RamisScaffold(
            maxContentWidth: 1200,
            appBar: RamisAppBar(
              title: 'Mi jornada',
              automaticallyImplyLeading: true,
            ),
            body: body);
  }

  Widget _sinJornada() => ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(RamisSpacing.large),
          children: [
            if (_cerrada case final cerrada?)
              RamisCard(
                  padding: EdgeInsets.zero,
                  child: Padding(
                      padding: EdgeInsets.all(RamisSpacing.medium),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jornada finalizada',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                'Recorrido: ${((cerrada.kmFinal ?? 0) - (cerrada.kmInicial ?? 0)).toStringAsFixed(1)} km'),
                            Text(
                                'Consumo: ${cerrada.galonesConsumidos?.toStringAsFixed(2) ?? "Sin estimación"} gal'),
                            Text(
                                'Rendimiento: ${cerrada.rendimientoKmGalon?.toStringAsFixed(2) ?? "Sin estimación"} km/gal'),
                          ]))),
            RamisEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Tu próxima jornada',
              description: 'No tienes una jornada activa en este momento.',
            ),
            SizedBox(height: RamisSpacing.large),
            RamisButton(
              label: 'Empezar a Conducir',
              onPressed: () async {
                await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => RamisScaffold(
                            maxContentWidth: 1200,
                            appBar: RamisAppBar(
                              title: 'Abrir jornada',
                              automaticallyImplyLeading: true,
                            ),
                            body: RegistroAccionForm(
                                soloApertura: true,
                                onRegistered: () => Navigator.pop(ctx)))));
                if (mounted) {
                  setState(() => _cerrada = null);
                  await _actualizar();
                }
              },
              variant: RamisButtonVariant.primary,
              icon: Icons.local_shipping,
            ),
            SizedBox(height: RamisSpacing.mediumSmall),
            Text(
                'Registra el vehículo, el odómetro inicial, el combustible y el checklist para empezar tu jornada.'),
          ]);

  Widget _consola(JornadaTransporte j) {
    final vehiculo = ref.watch(vehiculoJornadaProvider(j.vehiculoId!));
    final v = vehiculo.value;
    final color = v?['estado_semaforo'] as String? ?? j.estadoSemaforo;
    final conductor = ref.watch(currentUserForTransportProvider).value;
    final eventos = <_Evento>[
      _Evento(
          j.fechaInicio,
          'Apertura de jornada',
          'Odómetro inicial: ${j.kmInicial ?? "Pendiente"} km',
          j.fotoObservacion,
          j.estadoSemaforo),
      for (final a in j.subAcciones)
        _Evento(a.fechaInicio, a.accionTipo ?? 'Actividad', _resumen(a),
            a.fotoObservacion, a.estadoSemaforo),
      for (final i in j.incidencias)
        _Evento(
            i.fecha,
            'Observación en ruta',
            i.descripcion,
            i.fotoIncidencia,
            i.severidad == 'critica' || i.severidad == 'grave'
                ? 'rojo'
                : i.severidad == 'moderada'
                    ? 'amarillo'
                    : 'verde'),
    ].where((evento) {
      if (evento.fecha == null) return false;
      final fecha = _local(evento.fecha!);
      final hoy = DateTime.now();
      return fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day;
    }).toList()
      ..sort((a, b) => a.fecha!.compareTo(b.fecha!));
    return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(RamisSpacing.large),
        children: [
          if (['pendiente_de_cierre', 'cerrada_por_sistema'].contains(j.estado))
            RamisCard(
                padding: EdgeInsets.zero,
                color: context.ramis.pendingBackground,
                child: Padding(
                    padding: EdgeInsets.all(RamisSpacing.medium),
                    child: Text(
                        'Odómetro pendiente de cierre. Regularice esta jornada para poder tomar otro vehículo.'))),
          for (final sub in j.subAcciones)
            if (sub.estado == 'en_curso' || sub.estado == 'cancelada')
              SubaccionControls(subaccion: sub, onChanged: _actualizar),
          Text(
              j.estado == 'en_curso'
                  ? 'Mi jornada en curso'
                  : 'Jornada asignada',
              style: Theme.of(context).textTheme.titleLarge!),
          SizedBox(height: RamisSpacing.mediumSmall),
          RamisCard(
              padding: EdgeInsets.zero,
              child: Padding(
                  padding: EdgeInsets.all(RamisSpacing.medium),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            v == null
                                ? 'Vehículo #${j.vehiculoId}'
                                : '${v['placa']} · ${v['tipo'] ?? v['modelo']}',
                            style: Theme.of(context).textTheme.titleMedium!),
                        if (vehiculo.hasError)
                          RamisButton(
                            label: 'Reintentar datos del vehículo',
                            onPressed: () => ref.invalidate(
                                vehiculoJornadaProvider(j.vehiculoId!)),
                            variant: RamisButtonVariant.text,
                          ),
                        Text(conductor == null
                            ? 'Conductor #${j.conductorId}'
                            : '${conductor.nombre} ${conductor.apellidos}'),
                        Text('Inicio: ${_fecha(j.fechaInicio)}'),
                        Text(
                            'Odómetro inicial: ${j.kmInicial ?? "Pendiente"} km'),
                        Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(Icons.circle,
                                  color: colorSemaforo(context, color)),
                              Text(switch (color) {
                                'rojo' => 'Rojo · Vehículo inoperativo',
                                'amarillo' =>
                                  'Amarillo · Observaciones pendientes',
                                _ => 'Verde · Buen estado'
                              })
                            ]),
                        if (color == 'rojo')
                          Text(
                              'La unidad está inoperativa. La jornada permanece abierta para registrar novedades y efectuar el cierre.',
                              style: TextStyle(color: context.ramis.error)),
                        if (v?['observaciones_pendientes'] != null)
                          Text(v!['observaciones_pendientes'] as String),
                      ]))),
          if (j.estado == 'pendiente')
            RamisButton(
              label: 'Checklist de apertura',
              onPressed: () => _checklist(j, 'inicial', v),
              variant: RamisButtonVariant.primary,
            ),
          if (j.estado == 'en_curso') ...[
            SizedBox(height: RamisSpacing.medium),
            Text('Acciones en ruta · Sin finalizar la jornada'),
            SizedBox(height: RamisSpacing.small),
            RamisButton(
              label: 'Reportar Observación',
              onPressed: () => _reportar(j),
              variant: RamisButtonVariant.primary,
              icon: Icons.warning_amber,
            ),
            SizedBox(height: RamisSpacing.small),
            RamisButton(
              label: 'Registrar Sub-Acción en Ruta',
              onPressed: () async {
                await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => RamisScaffold(
                            maxContentWidth: 1200,
                            appBar: RamisAppBar(
                              title: 'Sub-acción en ruta',
                              automaticallyImplyLeading: true,
                            ),
                            body: RegistroAccionForm(
                                jornada: j,
                                onRegistered: () => Navigator.pop(ctx)))));
                if (mounted) await _actualizar();
              },
              variant: RamisButtonVariant.outlined,
              icon: Icons.add,
            ),
          ],
          SizedBox(height: RamisSpacing.large),
          Text('Línea de tiempo de hoy',
              style: Theme.of(context).textTheme.titleMedium!),
          if (eventos.isEmpty) Text('Aún no hay actividades registradas hoy.'),
          for (final e in eventos)
            RamisCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  leading: Icon(Icons.circle,
                      size: 14, color: colorSemaforo(context, e.color)),
                  title: Text(e.titulo),
                  subtitle: Text(_fecha(e.fecha)),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(RamisSpacing.mediumSmall),
                        child: Text(e.descripcion)),
                    if (e.foto != null) FotoObservacion(url: e.foto!)
                  ],
                )),
          if (['en_curso', 'pendiente_de_cierre', 'cerrada_por_sistema']
              .contains(j.estado))
            Padding(
                padding: EdgeInsets.only(top: RamisSpacing.large),
                child: RamisButton(
                  label: 'Finalizar Jornada',
                  onPressed: () => _checklist(j, 'final', v),
                  variant: RamisButtonVariant.primary,
                  icon: Icons.stop_circle_outlined,
                )),
        ]);
  }

  Future<void> _checklist(
      JornadaTransporte j, String tipo, Map<String, dynamic>? v) async {
    // Obtain the current odometer on every attempt; never fall back to zero on failure.
    try {
      final vehiculo = await ref
          .read(transporteRepositoryProvider)
          .obtenerVehiculo(j.vehiculoId!);
      if (!mounted) return;
      await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (ctx) => ChecklistForm(
              jornadaId: j.id,
              tipo: tipo,
              kilometrajeBase: ['pendiente_de_cierre', 'cerrada_por_sistema']
                      .contains(j.estado)
                  ? (j.kmInicial ?? 0)
                  : (vehiculo['kilometraje_actual'] as num).toDouble(),
              kmInicial: j.kmInicial,
              nivelInicial: j.nivelCombustible,
              capacidadTanque:
                  (vehiculo['capacidad_tanque_galones'] as num?)?.toDouble(),
              galonesAbastecidos: j.subAcciones.fold<double>(
                  0,
                  (total, a) =>
                      total +
                      ((a.detallesCombustible?['galones'] as num?)
                              ?.toDouble() ??
                          0)),
              onSubmit: (request) async {
                try {
                  final repo = ref.read(transporteRepositoryProvider);
                  final resultado = tipo == 'final'
                      ? await repo.registrarChecklistFinal(j.id, request)
                      : await repo.registrarChecklistInicial(j.id, request);
                  if (!mounted) return;
                  if (tipo == 'final') setState(() => _cerrada = resultado);
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.invalidate(vehiculoJornadaProvider(j.vehiculoId!));
                  await _actualizar();
                } catch (e) {
                  if (mounted) _error(e);
                }
              }));
    } catch (e) {
      if (mounted) _error(e);
    }
  }

  Future<void> _reportar(JornadaTransporte j) async {
    final form = GlobalKey<FormState>();
    bool activa = false;
    bool enviando = false;
    String severidad = 'leve';
    String descripcion = '';
    String? foto;
    List<String> fotos = [];
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                  scrollable: true,
                  title: Text('Reportar Observación en Ruta'),
                  content: Form(
                      key: form,
                      child: ObservacionFields(
                          onPhotosChanged: (value) => fotos = value,
                          onChanged: (valor, nivel, texto, url) {
                            activa = valor;
                            severidad = nivel;
                            descripcion = texto;
                            foto = url;
                          })),
                  actions: [
                    RamisButton(
                      label: 'Cancelar',
                      onPressed: enviando ? null : () => Navigator.pop(ctx),
                      variant: RamisButtonVariant.text,
                    ),
                    RamisButton(
                      label: enviando
                          ? 'Guardando...'
                          : 'Guardar Observación (continuar jornada)',
                      onPressed: enviando
                          ? null
                          : () async {
                              if (!form.currentState!.validate()) return;
                              if (!activa) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'Active las observaciones para registrar una novedad.')));
                                return;
                              }
                              update(() => enviando = true);
                              try {
                                await ref
                                    .read(transporteRepositoryProvider)
                                    .registrarIncidencia(
                                        j.id,
                                        IncidenciaRutaRequest(
                                            tipo: 'falla',
                                            severidad: severidad,
                                            fotoIncidencia: foto,
                                            fotos: fotos,
                                            descripcion: descripcion.trim()));
                                if (!mounted) return;
                                if (ctx.mounted) Navigator.pop(ctx);
                                ref.invalidate(
                                    vehiculoJornadaProvider(j.vehiculoId!));
                                await _actualizar();
                              } on TransportQueued catch (e) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())));
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  update(() => enviando = false);
                                }
                                if (mounted) _error(e);
                              }
                            },
                      variant: RamisButtonVariant.primary,
                    )
                  ],
                )));
  }

  void _error(Object e) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo completar la operación: $e')));
}

class _Evento {
  const _Evento(
      this.fecha, this.titulo, this.descripcion, this.foto, this.color);
  final DateTime? fecha;
  final String titulo;
  final String descripcion;
  final String? foto;
  final String color;
}

String _resumen(JornadaTransporte a) {
  if (a.detallesCombustible case final c?) {
    return 'Abastecimiento: ${c['galones']} gal · S/ ${c['costo'] ?? "Sin costo registrado"} · Vale ${c['comprobante'] ?? "—"}';
  }
  if (a.detallesGrua case final g?) {
    return 'Horómetro de grúa: ${g['horometro_inicial']} → ${g['horometro_final']} h';
  }
  return a.observaciones ?? 'Sin novedades';
}

String _fecha(DateTime? f) {
  if (f == null) return 'Pendiente';
  final local = _local(f);
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

DateTime _local(DateTime f) => (f.isUtc
        ? f
        : DateTime.utc(f.year, f.month, f.day, f.hour, f.minute, f.second))
    .toLocal();

import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import '../widgets/observacion_fields.dart';
import '../widgets/transport_notification_bell.dart';
import 'documentos_screen.dart';
import '../../../dashboard/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/mi_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/login/login_provider.dart';
import 'package:sistema_ocs/features/login/login_screen.dart';

class ConductorJornadaScreen extends ConsumerStatefulWidget {
  const ConductorJornadaScreen({super.key, this.initialIndex = 0})
      : assert(initialIndex >= 0 && initialIndex < 3);
  final int initialIndex;

  @override
  ConsumerState<ConductorJornadaScreen> createState() =>
      _ConductorJornadaScreenState();
}

class _ConductorJornadaScreenState
    extends ConsumerState<ConductorJornadaScreen> {
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return RamisScaffold(
      maxContentWidth: 1200,
      drawer: CustomDrawer(
          onMenuItemTap: (_) =>
              Navigator.of(context).popUntil((route) => route.isFirst)),
      appBar: RamisAppBar(
        title: [
          'Mi jornada',
          'Historial de jornadas',
          'Mis Documentos'
        ][_selectedIndex],
        automaticallyImplyLeading: true,
        actions: [
          TransportNotificationBell(),
          IconButton(
              icon: Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                            title: Text('Cerrar Sesión'),
                            content: Text(
                                '¿Estás seguro de que deseas cerrar sesión?'),
                            actions: [
                              RamisButton(
                                label: 'Cancelar',
                                onPressed: () => Navigator.pop(ctx, false),
                                variant: RamisButtonVariant.text,
                              ),
                              RamisButton(
                                label: 'Cerrar Sesión',
                                onPressed: () => Navigator.pop(ctx, true),
                                variant: RamisButtonVariant.primary,
                              )
                            ]));
                if (confirm == true) {
                  await ref.read(authNotifierProvider.notifier).logout();
                  ref
                      .read(navigatorKeyProvider)
                      .currentState
                      ?.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false);
                }
              })
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MiJornadaScreen(embedded: true),
          _AccionesRegistradasTab(
              onNewAction: () => setState(() => _selectedIndex = 0)),
          _selectedIndex == 2
              ? MisDocumentosScreen(embedded: true)
              : SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Seguimiento'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historial'),
          NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge),
              label: 'Mis Documentos'),
        ],
      ),
    );
  }
}

class _AccionesRegistradasTab extends ConsumerWidget {
  const _AccionesRegistradasTab({required this.onNewAction});

  final VoidCallback onNewAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accionesAsync = ref.watch(accionesRegistradasProvider);
    final jornadaAsync = ref.watch(miJornadaProvider);

    return accionesAsync.when(
      loading: () => RamisLoading(),
      error: (error, _) => RamisErrorView(
        description: 'No se pudieron cargar las acciones: $error',
        onRetry: () => ref.invalidate(accionesRegistradasProvider),
      ),
      data: (acciones) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(miJornadaProvider);
          final refreshed = ref.refresh(accionesRegistradasProvider.future);
          await refreshed;
        },
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(RamisSpacing.medium),
          children: [
            Text('Lo que registraste',
                style: Theme.of(context).textTheme.titleLarge!),
            SizedBox(height: RamisSpacing.small),
            Text(
              'Consulta tus acciones y abre cada una para ver sus datos.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: context.ramis.textSecondary,
                  ),
            ),
            SizedBox(height: RamisSpacing.medium),
            if (jornadaAsync.value != null)
              _JornadaActivaCard(jornada: jornadaAsync.value!),
            if (acciones.isEmpty)
              RamisCard(
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    SizedBox(height: RamisSpacing.mediumSmall),
                    Text('Aún no tienes acciones registradas.',
                        style: Theme.of(context).textTheme.bodyMedium!),
                    SizedBox(height: RamisSpacing.mediumSmall),
                    RamisButton(
                      label: 'Registrar nueva acción',
                      onPressed: onNewAction,
                      variant: RamisButtonVariant.outlined,
                      icon: Icons.add,
                    ),
                  ],
                ),
              )
            else
              ...acciones.map((accion) => _AccionTile(
                    key: ValueKey(accion.id),
                    accion: accion,
                  )),
          ],
        ),
      ),
    );
  }
}

class _JornadaActivaCard extends ConsumerWidget {
  const _JornadaActivaCard({required this.jornada});

  final JornadaTransporte jornada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: RamisSpacing.medium),
      child: RamisCard(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jornada por atender',
                style: Theme.of(context).textTheme.titleMedium!),
            SizedBox(height: RamisSpacing.small),
            Text(
              jornada.accionTipo ?? 'Jornada asignada',
              style: Theme.of(context).textTheme.bodyMedium!,
            ),
            SizedBox(height: RamisSpacing.mediumSmall),
            RamisButton(
              label: 'Continuar jornada',
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MiJornadaScreen()));
                ref.invalidate(miJornadaProvider);
                ref.invalidate(accionesRegistradasProvider);
              },
              variant: RamisButtonVariant.outlined,
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccionTile extends ConsumerStatefulWidget {
  const _AccionTile({super.key, required this.accion});

  final JornadaTransporte accion;

  @override
  ConsumerState<_AccionTile> createState() => _AccionTileState();
}

class _AccionTileState extends ConsumerState<_AccionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final accion = widget.accion;
    return RamisCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.only(bottom: RamisSpacing.mediumSmall),
      child: ExpansionTile(
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        leading: Icon(_iconoAccion(accion.accionTipo),
            color: colorSemaforo(context, accion.estadoSemaforo)),
        title: Text(accion.accionTipo ?? 'Acción #${accion.id}',
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_fecha(accion.fechaInicio)} · ${_estado(accion.estado)}',
          style: Theme.of(context).textTheme.bodySmall!,
        ),
        children: [
          if (_expanded) _DetalleAccion(id: accion.id),
        ],
      ),
    );
  }
}

class _DetalleAccion extends ConsumerWidget {
  const _DetalleAccion({required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(detalleAccionProvider(id)).when(
          loading: () => Padding(
            padding: EdgeInsets.all(RamisSpacing.medium),
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Padding(
            padding: EdgeInsets.all(RamisSpacing.medium),
            child: RamisButton(
              label: 'No se pudo cargar el detalle. Reintentar',
              onPressed: () => ref.invalidate(detalleAccionProvider(id)),
              variant: RamisButtonVariant.text,
            ),
          ),
          data: (accion) => Padding(
            padding: EdgeInsets.fromLTRB(RamisSpacing.medium, 0,
                RamisSpacing.medium, RamisSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(),
                _dato(context, 'Vehículo', accion.vehiculoId?.toString()),
                _dato(context, 'Kilometraje inicial',
                    accion.kmInicial == null ? null : '${accion.kmInicial} km'),
                _dato(
                    context,
                    'Combustible inicial',
                    accion.nivelCombustible == null
                        ? null
                        : '${accion.nivelCombustible}%'),
                _dato(context, 'Ruta', accion.ruta),
                _dato(context, 'Observaciones', accion.observaciones),
                if (accion.fotoObservacion != null)
                  FotoObservacion(url: accion.fotoObservacion!),
                _dato(context, 'Jornada principal',
                    accion.jornadaPadreId?.toString()),
                _dato(context, 'Galones consumidos',
                    accion.galonesConsumidos?.toStringAsFixed(2)),
                _dato(context, 'Rendimiento km/gal',
                    accion.rendimientoKmGalon?.toStringAsFixed(2)),
                if (accion.detallesGrua case final detalle?) ...[
                  _dato(context, 'Actividad', detalle['actividad']?.toString()),
                  _dato(context, 'Horómetro inicial',
                      detalle['horometro_inicial']?.toString()),
                  _dato(context, 'Horómetro final',
                      detalle['horometro_final']?.toString()),
                ],
                if (accion.detallesCombustible case final detalle?) ...[
                  _dato(context, 'Galones abastecidos',
                      detalle['galones']?.toString()),
                  _dato(
                      context,
                      'Combustible final',
                      detalle['nivel_final'] == null
                          ? null
                          : "${detalle['nivel_final']}%"),
                ],
                if (accion.detallesMantenimiento case final detalle?) ...[
                  _dato(context, 'Taller', detalle['taller']?.toString()),
                  _dato(context, 'Tipo', detalle['tipo']?.toString()),
                  _dato(context, 'Trabajos',
                      (detalle['trabajos_preventivos'] as List?)?.join(', ')),
                  _dato(context, 'Descripción',
                      detalle['descripcion_correctivo']?.toString()),
                ],
                if (accion.detallesInspeccion case final detalle?) ...[
                  _dato(context, 'Fecha de inspección',
                      detalle['fecha_inspeccion']?.toString()),
                  _dato(context, 'Vencimiento',
                      detalle['fecha_vencimiento']?.toString()),
                ],
                if (accion.detallesCocada case final detalle?)
                  _dato(context, 'Cocada', detalle['medida']?.toString()),
                if (accion.detallesTorque case final detalle?)
                  _dato(context, 'Torque', detalle['medida']?.toString()),
                if (accion.detallesTrabajosExternos case final detalle?)
                  _dato(context, 'Trabajos realizados',
                      detalle['descripcion_trabajos']?.toString()),
                if (accion.checklistFlash != null)
                  _dato(
                      context,
                      'Check List Flash',
                      accion.checklistFlash!.entries
                          .where((item) => item.value == true)
                          .map((item) => item.key)
                          .join(', ')),
                if (accion.incidencias.isNotEmpty)
                  _dato(
                      context,
                      'Incidencias',
                      accion.incidencias
                          .map((item) => '${item.tipo}: ${item.descripcion}')
                          .join('\n')),
              ].whereType<Widget>().toList(),
            ),
          ),
        );
  }

  Widget? _dato(BuildContext context, String label, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Padding(
      padding: EdgeInsets.only(top: RamisSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall!),
          Text(value, style: Theme.of(context).textTheme.bodyMedium!),
        ],
      ),
    );
  }
}

String _fecha(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha';
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}

String _estado(String estado) => switch (estado) {
      'en_curso' => 'En curso',
      'finalizada' => 'Finalizada',
      'cancelada_por_averia' => 'Cancelada por avería',
      _ => estado.replaceAll('_', ' '),
    };

IconData _iconoAccion(String? accion) => switch (accion) {
      'Empezar a Conducir' => Icons.directions_car_outlined,
      'Operar Grúa' => Icons.construction_outlined,
      'Abastecer Combustible' => Icons.local_gas_station_outlined,
      'Mantenimiento Preventivo / Correctivo' => Icons.build_outlined,
      'Reporte de Incidencias u Observaciones' => Icons.report_outlined,
      _ => Icons.assignment_outlined,
    };

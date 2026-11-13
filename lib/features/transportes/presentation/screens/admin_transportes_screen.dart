import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import '../../providers/jornadas_provider.dart';
import '../widgets/observacion_fields.dart';
import '../widgets/transport_notification_bell.dart';
import 'conductores_screen.dart';
import 'vehiculo_detalle_screen.dart';
import '../../../dashboard/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/providers/admin_transportes_provider.dart';

class AdminTransportesScreen extends ConsumerWidget {
  const AdminTransportesScreen({super.key, this.initialIndex = 0})
      : assert(initialIndex >= 0 && initialIndex < 6);
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      initialIndex: initialIndex,
      child: RamisScaffold(
        maxContentWidth: 1200,
        drawer: CustomDrawer(
            onMenuItemTap: (_) =>
                Navigator.of(context).popUntil((route) => route.isFirst)),
        appBar: RamisAppBar(
          title: 'Gestión de Flota',
          automaticallyImplyLeading: true,
          actions: [TransportNotificationBell()],
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(icon: Icon(Icons.assignment), text: 'Jornadas'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Flota'),
            Tab(icon: Icon(Icons.visibility), text: 'Observaciones'),
            Tab(icon: Icon(Icons.build), text: 'Mantenimientos'),
            Tab(icon: Icon(Icons.gps_fixed), text: 'GPS'),
            Tab(icon: Icon(Icons.people_alt), text: 'Conductores')
          ]),
        ),
        body: TabBarView(
          children: [
            _JornadasTab(),
            _FlotaTab(),
            _ObservacionesTab(),
            _MantenimientosTab(),
            _GpsTab(),
            ConductoresScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

// ── Pestaña 1: Jornadas ──────────────────────────────────────────────────────
class _JornadasTab extends ConsumerWidget {
  const _JornadasTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(jornadasListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(jornadasListProvider),
      child: jornadasAsync.when(
        data: (jornadas) {
          if (jornadas.isEmpty) {
            return RamisEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Sin registros',
                description: 'No hay jornadas registradas.');
          }
          return ListView.builder(
            padding: EdgeInsets.all(RamisSpacing.mediumSmall),
            itemCount: jornadas.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                final cerradas = jornadas.where((j) =>
                    j['jornada_padre_id'] == null &&
                    j['galones_consumidos'] != null);
                final galones = cerradas.fold<double>(
                    0,
                    (total, j) =>
                        total + (j['galones_consumidos'] as num).toDouble());
                final km = cerradas.fold<double>(
                    0,
                    (total, j) =>
                        total +
                        ((j['km_final'] as num?)?.toDouble() ?? 0) -
                        ((j['km_inicial'] as num?)?.toDouble() ?? 0));
                return RamisCard(
                    padding: EdgeInsets.zero,
                    child: Padding(
                        padding: EdgeInsets.all(RamisSpacing.medium),
                        child: Text(
                            'Consumo consolidado: ${galones.toStringAsFixed(2)} gal · ${km.toStringAsFixed(1)} km · ${galones > 0 ? (km / galones).toStringAsFixed(2) : "Sin datos"} km/gal')));
              }
              final j = jornadas[i - 1];
              final tieneAlerta = (j['alerta_horas'] as bool? ?? false) ||
                  (j['alerta_km'] as bool? ?? false);
              return RamisCard(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.only(bottom: RamisSpacing.mediumSmall),
                child: ExpansionTile(
                  leading: Icon(
                    tieneAlerta
                        ? Icons.warning_amber
                        : Icons.check_circle_outline,
                    color: colorSemaforo(
                        context, j['estado_semaforo'] as String? ?? 'verde'),
                  ),
                  title: Text(
                      'Jornada #${j['id']} - Conductor ID: ${j['conductor_id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Estado: ${j['estado']} | Acción: ${j['accion_tipo'] ?? 'N/A'}'),
                      if (tieneAlerta)
                        Text(
                          '⚠ Tiene alertas de horas/km',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: context.ramis.error),
                        ),
                    ],
                  ),
                  children: [
                    Padding(
                        padding: EdgeInsets.all(RamisSpacing.medium),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Vehículo #${j['vehiculo_id']} · Jornada principal: ${j['jornada_padre_id'] ?? j['id']}'),
                              Text(j['observaciones'] as String? ??
                                  'Sin novedades'),
                              if (j['foto_observacion'] != null)
                                FotoObservacion(
                                    url: j['foto_observacion'] as String),
                              Text(
                                  'Km efectivos: ${j['km_final'] != null && j['km_inicial'] != null ? (j['km_final'] as num) - (j['km_inicial'] as num) : 'Pendiente'}'),
                              Text(
                                  'Consumo: ${j['galones_consumidos'] ?? 'Sin datos de tanque/cierre'} gal · Rendimiento: ${j['rendimiento_km_galon'] ?? 'Pendiente'} km/gal'),
                            ])),
                  ],
                ),
              );
            },
          );
        },
        loading: () => RamisLoading(),
        error: (e, _) => RamisErrorView(
            description: 'No se pudo cargar la información: $e',
            onRetry: () => ref.invalidate(jornadasListProvider)),
      ),
    );
  }
}

// ── Pestaña 2: Flota ─────────────────────────────────────────────────────────
class _FlotaTab extends ConsumerWidget {
  const _FlotaTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculosAsync = ref.watch(vehiculosListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(vehiculosListProvider),
      child: vehiculosAsync.when(
        data: (vehiculos) {
          return ListView.builder(
            padding: EdgeInsets.all(RamisSpacing.mediumSmall),
            itemCount: vehiculos.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return RamisCard(
                    padding: EdgeInsets.zero,
                    child: Padding(
                        padding: EdgeInsets.all(RamisSpacing.medium),
                        child: Wrap(spacing: 16, children: [
                          RamisButton(
                            label: 'Alta Rápida de Vehículo',
                            onPressed: () => mostrarAltaVehiculo(context),
                            variant: RamisButtonVariant.primary,
                            icon: Icons.add,
                          ),
                          if (vehiculos.isEmpty)
                            Text('No hay vehículos registrados.'),
                          for (final estado in ['verde', 'amarillo', 'rojo'])
                            RamisStatusChip(
                              label:
                                  '$estado: ${vehiculos.where((v) => (v['estado_semaforo'] ?? 'verde') == estado).length}',
                              foregroundColor: colorSemaforo(context, estado),
                            ),
                        ])));
              }
              final v = vehiculos[i - 1];
              final estado = v['estado'] as String? ?? 'desconocido';
              final color = switch (estado) {
                'disponible' => Theme.of(context).colorScheme.primary,
                'en_ruta' => Theme.of(context).colorScheme.primary,
                'en_mantenimiento' => context.ramis.warning,
                _ => Theme.of(context).colorScheme.onSurfaceVariant,
              };
              return RamisCard(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.only(bottom: RamisSpacing.mediumSmall),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(30),
                    child: Icon(Icons.directions_car,
                        color: colorSemaforo(context,
                            v['estado_semaforo'] as String? ?? 'verde')),
                  ),
                  onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => VehiculoDetalleScreen(vehiculo: v))),
                  title: Text('${v['placa']} - ${v['marca']} ${v['modelo']}'),
                  subtitle:
                      Text('Km: ${v['kilometraje_actual']} | Estado: $estado'),
                  trailing: PopupMenuButton<String>(
                      tooltip: 'Opciones del vehículo',
                      onSelected: (_) => _editarVehiculo(context, ref, v),
                      itemBuilder: (_) => [
                            PopupMenuItem(
                                value: 'tanque',
                                child: Text('Configurar tipo y tanque'))
                          ]),
                ),
              );
            },
          );
        },
        loading: () => RamisLoading(),
        error: (e, _) => RamisErrorView(
            description: 'No se pudo cargar la información: $e',
            onRetry: () => ref.invalidate(vehiculosListProvider)),
      ),
    );
  }
}

// ── Pestaña 3: Observaciones ─────────────────────────────────────────────────
class _ObservacionesTab extends ConsumerWidget {
  const _ObservacionesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(jornadasListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(jornadasListProvider),
      child: jornadasAsync.when(
        data: (jornadas) {
          final conObs = jornadas
              .where((j) =>
                  j['observaciones'] != null &&
                  (j['observaciones'] as String).isNotEmpty &&
                  j['observaciones'] != 'Sin novedades')
              .toList();
          if (conObs.isEmpty) {
            return RamisEmptyState(
              icon: Icons.visibility_off_outlined,
              title: 'Sin observaciones',
              description: 'No hay observaciones registradas.',
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(RamisSpacing.mediumSmall),
            itemCount: conObs.length,
            itemBuilder: (_, i) {
              final j = conObs[i];
              return RamisCard(
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    leading: Icon(Icons.circle,
                        color: colorSemaforo(context,
                            j['estado_semaforo'] as String? ?? 'verde')),
                    title: Text(
                        'Jornada #${j['id']} · Vehículo #${j['vehiculo_id']}'),
                    subtitle: Text(j['accion_tipo'] as String? ?? 'Jornada'),
                    children: [
                      Padding(
                          padding: EdgeInsets.all(RamisSpacing.medium),
                          child: Column(children: [
                            Text(j['observaciones'] as String),
                            if (j['foto_observacion'] != null)
                              FotoObservacion(
                                  url: j['foto_observacion'] as String),
                          ]))
                    ],
                  ));
            },
          );
        },
        loading: () => RamisLoading(),
        error: (e, _) => RamisErrorView(
            description: 'No se pudo cargar la información: $e',
            onRetry: () => ref.invalidate(jornadasListProvider)),
      ),
    );
  }
}

// ── Pestaña 4: Mantenimientos ────────────────────────────────────────────────
class _MantenimientosTab extends ConsumerWidget {
  const _MantenimientosTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantenimientosAsync = ref.watch(mantenimientosListProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(mantenimientosListProvider),
      child: mantenimientosAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return RamisEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Sin registros',
                description: 'No hay mantenimientos registrados.');
          }
          return ListView.builder(
            padding: EdgeInsets.all(RamisSpacing.mediumSmall),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final m = items[i];
              final estado = m['estado'] as String? ?? 'pendiente';
              final colorEstado = switch (estado.toLowerCase()) {
                'finalizado' ||
                'completado' =>
                  Theme.of(context).colorScheme.primary,
                'en_proceso' ||
                'en proceso' =>
                  Theme.of(context).colorScheme.primary,
                _ => context.ramis.warning,
              };
              return RamisCard(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.only(bottom: RamisSpacing.mediumSmall),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.build_circle)),
                  title: Text(m['descripcion'] as String? ?? 'Mantenimiento'),
                  subtitle: Text(
                      'Vehículo ID: ${m['vehiculo_id']} | Tipo: ${m['tipo'] ?? 'N/A'}'),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: RamisSpacing.small,
                        vertical: RamisSpacing.xSmall),
                    decoration: BoxDecoration(
                      color: colorEstado.withAlpha(30),
                      borderRadius: RamisRadius.medium,
                    ),
                    child: Text(estado,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: colorEstado)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => RamisLoading(),
        error: (e, _) => RamisErrorView(
            description: 'No se pudo cargar la información: $e',
            onRetry: () => ref.invalidate(mantenimientosListProvider)),
      ),
    );
  }
}

// ── Pestaña 5: GPS ───────────────────────────────────────────────────────────
class _GpsTab extends StatelessWidget {
  const _GpsTab();
  @override
  Widget build(BuildContext context) {
    return RamisEmptyState(
      icon: Icons.gps_fixed,
      title: 'Integración futura de GPS',
      description:
          'Este módulo permitirá el rastreo en tiempo real de los vehículos de la flota.',
    );
  }
}

Future<void> _editarVehiculo(
    BuildContext context, WidgetRef ref, Map<String, dynamic> vehiculo) async {
  final tipos = ['Camión Grúa', 'Camión de Carga', 'Camioneta', 'Coaster'];
  String tipo = tipos.contains(vehiculo['tipo'])
      ? vehiculo['tipo'] as String
      : 'Camión de Carga';
  final capacidad = TextEditingController(
      text: vehiculo['capacidad_tanque_galones']?.toString() ?? '');
  final form = GlobalKey<FormState>();
  bool guardando = false;
  await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => AlertDialog(
                scrollable: true,
                title: Text('Datos de ${vehiculo['placa']}'),
                content: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<String>(
                          initialValue: tipo,
                          isExpanded: true,
                          decoration:
                              InputDecoration(labelText: 'Tipo de vehículo'),
                          items: tipos
                              .map((t) =>
                                  DropdownMenuItem(value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) => tipo = v!),
                      RamisTextField(
                          controller: capacidad,
                          decoration: InputDecoration(
                              labelText: 'Capacidad del tanque (galones)',
                              helperText:
                                  'Necesaria para estimar el consumo por jornada',
                              helperMaxLines: 2),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (v ?? '').isNotEmpty &&
                                  (double.tryParse(v!.replaceAll(',', '.')) ==
                                          null ||
                                      double.parse(v.replaceAll(',', '.')) <= 0)
                              ? 'Ingrese una capacidad mayor a cero'
                              : null),
                    ])),
                actions: [
                  RamisButton(
                    label: 'Cancelar',
                    onPressed: guardando ? null : () => Navigator.pop(ctx),
                    variant: RamisButtonVariant.text,
                  ),
                  RamisButton(
                    label: guardando ? 'Guardando...' : 'Guardar',
                    onPressed: guardando
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            update(() => guardando = true);
                            try {
                              await ref
                                  .read(transporteRepositoryProvider)
                                  .actualizarDatosVehiculo(
                                      vehiculo['id'] as int,
                                      tipo,
                                      double.tryParse(
                                          capacidad.text.replaceAll(',', '.')));
                              ref.invalidate(vehiculosListProvider);
                              ref.invalidate(vehiculosDisponiblesProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (ctx.mounted) {
                                update(() => guardando = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text('No se pudo guardar: $e')));
                              }
                            }
                          },
                    variant: RamisButtonVariant.primary,
                  )
                ],
              )));
  capacidad.dispose();
}

import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import '../widgets/vehiculo_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

class AsignacionJornadaScreen extends ConsumerStatefulWidget {
  const AsignacionJornadaScreen({super.key});

  @override
  ConsumerState<AsignacionJornadaScreen> createState() =>
      _AsignacionJornadaScreenState();
}

class _AsignacionJornadaScreenState
    extends ConsumerState<AsignacionJornadaScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedVehiculoId;
  int? _selectedConductorId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Forzar refresco de datos cada vez que se abre la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(vehiculosDisponiblesProvider);
      ref.invalidate(trabajadoresProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiculosAsync = ref.watch(vehiculosDisponiblesProvider);
    final trabajadoresAsync = ref.watch(trabajadoresProvider);

    return RamisScaffold(
      maxContentWidth: 1200,
      appBar: RamisAppBar(
        title: 'Asignar Jornada',
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(RamisSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RamisCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nueva Jornada de Transporte',
                        style: Theme.of(context).textTheme.titleLarge!),
                    SizedBox(height: RamisSpacing.xLarge),

                    // ── Vehículo ──
                    vehiculosAsync.when(
                      data: (vehiculos) {
                        return VehiculoSelector(
                            vehiculos: vehiculos,
                            value: _selectedVehiculoId,
                            onChanged: (v) => setState(
                                () => _selectedVehiculoId = v['id'] as int));
                      },
                      loading: () => LinearProgressIndicator(),
                      error: (e, _) => Text(
                        'Error al cargar vehículos: $e',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: context.ramis.error),
                      ),
                    ),

                    SizedBox(height: RamisSpacing.medium),

                    // ── Conductor ──
                    trabajadoresAsync.when(
                      data: (trabajadores) {
                        return DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Conductor',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: trabajadores
                              .map((t) => DropdownMenuItem<int>(
                                    value: t['id'] as int,
                                    child: Text(
                                      '${t['nombre']} ${t['apellidos'] ?? ''}'
                                          .trim(),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedConductorId = val),
                          validator: (val) =>
                              val == null ? 'Seleccione un conductor' : null,
                        );
                      },
                      loading: () => LinearProgressIndicator(),
                      error: (e, _) => Text(
                        'Error al cargar trabajadores: $e',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: context.ramis.error),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: RamisSpacing.xxLarge),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: RamisButton(
                  isLoading: _isSubmitting,
                  label: _isSubmitting ? 'Asignando...' : 'Crear Jornada',
                  onPressed: _isSubmitting ? null : _submit,
                  variant: RamisButtonVariant.primary,
                  icon: Icons.check,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehiculoId == null || _selectedConductorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Por favor seleccione un vehículo y un conductor válidos.'),
          backgroundColor: context.ramis.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(jornadaNotifierProvider.notifier).asignar(
            AsignarJornadaRequest(
              vehiculoId: _selectedVehiculoId!,
              conductorId: _selectedConductorId!,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jornada asignada exitosamente'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context);
    } on TransportFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.ramis.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

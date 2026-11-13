import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'vehiculo_selector.dart';
import 'observacion_fields.dart';
import 'odometro_confirm.dart';
import '../../data/repositories/transporte_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/domain/failures/transport_failure.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/fuel_gauge_selector.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/dynamic_actions/grua_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/dynamic_actions/combustible_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/dynamic_actions/mantenimiento_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/inspeccion_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/cocada_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/torque_form_widget.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/trabajos_externos_form_widget.dart';

class RegistroAccionForm extends ConsumerStatefulWidget {
  const RegistroAccionForm(
      {super.key, this.onRegistered, this.jornada, this.soloApertura = false});

  final JornadaTransporte? jornada;
  final bool soloApertura;

  final VoidCallback? onRegistered;

  @override
  ConsumerState<RegistroAccionForm> createState() => _RegistroAccionFormState();
}

class _RegistroAccionFormState extends ConsumerState<RegistroAccionForm> {
  final _formKey = GlobalKey<FormState>();
  final _fechaRegistro = DateTime.now();

  static const _acciones = [
    "Empezar a Conducir",
    "Operar Grúa",
    "Abastecer Combustible",
    "Mantenimiento Preventivo / Correctivo",
    "Reporte de Incidencias u Observaciones",
    "Check List y/o V°B° de vehículos",
    "Inspección Técnica",
    "Medición de Cocada",
    "Medición de Torque",
    "Trabajos a Externos",
  ];

  static const _rutas = [
    "Traslados en la UM San Rafael",
    "Traslados sólo en Antauta",
    "Traslados en Juliaca",
    "Ruta Antauta a Juliaca (Viceversa)",
    "Ruta Juliaca a Arequipa (Viceversa)",
    "Otras"
  ];

  final Map<String, List<String>> _categorias = {
    'Fluidos y Motor': [
      'Nivel de aceite',
      'Nivel de refrigerante',
      'Líquido de frenos',
      'Ausencia de fugas visibles'
    ],
    'Sistema Eléctrico y Luces': [
      'Faros principales',
      'Direccionales e intermitentes',
      'Bocina',
      'Luces de frenado y reversa'
    ],
    'Neumáticos y Ruedas': [
      'Presión de llantas',
      'Cocada visible segura',
      'Tuercas completas'
    ],
  };
  @override
  void initState() {
    super.initState();
    _vehiculoId = widget.jornada?.vehiculoId;
    _nivelCombustible = widget.jornada?.nivelCombustible;
    if (widget.soloApertura) _accionSeleccionada = "Empezar a Conducir";
    for (final items in _categorias.values) {
      for (final item in items) {
        _checklistFlash[item] = false;
      }
    }
  }

  final Map<String, bool> _checklistFlash = {
    "Documentos en vigencia (Soat, Rev.Tec., Tarjeta propiedad, licencia)":
        false,
    "Linterna (deberá estar en la guantera)": false,
    "Kits de herramientas (gata, cable pasacorriente, triangulo, alicate y desarmadores)":
        false,
    "Botiquín": false,
    "Llanta de repuesto": false,
    "Extintor": false,
    "Tacos": false,
    "Conos": false,
    "Lampa y pico": false,
    "Kits antiderrames": false,
    "Codificación": false,
  };

  String? _accionSeleccionada;
  int? _vehiculoId;
  String? _rutaSeleccionada;
  int? _nivelCombustible;
  final _observacionesController = TextEditingController();
  final _otraRutaController = TextEditingController();
  final _kmController = TextEditingController();
  bool _loadingKm = false;
  bool _isSubmitting = false;
  bool _tieneObservaciones = false;
  String _severidad = 'leve';
  String? _foto;
  List<String> _fotos = [];
  double _kmBase = 0;
  bool _esGrua = false;
  bool _esLigero = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    _otraRutaController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  Future<void> _fetchKilometraje(int? vehiculoId) async {
    _kmController.clear();
    if (vehiculoId == null) return;
    setState(() => _loadingKm = true);
    try {
      final repo = ref.read(transporteRepositoryProvider);
      final km = await repo.obtenerKilometrajeVehiculo(vehiculoId);
      _kmBase = km;
      if (mounted && _vehiculoId == vehiculoId) {
        _kmController.text = km.toStringAsFixed(1);
      }
    } catch (_) {
      // El campo queda vacío y su validador impide enviar datos incompletos.
    } finally {
      if (mounted && _vehiculoId == vehiculoId) {
        setState(() => _loadingKm = false);
      }
    }
  }

  AccionGruaRequest? _detallesGrua;
  AccionCombustibleRequest? _detallesCombustible;
  AccionMantenimientoRequest? _detallesMantenimiento;
  AccionInspeccionRequest? _detallesInspeccion;
  AccionCocadaRequest? _detallesCocada;
  AccionTorqueRequest? _detallesTorque;
  AccionTrabajosExternosRequest? _detallesTrabajosExternos;

  @override
  Widget build(BuildContext context) {
    final vehiculos = ref.watch(vehiculosDisponiblesProvider).value ?? [];
    final actual = vehiculos.where((v) => v['id'] == _vehiculoId);
    if (actual.isNotEmpty) {
      final v = actual.first;
      final tipo = (v['tipo'] ?? v['modelo'] ?? '').toString().toLowerCase();
      _esLigero = ['camioneta', 'coaster'].contains(tipo);
      _esGrua = tipo.contains('grúa') ||
          tipo.contains('grua') ||
          (v['tipo'] == null && ['Z7F-777', 'Z7M-813'].contains(v['placa']));
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(RamisSpacing.medium),
      child: RamisCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registro de Actividad',
                  style: Theme.of(context).textTheme.titleLarge!),
              SizedBox(height: RamisSpacing.medium),
              _buildGlobalFields(),
              SizedBox(height: RamisSpacing.medium),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'ACCIÓN A REALIZAR',
                  prefixIcon: Icon(Icons.touch_app),
                ),
                key: ValueKey("$_vehiculoId-$_esGrua"),
                initialValue: _accionSeleccionada,
                items: _acciones
                    .where((a) => widget.soloApertura
                        ? a == 'Empezar a Conducir'
                        : widget.jornada != null
                            ? a != 'Empezar a Conducir'
                            : true)
                    .where((a) =>
                        (a != "Operar Grúa" || _esGrua) &&
                        (!_esLigero ||
                            ![
                              "Medición de Cocada",
                              "Medición de Torque",
                              "Trabajos a Externos"
                            ].contains(a)))
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() {
                  _accionSeleccionada = val;
                  _detallesGrua = null;
                  _detallesCombustible = null;
                  _detallesMantenimiento = null;
                  _detallesInspeccion = null;
                  _detallesCocada = null;
                  _detallesTorque = null;
                  _detallesTrabajosExternos = null;
                }),
                validator: (val) =>
                    val == null ? 'Seleccione una acción' : null,
              ),
              SizedBox(height: RamisSpacing.xLarge),
              if (_accionSeleccionada == "Empezar a Conducir") ...[
                _buildConducirFields(),
              ] else if (_accionSeleccionada == "Operar Grúa") ...[
                GruaFormWidget(
                    onChanged: (val) => setState(() => _detallesGrua = val)),
              ] else if (_accionSeleccionada == "Abastecer Combustible") ...[
                CombustibleFormWidget(
                    onChanged: (val) =>
                        setState(() => _detallesCombustible = val)),
              ] else if (_accionSeleccionada ==
                  "Mantenimiento Preventivo / Correctivo") ...[
                Material(
                  type: MaterialType.transparency,
                  child: MantenimientoFormWidget(
                      onChanged: (val) =>
                          setState(() => _detallesMantenimiento = val)),
                ),
              ] else if (_accionSeleccionada ==
                  "Check List y/o V°B° de vehículos") ...[
                _buildChecklistFlash(),
              ] else if (_accionSeleccionada == "Inspección Técnica") ...[
                InspeccionFormWidget(
                  onChanged: (value) =>
                      setState(() => _detallesInspeccion = value),
                ),
              ] else if (_accionSeleccionada == "Medición de Cocada") ...[
                CocadaFormWidget(
                  onChanged: (value) => setState(() => _detallesCocada = value),
                ),
              ] else if (_accionSeleccionada == "Medición de Torque") ...[
                TorqueFormWidget(
                  onChanged: (value) => setState(() => _detallesTorque = value),
                ),
              ] else if (_accionSeleccionada == "Trabajos a Externos") ...[
                TrabajosExternosFormWidget(
                  onChanged: (value) =>
                      setState(() => _detallesTrabajosExternos = value),
                ),
              ],
              SizedBox(height: RamisSpacing.medium),
              ObservacionFields(
                onPhotosChanged: (fotos) => _fotos = fotos,
                obligatoria: _accionSeleccionada ==
                    'Reporte de Incidencias u Observaciones',
                onChanged: (activa, severidad, descripcion, foto) {
                  _tieneObservaciones = activa;
                  _severidad = severidad;
                  _observacionesController.text = descripcion;
                  _foto = foto;
                },
              ),
              SizedBox(height: RamisSpacing.xLarge),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: RamisButton(
                  isLoading: _isSubmitting,
                  label: _isSubmitting ? 'Registrando...' : 'Registrar Acción',
                  onPressed: _isSubmitting ? null : _submit,
                  variant: RamisButtonVariant.primary,
                  icon: Icons.send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalFields() {
    final vehiculosAsync = ref.watch(vehiculosDisponiblesProvider);
    final usuarioAsync = ref.watch(currentUserForTransportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildReadonlyField(
          'Fecha del Registro',
          Icons.calendar_today_outlined,
          '${_fechaRegistro.day.toString().padLeft(2, '0')}/'
              '${_fechaRegistro.month.toString().padLeft(2, '0')}/'
              '${_fechaRegistro.year} '
              '${_fechaRegistro.hour.toString().padLeft(2, '0')}:'
              '${_fechaRegistro.minute.toString().padLeft(2, '0')}',
        ),
        SizedBox(height: RamisSpacing.medium),
        usuarioAsync.when(
          data: (usuario) => _buildReadonlyField(
            'Nombre del Registrador',
            Icons.person_outline,
            usuario == null
                ? 'Usuario no disponible'
                : '${usuario.nombre} ${usuario.apellidos}'.trim(),
          ),
          loading: () => _buildReadonlyField(
            'Nombre del Registrador',
            Icons.person_outline,
            'Cargando...',
          ),
          error: (_, __) => _buildReadonlyField(
            'Nombre del Registrador',
            Icons.person_outline,
            'Usuario no disponible',
          ),
        ),
        SizedBox(height: RamisSpacing.medium),
        // ── Vehículo ──
        vehiculosAsync.when(
          data: (vehiculos) {
            if (widget.jornada != null) {
              final lista = vehiculos.where((v) => v['id'] == _vehiculoId);
              final vehiculo = lista.isEmpty ? null : lista.first;
              return _buildReadonlyField(
                  'Vehículo de la jornada',
                  Icons.local_shipping,
                  vehiculo == null
                      ? 'Vehículo #$_vehiculoId'
                      : '${vehiculo['placa']} · ${vehiculo['tipo'] ?? vehiculo['modelo']}');
            }
            return VehiculoSelector(
              vehiculos: vehiculos,
              value: _vehiculoId,
              onChanged: (v) {
                setState(() {
                  _vehiculoId = v['id'] as int;
                  _accionSeleccionada =
                      widget.soloApertura ? 'Empezar a Conducir' : null;
                });
                _fetchKilometraje(_vehiculoId);
              },
            );
          },
          loading: () => LinearProgressIndicator(),
          error: (e, _) => Text('Error al cargar vehículos: $e',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: context.ramis.error)),
        ),
        SizedBox(height: RamisSpacing.medium),

        if (_accionSeleccionada != 'Operar Grúa') ...[
          // ── Kilometraje Inicial ──
          RamisTextField(
            controller: _kmController,
            decoration: InputDecoration(
              labelText: widget.jornada == null
                  ? 'Kilometraje Inicial'
                  : 'Odómetro al registrar la actividad',
              prefixIcon: Icon(Icons.speed),
              helperText: 'Km registrado del vehículo al inicio',
              suffixIcon: _loadingKm
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(RamisSpacing.mediumSmall),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final kmStr = value?.replaceAll(',', '.') ?? '';
              final km = double.tryParse(kmStr);
              return km == null || km <= 0
                  ? 'El kilometraje inicial debe ser mayor que cero'
                  : null;
            },
          ),
          SizedBox(height: RamisSpacing.medium),

          // ── Combustible Inicial ──
          FormField<int>(
            initialValue: _nivelCombustible,
            validator: (value) => value == null
                ? 'Seleccione el nivel de combustible inicial'
                : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FuelGaugeSelector(
                  value: _nivelCombustible,
                  onChanged: (value) {
                    field.didChange(value);
                    setState(() => _nivelCombustible = value);
                  },
                ),
                if (field.hasError)
                  Text(field.errorText!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: context.ramis.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadonlyField(String label, IconData icon, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: Text(value, style: Theme.of(context).textTheme.bodyMedium!),
    );
  }

  Widget _buildConducirFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Ruta ──
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Ruta o Recorrido',
            prefixIcon: Icon(Icons.route),
          ),
          items: _rutas
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _rutaSeleccionada = val),
          validator: (val) => val == null ? 'Seleccione una ruta' : null,
        ),
        if (_rutaSeleccionada == 'Otras') ...[
          SizedBox(height: RamisSpacing.mediumSmall),
          RamisTextField(
            controller: _otraRutaController,
            decoration: InputDecoration(
              labelText: 'Especifique la ruta',
              prefixIcon: Icon(Icons.edit_road),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingrese la ruta o recorrido'
                : null,
          ),
        ],
        SizedBox(height: RamisSpacing.medium),
        _buildChecklistFlash(),
      ],
    );
  }

  Widget _buildChecklistFlash() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Check List Flash (Obligatorio)',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.bold)),
        if (_checklistFlash.entries.any((e) =>
            !e.value &&
            RegExp('freno|direcci|Extintor|Documentos', caseSensitive: false)
                .hasMatch(e.key)))
          RamisCard(
              padding: EdgeInsets.zero,
              color: context.ramis.pendingBackground,
              child: Padding(
                  padding: EdgeInsets.all(RamisSpacing.mediumSmall),
                  child: Text(
                      'Advertencia de seguridad: revise frenos/dirección, extintor y documentos. Se notificará a administración; la supervisión debe evaluar la operación.'))),
        SizedBox(height: RamisSpacing.small),
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.ramis.border),
            borderRadius: RamisRadius.small,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final categoria in {
                ..._categorias,
                'Seguridad y Documentos': _checklistFlash.keys
                    .where((k) =>
                        !_categorias.values.any((items) => items.contains(k)))
                    .toList()
              }.entries) ...[
                Divider(),
                Padding(
                    padding: EdgeInsets.all(RamisSpacing.mediumSmall),
                    child: Text(categoria.key,
                        style: Theme.of(context).textTheme.labelLarge!)),
                for (final item in categoria.value)
                  CheckboxListTile(
                      title: Text(item,
                          style: Theme.of(context).textTheme.bodySmall!,
                          softWrap: true),
                      value: _checklistFlash[item],
                      onChanged: (v) =>
                          setState(() => _checklistFlash[item] = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (ref.read(currentUserForTransportProvider).value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo identificar al registrador.')),
      );
      return;
    }

    if (_vehiculoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleccione un vehículo.')),
      );
      return;
    }

    final distancia = _accionSeleccionada == 'Operar Grúa'
        ? 0.0
        : (double.tryParse(_kmController.text.replaceAll(',', '.')) ??
                _kmBase) -
            _kmBase;
    final evidencia = await confirmarOdometro(context, distancia);
    if (evidencia == null || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(jornadaNotifierProvider.notifier).registrarAccion(
            RegistroAccionRequest(
              accionTipo: _accionSeleccionada!,
              vehiculoId: _vehiculoId!,
              jornadaPadreId: widget.jornada?.id,
              kmInicial: _accionSeleccionada == 'Operar Grúa'
                  ? null
                  : double.parse(_kmController.text.replaceAll(',', '.')),
              ruta: _accionSeleccionada == 'Empezar a Conducir'
                  ? (_rutaSeleccionada == 'Otras'
                      ? _otraRutaController.text.trim()
                      : _rutaSeleccionada)
                  : null,
              nivelCombustible: _accionSeleccionada == 'Operar Grúa'
                  ? null
                  : _nivelCombustible!,
              checklistFlash: _accionSeleccionada == 'Empezar a Conducir' ||
                      _accionSeleccionada == 'Check List y/o V°B° de vehículos'
                  ? _checklistFlash
                  : null,
              tieneObservaciones: _tieneObservaciones,
              severidad: _severidad,
              fotoObservacion: _foto,
              fotosObservacion: _fotos,
              odometroEvidenciaUrl: evidencia['odometro_evidencia_url'],
              odometroMotivo: evidencia['odometro_motivo'],
              observaciones: _tieneObservaciones
                  ? _observacionesController.text.trim()
                  : 'Sin novedades',
              detallesGrua: _detallesGrua,
              detallesCombustible: _detallesCombustible,
              detallesMantenimiento: _detallesMantenimiento,
              detallesInspeccion: _detallesInspeccion,
              detallesCocada: _detallesCocada,
              detallesTorque: _detallesTorque,
              detallesTrabajosExternos: _detallesTrabajosExternos,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acción registrada exitosamente'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      // Trigger a refresh of the miJornadaProvider
      ref.invalidate(vehiculosDisponiblesProvider);
      ref.invalidate(miJornadaProvider);
      ref.invalidate(accionesRegistradasProvider);
      widget.onRegistered?.call();
    } on TransportQueued catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      widget.onRegistered?.call();
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

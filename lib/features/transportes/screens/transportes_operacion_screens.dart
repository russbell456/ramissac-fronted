import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/features/transportes/models/averia_model.dart';
import 'package:sistema_ocs/features/transportes/models/incidente_model.dart';
import 'package:sistema_ocs/features/transportes/models/inspeccion_model.dart';
import 'package:sistema_ocs/features/transportes/models/mantenimiento_model.dart';
import 'package:sistema_ocs/features/transportes/providers/transportes_provider.dart';

/// Tipos de inspeccion soportados en el flujo.
enum TipoInspeccion { salida, llegada, postMantenimiento }

extension TipoInspeccionX on TipoInspeccion {
  String get api => switch (this) {
        TipoInspeccion.salida => 'salida',
        TipoInspeccion.llegada => 'llegada',
        TipoInspeccion.postMantenimiento => 'post_mantenimiento',
      };
  String get label => switch (this) {
        TipoInspeccion.salida => 'Checklist de salida',
        TipoInspeccion.llegada => 'Checklist de llegada',
        TipoInspeccion.postMantenimiento => 'Inspeccion post mantenimiento',
      };
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool number = false,
  int maxLines = 1,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: RamisSpacing.mediumSmall),
    child: RamisTextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType:
          number ? TextInputType.numberWithOptions(decimal: true) : null,
      decoration:
          InputDecoration(labelText: label, border: OutlineInputBorder()),
      validator: (value) {
        if (label.startsWith('Observaciones')) return null;
        if (value == null || value.trim().isEmpty) return 'Campo requerido';
        if (number && double.tryParse(value.trim()) == null) {
          return 'Ingrese un numero valido';
        }
        return null;
      },
    ),
  );
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}

/// Pantalla para realizar una inspeccion (checklist salida/llegada/post-mant).
class InspeccionScreen extends ConsumerStatefulWidget {
  const InspeccionScreen({
    super.key,
    required this.vehiculoId,
    required this.trabajadorId,
    required this.tipo,
    this.rutaId,
    this.kilometrajeInicial,
  });

  final int vehiculoId;
  final int trabajadorId;
  final TipoInspeccion tipo;
  final int? rutaId;
  final double? kilometrajeInicial;

  @override
  ConsumerState<InspeccionScreen> createState() => _InspeccionScreenState();
}

class _InspeccionScreenState extends ConsumerState<InspeccionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kilometraje = TextEditingController();
  final _combustible = TextEditingController();
  final _observaciones = TextEditingController();
  // checklist_item_id -> resultado
  final Map<int, String> _resultados = {};
  List<ChecklistItemModel> _items = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.kilometrajeInicial != null) {
      _kilometraje.text = widget.kilometrajeInicial.toString();
    }
    _cargarChecklist();
  }

  Future<void> _cargarChecklist() async {
    try {
      final items =
          await ref.read(transportesServiceProvider).listarChecklistItems();
      if (!mounted) return;
      setState(() => _items = items);
      for (final item in items) {
        _resultados[item.id] = 'conforme';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar checklist: $error')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay items de checklist disponibles')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final detalles = _items
          .map((item) => InspeccionDetalleCreate(
                checklistItemId: item.id,
                resultadoItem: _resultados[item.id] ?? 'conforme',
              ))
          .toList();
      await ref.read(transportesServiceProvider).crearInspeccion(
            CrearInspeccionRequest(
              vehiculoId: widget.vehiculoId,
              trabajadorId: widget.trabajadorId,
              tipo: widget.tipo.api,
              kilometraje: double.parse(_kilometraje.text.trim()),
              combustible: _combustible.text.trim(),
              detalles: detalles,
              rutaId: widget.rutaId,
              observaciones: _observaciones.text.trim().isEmpty
                  ? null
                  : _observaciones.text.trim(),
            ),
          );
      ref.invalidate(inspeccionesProvider);
      ref.invalidate(inspeccionesVehiculoProvider(widget.vehiculoId));
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _kilometraje.dispose();
    _combustible.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RamisScaffold(
      maxContentWidth: 1200,
      appBar: RamisAppBar(
        title: widget.tipo.label,
        automaticallyImplyLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(RamisSpacing.medium),
          children: [
            Text('Vehiculo ${widget.vehiculoId}'),
            SizedBox(height: RamisSpacing.small),
            _field(_kilometraje, 'Kilometraje', number: true),
            _field(_combustible, 'Combustible (ej: 1/4, 1/2, lleno)'),
            if (_items.isEmpty)
              Padding(
                padding: EdgeInsets.all(RamisSpacing.medium),
                child: Text('Cargando checklist...'),
              )
            else
              ..._items.map(
                (item) => RamisCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(item.nombre),
                    subtitle: Text('${item.categoria} - ${item.criticidad}'),
                    trailing: DropdownButton<String>(
                      value: _resultados[item.id],
                      items: [
                        DropdownMenuItem(
                          value: 'conforme',
                          child: Text('Conforme'),
                        ),
                        DropdownMenuItem(
                          value: 'observado',
                          child: Text('Observado'),
                        ),
                        DropdownMenuItem(
                          value: 'no_conforme',
                          child: Text('No conforme'),
                        ),
                        DropdownMenuItem(
                          value: 'no_aplica',
                          child: Text('No aplica'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          if (value != null) {
                            _resultados[item.id] = value;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            _field(_observaciones, 'Observaciones', maxLines: 3),
            SizedBox(height: RamisSpacing.medium),
            RamisButton(
              isLoading: _saving,
              label: 'Guardar inspeccion',
              onPressed: _saving ? null : _save,
              variant: RamisButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla para reportar una averia.
class AveriaFormScreen extends ConsumerStatefulWidget {
  const AveriaFormScreen({
    super.key,
    required this.vehiculoId,
    this.trabajadorId,
    this.rutaId,
  });

  final int vehiculoId;
  final int? trabajadorId;
  final int? rutaId;

  @override
  ConsumerState<AveriaFormScreen> createState() => _AveriaFormScreenState();
}

class _AveriaFormScreenState extends ConsumerState<AveriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoria = TextEditingController();
  final _componente = TextEditingController();
  final _descripcion = TextEditingController();
  String _criticidad = 'media';
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportesServiceProvider).crearAveria(
            CrearAveriaRequest(
              vehiculoId: widget.vehiculoId,
              categoria: _categoria.text.trim(),
              componente: _componente.text.trim(),
              descripcion: _descripcion.text.trim(),
              criticidad: _criticidad,
              origen: 'operacion',
              trabajadorId: widget.trabajadorId,
              rutaId: widget.rutaId,
            ),
          );
      ref.invalidate(averiasProvider);
      ref.invalidate(averiasVehiculoProvider(widget.vehiculoId));
      ref.invalidate(vehiculosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _categoria.dispose();
    _componente.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RamisScaffold(
      maxContentWidth: 1200,
      appBar: RamisAppBar(
        title: 'Reportar averia',
        automaticallyImplyLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(RamisSpacing.medium),
          children: [
            Text('Vehiculo ${widget.vehiculoId}'),
            _field(_categoria, 'Categoria (Motor, Electrico, etc.)'),
            _field(_componente, 'Componente afectado'),
            _field(_descripcion, 'Descripcion del problema', maxLines: 3),
            Padding(
              padding: EdgeInsets.only(bottom: RamisSpacing.mediumSmall),
              child: Text('Criticidad'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _criticidad,
              items: [
                DropdownMenuItem(value: 'baja', child: Text('Baja')),
                DropdownMenuItem(value: 'media', child: Text('Media')),
                DropdownMenuItem(value: 'alta', child: Text('Alta')),
                DropdownMenuItem(value: 'critica', child: Text('Critica')),
              ],
              onChanged: (value) =>
                  setState(() => _criticidad = value ?? 'media'),
            ),
            SizedBox(height: RamisSpacing.large),
            RamisButton(
              isLoading: _saving,
              label: 'Guardar averia',
              onPressed: _saving ? null : _save,
              variant: RamisButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla para reportar un incidente.
class IncidenteFormScreen extends ConsumerStatefulWidget {
  const IncidenteFormScreen({
    super.key,
    required this.vehiculoId,
    required this.trabajadorId,
    this.rutaId,
  });

  final int vehiculoId;
  final int trabajadorId;
  final int? rutaId;

  @override
  ConsumerState<IncidenteFormScreen> createState() =>
      _IncidenteFormScreenState();
}

class _IncidenteFormScreenState extends ConsumerState<IncidenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ubicacion = TextEditingController();
  final _descripcion = TextEditingController();
  String _tipo = 'colision';
  bool _hayDanos = false;
  bool _hayPersonas = false;
  bool _generarAveria = false;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportesServiceProvider).crearIncidente(
            CrearIncidenteRequest(
              vehiculoId: widget.vehiculoId,
              trabajadorId: widget.trabajadorId,
              tipo: _tipo,
              ubicacion: _ubicacion.text.trim(),
              descripcion: _descripcion.text.trim(),
              rutaId: widget.rutaId,
              hayDanos: _hayDanos,
              hayPersonasAfectadas: _hayPersonas,
              generarAveria: _generarAveria,
              averiaCategoria: _generarAveria ? 'Carroceria' : null,
              averiaComponente: _generarAveria ? 'General' : null,
              averiaCriticidad: _hayPersonas ? 'critica' : 'alta',
              averiaDescripcion:
                  _generarAveria ? _descripcion.text.trim() : null,
            ),
          );
      ref.invalidate(incidentesProvider);
      ref.invalidate(incidentesVehiculoProvider(widget.vehiculoId));
      ref.invalidate(vehiculosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _ubicacion.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RamisScaffold(
      maxContentWidth: 1200,
      appBar: RamisAppBar(
        title: 'Reportar incidente',
        automaticallyImplyLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(RamisSpacing.medium),
          children: [
            Text('Vehiculo ${widget.vehiculoId}'),
            SizedBox(height: RamisSpacing.small),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              items: [
                DropdownMenuItem(value: 'colision', child: Text('Colision')),
                DropdownMenuItem(value: 'choque', child: Text('Choque')),
                DropdownMenuItem(
                  value: 'volcadura',
                  child: Text('Volcadura'),
                ),
                DropdownMenuItem(value: 'impacto', child: Text('Impacto')),
                DropdownMenuItem(
                  value: 'dano_estructural',
                  child: Text('Dano estructural'),
                ),
                DropdownMenuItem(
                  value: 'casi_accidente',
                  child: Text('Casi accidente'),
                ),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? 'colision'),
            ),
            _field(_ubicacion, 'Ubicacion'),
            _field(_descripcion, 'Descripcion', maxLines: 3),
            SwitchListTile(
              title: Text('Hay danos'),
              value: _hayDanos,
              onChanged: (v) => setState(() => _hayDanos = v),
            ),
            SwitchListTile(
              title: Text('Hay personas afectadas'),
              value: _hayPersonas,
              onChanged: (v) => setState(() => _hayPersonas = v),
            ),
            SwitchListTile(
              title: Text('Generar averia asociada'),
              value: _generarAveria,
              onChanged: (v) => setState(() => _generarAveria = v),
            ),
            SizedBox(height: RamisSpacing.large),
            RamisButton(
              isLoading: _saving,
              label: 'Guardar incidente',
              onPressed: _saving ? null : _save,
              variant: RamisButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla para ejecutar un mantenimiento y luego realizar la inspeccion
/// post-mantenimiento (regreso del vehiculo a disponible).
class EjecutarMantenimientoScreen extends ConsumerStatefulWidget {
  const EjecutarMantenimientoScreen({
    super.key,
    required this.mantenimientoId,
    required this.vehiculoId,
    this.trabajadorId = 0,
  });

  final int mantenimientoId;
  final int vehiculoId;
  final int trabajadorId;

  @override
  ConsumerState<EjecutarMantenimientoScreen> createState() =>
      _EjecutarMantenimientoScreenState();
}

class _EjecutarMantenimientoScreenState
    extends ConsumerState<EjecutarMantenimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _km = TextEditingController();
  final _horas = TextEditingController(text: '0');
  final _observaciones = TextEditingController();
  final _combustible = TextEditingController(text: 'lleno');
  bool _saving = false;
  bool _crearInspeccionPost = true;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(transportesServiceProvider).ejecutarMantenimiento(
            widget.mantenimientoId,
            EjecutarMantenimientoRequest(
              trabajadorId: widget.trabajadorId,
              kmEjecucion: double.parse(_km.text.trim()),
              horasEjecucion: double.parse(_horas.text.trim()),
              observacionesEjecucion: _observaciones.text.trim().isEmpty
                  ? null
                  : _observaciones.text.trim(),
            ),
          );
      // Regreso a disponible: inspeccion post-mantenimiento.
      if (_crearInspeccionPost) {
        await ref.read(transportesServiceProvider).crearInspeccion(
              CrearInspeccionRequest(
                vehiculoId: widget.vehiculoId,
                trabajadorId: widget.trabajadorId,
                tipo: TipoInspeccion.postMantenimiento.api,
                kilometraje: double.parse(_km.text.trim()),
                combustible: _combustible.text.trim(),
                detalles: [],
              ),
            );
      }
      ref.invalidate(mantenimientosProvider);
      ref.invalidate(
        mantenimientosVehiculoProvider(widget.vehiculoId),
      );
      ref.invalidate(inspeccionesVehiculoProvider(widget.vehiculoId));
      ref.invalidate(vehiculosProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _km.dispose();
    _horas.dispose();
    _observaciones.dispose();
    _combustible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RamisScaffold(
      maxContentWidth: 1200,
      appBar: RamisAppBar(
        title: 'Ejecutar mantenimiento',
        automaticallyImplyLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(RamisSpacing.medium),
          children: [
            Text('Vehiculo ${widget.vehiculoId} - Mantenimiento '
                '${widget.mantenimientoId}'),
            _field(_km, 'Kilometraje de ejecucion', number: true),
            _field(_horas, 'Horas de ejecucion', number: true),
            _field(_observaciones, 'Observaciones de ejecucion', maxLines: 3),
            SwitchListTile(
              title: Text('Crear inspeccion post-mantenimiento'),
              subtitle: Text('Vuelve el vehiculo al flujo de operacion'),
              value: _crearInspeccionPost,
              onChanged: (v) => setState(() => _crearInspeccionPost = v),
            ),
            if (_crearInspeccionPost)
              _field(_combustible, 'Combustible tras mantenimiento'),
            SizedBox(height: RamisSpacing.large),
            RamisButton(
              isLoading: _saving,
              label: 'Ejecutar y liberar vehiculo',
              onPressed: _saving ? null : _save,
              variant: RamisButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}

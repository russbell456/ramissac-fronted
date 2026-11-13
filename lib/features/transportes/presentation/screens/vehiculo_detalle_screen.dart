import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/save_download.dart';
import '../../providers/jornadas_provider.dart';
import '../../providers/admin_transportes_provider.dart';
import 'documentos_screen.dart';

class VehiculoDetalleScreen extends ConsumerStatefulWidget {
  const VehiculoDetalleScreen(
      {super.key, required this.vehiculo, this.administrar = true});
  final Map<String, dynamic> vehiculo;
  final bool administrar;
  @override
  ConsumerState<VehiculoDetalleScreen> createState() =>
      _VehiculoDetalleScreenState();
}

class _VehiculoDetalleScreenState extends ConsumerState<VehiculoDetalleScreen> {
  bool _descargando = false;
  Future<void> _descargar() async {
    String estado = 'pendientes';
    DateTimeRange? rango;
    final confirmar = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => Padding(
                padding: EdgeInsets.all(RamisSpacing.large),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Ficha Técnica PDF',
                          style: Theme.of(context).textTheme.headlineSmall),
                      DropdownButtonFormField<String>(
                          initialValue: estado,
                          decoration:
                              InputDecoration(labelText: 'Observaciones'),
                          items: [
                            DropdownMenuItem(
                                value: 'pendientes',
                                child: Text('Solo pendientes')),
                            DropdownMenuItem(
                                value: 'todas',
                                child: Text('Historial completo'))
                          ],
                          onChanged: (v) => update(() => estado = v!)),
                      RamisButton(
                        label: rango == null
                            ? 'Filtrar por fechas (opcional)'
                            : '${rango!.start.day}/${rango!.start.month}/${rango!.start.year} – ${rango!.end.day}/${rango!.end.month}/${rango!.end.year}',
                        onPressed: () async {
                          final result = await showDateRangePicker(
                              context: ctx,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              initialDateRange: rango);
                          if (result != null && ctx.mounted) {
                            update(() => rango = result);
                          }
                        },
                        variant: RamisButtonVariant.text,
                        icon: Icons.date_range,
                      ),
                      if (rango != null)
                        RamisButton(
                          label: 'Quitar fechas',
                          onPressed: () => update(() => rango = null),
                          variant: RamisButtonVariant.text,
                        ),
                      SizedBox(height: RamisSpacing.medium),
                      RamisButton(
                        label: 'Descargar PDF',
                        onPressed: () => Navigator.pop(ctx, true),
                        variant: RamisButtonVariant.primary,
                      ),
                    ]))));
    if (confirmar != true || !mounted) return;
    setState(() => _descargando = true);
    try {
      String fecha(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final bytes = await ref.read(transporteRepositoryProvider).reportePdf(
          (widget.vehiculo['id'] as num).toInt(),
          estado,
          rango == null ? null : fecha(rango!.start),
          rango == null ? null : fecha(rango!.end));
      final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar ficha técnica',
          fileName: 'vehiculo-${widget.vehiculo['placa']}.pdf',
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: Uint8List.fromList(bytes));
      if (path != null &&
          !kIsWeb &&
          [TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macOS]
              .contains(defaultTargetPlatform)) {
        await writeDownloadedFile(path, bytes);
      }
      if (path != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ficha técnica descargada.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo descargar el PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _descargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => RamisScaffold(
      maxContentWidth: 1200,
      appBar: RamisAppBar(
        title: 'Vehículo ${widget.vehiculo['placa']}',
        automaticallyImplyLeading: true,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: EdgeInsets.fromLTRB(
                RamisSpacing.medium,
                RamisSpacing.mediumSmall,
                RamisSpacing.medium,
                RamisSpacing.small),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      '${widget.vehiculo['marca']} ${widget.vehiculo['modelo']}',
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: RamisSpacing.small),
                  Wrap(
                      spacing: RamisSpacing.small,
                      runSpacing: RamisSpacing.small,
                      children: [
                        RamisStatusChip(
                          label:
                              'Operativo: ${widget.vehiculo['estado_semaforo'] ?? 'verde'}',
                          foregroundColor: colorDocumento(context,
                              '${widget.vehiculo['estado_semaforo'] ?? 'verde'}'),
                        ),
                        RamisStatusChip(
                          label: '${widget.vehiculo['kilometraje_actual']} km',
                        )
                      ]),
                  SizedBox(height: RamisSpacing.mediumSmall),
                  RamisButton(
                    isLoading: _descargando,
                    label: _descargando
                        ? 'Descargando…'
                        : 'Descargar Ficha Técnica PDF',
                    onPressed: _descargando ? null : _descargar,
                    variant: RamisButtonVariant.primary,
                    icon: Icons.picture_as_pdf,
                  ),
                ])),
        Expanded(
            child: DocumentosScreen(
                entidad: 'vehiculo',
                titularId: (widget.vehiculo['id'] as num).toInt(),
                administrar: widget.administrar,
                embedded: true)),
      ]));
}

Future<bool?> mostrarAltaVehiculo(BuildContext context) =>
    showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => AltaVehiculoForm());

class AltaVehiculoForm extends ConsumerStatefulWidget {
  const AltaVehiculoForm({super.key});
  @override
  ConsumerState<AltaVehiculoForm> createState() => _AltaVehiculoFormState();
}

class _AltaVehiculoFormState extends ConsumerState<AltaVehiculoForm> {
  final _form = GlobalKey<FormState>();
  final _placa = TextEditingController(),
      _modelo = TextEditingController(),
      _marca = TextEditingController();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _placa.dispose();
    _modelo.dispose();
    _marca.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(transporteRepositoryProvider).altaVehiculo({
        'placa': _placa.text.trim().toUpperCase(),
        'modelo': _modelo.text.trim(),
        if (_marca.text.trim().isNotEmpty) 'marca': _marca.text.trim()
      });
      ref.invalidate(vehiculosListProvider);
      ref.invalidate(vehiculosDisponiblesProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
          child: Form(
              key: _form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Alta Rápida de Vehículo',
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: RamisSpacing.large),
                    RamisTextField(
                        controller: _placa,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 20,
                        decoration: InputDecoration(labelText: 'Placa'),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Ingrese la placa'
                            : null),
                    RamisTextField(
                        controller: _modelo,
                        decoration:
                            InputDecoration(labelText: 'Nombre / Modelo'),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Ingrese el nombre o modelo'
                            : null),
                    SizedBox(height: RamisSpacing.medium),
                    RamisTextField(
                        controller: _marca,
                        decoration:
                            InputDecoration(labelText: 'Marca (opcional)')),
                    if (_error != null)
                      Padding(
                          padding:
                              EdgeInsets.only(top: RamisSpacing.mediumSmall),
                          child: Text(_error!,
                              style: TextStyle(color: context.ramis.error))),
                    SizedBox(height: RamisSpacing.xLarge),
                    RamisButton(
                      label: _saving ? 'Guardando…' : 'Registrar vehículo',
                      onPressed: _saving ? null : _save,
                      variant: RamisButtonVariant.primary,
                    ),
                  ]))));
}

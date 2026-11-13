import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/documento_transporte.dart';
import '../../providers/documentos_provider.dart';
import '../../providers/jornadas_provider.dart';
import 'documentos_screen.dart';

class ConductoresScreen extends ConsumerStatefulWidget {
  const ConductoresScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends ConsumerState<ConductoresScreen> {
  String _buscar = '';
  Future<void> _refresh() async {
    ref.invalidate(conductoresV3Provider);
    await ref.read(conductoresV3Provider.future);
  }

  Future<void> _formulario([Map<String, dynamic>? conductor]) async {
    final cambiado = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ConductorForm(conductor: conductor));
    if (cambiado == true) await _refresh();
  }

  void _documentos(Map<String, dynamic> c) => Navigator.push<void>(
      context,
      MaterialPageRoute(
          builder: (_) => DocumentosScreen(
              entidad: 'conductor',
              titularId: (c['id'] as num).toInt(),
              administrar: true,
              titulo: 'Documentos · ${c['nombre']} ${c['apellidos']}')));
  @override
  Widget build(BuildContext context) => RamisScaffold(
      maxContentWidth: 1200,
      appBar: widget.embedded
          ? null
          : RamisAppBar(
              title: 'Conductores',
              automaticallyImplyLeading: true,
            ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _formulario,
          icon: Icon(Icons.person_add),
          label: Text('Nuevo conductor')),
      body: Column(children: [
        Padding(
            padding: EdgeInsets.all(RamisSpacing.medium),
            child: RamisTextField(
                onChanged: (v) => setState(() => _buscar = v.toLowerCase()),
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar por DNI o nombre'))),
        Expanded(
            child: ref.watch(conductoresV3Provider).when(
                loading: () => RamisLoading(),
                error: (e, _) => RamisErrorView(
                      description: 'No se pudieron cargar los conductores: $e',
                      onRetry: () => ref.invalidate(conductoresV3Provider),
                    ),
                data: (lista) {
                  final rows = lista
                      .where((c) =>
                          '${c['dni']} ${c['nombre']} ${c['apellidos']}'
                              .toLowerCase()
                              .contains(_buscar))
                      .toList();
                  return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                          padding: EdgeInsets.fromLTRB(RamisSpacing.mediumSmall,
                              0, RamisSpacing.mediumSmall, 110),
                          children: [
                            if (rows.isEmpty)
                              Padding(
                                  padding: EdgeInsets.all(RamisSpacing.xLarge),
                                  child:
                                      Text('No hay conductores para mostrar.')),
                            for (final c in rows)
                              RamisCard(
                                  padding: EdgeInsets.zero,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.all(RamisSpacing.medium),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${c['nombre']} ${c['apellidos']}',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                            Text('DNI: ${c['dni']}'),
                                            Text('Correo: ${c['email']}'),
                                            SizedBox(
                                                height: RamisSpacing.small),
                                            Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  for (final tipo
                                                      in documentosConductor
                                                          .keys)
                                                    Builder(builder: (_) {
                                                      final docs =
                                                          (c['documentos']
                                                                      as List? ??
                                                                  [])
                                                              .whereType<Map>()
                                                              .where((d) =>
                                                                  d['tipo'] ==
                                                                  tipo);
                                                      final doc = docs.isEmpty
                                                          ? <String, dynamic>{}
                                                          : docs.first;
                                                      final color = (doc[
                                                                  'semaforo'] ??
                                                              doc['estado'] ??
                                                              'pendiente')
                                                          as String;
                                                      return RamisStatusChip(
                                                        label:
                                                            '${tipo == 'licencia' ? 'Licencia' : tipo == 'emo' ? 'EMO' : 'Pase Minero'}: $color',
                                                        foregroundColor:
                                                            colorDocumento(
                                                                context, color),
                                                      );
                                                    })
                                                ]),
                                            Wrap(spacing: 8, children: [
                                              RamisButton(
                                                label: 'Revisar Documentos',
                                                onPressed: () => _documentos(c),
                                                variant:
                                                    RamisButtonVariant.primary,
                                                icon: Icons.fact_check,
                                              ),
                                              RamisButton(
                                                label: 'Configurar Acceso',
                                                onPressed: () => _formulario(c),
                                                variant:
                                                    RamisButtonVariant.outlined,
                                                icon: Icons.manage_accounts,
                                              ),
                                            ]),
                                          ]))),
                          ]));
                })),
      ]));
}

class ConductorForm extends ConsumerStatefulWidget {
  const ConductorForm({super.key, this.conductor});
  final Map<String, dynamic>? conductor;
  @override
  ConsumerState<ConductorForm> createState() => _ConductorFormState();
}

class _ConductorFormState extends ConsumerState<ConductorForm> {
  final _form = GlobalKey<FormState>();
  final _dni = TextEditingController(),
      _nombre = TextEditingController(),
      _apellidos = TextEditingController();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _guardando = false, _visible = false;
  String? _error;
  bool get acceso => widget.conductor != null;
  @override
  void initState() {
    super.initState();
    _email.text = widget.conductor?['email'] as String? ?? '';
  }

  @override
  void dispose() {
    for (final c in [_dni, _nombre, _apellidos, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final repo = ref.read(transporteRepositoryProvider);
      if (acceso) {
        await repo.configurarAcceso((widget.conductor!['id'] as num).toInt(),
            _email.text.trim(), _password.text);
      } else {
        await repo.altaConductor(
            _dni.text.trim(), _nombre.text.trim(), _apellidos.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _guardando = false);
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
                    Text(
                        acceso
                            ? 'Configurar Acceso'
                            : 'Alta Rápida de Conductor',
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: RamisSpacing.large),
                    if (!acceso) ...[
                      RamisTextField(
                          controller: _dni,
                          maxLength: 8,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'DNI'),
                          validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '')
                              ? null
                              : 'Ingrese 8 dígitos'),
                      RamisTextField(
                          controller: _nombre,
                          decoration: InputDecoration(labelText: 'Nombres'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v ?? '').trim().length < 2
                              ? 'Ingrese los nombres'
                              : null),
                      SizedBox(height: RamisSpacing.medium),
                      RamisTextField(
                          controller: _apellidos,
                          decoration: InputDecoration(labelText: 'Apellidos'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v ?? '').trim().length < 2
                              ? 'Ingrese los apellidos'
                              : null),
                    ] else ...[
                      Text(
                          '${widget.conductor!['nombre']} ${widget.conductor!['apellidos']}'),
                      RamisTextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              InputDecoration(labelText: 'Correo electrónico'),
                          validator: (v) =>
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch((v ?? '').trim())
                                  ? null
                                  : 'Ingrese un correo válido'),
                      SizedBox(height: RamisSpacing.medium),
                      RamisTextField(
                          controller: _password,
                          obscureText: !_visible,
                          maxLength: 128,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                              labelText: 'Contraseña inicial',
                              suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _visible = !_visible),
                                  icon: Icon(_visible
                                      ? Icons.visibility_off
                                      : Icons.visibility))),
                          validator: (v) => (v ?? '').length < 8
                              ? 'Mínimo 8 caracteres'
                              : null),
                    ],
                    if (_error != null)
                      Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: RamisSpacing.mediumSmall),
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    SizedBox(height: RamisSpacing.xLarge),
                    RamisButton(
                      label: _guardando ? 'Guardando…' : 'Guardar',
                      onPressed: _guardando ? null : _guardar,
                      variant: RamisButtonVariant.primary,
                    ),
                  ]))));
}

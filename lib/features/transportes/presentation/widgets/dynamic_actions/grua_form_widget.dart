import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';

class GruaFormWidget extends StatefulWidget {
  final void Function(AccionGruaRequest) onChanged;

  const GruaFormWidget({super.key, required this.onChanged});

  @override
  State<GruaFormWidget> createState() => _GruaFormWidgetState();
}

class _GruaFormWidgetState extends State<GruaFormWidget> {
  final _actividadController = TextEditingController();
  final _horometroInicialController = TextEditingController();
  final _horometroFinalController = TextEditingController();

  @override
  void dispose() {
    _actividadController.dispose();
    _horometroInicialController.dispose();
    _horometroFinalController.dispose();
    super.dispose();
  }

  double? _numero(String value) => double.tryParse(value.replaceAll(',', '.'));

  void _emit() {
    widget.onChanged(AccionGruaRequest(
      actividad: _actividadController.text.trim(),
      horometroInicial: _numero(_horometroInicialController.text),
      horometroFinal: _numero(_horometroFinalController.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RamisTextField(
          controller: _actividadController,
          decoration: InputDecoration(
            labelText: 'ACTIVIDAD A REALIZAR',
            helperText: 'Describir la actividad que se realiza con la grúa',
            helperMaxLines: 2,
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Describa la actividad'
              : null,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: RamisSpacing.medium),
        RamisTextField(
          controller: _horometroInicialController,
          decoration: InputDecoration(
            labelText: 'HORÓMETRO INICIAL',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final numero = _numero(value ?? '');
            return numero == null || numero <= 0
                ? 'Ingrese un horómetro inicial válido'
                : null;
          },
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: RamisSpacing.medium),
        RamisTextField(
          controller: _horometroFinalController,
          decoration: InputDecoration(
            labelText: 'HORÓMETRO FINAL',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final numero = _numero(value);
            if (numero == null || numero <= 0) {
              return 'Ingrese un horómetro final válido';
            }
            final inicial = _numero(_horometroInicialController.text);
            return inicial != null && numero < inicial
                ? 'El horómetro final no puede ser menor al inicial'
                : null;
          },
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}

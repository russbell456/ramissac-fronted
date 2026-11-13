import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/fuel_gauge_selector.dart';

class CombustibleFormWidget extends StatefulWidget {
  final void Function(AccionCombustibleRequest) onChanged;

  const CombustibleFormWidget({super.key, required this.onChanged});

  @override
  State<CombustibleFormWidget> createState() => _CombustibleFormWidgetState();
}

class _CombustibleFormWidgetState extends State<CombustibleFormWidget> {
  final _galonesController = TextEditingController();
  int? _nivelFinal;
  final _costoController = TextEditingController();
  final _comprobanteController = TextEditingController();

  @override
  void dispose() {
    _galonesController.dispose();
    _costoController.dispose();
    _comprobanteController.dispose();
    super.dispose();
  }

  double? _galones(String value) => double.tryParse(value.replaceAll(',', '.'));

  void _emit() {
    widget.onChanged(AccionCombustibleRequest(
      costo: _galones(_costoController.text),
      comprobante: _comprobanteController.text.trim(),
      galones: _galones(_galonesController.text),
      nivelFinal: _nivelFinal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RamisTextField(
            controller: _costoController,
            decoration: InputDecoration(labelText: 'Costo total (S/)'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _emit(),
            validator: (v) => (v ?? '').isNotEmpty &&
                    (_galones(v!) == null || _galones(v)! < 0)
                ? 'Ingrese un costo válido'
                : null),
        RamisTextField(
            controller: _comprobanteController,
            decoration: InputDecoration(labelText: 'N° factura / vale'),
            maxLength: 100,
            onChanged: (_) => _emit()),
        RamisTextField(
          controller: _galonesController,
          decoration: InputDecoration(
            labelText: 'CANTIDAD COMBUSTIBLE ABASTECIDO EN GALONES',
            helperText:
                'Colocar la cantidad de galones abastecidos en el grifo',
            helperMaxLines: 2,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final cantidad = _galones(value ?? '');
            return cantidad == null || cantidad < 0.1 || cantidad > 100
                ? 'Ingrese entre 0.1 y 100 galones'
                : null;
          },
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: RamisSpacing.medium),
        Text('NIVEL DE COMBUSTIBLE FINAL',
            style: Theme.of(context).textTheme.bodyMedium!),
        Text('Colocar el nivel después de abastecer',
            style: Theme.of(context).textTheme.bodySmall!),
        SizedBox(height: RamisSpacing.small),
        FormField<int>(
          validator: (value) =>
              value == null ? 'Seleccione el nivel de combustible final' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FuelGaugeSelector(
                value: _nivelFinal,
                onChanged: (val) {
                  field.didChange(val);
                  setState(() => _nivelFinal = val);
                  _emit();
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
    );
  }
}

import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';

/// Widget que imita un medidor de combustible con 5 niveles.
/// Devuelve el valor entero [0, 25, 50, 75, 100].
class FuelGaugeSelector extends StatelessWidget {
  const FuelGaugeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final void Function(int) onChanged;

  static const _labels = ['E', '1/4', '1/2', '3/4', 'F'];
  static const _values = [0, 25, 50, 75, 100];

  Color _colorForValue(BuildContext context, int v) {
    if (v <= 25) return context.ramis.error;
    if (v <= 50) return context.ramis.warning;
    if (v <= 75) return context.ramis.warning;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nivel de Combustible',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: RamisSpacing.small),
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: context.ramis.border),
            borderRadius: RamisRadius.medium,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(RamisSpacing.mediumSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_gas_station,
                        color: value == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : _colorForValue(context, value!),
                        size: 32),
                    Spacer(),
                    Text(
                      value == null ? 'Seleccione' : '$value%',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: value == null
                                ? context.ramis.textSecondary
                                : _colorForValue(context, value!),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: RamisSpacing.small),
                Row(
                  children: List.generate(_values.length, (i) {
                    final isSelected = _values[i] == value;
                    final segColor = _colorForValue(context, _values[i]);
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: i == _values.length - 1
                                ? 0
                                : RamisSpacing.xSmall),
                        child: Semantics(
                          button: true,
                          label: '${_values[i]}% de combustible',
                          selected: isSelected,
                          child: InkWell(
                            onTap: () => onChanged(_values[i]),
                            borderRadius: RamisRadius.small,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? segColor.withAlpha(45)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: RamisRadius.small,
                                border: Border.all(
                                  color: isSelected
                                      ? segColor
                                      : context.ramis.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _labels[i],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: isSelected
                                              ? segColor
                                              : context.ramis.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

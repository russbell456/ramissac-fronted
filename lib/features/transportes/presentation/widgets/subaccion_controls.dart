import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/jornada_transporte.dart';
import '../../providers/jornadas_provider.dart';
import 'odometro_confirm.dart';

class SubaccionControls extends ConsumerWidget {
  const SubaccionControls(
      {super.key, required this.subaccion, required this.onChanged});
  final JornadaTransporte subaccion;
  final Future<void> Function() onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) => RamisCard(
      padding: EdgeInsets.zero,
      color:
          subaccion.estado == 'cancelada' ? context.ramis.surfaceVariant : null,
      child: ListTile(
          title: Text('${subaccion.accionTipo} · ${subaccion.estado}'),
          subtitle: subaccion.estado == 'cancelada'
              ? Text(
                  '${subaccion.motivoCancelacion ?? ""} · Responsable: ${subaccion.canceladoPorId ?? "Sistema"}')
              : null,
          trailing: subaccion.estado == 'en_curso'
              ? Wrap(children: [
                  RamisButton(
                    label: 'Cerrar',
                    onPressed: () => _cerrar(context, ref),
                    variant: RamisButtonVariant.text,
                  ),
                  RamisButton(
                    label: 'Cancelar',
                    onPressed: () => _cancelar(context, ref),
                    variant: RamisButtonVariant.text,
                  ),
                ])
              : null));

  Future<void> _cerrar(BuildContext context, WidgetRef ref) async {
    final grua = subaccion.accionTipo == 'Operar Grúa';
    final valor = TextEditingController();
    final texto = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(grua ? 'Horómetro final' : 'Odómetro actual'),
                content: RamisTextField(
                    controller: valor,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true)),
                actions: [
                  RamisButton(
                    label: 'Volver',
                    onPressed: () => Navigator.pop(ctx),
                    variant: RamisButtonVariant.text,
                  ),
                  RamisButton(
                    label: 'Cerrar actividad',
                    onPressed: () => Navigator.pop(ctx, valor.text),
                    variant: RamisButtonVariant.primary,
                  )
                ]));
    valor.dispose();
    final numero = double.tryParse((texto ?? '').replaceAll(',', '.'));
    if (numero == null || !numero.isFinite || !context.mounted) return;
    try {
      final evidencia = grua
          ? <String, String>{}
          : await confirmarOdometro(
              context, numero - (subaccion.kmInicial ?? numero));
      if (evidencia == null) return;
      await ref.read(transporteRepositoryProvider).cerrarSubaccion(subaccion.id,
          {grua ? 'horometro_final' : 'km_final': numero, ...evidencia});
      await onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final aceptar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('Cancelar actividad'),
                content: Text(
                    'La actividad conservará su historial y quedará marcada como cancelada.'),
                actions: [
                  RamisButton(
                    label: 'Volver',
                    onPressed: () => Navigator.pop(ctx, false),
                    variant: RamisButtonVariant.text,
                  ),
                  RamisButton(
                    label: 'Continuar',
                    onPressed: () => Navigator.pop(ctx, true),
                    variant: RamisButtonVariant.text,
                  )
                ]));
    if (aceptar != true || !context.mounted) return;
    final motivo = TextEditingController();
    final razon = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: Text('Motivo obligatorio'),
                    content: RamisTextField(
                        controller: motivo,
                        onChanged: (_) => update(() {}),
                        decoration: InputDecoration(
                            helperText: 'Mínimo 10 caracteres')),
                    actions: [
                      RamisButton(
                        label: 'Volver',
                        onPressed: () => Navigator.pop(ctx),
                        variant: RamisButtonVariant.text,
                      ),
                      RamisButton(
                        label: 'Confirmar cancelación',
                        onPressed: motivo.text.trim().length < 10
                            ? null
                            : () => Navigator.pop(ctx, motivo.text.trim()),
                        variant: RamisButtonVariant.destructive,
                      )
                    ])));
    motivo.dispose();
    if (razon == null) return;
    try {
      await ref
          .read(transporteRepositoryProvider)
          .cancelarSubaccion(subaccion.id, razon);
      await onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

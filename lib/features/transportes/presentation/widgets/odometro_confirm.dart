import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/jornadas_provider.dart';
import 'observacion_fields.dart';

Future<Map<String, String>?> confirmarOdometro(
    BuildContext context, double distancia) async {
  if (distancia <= 300) return {};
  final motivo = TextEditingController();
  String? foto;
  final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
          builder: (ctx, ref, _) => StatefulBuilder(
              builder: (ctx, update) => AlertDialog(
                    title: Text(distancia > 600
                        ? 'Verificar odómetro'
                        : 'Confirmar distancia'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          'La distancia registrada es ${distancia.toStringAsFixed(1)} km.'),
                      if (distancia > 600) ...[
                        RamisTextField(
                            controller: motivo,
                            onChanged: (_) => update(() {}),
                            decoration: InputDecoration(
                                labelText: 'Motivo (mínimo 15 caracteres)')),
                        RamisButton(
                          label: foto == null
                              ? 'Fotografiar odómetro'
                              : 'Fotografía adjunta',
                          onPressed: () async {
                            final image = await ref
                                .read(elegirFotoProvider)(ImageSource.camera);
                            if (image == null) return;
                            final url = await ref
                                .read(transporteRepositoryProvider)
                                .subirFoto(
                                    await image.readAsBytes(), image.name);
                            if (ctx.mounted) update(() => foto = url);
                          },
                          variant: RamisButtonVariant.text,
                          icon: Icons.camera_alt,
                        ),
                      ],
                    ]),
                    actions: [
                      RamisButton(
                        label: 'Revisar',
                        onPressed: () => Navigator.pop(ctx),
                        variant: RamisButtonVariant.text,
                      ),
                      RamisButton(
                        label: 'Confirmar',
                        onPressed: distancia > 600 &&
                                (foto == null || motivo.text.trim().length < 15)
                            ? null
                            : () => Navigator.pop(ctx, {
                                  if (foto != null)
                                    'odometro_evidencia_url': foto!,
                                  if (distancia > 600)
                                    'odometro_motivo': motivo.text.trim()
                                }),
                        variant: RamisButtonVariant.primary,
                      )
                    ],
                  ))));
  motivo.dispose();
  return resultado;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/widgets/app_ui.dart';
import 'package:sistema_ocs/features/ordenes_compra/models/orden_compra_request.dart';
import 'package:sistema_ocs/features/ordenes_compra/providers/oc_provider.dart';
import 'package:sistema_ocs/data/services/orden_compra_service.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/ordenes_compra/screens/subircomprobantescreen.dart';

class OrdenesListaScreen extends ConsumerWidget {
  final bool embedded;
  const OrdenesListaScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordenesLocales = ref.watch(listaOrdenesLocalesProvider);

    final body = ordenesLocales.isEmpty
        ? const Center(
            child: AppEmptyState(
                icon: LucideIcons.receipt,
                title: 'Todavía no hay órdenes de compra'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordenesLocales.length,
            itemBuilder: (context, index) {
              final orden = ordenesLocales[index];
              final esEnviado = orden.estado == 'enviado';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(orden.proveedor),
                  subtitle: Text("Total: S/ ${orden.total.toStringAsFixed(2)}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BOTÓN ELIMINAR
                      IconButton(
                        tooltip: 'Quitar orden local',
                        icon: const Icon(LucideIcons.trash2,
                            color: AppTheme.error, size: 20),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                      title: const Text('¿Quitar orden local?'),
                                      content: const Text(
                                          'Se quitará de este dispositivo, no del servidor.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text('Cancelar')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: const Text('Quitar')),
                                      ]));
                          if (confirmed == true) {
                            ref
                                .read(listaOrdenesLocalesProvider.notifier)
                                .eliminarOrden(orden.idLocal!);
                          }
                        },
                      ),
                      // BOTÓN MANDAR (PALOMITA)
                      IconButton(
                        tooltip: esEnviado ? 'Orden enviada' : 'Enviar orden',
                        icon: Icon(
                            esEnviado
                                ? LucideIcons.circleCheck
                                : LucideIcons.send,
                            color: esEnviado
                                ? AppTheme.secondaryDark
                                : AppTheme.primary),
                        onPressed: esEnviado
                            ? null
                            : () => _procesoEnvioCompleto(context, ref, orden),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
    return embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Órdenes de compra')), body: body);
  }

  Future<void> _procesoEnvioCompleto(
      BuildContext context, WidgetRef ref, OrdenCompraRequest orden) async {
    final service = OrdenCompraService();

    try {
      // 1. Enviar JSON al servidor
      final int ordenId = await service.crearOrden(orden);

      // 2. Abrir Formulario de Fotos (Paso Obligatorio)
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SubirComprobantesScreen(ordenId: ordenId, ordenLocal: orden),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

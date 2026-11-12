// lib/features/requerimientos/rqs_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/rq_model.dart';
import 'package:sistema_ocs/features/requerimientos/rq_providers.dart';
import 'package:sistema_ocs/features/requerimientos/rq_detail_screen.dart';

class RQsListScreen extends ConsumerWidget {
  const RQsListScreen({super.key});

  void _handleDelete(
      BuildContext context, WidgetRef ref, int rqId, String nroRq) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        // Cambiado a Dialog estándar para mejor control de tamaño
        backgroundColor: Colors.transparent,
        child: AppCard(
          backgroundColor: AppTheme.background,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Confirmar Eliminación',
                  style: AppTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  '¿Está seguro de eliminar el Requerimiento $nroRq? Esta acción es irreversible.',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingM),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.borderRadiusMedium,
                          ),
                          side: BorderSide(color: AppTheme.border),
                        ),
                        child: Text(
                          'Cancelar',
                          style: AppTheme.labelLarge
                              .copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: AppButton(
                        text: 'Eliminar',
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          try {
                            await ref
                                .read(rqListNotifierProvider.notifier)
                                .deleteRq(rqId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('RQ $nroRq eliminado con éxito.'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppTheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        backgroundColor: AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rqsAsyncValue = ref.watch(rqListNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background, // Usamos color sólido o gradiente del tema
      ),
      child: Column(
        children: [
          // Header con búsqueda mejorado para evitar overflow
          AppCard(
            backgroundColor: AppTheme.background,
            padding: EdgeInsets.zero,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        style: AppTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Buscar RQ...',
                          hintStyle: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textDisabled),
                          filled: true,
                          fillColor: AppTheme.surface,
                          prefixIcon: const Icon(Icons.search,
                              color: AppTheme.primary, size: 20),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 42),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: AppTheme.borderRadiusMedium,
                            borderSide:
                                BorderSide(color: AppTheme.border.lighten10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppTheme.borderRadiusMedium,
                            borderSide:
                                BorderSide(color: AppTheme.border.lighten10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppTheme.borderRadiusMedium,
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 1.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: AppTheme.primary,
                      borderRadius: AppTheme.borderRadiusMedium,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.refresh,
                            color: AppTheme.background, size: 22),
                        onPressed: () => ref.invalidate(rqListNotifierProvider),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de RQs
          Expanded(
            child: rqsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.primary, size: 42),
                      const SizedBox(height: 12),
                      const Text(
                        'No se pudieron cargar los requerimientos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.primary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(rqListNotifierProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Volver a intentar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondary,
                          side: const BorderSide(color: AppTheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (rqs) {
                if (rqs.isEmpty) {
                  return const Center(
                      child: Text('No hay requerimientos disponibles'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
                  itemCount: rqs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RQCard(
                        rq: rqs[index],
                        onDelete: () => _handleDelete(
                            context, ref, rqs[index].id, rqs[index].nroRq),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RQCard extends StatelessWidget {
  final RQResponse rq;
  final VoidCallback onDelete;

  const RQCard({super.key, required this.rq, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(rq.estado);
    final progressColor = AppTheme.getProgressColor(rq.progresoCompra);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Nro y Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rq.nroRq,
                        style: AppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Emisión: ${rq.fechaEmision.toLocal().toString().split(' ')[0]}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textDisabled),
                      ),
                    ],
                  ),
                ),
                AppBadge(text: rq.estado, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),

            // Info items con Wrap o Expanded para evitar desbordamientos laterales
            Row(
              children: [
                Expanded(
                  child: AppInfoItem(
                    icon: Icons.person_outline,
                    label: 'Solicitante',
                    value: rq.solicitante,
                    iconColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: AppInfoItem(
                    icon: Icons.work_outline,
                    label: 'Proyecto',
                    value: rq.proyecto,
                    iconColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),

            // Progreso
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progreso de Compra', style: AppTheme.labelMedium),
                      Text('${rq.progresoCompra.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: progressColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppProgressBar(progress: rq.progresoCompra, height: 6),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      textStyle: AppTheme.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadiusMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => RQDetailScreen(rq: rq)),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text('Detalles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textOnPrimary,
                      elevation: 1,
                      textStyle: AppTheme.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadiusMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_status.dart';

class DashboardHomeView extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onNewRequest;
  final String rol;
  const DashboardHomeView(
      {super.key, this.onNavigate, this.onNewRequest, this.rol = ''});
  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  late final Future<String?> _user =
      const SessionStorage().read(key: 'user_data');

  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<String?>(
                  future: _user,
                  builder: (_, snapshot) {
                    final data = snapshot.data;
                    final user = data == null
                        ? <String, dynamic>{}
                        : jsonDecode(data) as Map<String, dynamic>;
                    final name = user['nombre']?.toString().trim() ?? '';
                    return Text(name.isEmpty ? 'Operaciones' : 'Hola, $name',
                        style: AppTheme.headlineMedium);
                  }),
              const SizedBox(height: 4),
              const Text('Corporación Ramis SAC', style: AppTheme.bodySmall),
              if (!esCompras(widget.rol) || esLogistica(widget.rol)) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                    onPressed: widget.onNewRequest,
                    icon: const Icon(LucideIcons.plus, size: 20),
                    label: const Text('Nuevo requerimiento')),
              ],
              const SizedBox(height: 28),
              const Text('Mi trabajo', style: AppTheme.titleSmall),
              const SizedBox(height: 8),
              _access(LucideIcons.fileText, 'Requerimientos', 1),
              if (esLogistica(widget.rol))
                _access(LucideIcons.clipboardCheck, 'Revisión logística', 5),
              if (esCompras(widget.rol)) ...[
                _access(LucideIcons.shoppingCart, 'Compras', 2),
                _access(LucideIcons.receipt, 'Órdenes de compra', 4),
              ],
              const SizedBox(height: 24),
              const Text('Almacén', style: AppTheme.titleSmall),
              const SizedBox(height: 8),
              _access(LucideIcons.package, 'Catálogo y stock', 3),
            ],
          )));

  Widget _access(IconData icon, String title, int index) => Material(
        color: AppTheme.surface,
        child: InkWell(
          onTap: widget.onNavigate == null
              ? null
              : () => widget.onNavigate!(index),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.divider))),
            child: Row(children: [
              Icon(icon, size: 21, color: AppTheme.primary),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: AppTheme.titleSmall)),
              const Icon(LucideIcons.chevronRight,
                  size: 18, color: AppTheme.textDisabled),
            ]),
          ),
        ),
      );
}

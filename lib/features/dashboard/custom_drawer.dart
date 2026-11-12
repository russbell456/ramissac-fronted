import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/almacen/almacen_main_screen.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_status.dart';

class CustomDrawer extends ConsumerWidget {
  final ValueChanged<int> onMenuItemTap;
  final int selectedIndex;
  final String rol;
  const CustomDrawer(
      {super.key,
      required this.onMenuItemTap,
      this.selectedIndex = 0,
      this.rol = ''});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
          child: SafeArea(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Image.asset('assets/images/ramissapp_icon.png',
                            width: 36, height: 36, fit: BoxFit.contain),
                        const SizedBox(width: 12),
                        const Text('RamissApp', style: AppTheme.titleLarge),
                      ]),
                      const SizedBox(height: 16),
                      FutureBuilder<String?>(
                          future: const SessionStorage().read(key: 'user_data'),
                          builder: (_, snapshot) {
                            final user = snapshot.data == null
                                ? <String, dynamic>{}
                                : jsonDecode(snapshot.data!)
                                    as Map<String, dynamic>;
                            return Text(
                                user['nombre']?.toString() ?? 'Operaciones',
                                style: AppTheme.bodySmall);
                          }),
                    ])),
            const Divider(height: 1),
            Expanded(
                child: ListView(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    children: [
                  _tile(context, LucideIcons.house, 'Inicio', 0),
                  _tile(context, LucideIcons.fileText, 'Requerimientos', 1),
                  _tile(context, LucideIcons.package, 'Catálogo y stock', 3),
                  if (esLogistica(rol))
                    _tile(context, LucideIcons.clipboardCheck,
                        'Revisión logística', 5),
                  if (esCompras(rol)) ...[
                    const Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text('Compras', style: AppTheme.labelSmall)),
                    _tile(context, LucideIcons.shoppingCart,
                        'Artículos por comprar', 2),
                    _tile(context, LucideIcons.receipt, 'Órdenes de compra', 4),
                    _tile(context, LucideIcons.fileUp,
                        'Importar requerimiento PDF', 7),
                  ],
                  const Divider(),
                  ListTile(
                      leading: const Icon(LucideIcons.wrench),
                      title: const Text('Préstamos y devoluciones'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AlmacenMainScreen()));
                      }),
                ])),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(LucideIcons.logOut, size: 20),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authNotifierProvider.notifier).logout();
                }),
          ])));
  Widget _tile(BuildContext context, IconData icon, String title, int index) =>
      ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          selected: selectedIndex == index,
          selectedTileColor: AppTheme.primaryLight,
          selectedColor: AppTheme.primary,
          leading: Icon(icon, size: 22),
          title: Text(title),
          onTap: () {
            Navigator.pop(context);
            onMenuItemTap(index);
          });
}

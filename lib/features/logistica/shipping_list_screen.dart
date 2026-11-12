import 'package:flutter/material.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/features/rq_urgente/rq_review_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/services/urgent_rq_service.dart';

class ShippingListScreen extends StatefulWidget {
  const ShippingListScreen({super.key});
  @override
  State<ShippingListScreen> createState() => _ShippingListScreenState();
}
class _ShippingListScreenState extends State<ShippingListScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = UrgentRQService().listar(); }
  Future<void> _refresh() async { setState(() => _future = UrgentRQService().listar()); await _future; }
  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960),
    child: Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Row(children: [const Expanded(child: Text('Requerimientos enviados', style: AppTheme.titleLarge)),
        IconButton(onPressed: _refresh, tooltip: 'Actualizar solicitudes', icon: const Icon(Icons.refresh))])),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(UrgentRQService.mensajeError(snapshot.error!)), TextButton(onPressed: _refresh, child: const Text('Reintentar')),
        ]));
        final rows = snapshot.data!.where((r) => r['estado'] == 'ENVIADO').toList();
        return RefreshIndicator(onRefresh: _refresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20), children: [
          if (rows.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('No hay solicitudes enviadas para revisar'))),
          ...rows.map((r) => Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.border)),
            child: ListTile(title: Text(r['nombre_proyecto'] as String, style: AppTheme.titleSmall), subtitle: Text('${r['numero']} · ${(r['items'] as List).length} productos', style: AppTheme.bodySmall),
              trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RqReviewScreen(servidorId: r['id'] as int)))))),
        ]));
      })),
    ])));
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/rq_model.dart';
import 'package:sistema_ocs/features/ordenes_compra/screens/seleccionar_items_oc_screen.dart';

class RQDetailScreen extends StatelessWidget {
  final RQResponse rq;

  const RQDetailScreen({super.key, required this.rq});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.surface,
          elevation: 0,
          title: Text('RQ ${rq.nroRq}'),
          bottom: const TabBar(
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 4,
            labelColor: AppTheme.surface,
            unselectedLabelColor: AppTheme.surface,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Ítems'),
              Tab(icon: Icon(Icons.history_outlined), text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_items(context), _historial()],
        ),
      ),
    );
  }

  Widget _items(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _estado(),
        const SizedBox(height: 14),
        _datosGenerales(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.list_alt_outlined, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ítems solicitados (${rq.items.length})',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (rq.items.isEmpty)
          const _MensajeVacio(texto: 'Este requerimiento no contiene ítems.')
        else
          ...rq.items.asMap().entries.map(
                (entry) => _ItemCard(numero: entry.key + 1, item: entry.value),
              ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SeleccionarItemsOCScreen(rq: rq)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.surface,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: const Text('Agregar ítems a orden de compra'),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _estado() {
    final progreso = (rq.progresoCompra / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.primary),
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADO DEL REQUERIMIENTO',
            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  rq.estado.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${rq.progresoCompra.toStringAsFixed(0)}%',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.primary),
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: ClipRRect(
              borderRadius: AppTheme.borderRadiusSmall,
              child: LinearProgressIndicator(
                minHeight: 9,
                value: progreso,
                backgroundColor: AppTheme.surface,
                valueColor: const AlwaysStoppedAnimation(AppTheme.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datosGenerales() {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(rq.fechaEmision);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.primary),
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos generales',
            style: TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Dato(icono: Icons.work_outline, titulo: 'Proyecto', valor: rq.proyecto),
          const Divider(color: AppTheme.primary),
          _Dato(icono: Icons.person_outline, titulo: 'Solicitante', valor: rq.solicitante),
          const Divider(color: AppTheme.primary),
          _Dato(icono: Icons.calendar_today_outlined, titulo: 'Fecha de emisión', valor: fecha),
          const Divider(color: AppTheme.primary),
          _Dato(
            icono: Icons.shopping_cart_outlined,
            titulo: 'Estado de compra',
            valor: rq.estadoCompra.replaceAll('_', ' ').toUpperCase(),
            valorVerde: true,
          ),
        ],
      ),
    );
  }

  Widget _historial() {
    return const _MensajeVacio(
      icono: Icons.history_outlined,
      texto: 'El historial estará disponible próximamente.',
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final bool valorVerde;

  const _Dato({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.valorVerde = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppTheme.primary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: TextStyle(
                    color: valorVerde ? AppTheme.secondary : AppTheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final int numero;
  final dynamic item;

  const _ItemCard({required this.numero, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.primary),
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$numero.',
              style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('Código: ${item.codigo}', style: const TextStyle(color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.cantidad.toStringAsFixed(2),
                style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(item.unidad, style: const TextStyle(color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MensajeVacio extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _MensajeVacio({this.icono = Icons.inventory_2_outlined, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: AppTheme.secondary, size: 52),
            const SizedBox(height: 14),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.primary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

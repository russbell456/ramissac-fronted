import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/rq_item_model.dart';
import 'package:sistema_ocs/data/models/rq_model.dart';
import 'package:sistema_ocs/features/ordenes_compra/models/oc_item_model.dart';
import 'package:sistema_ocs/features/ordenes_compra/providers/oc_provider.dart';

class SeleccionarItemsOCScreen extends ConsumerStatefulWidget {
  final RQResponse rq;

  const SeleccionarItemsOCScreen({super.key, required this.rq});

  @override
  ConsumerState<SeleccionarItemsOCScreen> createState() => _SeleccionarItemsOCScreenState();
}

class _SeleccionarItemsOCScreenState extends ConsumerState<SeleccionarItemsOCScreen> {
  final Map<int, bool> seleccionados = {};
  final Map<int, TextEditingController> cantidadCtrl = {};
  final Map<int, TextEditingController> costoCtrl = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.rq.items) {
      seleccionados[item.id] = false;
      cantidadCtrl[item.id] = TextEditingController();
      costoCtrl[item.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in [...cantidadCtrl.values, ...costoCtrl.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _cantidadSeleccionada => seleccionados.values.where((valor) => valor).length;

  void _seleccionarTodos() {
    final seleccionar = _cantidadSeleccionada != widget.rq.items.length;
    setState(() {
      for (final item in widget.rq.items) {
        seleccionados[item.id] = seleccionar;
      }
    });
  }

  void _guardarItems() {
    if (_cantidadSeleccionada == 0) {
      _mensaje('Seleccione al menos un ítem');
      return;
    }

    final nuevosItems = <OCItem>[];
    for (final item in widget.rq.items) {
      if (seleccionados[item.id] != true) continue;
      final cantidad = _numero(cantidadCtrl[item.id]!.text);
      final costo = _numero(costoCtrl[item.id]!.text);
      if (cantidad <= 0 || cantidad > item.cantidad || costo <= 0) {
        _mensaje('Revise la cantidad y el costo de ${item.codigo}');
        return;
      }
      nuevosItems.add(OCItem(
        rqId: widget.rq.id,
        rqItemId: item.id,
        descripcion: item.descripcion,
        cantidadSolicitada: item.cantidad,
        cantidadComprada: cantidad,
        costoUnitario: costo,
      ));
    }

    final notifier = ref.read(ocProvider.notifier);
    for (final item in nuevosItems) {
      notifier.addItem(item);
    }
    _mensaje('${nuevosItems.length} ítem(s) agregado(s)', correcto: true);
    Navigator.pop(context);
  }

  double _numero(String valor) => double.tryParse(valor.trim().replaceAll(',', '.')) ?? 0;

  void _mensaje(String texto, {bool correcto = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: correcto ? AppTheme.secondary : AppTheme.primary,
    ));
  }

  Widget _resumen() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RQ ${widget.rq.nroRq}',
            style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text('Seleccione los productos que pasarán a la orden de compra.',
              style: TextStyle(color: AppTheme.primary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_cantidadSeleccionada de ${widget.rq.items.length} seleccionados',
                  style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w700),
                ),
              ),
              OutlinedButton(
                onPressed: widget.rq.items.isEmpty ? null : _seleccionarTodos,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
                child: Text(
                  _cantidadSeleccionada == widget.rq.items.length && widget.rq.items.isNotEmpty
                      ? 'Quitar todos'
                      : 'Seleccionar todos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 2, color: AppTheme.secondary),
        ],
      ),
    );
  }

  InputDecoration _decoracionCampo(String etiqueta, {String? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: const TextStyle(color: AppTheme.primary),
      suffixText: sufijo,
      suffixStyle: const TextStyle(color: AppTheme.primary),
      filled: true,
      fillColor: AppTheme.surface,
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.secondary, width: 2)),
      border: const OutlineInputBorder(),
    );
  }

  Widget _item(RQItemResponse item, int index) {
    final seleccionado = seleccionados[item.id] ?? false;
    final cantidad = _numero(cantidadCtrl[item.id]!.text);
    final costo = _numero(costoCtrl[item.id]!.text);
    final total = cantidad * costo;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: seleccionado ? AppTheme.secondary : AppTheme.primary,
          width: seleccionado ? 2 : 1,
        ),
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.primary),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Text('${index + 1}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.codigo,
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(item.descripcion, style: const TextStyle(color: AppTheme.primary)),
                    const SizedBox(height: 5),
                    Text('Solicitado: ${item.cantidad.toStringAsFixed(2)} ${item.unidad}',
                        style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Checkbox(
                value: seleccionado,
                activeColor: AppTheme.secondary,
                checkColor: AppTheme.surface,
                side: const BorderSide(color: AppTheme.primary),
                onChanged: (valor) => setState(() => seleccionados[item.id] = valor ?? false),
              ),
            ],
          ),
          if (seleccionado) ...[
            const SizedBox(height: 14),
            TextField(
              controller: cantidadCtrl[item.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.primary),
              onChanged: (_) => setState(() {}),
              decoration: _decoracionCampo('Cantidad a comprar', sufijo: 'Máx. ${item.cantidad.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costoCtrl[item.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.primary),
              onChanged: (_) => setState(() {}),
              decoration: _decoracionCampo('Costo unitario', sufijo: 'S/'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Total del ítem',
                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.secondary, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Agregar a orden de compra'),
      ),
      body: Column(
        children: [
          _resumen(),
          Expanded(
            child: widget.rq.items.isEmpty
                ? const Center(
                    child: Text('No hay ítems disponibles', style: TextStyle(color: AppTheme.primary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: widget.rq.items.length,
                    itemBuilder: (_, index) => _item(widget.rq.items[index], index),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _guardarItems,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: AppTheme.surface,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: Text('Agregar $_cantidadSeleccionada ítem(s)'),
          ),
        ),
      ),
    );
  }
}

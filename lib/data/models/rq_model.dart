// lib/data/models/rq_model.dart

import 'rq_item_model.dart';

class RQResponse {
  final int id;
  final String nroRq;
  final String proyecto;
  final String solicitante;
  final DateTime fechaEmision;
  final String estado; // pendiente, aprobado, rechazado
  final String estadoCompra; // sin_compras, parcial, completo
  final double progresoCompra; // 0.0 a 100.0
  final List<RQItemResponse> items;

  RQResponse({
    required this.id,
    required this.nroRq,
    required this.proyecto,
    required this.solicitante,
    required this.fechaEmision,
    required this.estado,
    required this.estadoCompra,
    required this.progresoCompra,
    required this.items,
  });

  factory RQResponse.fromJson(Map<String, dynamic> json) {
    return RQResponse(
      id: json['id'] as int,
      nroRq: json['numero']?.toString() ?? '',
      proyecto: json['nombre_proyecto']?.toString() ?? '',
      solicitante: json['solicitante_nombre']?.toString() ?? '',
      fechaEmision: DateTime.tryParse(json['fecha_requerimiento']?.toString() ?? '') ?? DateTime.now(),
      estado: json['estado']?.toString() ?? 'BORRADOR',
      // Estos campos todavía no forman parte del módulo RQ Campo del backend.
      estadoCompra: json['estado_compra'] as String? ?? 'sin_compras',
      progresoCompra: (json['progreso_compra'] as num?)?.toDouble() ?? 0,
      // Mapear la lista de ítems
      items: (json['items'] as List<dynamic>?)
          ?.map((i) => RQItemResponse.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

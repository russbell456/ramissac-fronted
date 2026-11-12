// lib/data/models/rq_item_model.dart

// 💡 Nota: Crearemos una clase vacía para OrdenParcialResponse por ahora.
class OrdenParcialResponse {}

class RQItemResponse {
  final int id;
  final String codigo;
  final String descripcion;
  final double cantidad;
  final String unidad; // ✅ Nuevo campo
  final List<OrdenParcialResponse> ordenesParciales;
   // ✅ Nuevo campo (vacío por ahora)
     // 👇 SOLO PARA OC (FRONT)
  bool seleccionado = false;
  int cantidadComprar = 0;
  double costoUnitario = 0.0;

  RQItemResponse({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.cantidad,
    required this.unidad,
    required this.ordenesParciales,
  });

  factory RQItemResponse.fromJson(Map<String, dynamic> json) {
    final cantidadRaw = json['cantidad'];
    final cantidad = cantidadRaw is num
        ? cantidadRaw.toDouble()
        : double.tryParse(cantidadRaw?.toString() ?? '') ?? 0.0;
    return RQItemResponse(
      id: json['id'] as int,
      codigo: json['codigo_producto'] as String? ?? 'S/C',
      descripcion: json['descripcion'] as String? ??
          json['nombre_producto'] as String? ??
          'Sin descripción',
      cantidad: cantidad,
      unidad: json['unidad_medida']?.toString() ?? '',
      // Asumimos que "ordenes_parciales" es una lista y la dejamos vacía por ahora
      ordenesParciales: (json['ordenes_parciales'] as List<dynamic>?)
          ?.map((i) => OrdenParcialResponse()) // Simulación
          .toList() ?? [],
    );
  }
}

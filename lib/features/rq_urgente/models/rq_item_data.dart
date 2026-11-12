String categoriaProducto(Map<String, dynamic> producto) {
  final valor =
      '${producto['categoria'] ?? ''} ${producto['tipo'] ?? ''}'.toLowerCase();
  if (valor.contains('herramienta')) return 'Herramienta';
  if (valor.contains('equipo')) return 'Equipo';
  final tipo =
      RegExp(r'^Tipo:\s*(material|equipo|herramienta)', caseSensitive: false)
          .firstMatch(producto['descripcion']?.toString() ?? '');
  if (tipo != null) return categoriaProducto({'categoria': tipo.group(1)});
  return 'Material';
}

String detalleProducto(Map<String, dynamic> producto) {
  if (producto['detalle'] != null) return producto['detalle'].toString();
  return [
    if ((producto['medidas'] ?? '').toString().trim().isNotEmpty)
      'Medidas: ${producto['medidas']}',
    if ((producto['especificaciones'] ?? '').toString().trim().isNotEmpty)
      'Especificaciones: ${producto['especificaciones']}',
    (producto['descripcion'] ?? '').toString().replaceFirst(
        RegExp(r'^Tipo:\s*(?:material|equipo|herramienta|insumo)\s*\n?',
            caseSensitive: false),
        ''),
    if ((producto['observacion'] ?? '').toString().trim().isNotEmpty)
      'Observación: ${producto['observacion']}',
    if ((producto['fecha_vencimiento'] ?? '').toString().trim().isNotEmpty)
      'Vencimiento de referencia: ${producto['fecha_vencimiento']}',
  ].where((v) => v.trim().isNotEmpty).join('\n').trim();
}

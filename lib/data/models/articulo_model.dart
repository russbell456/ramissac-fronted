import 'articulo_imagen_model.dart';

class ArticuloModel {
  final int id;
  final String nombre;
  final String? unidadMedida;
  final String tipo;
  final int stockActual;
  final int stockTotal;
  final String? codigoExcel;
  final String? serie;
  final String? descripcion;
  final String? marca;
  final String? modelo;
  final String? categoria;
  final String? medidas;
  final String? especificaciones;
  final String? observacion;
  final String? fichaTecnicaNombre;
  final bool activo;
  final int enPrestamo;
  final List<ArticuloImagenModel> imagenes;
  final int? creadoPor;
  final int? actualizadoPor;
  final String? fechaCreacion;
  final String? fechaActualizacion;

  ArticuloModel({
    required this.id,
    required this.nombre,
    this.unidadMedida,
    required this.tipo,
    required this.stockActual,
    this.stockTotal = 0,
    this.codigoExcel,
    this.serie,
    this.descripcion,
    this.marca,
    this.modelo,
    this.categoria,
    this.medidas,
    this.especificaciones,
    this.observacion,
    this.fichaTecnicaNombre,
    this.activo = true,
    this.enPrestamo = 0,
    this.imagenes = const [],
    this.creadoPor,
    this.actualizadoPor,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  bool get esEquipo => tipo.toLowerCase() == 'equipo';
  bool get esHerramienta => tipo.toLowerCase() == 'herramienta';
  String get tipoLabel => esEquipo
      ? 'Equipo'
      : esHerramienta
          ? 'Herramienta'
          : 'Consumible';

  factory ArticuloModel.fromJson(Map<String, dynamic> json) {
    return ArticuloModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? '',
      unidadMedida: json['unidad_medida'] as String?,
      tipo: json['tipo'] as String? ?? '',
      stockActual: (json['stock_actual'] as num?)?.toInt() ?? 0,
      stockTotal: (json['stock_total'] as num?)?.toInt() ?? 0,
      codigoExcel: json['codigo_excel'] as String?,
      serie: json['serie'] as String?,
      descripcion: json['descripcion'] as String?,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      categoria: json['categoria'] as String?,
      medidas: json['medidas'] as String?,
      especificaciones: json['especificaciones'] as String?,
      observacion: json['observacion'] as String?,
      fichaTecnicaNombre: json['ficha_tecnica_nombre'] as String?,
      activo: json['activo'] as bool? ?? true,
      enPrestamo: (json['en_prestamo'] as num?)?.toInt() ?? 0,
      imagenes: (json['imagenes'] as List?)
              ?.map((e) =>
                  ArticuloImagenModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      creadoPor: (json['creado_por'] as num?)?.toInt(),
      actualizadoPor: (json['actualizado_por'] as num?)?.toInt(),
      fechaCreacion: json['fecha_creacion'] as String?,
      fechaActualizacion: json['fecha_actualizacion'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nombre': nombre,
      if (unidadMedida != null) 'unidad_medida': unidadMedida,
      'tipo': tipo,
      if (codigoExcel != null && codigoExcel!.isNotEmpty)
        'codigo_excel': codigoExcel,
      if (serie != null && serie!.isNotEmpty) 'serie': serie,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nombre': nombre,
      if (unidadMedida != null) 'unidad_medida': unidadMedida,
      'tipo': tipo,
      if (codigoExcel != null && codigoExcel!.isNotEmpty)
        'codigo_excel': codigoExcel,
      if (serie != null && serie!.isNotEmpty) 'serie': serie,
    };
  }
}

class RQLocal {
  int? id;
  int? obraId;
  String? obraCodigo;
  String? obraDescripcion;
  int? servidorId;
  String? numero;
  String estadoServidor;
  String servicio;
  String productosJson;
  String fecha;
  int enviado;

  RQLocal({
    this.id,
    this.obraId,
    this.obraCodigo,
    this.obraDescripcion,
    this.servidorId,
    this.numero,
    this.estadoServidor = 'BORRADOR',
    required this.servicio,
    required this.productosJson,
    required this.fecha,
    this.enviado = 0,
  });

  bool get editable => enviado == 0 && estadoServidor == 'BORRADOR';
  bool get tieneObra =>
      obraId != null || RegExp(r'^\d{3}-\d{4}$').hasMatch(obraCodigo ?? '');

  Map<String, dynamic> toMap() => {
        'id': id,
        'obra_id': obraId,
        'obra_codigo': obraCodigo,
        'obra_descripcion': obraDescripcion,
        'servidor_id': servidorId,
        'numero': numero,
        'estado_servidor': estadoServidor,
        'servicio': servicio,
        'productos': productosJson,
        'fecha': fecha,
        'enviado': enviado,
      };

  factory RQLocal.fromMap(Map<String, dynamic> map) => RQLocal(
        id: map['id'] as int?,
        obraId: map['obra_id'] as int?,
        obraCodigo: map['obra_codigo'] as String?,
        obraDescripcion: map['obra_descripcion'] as String?,
        servidorId: map['servidor_id'] as int?,
        numero: map['numero'] as String?,
        estadoServidor: map['estado_servidor'] as String? ?? 'BORRADOR',
        servicio: map['servicio'] as String,
        productosJson: map['productos'] as String,
        fecha: map['fecha'] as String,
        enviado: map['enviado'] as int,
      );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_local_model.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_item_data.dart';

class UrgentRQService {
  final Dio _dio;
  UrgentRQService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 45),
            ));

  Future<Options> _authOptions({ResponseType? responseType}) async {
    final token = await const SessionStorage().read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      throw Exception('Inicie sesión nuevamente');
    }
    return Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: responseType);
  }

  Future<List<Map<String, dynamic>>> buscarProductos(String query) async {
    final response =
        await _dio.get('/articulo/buscar', queryParameters: {'q': query});
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> obrasActivas() async {
    final response = await _dio.get('/almacen/obra/');
    return (response.data as List)
        .cast<Map<String, dynamic>>()
        .where((obra) => obra['estado']?.toString().toLowerCase() == 'activo')
        .toList()
      ..sort(
          (a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));
  }

  static Map<String, dynamic> datosRequerimiento(RQLocal rq) {
    if (!rq.tieneObra) {
      throw StateError('Ingrese un código de obra válido antes de continuar');
    }
    final productos =
        (jsonDecode(rq.productosJson) as List).cast<Map<String, dynamic>>();
    return {
      if (rq.obraId != null) 'obra_id': rq.obraId,
      if ((rq.obraCodigo ?? '').isNotEmpty)
        'obra_codigo': rq.obraCodigo!.trim(),
      'obra_descripcion': rq.obraDescripcion?.trim(),
      'items': productos.map((producto) {
        final catalogado = producto['articulo_id'] != null;
        final adjuntos = (producto['adjuntos'] as List? ?? []).map((raw) {
          final a = raw as Map<String, dynamic>;
          final extension = a['extension']?.toString().toLowerCase();
          return {
            'nombre': a['nombre'],
            'tipo_mime': a['tipo_mime'] ??
                (extension == 'pdf'
                    ? 'application/pdf'
                    : extension == 'png'
                        ? 'image/png'
                        : 'image/jpeg'),
            'contenido_base64': a['contenido_base64'] ?? a['base64'],
          };
        }).toList();
        return {
          'tipo': catalogado ? 'CATALOGADO' : 'NO_CATALOGADO',
          if (catalogado) 'articulo_id': producto['articulo_id'],
          if (!catalogado) 'nombre_producto': producto['nombre'],
          if (!catalogado) 'unidad_medida': producto['unidad'],
          'cantidad': producto['cantidad'],
          'descripcion':
              'Tipo: ${categoriaProducto(producto)}\n${detalleProducto(producto)}'
                  .trim(),
          'fecha_requerida': producto['fecha_requerida'],
          // Compatibilidad con borradores anteriores que guardaban una sola foto.
          if (adjuntos.isEmpty) 'foto_base64': producto['foto_base64'],
          'adjuntos': adjuntos,
        };
      }).toList(),
    };
  }

  void _actualizarEstado(RQLocal rq, Map<String, dynamic> data) {
    rq.servidorId = data['id'] as int;
    rq.numero = data['numero'] as String;
    rq.estadoServidor = (data['estado_gestion'] ?? data['estado']) as String;
    rq.enviado = data['estado'] == 'ENVIADO' ? 1 : 0;
    if (data['obra_id'] != null) rq.obraId = data['obra_id'] as int;
    if (data['obra_codigo'] != null) {
      rq.obraCodigo = data['obra_codigo'] as String;
    }
    if (data['obra_descripcion'] != null) {
      rq.obraDescripcion = data['obra_descripcion'] as String;
    }
    if (data['nombre_proyecto'] != null) {
      rq.servicio = data['nombre_proyecto'] as String;
    }
  }

  Future<Map<String, dynamic>> obtener(int id) async {
    final response =
        await _dio.get('/rq-campo/$id', options: await _authOptions());
    return response.data as Map<String, dynamic>;
  }

  Future<void> guardarEnServidor(RQLocal rq) async {
    final options = await _authOptions();
    if (rq.servidorId != null) {
      final actual = await obtener(rq.servidorId!);
      _actualizarEstado(rq, actual);
      if (!rq.editable) return;
    }
    final response = rq.servidorId == null
        ? await _dio.post('/rq-campo',
            options: options, data: datosRequerimiento(rq))
        : await _dio.put('/rq-campo/${rq.servidorId}',
            options: options, data: datosRequerimiento(rq));
    _actualizarEstado(rq, response.data as Map<String, dynamic>);
  }

  Future<void> enviar(
      RQLocal rq, Uint8List? firma, Future<void> Function() persistir) async {
    await guardarEnServidor(rq);
    await persistir(); // Conservar ID antes del correo permite reintentar sin duplicar.
    if (rq.enviado == 1) return;
    try {
      final options = await _authOptions();
      final response = rq.estadoServidor == 'FIRMADO'
          ? await _dio.post('/rq-campo/${rq.servidorId}/reenviar',
              options: options, data: {})
          : await _dio.post('/rq-campo/${rq.servidorId}/firmar-y-enviar',
              options: options,
              data: {
                  'firma_base64':
                      'data:image/png;base64,${base64Encode(firma!)}'
                });
      _actualizarEstado(rq, response.data as Map<String, dynamic>);
      await persistir();
    } catch (_) {
      try {
        _actualizarEstado(rq, await obtener(rq.servidorId!));
        await persistir();
        if (rq.enviado == 1) return;
      } catch (_) {
        /* Se conserva el ID para recuperar el estado al reintentar. */
      }
      rethrow;
    }
  }

  Future<Uint8List> pdf(int id) async {
    final response = await _dio.get<List<int>>('/rq-campo/$id/pdf',
        options: await _authOptions(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data!);
  }

  Future<List<Map<String, dynamic>>> listar() async {
    final response = await _dio.get('/rq-campo', options: await _authOptions());
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> stock(int id) async {
    final response =
        await _dio.get('/rq-campo/$id/stock', options: await _authOptions());
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> gestionarItem(int rqId, int itemId, String estado, String? nota,
      {String? detalle, List<Map<String, dynamic>>? adjuntos}) async {
    await _dio.patch('/rq-campo/$rqId/items/$itemId/gestion',
        options: await _authOptions(),
        data: {
          'estado': estado,
          'nota': nota,
          if (detalle != null) 'detalle': detalle,
          if (adjuntos != null) 'adjuntos': adjuntos
        });
  }

  static String mensajeError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
      if (data is Map && data['detail'] is List) {
        return 'Revise los datos y adjuntos del requerimiento';
      }
      return 'No se pudo conectar con el servidor. Intente nuevamente.';
    }
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }
}

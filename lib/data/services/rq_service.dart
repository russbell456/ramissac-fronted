// lib/data/services/rq_service.dart

import 'package:dio/dio.dart';
import 'package:sistema_ocs/data/models/rq_model.dart'; // Crearemos este modelo

class RqService {
  final Dio _dio;

  RqService(this._dio);

  Future<List<RQResponse>> listRqs() async {
    try {
      final response = await _dio.get('/rq-campo');
      
      if (response.statusCode == 200) {
        // Mapear la lista de JSONs a List<RQResponse>
        return (response.data as List)
            .map((json) => RQResponse.fromJson(json))
            .toList();
      }
      throw Exception('Fallo al cargar RQs: ${response.statusCode}');
    } on DioException catch (e) {
      // Manejo de errores de red o servidor
      final data = e.response?.data;
      final detalle = data is Map<String, dynamic> ? data['detail'] : data;
      throw Exception(detalle ?? 'Error de conexión al listar RQs: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('El backend devolvió datos inválidos: ${e.message}');
    } on TypeError catch (e) {
      throw Exception('El formato de los RQs no es compatible: $e');
    }
  }

  Future<void> deleteRq(int rqId) async {
    try {
      final response = await _dio.delete('/rq-campo/$rqId');
      
      if (response.statusCode != 204) {
        throw Exception('Fallo al eliminar el RQ: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error de conexión al eliminar RQ: ${e.message}');
    }
  }
}

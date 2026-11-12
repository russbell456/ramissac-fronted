import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/core/config/api_config.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';

// Definimos el storage aquí para que sea accesible
const _storage = SessionStorage();

final apiBaseUrlProvider = StateProvider<String>((ref) => ApiConfig.baseUrl);

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // AGREGAMOS EL INTERCEPTOR
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Leemos el token del almacenamiento seguro
        final token = await _storage.read(key: 'jwt_token');
        
        // Si el token existe, lo inyectamos en los Headers
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        print('🚀 ENVIANDO [${options.method}] a ${options.uri}');
        return handler.next(options); // Continúa la petición
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print(' Error 401: Token inválido o expirado');
          // Aquí podrías disparar una lógica de logout si fuera necesario
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});

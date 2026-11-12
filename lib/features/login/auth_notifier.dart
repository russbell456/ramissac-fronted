import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_ocs/data/services/auth_service.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/data/network/dio_client.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  final SessionStorage _storage;

  AuthNotifier(this._authService, this._storage) : super(AuthStatus.initial) {
    _checkAuthStatus();
  }

  // ✅ CAMBIO 1: La firma usa 'email'
  Future<void> login(String email, String password) async {
    state = AuthStatus.loading;
    try {
      // ✅ Usa el parámetro 'email'
      final token = await _authService.login(email, password);
      
      await _storage.write(key: 'jwt_token', value: token.accessToken);
      
      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.unauthenticated;
      rethrow; 
    }
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && _tokenVigente(token)) {
      state = AuthStatus.authenticated;
    } else {
      await _storage.delete(key: 'jwt_token');
      state = AuthStatus.unauthenticated;
    }
  }

  bool _tokenVigente(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      ) as Map<String, dynamic>;
      final expiracion = payload['exp'];
      if (expiracion is! num) return false;
      return DateTime.fromMillisecondsSinceEpoch(expiracion.toInt() * 1000)
          .isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = AuthStatus.unauthenticated;
  }
}

// Proveedores de Riverpod
final secureStorageProvider = Provider((ref) => const SessionStorage());

final authServiceProvider = Provider((ref) {
  // Aquí está el truco: le pasamos el Dio que ya tiene el Interceptor
  final dio = ref.watch(dioProvider); 
  return AuthService(dio);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthStatus>(
  (ref) => AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(secureStorageProvider),
  ),
);

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _keyTwoFactorSecret = '2fa_secret';

  Future<void> saveUser(UserModel user) async {
    try {
      await Future.wait([
        _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
        _storage.write(key: _tokenKey, value: user.accessToken),
        _storage.write(key: _refreshTokenKey, value: user.refreshToken),
      ]);
      debugPrint('Sesión guardada de forma segura');
    } catch (e) {
      debugPrint('Error al guardar sesión: $e');
      rethrow;
    }
  }

  Future<void> updateTokens(String accessToken, String refreshToken) async {
    try {
      await Future.wait([
        _storage.write(key: _tokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
      debugPrint('Tokens actualizados de forma segura');
    } catch (e) {
      debugPrint('Error al actualizar tokens: $e');
      rethrow;
    }
  }

  // Obtener Token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<UserModel?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      final accessToken = await _storage.read(key: _tokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (userJson == null || accessToken == null || refreshToken == null) {
        return null;
      }

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      final completeData = <String, dynamic>{
        ...userData,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };

      return UserModel.fromJson(completeData);
    } catch (e) {
      debugPrint('Error al recuperar usuario: $e');
      return null;
    }
  }

  Future<UserModel?> reloadUserFromToken() async {
    try {
      final accessToken = await _storage.read(key: _tokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (accessToken == null || refreshToken == null) {
        return null;
      }

      final dummyJson = <String, dynamic>{
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'usuario': {},
      };

      return UserModel.fromJson(dummyJson);
    } catch (e) {
      debugPrint('❌ Error al recargar usuario: $e');
      return null;
    }
  }

  Future<void> saveTwoFactorSecret(String secret) async {
    await _storage.write(key: _keyTwoFactorSecret, value: secret);
  }

  Future<String?> getTwoFactorSecret() async {
    return await _storage.read(key: _keyTwoFactorSecret);
  }

  Future<void> logout() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ Datos de sesión eliminados de forma segura');
    } catch (e) {
      debugPrint('❌ Error en logout: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

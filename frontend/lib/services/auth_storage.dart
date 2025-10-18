import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthStorage {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Guardar usuario
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, user.accessToken);
    await prefs.setString(_refreshTokenKey, user.refreshToken);
  }

  // Obtener usuario (siempre extrae el RUN del token)
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final accessToken = prefs.getString(_tokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (userJson == null || accessToken == null || refreshToken == null) {
      return null;
    }

    final userData = jsonDecode(userJson) as Map<String, dynamic>;

    // Asegurarse de que los tokens estén en los datos para forzar la decodificación del JWT
    final completeData = <String, dynamic>{
      ...userData,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };

    return UserModel.fromJson(completeData);
  }

  // Recargar usuario desde el token (útil si el modelo cambió)
  Future<UserModel?> reloadUserFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_tokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    // Obtener datos básicos del usuario guardado
    final userJson = prefs.getString(_userKey);
    if (userJson == null) {
      return null;
    }

    final userData = jsonDecode(userJson) as Map<String, dynamic>;

    // Recrear el usuario con los tokens actuales para forzar la decodificación del JWT
    final refreshedData = <String, dynamic>{
      ...userData,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };

    final user = UserModel.fromJson(refreshedData);

    // Guardar el usuario actualizado
    await saveUser(user);

    return user;
  }

  // Obtener token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Obtener refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Actualizar tokens después de refresh
  Future<void> updateTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // Verificar si está logueado
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}

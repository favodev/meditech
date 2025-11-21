import 'dart:convert';
import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String run;
  final String tipoUsuario;
  final String accessToken;
  final String refreshToken;
  final bool isTwoFactorEnabled;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.run,
    required this.tipoUsuario,
    required this.accessToken,
    required this.refreshToken,
    this.isTwoFactorEnabled = false,
  });

  // Decodifica el payload del JWT (sin verificar la firma)
  static Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // El payload es la segunda parte del JWT (base64 encoded)
      final payload = parts[1];

      // Normalizar el base64 (agregar padding si es necesario)
      var normalized = base64Url.normalize(payload);

      // Decodificar
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // El backend retorna: { usuario: { id, nombre, email, tipo_usuario }, accessToken, refreshToken }
  // NOTA: El RUN NO viene en el objeto usuario, pero SÍ está en el JWT
  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint('\n🔍 ========== UserModel.fromJson ==========');
    debugPrint('📦 JSON recibido: $json');

    final usuario = json['usuario'] as Map<String, dynamic>?;
    final accessToken = json['accessToken'] ?? json['access_token'] ?? '';

    debugPrint('👤 Objeto usuario: $usuario');
    debugPrint(
      '🔑 Access Token presente: ${accessToken.isNotEmpty ? "SÍ (${accessToken.length} chars)" : "NO"}',
    );

    String run = '';
    String userId = '';
    String email = '';
    String roleFromJwt = ''; // Nueva variable

    if (accessToken.isNotEmpty) {
      debugPrint('🔓 Intentando decodificar JWT...');
      final jwtPayload = _decodeJwt(accessToken);
      if (jwtPayload != null) {
        run = jwtPayload['run'] ?? '';
        userId = jwtPayload['sub'] ?? '';
        email = jwtPayload['email'] ?? '';
        roleFromJwt = jwtPayload['tipo_usuario'] ?? ''; // Extraer rol
        debugPrint('✅ JWT decodificado exitosamente');
        debugPrint('📋 Payload completo: $jwtPayload');
        debugPrint('🆔 UserId del JWT: $userId');
        debugPrint('📧 Email del JWT: $email');
        debugPrint('🆔 RUN del JWT: ${run.isNotEmpty ? run : "❌ VACÍO"}');
        debugPrint(
          '👔 Rol del JWT: ${roleFromJwt.isNotEmpty ? roleFromJwt : "❌ VACÍO"}',
        );
      } else {
        debugPrint('❌ Error: No se pudo decodificar el JWT');
      }
    } else {
      debugPrint('⚠️ No hay access token para decodificar');
    }

    if (run.isEmpty) {
      final runFromUser = usuario?['run'] ?? json['run'] ?? '';
      if (runFromUser.isNotEmpty) {
        run = runFromUser;
        debugPrint('✅ RUN encontrado en el objeto usuario: $run');
      }
    }

    if (run.isEmpty) {
      debugPrint(
        '⚠️⚠️⚠️ ADVERTENCIA CRÍTICA: No se encontró el RUN del usuario ⚠️⚠️⚠️',
      );
    } else {
      debugPrint('✅✅✅ RUN FINAL: $run ✅✅✅');
    }

    debugPrint('========================================\n');

    return UserModel(
      id: usuario?['id'] ?? userId ?? json['id'] ?? json['_id'] ?? '',
      nombre: usuario?['nombre'] ?? json['nombre'] ?? '',
      email: usuario?['email'] ?? email ?? json['email'] ?? '',
      run: run,
      // Prioridad: Objeto Usuario > JWT > JSON raíz
      tipoUsuario:
          usuario?['tipo_usuario'] ?? roleFromJwt ?? json['tipo_usuario'] ?? '',
      accessToken: accessToken,
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      isTwoFactorEnabled:
          usuario?['isTwoFactorEnabled'] ?? json['isTwoFactorEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuario': {
        'id': id,
        'nombre': nombre,
        'email': email,
        'run': run,
        'tipo_usuario': tipoUsuario,
        'isTwoFactorEnabled': isTwoFactorEnabled,
      },
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

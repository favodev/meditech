import 'dart:convert';

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String run;
  final String tipoUsuario;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.run,
    required this.tipoUsuario,
    required this.accessToken,
    required this.refreshToken,
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
    print('\n🔍 ========== UserModel.fromJson ==========');
    print('📦 JSON recibido: $json');

    final usuario = json['usuario'] as Map<String, dynamic>?;
    final accessToken = json['accessToken'] ?? json['access_token'] ?? '';

    print('👤 Objeto usuario: $usuario');
    print(
      '🔑 Access Token presente: ${accessToken.isNotEmpty ? "SÍ (${accessToken.length} chars)" : "NO"}',
    );

    // Intentar extraer el RUN del JWT
    String run = '';

    if (accessToken.isNotEmpty) {
      print('🔓 Intentando decodificar JWT...');
      final jwtPayload = _decodeJwt(accessToken);
      if (jwtPayload != null) {
        run = jwtPayload['run'] ?? '';
        print('✅ JWT decodificado exitosamente');
        print('📋 Payload completo: $jwtPayload');
        print('🆔 RUN extraído del JWT: ${run.isNotEmpty ? run : "❌ VACÍO"}');
      } else {
        print('❌ Error: No se pudo decodificar el JWT');
      }
    } else {
      print('⚠️ No hay access token para decodificar');
    }

    // Si no se pudo extraer del JWT, intentar desde el objeto usuario
    if (run.isEmpty) {
      final runFromUser = usuario?['run'] ?? json['run'] ?? '';
      if (runFromUser.isNotEmpty) {
        run = runFromUser;
        print('✅ RUN encontrado en el objeto usuario: $run');
      }
    }

    if (run.isEmpty) {
      print(
        '⚠️⚠️⚠️ ADVERTENCIA CRÍTICA: No se encontró el RUN del usuario ⚠️⚠️⚠️',
      );
    } else {
      print('✅✅✅ RUN FINAL: $run ✅✅✅');
    }

    print('========================================\n');

    return UserModel(
      id: usuario?['id'] ?? json['id'] ?? json['_id'] ?? '',
      nombre: usuario?['nombre'] ?? json['nombre'] ?? '',
      email: usuario?['email'] ?? json['email'] ?? '',
      run: run,
      tipoUsuario: usuario?['tipo_usuario'] ?? json['tipo_usuario'] ?? '',
      accessToken: accessToken,
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
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
      },
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

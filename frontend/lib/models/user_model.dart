import 'dart:convert';

class RangoMeta {
  final double min;
  final double max;

  RangoMeta({required this.min, required this.max});

  factory RangoMeta.fromJson(Map<String, dynamic> json) {
    return RangoMeta(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}

class DatosAnticoagulacion {
  final String medicamento;
  final double mgPorPastilla;
  final RangoMeta rangoMeta;

  DatosAnticoagulacion({
    required this.medicamento,
    required this.mgPorPastilla,
    required this.rangoMeta,
  });

  factory DatosAnticoagulacion.fromJson(Map<String, dynamic> json) {
    return DatosAnticoagulacion(
      medicamento: json['medicamento'] ?? '',
      mgPorPastilla: (json['mg_por_pastilla'] as num?)?.toDouble() ?? 0.0,
      rangoMeta: RangoMeta.fromJson(
        json['rango_meta'] ?? {'min': 2.0, 'max': 3.0},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'medicamento': medicamento,
        'mg_por_pastilla': mgPorPastilla,
        'rango_meta': rangoMeta.toJson(),
      };
}

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String run;
  final String tipoUsuario;
  final String accessToken;
  final String refreshToken;
  final bool isTwoFactorEnabled;
  final DatosAnticoagulacion? datosAnticoagulacion; // <--- NUEVO CAMPO

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.run,
    required this.tipoUsuario,
    required this.accessToken,
    required this.refreshToken,
    this.isTwoFactorEnabled = false,
    this.datosAnticoagulacion,
  });

  // Decodifica el payload del JWT (sin verificar la firma)
  static Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>?;
    final accessToken = json['accessToken'] ?? json['access_token'] ?? '';

    String run = '';
    String userId = '';
    String email = '';

    if (accessToken.isNotEmpty) {
      final jwtPayload = _decodeJwt(accessToken);
      if (jwtPayload != null) {
        run = jwtPayload['run'] ?? '';
        userId = jwtPayload['sub'] ?? '';
        email = jwtPayload['email'] ?? '';
      }
    }

    if (run.isEmpty) {
      final runFromUser = usuario?['run'] ?? json['run'] ?? '';
      if (runFromUser.isNotEmpty) {
        run = runFromUser;
      }
    }

    return UserModel(
      id: usuario?['id'] ?? userId ?? json['id'] ?? json['_id'] ?? '',
      nombre: usuario?['nombre'] ?? json['nombre'] ?? '',
      email: usuario?['email'] ?? email ?? json['email'] ?? '',
      run: run,
      tipoUsuario: usuario?['tipo_usuario'] ?? json['tipo_usuario'] ?? '',
      accessToken: accessToken,
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      isTwoFactorEnabled:
          usuario?['isTwoFactorEnabled'] ?? json['isTwoFactorEnabled'] ?? false,
      // Mapeo del nuevo campo clínico
      datosAnticoagulacion:
          usuario?['datos_anticoagulacion'] != null
              ? DatosAnticoagulacion.fromJson(usuario!['datos_anticoagulacion'])
              : null,
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
        'datos_anticoagulacion': datosAnticoagulacion?.toJson(),
      },
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

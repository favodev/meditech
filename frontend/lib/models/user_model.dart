import 'dart:convert';
import 'package:flutter/foundation.dart';

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

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max};
  }
}

class DatosAnticoagulacion {
  final String medicamento;
  final double mgPorPastilla;
  final RangoMeta rangoMeta;
  final String? diagnosticoBase;
  final DateTime? fechaInicioTratamiento;

  DatosAnticoagulacion({
    required this.medicamento,
    required this.mgPorPastilla,
    required this.rangoMeta,
    this.diagnosticoBase,
    this.fechaInicioTratamiento,
  });

  factory DatosAnticoagulacion.fromJson(Map<String, dynamic> json) {
    return DatosAnticoagulacion(
      medicamento: json['medicamento'] ?? '',
      mgPorPastilla: (json['mg_por_pastilla'] as num).toDouble(),
      rangoMeta: RangoMeta.fromJson(json['rango_meta']),
      diagnosticoBase: json['diagnostico_base'],
      fechaInicioTratamiento: json['fecha_inicio_tratamiento'] != null
          ? DateTime.parse(json['fecha_inicio_tratamiento'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicamento': medicamento,
      'mg_por_pastilla': mgPorPastilla,
      'rango_meta': rangoMeta.toJson(),
      'diagnostico_base': diagnosticoBase,
      'fecha_inicio_tratamiento': fechaInicioTratamiento?.toIso8601String(),
    };
  }
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
  final DatosAnticoagulacion? datosAnticoagulacion;

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

  // Decodifica el payload del JWT
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
    debugPrint('\n🔍 ========== UserModel.fromJson ==========');
    debugPrint('📦 JSON recibido: $json');

    final usuario = json['usuario'] as Map<String, dynamic>?;
    final rootData = usuario ?? json;

    final accessToken = json['accessToken'] ?? json['access_token'] ?? '';

    debugPrint('👤 Objeto usuario (procesado): $rootData');

    String run = '';
    String userId = '';
    String email = '';
    String roleFromJwt = '';

    if (accessToken.isNotEmpty) {
      final jwtPayload = _decodeJwt(accessToken);
      if (jwtPayload != null) {
        run = jwtPayload['run'] ?? '';
        userId = jwtPayload['sub'] ?? '';
        email = jwtPayload['email'] ?? '';
        roleFromJwt = jwtPayload['tipo_usuario'] ?? '';
      }
    }

    if (run.isEmpty) {
      run = rootData['run'] ?? '';
    }

    // Extracción de Datos Clínicos (Anticoagulación)
    DatosAnticoagulacion? datosClinicos;
    if (rootData['datos_anticoagulacion'] != null) {
      try {
        datosClinicos = DatosAnticoagulacion.fromJson(
          rootData['datos_anticoagulacion'],
        );
        debugPrint('Datos de anticoagulación cargados correctamente');
      } catch (e) {
        debugPrint('Error al parsear datos de anticoagulación: $e');
      }
    }

    return UserModel(
      id: rootData['id'] ?? rootData['_id'] ?? userId ?? '',
      nombre: rootData['nombre'] ?? '',
      email: rootData['email'] ?? email ?? '',
      run: run,
      tipoUsuario: rootData['tipo_usuario'] ?? roleFromJwt ?? '',
      accessToken: accessToken,
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      isTwoFactorEnabled: rootData['isTwoFactorEnabled'] ?? false,
      datosAnticoagulacion: datosClinicos,
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

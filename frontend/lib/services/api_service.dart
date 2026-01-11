import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/tipo_informe_model.dart';
import '../models/informe_model.dart';
import 'auth_storage.dart';

class ApiService {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api-meditech-285055742691.southamerica-west1.run.app';
    } else {
      return 'https://api-meditech-285055742691.southamerica-west1.run.app';
    }
  }

  final AuthStorage _authStorage = AuthStorage();
  Future<void>? _refreshFuture;

  Future<http.Response> _requestWithAutoRefresh(
    Future<http.Response> Function(String token) request,
  ) async {
    String? token = await _authStorage.getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    if (_refreshFuture != null) {
      await _refreshFuture;
      token = await _authStorage.getToken();
    }

    http.Response response = await request(token!);

    if (response.statusCode == 401) {
      if (_refreshFuture == null) {
        debugPrint('Token expirado, iniciando renovación...');
        _refreshFuture = _refreshTokenFlow();
      }

      try {
        await _refreshFuture;
        final newToken = await _authStorage.getToken();
        if (newToken != null) {
          response = await request(newToken);
        }
      } catch (e) {
        await _authStorage.logout();
        rethrow;
      } finally {
        _refreshFuture = null;
      }
    }

    return response;
  }

  // Método auxiliar para la lógica de refresh
  Future<void> _refreshTokenFlow() async {
    final refreshToken = await _authStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No hay refresh token');

    final refreshResponse = await http.get(
      Uri.parse('$baseUrl/refresh'),
      headers: {'Authorization': 'Bearer $refreshToken'},
    );

    if (refreshResponse.statusCode == 200) {
      final data = jsonDecode(refreshResponse.body);
      await _authStorage.updateTokens(
        data['accessToken'],
        data['refreshToken'],
      );
      debugPrint('Token renovado exitosamente');
    } else {
      throw Exception('Sesión expirada');
    }
  }

  // Obtener tipos de informe
  Future<List<TipoInforme>> getTiposInforme(String token) async {
    final response = await _requestWithAutoRefresh(
      (t) => http.get(
        Uri.parse('$baseUrl/tipo-informe'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TipoInforme.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar tipos de informe');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Error en login');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Register Unificado
  Future<Map<String, dynamic>> register({
    required String tipoUsuario,
    required String nombre,
    required String apellido,
    required String email,
    required String run,
    String? telefono,
    required String password,
    Map<String, dynamic>? medicoDetalle,
    Map<String, dynamic>? pacienteDetalle,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'tipo_usuario': tipoUsuario,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'run': run,
        'password': password,
      };

      if (telefono != null && telefono.isNotEmpty) {
        body['telefono'] = telefono;
      }

      if (tipoUsuario == 'Medico' && medicoDetalle != null) {
        body['medico_detalle'] = medicoDetalle;
      }

      if (tipoUsuario == 'Paciente' && pacienteDetalle != null) {
        body['paciente_detalle'] = pacienteDetalle;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en registro');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener perfil del usuario autenticado
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      debugPrint('Obteniendo perfil de usuario...');
      final response = await http.get(
        Uri.parse('$baseUrl/usuario/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Perfil obtenido exitosamente');
        return data;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Error al obtener perfil');
      }
    } catch (e) {
      debugPrint('Error al obtener perfil: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener estadísticas del paciente (TTR, Rango Meta)
  Future<Map<String, dynamic>> getEstadisticas(String token) async {
    try {
      debugPrint('Obteniendo estadísticas clínicas...');
      final response = await http.get(
        Uri.parse('$baseUrl/informe/estadisticas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Estadísticas obtenidas');
        return data;
      } else {
        debugPrint(
          'No se pudieron cargar estadísticas: ${response.statusCode}',
        );
        return {};
      }
    } catch (e) {
      debugPrint('Error al obtener estadísticas: $e');
      return {};
    }
  }

  // Subir archivo a Google Cloud Storage
  Future<String> uploadFile({
    required File file,
    required String destination,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/storage/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final fileExtension = file.path.split('.').last.toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('application', fileExtension),
        ),
      );

      // Agregar el destino
      request.fields['destination'] = destination;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.body.replaceAll('"', '');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al subir archivo');
      }
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  // Obtener URL de descarga firmada
  Future<String> getDownloadUrl({
    required String path,
    required String name,
    required String format,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/storage/get-download-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'path': path, 'name': name, 'format': format}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['signedUrl'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener URL');
      }
    } catch (e) {
      throw Exception('Error al obtener URL de descarga: $e');
    }
  }

  // Obtener URL para abrir/visualizar archivo
  Future<String> getOpenUrl({
    required String path,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/storage/get-open-url'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'path': path}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['signedUrl'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener URL');
      }
    } catch (e) {
      throw Exception('Error al obtener URL: $e');
    }
  }

  // Crear informe con archivos
  Future<Map<String, dynamic>> createInforme({
    required String titulo,
    required String tipoInforme,
    required String runMedico,
    String? observaciones,
    Map<String, dynamic>? contenidoClinico,
    List<File>? files,
    required String token,
  }) async {
    try {
      debugPrint('Creando informe con ${files?.length ?? 0} archivo(s)');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/informe'),
      );

      // Agregar headers con token JWT
      request.headers['Authorization'] = 'Bearer $token';

      final informeData = {
        'titulo': titulo,
        'tipo_informe': tipoInforme,
        'run_medico': runMedico,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
        if (contenidoClinico != null) 'contenido_clinico': contenidoClinico,
      };

      request.fields['data'] = jsonEncode(informeData);

      debugPrint('Datos del informe: $informeData');
      debugPrint('JSON enviado: ${jsonEncode(informeData)}');

      if (files != null && files.isNotEmpty) {
        debugPrint('Agregando archivos al request:');
        for (var file in files) {
          final fileExtension = file.path.split('.').last.toLowerCase();
          final fileName = file.path.split(Platform.pathSeparator).last;

          debugPrint('  - Archivo: $fileName');
          debugPrint('    Path: ${file.path}');
          debugPrint('    Existe: ${await file.exists()}');
          debugPrint('    Tamaño: ${await file.length()} bytes');
          debugPrint('    Extensión: $fileExtension');

          MediaType contentType;
          switch (fileExtension) {
            case 'pdf':
              contentType = MediaType('application', 'pdf');
              break;
            case 'jpg':
            case 'jpeg':
              contentType = MediaType('image', 'jpeg');
              break;
            case 'png':
              contentType = MediaType('image', 'png');
              break;
            case 'bmp':
              contentType = MediaType('image', 'bmp');
              break;
            case 'doc':
              contentType = MediaType('application', 'msword');
              break;
            case 'docx':
              contentType = MediaType(
                'application',
                'vnd.openxmlformats-officedocument.wordprocessingml.document',
              );
              break;
            case 'xls':
              contentType = MediaType('application', 'vnd.ms-excel');
              break;
            case 'xlsx':
              contentType = MediaType(
                'application',
                'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              );
              break;
            case 'txt':
              contentType = MediaType('text', 'plain');
              break;
            default:
              contentType = MediaType('application', 'octet-stream');
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              file.path,
              contentType: contentType,
              filename: fileName,
            ),
          );
        }
        debugPrint('Total de archivos agregados: ${request.files.length}');
      } else {
        debugPrint('No hay archivos para subir');
      }

      debugPrint('Enviando request a: ${request.url}');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Fields: ${request.fields}');
      debugPrint('Files: ${request.files.map((f) => f.filename).toList()}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Respuesta del servidor:');
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('Informe creado exitosamente');
        debugPrint('  ID del informe: ${result['_id']}');
        debugPrint(
          '  Archivos en respuesta: ${result['archivos']?.length ?? 0}',
        );
        return result;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Error del servidor: $error');
        throw Exception(error['message'] ?? 'Error al crear informe');
      }
    } catch (e) {
      debugPrint('Error al crear informe: $e');
      rethrow;
    }
  }

  Future<void> crearInforme(Informe informe, List<File> files) async {
    final token = await _authStorage.getToken();
    if (token == null) throw Exception('No hay token');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/informe'));

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['data'] = jsonEncode(informe.toJson());

    for (var file in files) {
      final mimeType = file.path.endsWith('.pdf')
          ? MediaType('application', 'pdf')
          : MediaType('image', 'jpeg');

      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path,
          contentType: mimeType,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Error al crear informe: ${response.body}');
    }
  }

  // Logout
  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Error en logout: $e');
    }
  }

  // Obtener informes del usuario autenticado
  Future<List<Map<String, dynamic>>> getInformes(String token) async {
    try {
      debugPrint('Obteniendo informes del usuario...');

      final response = await _requestWithAutoRefresh((token) async {
        return await http.get(
          Uri.parse('$baseUrl/informe'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      });

      debugPrint('Respuesta del servidor:');
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Informes obtenidos: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Error del servidor: $error');
        throw Exception(error['message'] ?? 'Error al obtener informes');
      }
    } catch (e) {
      debugPrint('Error al obtener informes: $e');
      rethrow;
    }
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/refresh'),
        headers: {'Authorization': 'Bearer $refreshToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al renovar token');
      }
    } catch (e) {
      throw Exception('Error al renovar token: $e');
    }
  }

  // Obtener perfil del usuario autenticado
  Future<Map<String, dynamic>> getMyProfile(String token) async {
    try {
      debugPrint('Obteniendo perfil del usuario...');

      final response = await http.get(
        Uri.parse('$baseUrl/usuario/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Respuesta del servidor:');
      debugPrint('  Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Perfil obtenido exitosamente');
        return data;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Error del servidor: $error');
        throw Exception(error['message'] ?? 'Error al obtener perfil');
      }
    } catch (e) {
      debugPrint('Error al obtener perfil: $e');
      rethrow;
    }
  }

  // Actualizar perfil del usuario autenticado
  Future<Map<String, dynamic>> updateMyProfile(
    String token,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('Actualizando perfil del usuario...');
      debugPrint('  Datos: $updates');

      final response = await http.patch(
        Uri.parse('$baseUrl/usuario/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      debugPrint('Respuesta del servidor:');
      debugPrint('  Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Perfil actualizado exitosamente');
        return data;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Error del servidor: $error');
        throw Exception(error['message'] ?? 'Error al actualizar perfil');
      }
    } catch (e) {
      debugPrint('Error al actualizar perfil: $e');
      rethrow;
    }
  }

  // Cambiar contraseña
  Future<Map<String, dynamic>> changePassword(
    String token,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      debugPrint('Cambiando contraseña...');

      final response = await http.patch(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      debugPrint('Respuesta del servidor:');
      debugPrint('  Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('Contraseña cambiada exitosamente');
        return data;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Error del servidor: $error');
        throw Exception(error['message'] ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      debugPrint('Error al cambiar contraseña: $e');
      rethrow;
    }
  }

  // Obtener todas las instituciones
  Future<List<Map<String, dynamic>>> getInstituciones() async {
    try {
      debugPrint('Obteniendo instituciones...');

      final response = await http.get(
        Uri.parse('$baseUrl/institucion'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Instituciones obtenidas: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener instituciones');
      }
    } catch (e) {
      debugPrint('Error al obtener instituciones: $e');
      rethrow;
    }
  }

  // Obtener una institución por ID
  Future<Map<String, dynamic>> getInstitucion(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/institucion/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener institución');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Compartir informe con un médico
  Future<Map<String, dynamic>> compartirInforme({
    required String token,
    required String runMedico,
    required String informeIdOriginal,
    required String nivelAcceso,
    DateTime? fechaLimite,
    List<Map<String, dynamic>>? archivos,
  }) async {
    try {
      debugPrint('Compartiendo informe...');
      debugPrint('  RUN Médico: $runMedico');
      debugPrint('  Informe ID: $informeIdOriginal');
      debugPrint('  Nivel Acceso: $nivelAcceso');

      final Map<String, dynamic> body = {
        'run_medico': runMedico,
        'informe_id_original': informeIdOriginal,
        'nivel_acceso': nivelAcceso,
      };

      if (fechaLimite != null) {
        body['fecha_limite'] = fechaLimite.toIso8601String();
      }

      if (archivos != null && archivos.isNotEmpty) {
        body['archivos'] = archivos;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/permiso-compartir'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint('Respuesta del servidor:');
      debugPrint('  Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Informe compartido exitosamente');
        return data;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('Error del servidor: $error');
        throw Exception(error['message'] ?? 'Error al compartir informe');
      }
    } catch (e) {
      debugPrint('Error al compartir informe: $e');
      rethrow;
    }
  }

  // Obtener permisos compartidos
  Future<List<dynamic>> getPermisosCompartidos(String token) async {
    try {
      debugPrint('Obteniendo permisos compartidos...');

      final response = await _requestWithAutoRefresh((token) async {
        return await http.get(
          Uri.parse('$baseUrl/permiso-compartir/compartidos-conmigo'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Permisos obtenidos: ${data.length}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener permisos');
      }
    } catch (e) {
      debugPrint('Error al obtener permisos: $e');
      rethrow;
    }
  }

  // Revocar/actualizar permiso
  Future<void> revocarPermiso(String token, String permisoId) async {
    try {
      debugPrint('Revocando permiso: $permisoId');

      final response = await http.patch(
        Uri.parse('$baseUrl/permiso-compartir/$permisoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'activo': false}),
      );

      if (response.statusCode == 200) {
        debugPrint('Permiso revocado');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al revocar permiso');
      }
    } catch (e) {
      debugPrint('Error al revocar permiso: $e');
      rethrow;
    }
  }

  // Eliminar permiso
  Future<void> deletePermiso(String token, String permisoId) async {
    try {
      debugPrint('Eliminando permiso: $permisoId');

      final response = await http.delete(
        Uri.parse('$baseUrl/permiso-compartir/$permisoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Permiso eliminado');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al eliminar permiso');
      }
    } catch (e) {
      debugPrint('Error al eliminar permiso: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPermisoPublico({
    required String informeId,
    required String token,
  }) async {
    try {
      debugPrint('Creando permiso público para QR...');

      final response = await http.post(
        Uri.parse('$baseUrl/permiso-publico'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'informe_id_original': informeId,
          'nivel_acceso': 'Lectura',
        }),
      );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Permiso público creado - Response completo: $data');
        debugPrint('URL generada: ${data['Url']}');
        return data;
      } else {
        try {
          final error = jsonDecode(response.body);
          debugPrint('Error del servidor: ${error['message']}');
          debugPrint('Error completo: $error');
          throw Exception(error['message'] ?? 'Error al crear permiso público');
        } catch (jsonError) {
          debugPrint('Error parseando respuesta: $jsonError');
          throw Exception('Error al crear permiso público: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error al crear permiso público: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInformePublico(String token) async {
    try {
      debugPrint('Obteniendo informe público con token: $token');

      final response = await http.get(
        Uri.parse('$baseUrl/permiso-publico/ver?token=$token'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Informe público obtenido');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener informe público');
      }
    } catch (e) {
      debugPrint('Error al obtener informe público: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTiposArchivo(String token) async {
    try {
      debugPrint('Obteniendo tipos de archivo...');

      final response = await _requestWithAutoRefresh((token) async {
        return await http.get(
          Uri.parse('$baseUrl/tipo-archivo'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Tipos de informe obtenidos: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Error al obtener tipos de archivo',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener tipos de archivo: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEspecialidades() async {
    try {
      debugPrint('Obteniendo especialidades...');

      final response = await http.get(
        Uri.parse('$baseUrl/especialidad'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Especialidades obtenidas: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener especialidades');
      }
    } catch (e) {
      debugPrint('Error al obtener especialidades: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTiposInstitucion() async {
    try {
      debugPrint('Obteniendo tipos de institución...');

      final response = await http.get(
        Uri.parse('$baseUrl/tipo-institucion'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Tipos de institución obtenidos: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Error al obtener tipos de institución',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener tipos de institución: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setup2FA(String token) async {
    try {
      debugPrint('Configurando 2FA...');
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/setup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('2FA configurado: QR generado');
        return data;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Error al configurar 2FA');
      }
    } catch (e) {
      debugPrint('Error al configurar 2FA: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> verifyAndEnable2FA({
    required String token,
    required String code,
  }) async {
    try {
      debugPrint('Verificando y activando 2FA...');
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/verify-and-enable'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('2FA activado exitosamente');
        return data;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Código 2FA inválido');
      }
    } catch (e) {
      debugPrint('Error al activar 2FA: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> login2FAVerify({
    required String tempToken,
    required String code,
  }) async {
    try {
      debugPrint('Verificando código 2FA en login...');
      final response = await http.post(
        Uri.parse('$baseUrl/2fa/login-verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tempToken': tempToken, 'code': code}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Login 2FA exitoso');
        debugPrint('Data recibida: $data');
        return data;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['message'] ?? 'Código 2FA incorrecto');
      }
    } catch (e) {
      debugPrint('Error en login 2FA: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Error al solicitar recuperación de contraseña',
        );
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Error al restablecer la contraseña',
        );
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<bool> shareReportFormal(
    String doctorRun,
    String reportId,
    int expiryDays,
  ) async {
    final response = await _requestWithAutoRefresh((token) {
      return http.post(
        Uri.parse('$baseUrl/permiso-compartir/formal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'doctorRun': doctorRun,
          'reportId': reportId,
          'expiryDays': expiryDays,
        }),
      );
    });

    return response.statusCode == 201 || response.statusCode == 200;
  }
}

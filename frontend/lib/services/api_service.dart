import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.81:3000';

  // Login - según el backend retorna: { usuario: {...}, accessToken, refreshToken }
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en login');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Register Unificado - según el backend usa UnifiedRegisterDto
  Future<Map<String, dynamic>> register({
    required String tipoUsuario, // 'Medico' o 'Paciente'
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

      // Agregar headers con token JWT
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar el archivo
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
        // El backend retorna directamente el path del archivo como string
        return response.body.replaceAll('"', ''); // Quitar comillas si las hay
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
    List<File>? files,
    required String token,
  }) async {
    try {
      debugPrint('📤 Creando informe con ${files?.length ?? 0} archivo(s)');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/informe'),
      );

      // Agregar headers con token JWT
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar los datos del informe como JSON en el campo 'data'
      final informeData = {
        'titulo': titulo,
        'tipo_informe': tipoInforme,
        'run_medico': runMedico,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      };

      request.fields['data'] = jsonEncode(informeData);

      debugPrint('📋 Datos del informe: $informeData');
      debugPrint('📋 JSON enviado: ${jsonEncode(informeData)}');

      // Agregar los archivos con el nombre 'files' (plural)
      if (files != null && files.isNotEmpty) {
        debugPrint('📎 Agregando archivos al request:');
        for (var file in files) {
          final fileExtension = file.path.split('.').last.toLowerCase();
          final fileName = file.path.split(Platform.pathSeparator).last;

          debugPrint('  - Archivo: $fileName');
          debugPrint('    Path: ${file.path}');
          debugPrint('    Existe: ${await file.exists()}');
          debugPrint('    Tamaño: ${await file.length()} bytes');
          debugPrint('    Extensión: $fileExtension');

          // Determinar el Content-Type correcto según la extensión
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
            case 'doc':
              contentType = MediaType('application', 'msword');
              break;
            case 'docx':
              contentType = MediaType(
                'application',
                'vnd.openxmlformats-officedocument.wordprocessingml.document',
              );
              break;
            default:
              contentType = MediaType('application', 'octet-stream');
          }

          // IMPORTANTE: El backend espera 'files' como nombre del campo
          request.files.add(
            await http.MultipartFile.fromPath(
              'files', // ← Este nombre debe coincidir con el backend
              file.path,
              contentType: contentType,
              filename: fileName, // ← Agregar filename explícitamente
            ),
          );
        }
        debugPrint('✅ Total de archivos agregados: ${request.files.length}');
      } else {
        debugPrint('⚠️ No hay archivos para subir');
      }

      debugPrint('📡 Enviando request a: ${request.url}');
      debugPrint('📡 Headers: ${request.headers}');
      debugPrint('� Fields: ${request.fields}');
      debugPrint('📡 Files: ${request.files.map((f) => f.filename).toList()}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Respuesta del servidor:');
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Informe creado exitosamente');
        debugPrint('  ID del informe: ${result['_id']}');
        debugPrint(
          '  Archivos en respuesta: ${result['archivos']?.length ?? 0}',
        );
        return result;
      } else {
        final error = jsonDecode(response.body);
        debugPrint('❌ Error del servidor: $error');
        throw Exception(error['message'] ?? 'Error al crear informe');
      }
    } catch (e) {
      debugPrint('❌ Error al crear informe: $e');
      rethrow;
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
      // Ignorar errores en logout
      debugPrint('Error en logout: $e');
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
}

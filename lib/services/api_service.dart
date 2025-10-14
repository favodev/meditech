import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Cambia esta URL según tu configuración (localhost para emulador Android)
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android Emulator
  // static const String baseUrl = 'http://localhost:3000'; // iOS Simulator / Web
  // static const String baseUrl = 'http://192.168.x.x:3000'; // Dispositivo físico

  // Login
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
        throw Exception('Error en login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Register Médico
  Future<Map<String, dynamic>> registerMedico({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
    required String institucionId,
    required String especialidadId,
    String? telefonoConsultorio,
    int? aniosExperiencia,
    String? registroMpi,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipo_usuario': 'Medico',
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'telefono': telefono,
          'password': password,
          'medico_detalle': {
            'institucion': institucionId,
            'especialidad': especialidadId,
            'telefono_consultorio': telefonoConsultorio,
            'anios_experiencia': aniosExperiencia,
            'registro_mpi': registroMpi,
          },
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error en registro: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Register Paciente
  Future<Map<String, dynamic>> registerPaciente({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
    required String sexo,
    required String direccion,
    required DateTime fechaNacimiento,
    String? telefonoEmergencia,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipo_usuario': 'Paciente',
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'telefono': telefono,
          'password': password,
          'paciente_detalle': {
            'sexo': sexo,
            'direccion': direccion,
            'fecha_nacimiento': fechaNacimiento.toIso8601String(),
            'telefono_emergencia': telefonoEmergencia,
          },
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error en registro: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener instituciones
  Future<List<Map<String, dynamic>>> getInstituciones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/institucion'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener instituciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener especialidades
  Future<List<Map<String, dynamic>>> getEspecialidades() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/especialidad'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener especialidades');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}

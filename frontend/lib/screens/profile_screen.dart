import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _profileData;

  // Controladores de texto
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  final _telefonoConsultorioController = TextEditingController();
  final _aniosExperienciaController = TextEditingController();
  final _registroMpiController = TextEditingController();

  String? _tipoUsuario;
  String? _sexo;
  String? _especialidad;
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _telefonoEmergenciaController.dispose();
    _telefonoConsultorioController.dispose();
    _aniosExperienciaController.dispose();
    _registroMpiController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      final token = await _authStorage.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final profile = await _apiService.getMyProfile(token);

      setState(() {
        _profileData = profile;
        _tipoUsuario = profile['tipo_usuario'];

        // Datos comunes
        _nombreController.text = profile['nombre'] ?? '';
        _apellidoController.text = profile['apellido'] ?? '';
        _telefonoController.text = profile['telefono'] ?? '';

        // Datos de paciente
        if (_tipoUsuario == 'Paciente') {
          _sexo = profile['sexo'];
          _direccionController.text = profile['direccion'] ?? '';
          _telefonoEmergenciaController.text =
              profile['telefono_emergencia'] ?? '';
          if (profile['fecha_nacimiento'] != null) {
            _fechaNacimiento = DateTime.parse(profile['fecha_nacimiento']);
          }
        }

        // Datos de médico
        if (_tipoUsuario == 'Medico') {
          _especialidad = profile['especialidad'];
          _telefonoConsultorioController.text =
              profile['telefono_consultorio'] ?? '';
          _aniosExperienciaController.text =
              profile['anios_experiencia']?.toString() ?? '';
          _registroMpiController.text = profile['registro_mpi'] ?? '';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isSaving = true);

      final token = await _authStorage.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final updates = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
      };

      if (_telefonoController.text.trim().isNotEmpty) {
        updates['telefono'] = _telefonoController.text.trim();
      }

      // Datos de paciente
      if (_tipoUsuario == 'Paciente') {
        if (_sexo != null) updates['sexo'] = _sexo;
        if (_direccionController.text.trim().isNotEmpty) {
          updates['direccion'] = _direccionController.text.trim();
        }
        if (_telefonoEmergenciaController.text.trim().isNotEmpty) {
          updates['telefono_emergencia'] = _telefonoEmergenciaController.text
              .trim();
        }
        if (_fechaNacimiento != null) {
          updates['fecha_nacimiento'] = _fechaNacimiento!.toIso8601String();
        }
      }

      // Datos de médico
      if (_tipoUsuario == 'Medico') {
        if (_especialidad != null) updates['especialidad'] = _especialidad;
        if (_telefonoConsultorioController.text.trim().isNotEmpty) {
          updates['telefono_consultorio'] = _telefonoConsultorioController.text
              .trim();
        }
        if (_aniosExperienciaController.text.trim().isNotEmpty) {
          updates['anios_experiencia'] = int.tryParse(
            _aniosExperienciaController.text.trim(),
          );
        }
        if (_registroMpiController.text.trim().isNotEmpty) {
          updates['registro_mpi'] = _registroMpiController.text.trim();
        }
      }

      await _apiService.updateMyProfile(token, updates);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recargar perfil
      await _loadProfile();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar perfil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con tipo de usuario
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF2196F3),
                          child: Icon(
                            _tipoUsuario == 'Medico'
                                ? Icons.medical_services
                                : Icons.person,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_profileData?['nombre']} ${_profileData?['apellido']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tipoUsuario ?? 'Usuario',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _profileData?['email'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información Personal
                  const Text(
                    'Información Personal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  // Campos específicos de PACIENTE
                  if (_tipoUsuario == 'Paciente') ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Información Adicional',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _sexo,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Masculino',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'Femenino',
                          child: Text('Femenino'),
                        ),
                        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sexo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Nacimiento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _fechaNacimiento != null
                              ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                              : 'Seleccionar fecha',
                          style: TextStyle(
                            color: _fechaNacimiento != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _telefonoEmergenciaController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono de Emergencia',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.emergency),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],

                  // Campos específicos de MÉDICO
                  if (_tipoUsuario == 'Medico') ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Información Profesional',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _especialidad,
                      decoration: const InputDecoration(
                        labelText: 'Especialidad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Cardiologia',
                          child: Text('Cardiología'),
                        ),
                        DropdownMenuItem(
                          value: 'Dermatologia',
                          child: Text('Dermatología'),
                        ),
                        DropdownMenuItem(
                          value: 'Ginecologia',
                          child: Text('Ginecología'),
                        ),
                        DropdownMenuItem(
                          value: 'Medicina_General',
                          child: Text('Medicina General'),
                        ),
                        DropdownMenuItem(
                          value: 'Neurologia',
                          child: Text('Neurología'),
                        ),
                        DropdownMenuItem(
                          value: 'Pediatria',
                          child: Text('Pediatría'),
                        ),
                        DropdownMenuItem(
                          value: 'Psiquiatria',
                          child: Text('Psiquiatría'),
                        ),
                        DropdownMenuItem(
                          value: 'Traumatologia',
                          child: Text('Traumatología'),
                        ),
                        DropdownMenuItem(value: 'Otra', child: Text('Otra')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _especialidad = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _telefonoConsultorioController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono Consultorio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_in_talk),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _aniosExperienciaController,
                      decoration: const InputDecoration(
                        labelText: 'Años de Experiencia',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _registroMpiController,
                      decoration: const InputDecoration(
                        labelText: 'Registro MPI',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botón de guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar Cambios',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón de cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Future<void> _logout() async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Eliminar datos de sesión
      await _authStorage.logout();

      // Navegar a login y eliminar todas las rutas anteriores
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}

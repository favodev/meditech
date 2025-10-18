import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum TipoUsuarioEnum { medico, paciente }

// Constantes que coinciden con el backend
class BackendConstants {
  // Tipos de usuario (del backend: TipoUsuario enum)
  static const String tipoMedico = 'Medico';
  static const String tipoPaciente = 'Paciente';

  // Sexos (del backend: Sexo enum)
  static const List<String> sexos = ['Masculino', 'Femenino', 'Otro'];

  // Tipos de institución (del backend: TipoInstitucion enum)
  static const List<String> tiposInstitucion = [
    'Hospital Publico',
    'CESFAM',
    'CECOSF',
    'Posta Rural',
    'SAPU',
    'SAR',
    'COSAM',
    'CDT',
    'CRS',
    'Consultorio de Especialidades',
    'Clinica',
    'Consultorio Privado',
    'Centro Medico',
    'Laboratorio',
    'Banco de Sangre',
    'Centro de Imagenologia',
    'Farmacia',
    'Hogar de Ancianos',
    'Instituto de Salud Publica',
    'Instituciones Fuerzas Armadas',
    'Mutuo de Seguridad',
    'Central de Abastecimiento',
  ];

  // Especialidades (del backend: Especialidades enum)
  static const List<String> especialidades = [
    'Cardiologia',
    'Dermatologia',
    'Pediatria',
    'Oftalmologia',
    'Neurologia',
    'Traumatologia',
    'Gastroenterologia',
    'Neumologia',
    'Endocrinologia',
    'Nefrologia',
    'Otorrinolaringologia',
    'Psiquiatria',
    'Urologia',
    'Ginecologia',
    'Anestesiologia',
    'Radiologia',
    'Oncologia',
    'Hematologia',
    'Reumatologia',
    'Medicina Interna',
    'Medicina Familiar',
    'Medicina de Urgencias',
    'Alergologia',
    'Medicina Fisica y Rehabilitacion',
    'Cirugia General',
    'Cirugia Plastica',
    'Cirugia Cardiovascular',
    'Cirugia Pediatrica',
    'Medicina de Cuidados Paliativos',
    'Geriatria',
    'Infectologia',
    'Patologia',
    'Medicina del Deporte',
    'Medicina Nuclear',
    'Genetica Medica',
    'Epidemiologia',
    'Salud Publica',
    'Medicina del Trabajo',
    'Fisioterapia',
    'Nutriologia',
    'Odontologia',
    'Psicologia Clinica',
    'Podologia',
    'Microbiologia',
    'Bioquimica Clinica',
    'Toxicologia',
    'Farmacologia Clinica',
    'Inmunologia Clinica',
    'Angiologia',
    'Neurocirugia',
  ];
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _apiService = ApiService();

  // Controllers comunes
  final _nameController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _runController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers para Paciente
  final _direccionController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  DateTime? _fechaNacimiento;
  String? _sexoSeleccionado;

  // Controllers para Médico
  final _nombreInstitucionController = TextEditingController();
  final _telefonoConsultorioController = TextEditingController();
  final _aniosExperienciaController = TextEditingController();
  final _registroMpiController = TextEditingController();
  String? _tipoInstitucionSeleccionada;
  String? _especialidadSeleccionada;

  // Variables de estado
  TipoUsuarioEnum _tipoUsuario = TipoUsuarioEnum.paciente;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _runController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _direccionController.dispose();
    _telefonoEmergenciaController.dispose();
    _nombreInstitucionController.dispose();
    _telefonoConsultorioController.dispose();
    _aniosExperienciaController.dispose();
    _registroMpiController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validaciones básicas
    if (_nameController.text.isEmpty ||
        _apellidoController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _runController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorDialog('Por favor completa todos los campos obligatorios');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Las contraseñas no coinciden');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorDialog('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    // Validaciones específicas por tipo
    if (_tipoUsuario == TipoUsuarioEnum.paciente) {
      if (_sexoSeleccionado == null ||
          _direccionController.text.isEmpty ||
          _fechaNacimiento == null) {
        _showErrorDialog('Por favor completa todos los campos de paciente');
        return;
      }
    } else {
      if (_nombreInstitucionController.text.isEmpty ||
          _tipoInstitucionSeleccionada == null ||
          _especialidadSeleccionada == null) {
        _showErrorDialog(
          'Por favor completa nombre de institución, tipo y especialidad',
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? medicoDetalle;
      Map<String, dynamic>? pacienteDetalle;

      if (_tipoUsuario == TipoUsuarioEnum.paciente) {
        // Según el backend: CreatePacienteDetailsDto
        pacienteDetalle = {
          'sexo': _sexoSeleccionado!,
          'direccion': _direccionController.text.trim(),
          'fecha_nacimiento': _fechaNacimiento!.toIso8601String(),
        };

        if (_telefonoEmergenciaController.text.trim().isNotEmpty) {
          pacienteDetalle['telefono_emergencia'] = _telefonoEmergenciaController
              .text
              .trim();
        }
      } else {
        // Según el backend: CreateMedicoDetailsDto con institución embebida
        medicoDetalle = {
          'institucion': {
            'nombre': _nombreInstitucionController.text.trim(),
            'tipo_institucion': _tipoInstitucionSeleccionada!,
          },
          'especialidad': _especialidadSeleccionada!,
        };

        if (_telefonoConsultorioController.text.trim().isNotEmpty) {
          medicoDetalle['telefono_consultorio'] = _telefonoConsultorioController
              .text
              .trim();
        }

        if (_aniosExperienciaController.text.trim().isNotEmpty) {
          final anios = int.tryParse(_aniosExperienciaController.text.trim());
          if (anios != null) {
            medicoDetalle['anios_experiencia'] = anios;
          }
        }

        if (_registroMpiController.text.trim().isNotEmpty) {
          medicoDetalle['registro_mpi'] = _registroMpiController.text.trim();
        }
      }

      await _apiService.register(
        tipoUsuario: _tipoUsuario == TipoUsuarioEnum.paciente
            ? BackendConstants.tipoPaciente
            : BackendConstants.tipoMedico,
        nombre: _nameController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        run: _runController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        password: _passwordController.text,
        medicoDetalle: medicoDetalle,
        pacienteDetalle: pacienteDetalle,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¡Registro exitoso!'),
            content: const Text(
              'Tu cuenta ha sido creada. Ahora puedes iniciar sesión.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al registrarse: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFechaNacimiento() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Registrarse',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea una cuenta para iniciar',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Selector de Tipo de Usuario
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tipoUsuario = TipoUsuarioEnum.paciente;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tipoUsuario == TipoUsuarioEnum.paciente
                                ? const Color(0xFF2196F3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                color: _tipoUsuario == TipoUsuarioEnum.paciente
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Paciente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _tipoUsuario == TipoUsuarioEnum.paciente
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _tipoUsuario = TipoUsuarioEnum.medico;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tipoUsuario == TipoUsuarioEnum.medico
                                ? const Color(0xFF2196F3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services,
                                color: _tipoUsuario == TipoUsuarioEnum.medico
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Médico',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _tipoUsuario == TipoUsuarioEnum.medico
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campos comunes
              _buildTextField(
                controller: _nameController,
                label: 'Nombre *',
                hint: 'Ingresa tu nombre',
                keyboardType: TextInputType.name,
              ),
              _buildTextField(
                controller: _apellidoController,
                label: 'Apellido *',
                hint: 'Ingresa tu apellido',
                keyboardType: TextInputType.name,
              ),
              _buildTextField(
                controller: _runController,
                label: 'RUN *',
                hint: '12345678-9',
                keyboardType: TextInputType.text,
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Correo electrónico *',
                hint: 'nombre@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                controller: _telefonoController,
                label: 'Teléfono',
                hint: '+56912345678',
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                controller: _passwordController,
                label: 'Contraseña *',
                hint: 'Mínimo 6 caracteres',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirmar contraseña *',
                hint: 'Repite tu contraseña',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),

              // Campos específicos según tipo de usuario
              if (_tipoUsuario == TipoUsuarioEnum.paciente) ...[
                // Campos de Paciente
                const Text(
                  'Sexo *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _sexoSeleccionado,
                  decoration: InputDecoration(
                    hintText: 'Selecciona tu sexo',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2196F3),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: BackendConstants.sexos.map((sexo) {
                    return DropdownMenuItem(value: sexo, child: Text(sexo));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sexoSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _direccionController,
                  label: 'Dirección *',
                  hint: 'Calle, Número, Ciudad',
                  maxLines: 2,
                ),
                const Text(
                  'Fecha de Nacimiento *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectFechaNacimiento,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fechaNacimiento == null
                              ? 'Selecciona tu fecha de nacimiento'
                              : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                          style: TextStyle(
                            color: _fechaNacimiento == null
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _telefonoEmergenciaController,
                  label: 'Teléfono de Emergencia',
                  hint: '+56912345678',
                  keyboardType: TextInputType.phone,
                ),
              ] else ...[
                // Campos de Médico
                _buildTextField(
                  controller: _nombreInstitucionController,
                  label: 'Nombre de Institución *',
                  hint: 'Hospital Regional de Valdivia',
                ),
                const Text(
                  'Tipo de Institución *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _tipoInstitucionSeleccionada,
                  decoration: InputDecoration(
                    hintText: 'Selecciona el tipo',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2196F3),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: BackendConstants.tiposInstitucion.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoInstitucionSeleccionada = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Especialidad *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _especialidadSeleccionada,
                  decoration: InputDecoration(
                    hintText: 'Selecciona tu especialidad',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2196F3),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  items: BackendConstants.especialidades.map((esp) {
                    return DropdownMenuItem<String>(
                      value: esp,
                      child: Text(esp),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _especialidadSeleccionada = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _telefonoConsultorioController,
                  label: 'Teléfono Consultorio',
                  hint: '+56912345678',
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: _aniosExperienciaController,
                  label: 'Años de Experiencia',
                  hint: '5',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _registroMpiController,
                  label: 'Registro MPI',
                  hint: 'MPI-12345',
                ),
              ],

              // Checkbox de Términos y Condiciones
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(text: 'Acepto los '),
                            TextSpan(
                              text: 'Términos y Condiciones',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón de Registro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_acceptTerms && !_isLoading)
                      ? _handleRegister
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

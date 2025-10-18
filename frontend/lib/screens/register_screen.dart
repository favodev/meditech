import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum TipoUsuarioEnum { medico, paciente }

// Constantes del backend
class BackendConstants {
  static const String tipoMedico = 'Medico';
  static const String tipoPaciente = 'Paciente';
  static const List<String> sexos = ['Masculino', 'Femenino', 'Otro'];
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
  final _formKey = GlobalKey<FormState>();

  // Controllers comunes
  final _nameController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _runController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers Paciente
  final _direccionController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  DateTime? _fechaNacimiento;
  String? _sexoSeleccionado;

  // Controllers Médico
  final _nombreInstitucionController = TextEditingController();
  final _telefonoConsultorioController = TextEditingController();
  final _aniosExperienciaController = TextEditingController();
  final _registroMpiController = TextEditingController();
  String? _tipoInstitucionSeleccionada;
  String? _especialidadSeleccionada;

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
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Las contraseñas no coinciden');
      return;
    }

    if (!_acceptTerms) {
      _showErrorDialog('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? medicoDetalle;
      Map<String, dynamic>? pacienteDetalle;

      if (_tipoUsuario == TipoUsuarioEnum.paciente) {
        pacienteDetalle = {
          'sexo': _sexoSeleccionado!,
          'direccion': _direccionController.text.trim(),
          'fecha_nacimiento': _fechaNacimiento!.toIso8601String(),
        };
        if (_telefonoEmergenciaController.text.isNotEmpty) {
          pacienteDetalle['telefono_emergencia'] = _telefonoEmergenciaController
              .text
              .trim();
        }
      } else {
        medicoDetalle = {
          'institucion': {
            'nombre': _nombreInstitucionController.text.trim(),
            'tipo_institucion': _tipoInstitucionSeleccionada!,
          },
          'especialidad': _especialidadSeleccionada!,
        };
        if (_telefonoConsultorioController.text.isNotEmpty) {
          medicoDetalle['telefono_consultorio'] = _telefonoConsultorioController
              .text
              .trim();
        }
        if (_aniosExperienciaController.text.isNotEmpty) {
          medicoDetalle['anios_experiencia'] = int.tryParse(
            _aniosExperienciaController.text,
          );
        }
        if (_registroMpiController.text.isNotEmpty) {
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
        telefono: _telefonoController.text.isEmpty
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
      if (mounted) _showErrorDialog('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator ?? (v) => v!.isEmpty ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
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
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Tipo de Usuario con Radio Buttons
                const Text(
                  'Tipo de usuario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _tipoUsuario = TipoUsuarioEnum.paciente,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _tipoUsuario == TipoUsuarioEnum.paciente
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _tipoUsuario == TipoUsuarioEnum.paciente
                                ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _tipoUsuario == TipoUsuarioEnum.paciente
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _tipoUsuario == TipoUsuarioEnum.paciente
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              const Text('Paciente'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _tipoUsuario = TipoUsuarioEnum.medico,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _tipoUsuario == TipoUsuarioEnum.medico
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: _tipoUsuario == TipoUsuarioEnum.medico
                                ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _tipoUsuario == TipoUsuarioEnum.medico
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _tipoUsuario == TipoUsuarioEnum.medico
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              const Text('Médico'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nombre y Apellido en una fila
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nameController,
                        label: 'Nombre *',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _apellidoController,
                        label: 'Apellido *',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // RUN y Teléfono en una fila
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _runController,
                        label: 'RUN *',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _telefonoController,
                        label: 'Teléfono',
                        keyboardType: TextInputType.phone,
                        validator: (_) => null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email *',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Contraseñas en una fila
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _passwordController,
                        label: 'Contraseña *',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar *',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campos específicos
                if (_tipoUsuario == TipoUsuarioEnum.paciente) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Sexo *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          initialValue: _sexoSeleccionado,
                          items: BackendConstants.sexos
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _sexoSeleccionado = v),
                          validator: (v) =>
                              v == null ? 'Campo requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _fechaNacimiento = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha Nacimiento *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _fechaNacimiento == null
                                  ? 'Seleccionar'
                                  : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _direccionController,
                    label: 'Dirección *',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _telefonoEmergenciaController,
                    label: 'Teléfono Emergencia',
                    keyboardType: TextInputType.phone,
                    validator: (_) => null,
                  ),
                ] else ...[
                  _buildTextField(
                    controller: _nombreInstitucionController,
                    label: 'Nombre Institución *',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Tipo Institución *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          initialValue: _tipoInstitucionSeleccionada,
                          items: BackendConstants.tiposInstitucion
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _tipoInstitucionSeleccionada = v),
                          validator: (v) =>
                              v == null ? 'Campo requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Especialidad *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          initialValue: _especialidadSeleccionada,
                          items: BackendConstants.especialidades
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _especialidadSeleccionada = v),
                          validator: (v) =>
                              v == null ? 'Campo requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _telefonoConsultorioController,
                          label: 'Tel. Consultorio',
                          validator: (_) => null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _aniosExperienciaController,
                          label: 'Años Experiencia',
                          keyboardType: TextInputType.number,
                          validator: (_) => null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _registroMpiController,
                    label: 'Registro MPI',
                    validator: (_) => null,
                  ),
                ],

                const SizedBox(height: 24),

                // Checkbox términos
                CheckboxListTile(
                  title: const Text(
                    'Acepto términos y condiciones',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF2196F3),
                ),

                const SizedBox(height: 24),

                // Botón registrarse
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _runController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Paciente controllers
  final _direccionController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Tipo de usuario seleccionado
  String _tipoUsuario = 'Paciente';

  // Campos específicos
  String? _sexo;
  DateTime? _fechaNacimiento;
  String? _especialidad;
  String? _institucionSeleccionada; // ID de la institución seleccionada

  // Lista de instituciones del backend
  List<Map<String, dynamic>> _instituciones = [];
  bool _loadingInstituciones = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _loadInstituciones();
  }

  Future<void> _loadInstituciones() async {
    setState(() => _loadingInstituciones = true);
    try {
      final instituciones = await _apiService.getInstituciones();
      setState(() {
        _instituciones = instituciones;
      });
    } catch (e) {
      debugPrint('Error cargando instituciones: $e');
    } finally {
      setState(() => _loadingInstituciones = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _runController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? pacienteDetalle;
      Map<String, dynamic>? medicoDetalle;

      // Construir objeto específico según tipo de usuario
      if (_tipoUsuario == 'Paciente') {
        pacienteDetalle = {
          'sexo': _sexo,
          'direccion': _direccionController.text.trim(),
          'fecha_nacimiento': _fechaNacimiento?.toIso8601String(),
        };

        // Añadir teléfono de emergencia si no está vacío
        if (_telefonoEmergenciaController.text.trim().isNotEmpty) {
          pacienteDetalle['telefono_emergencia'] = _telefonoEmergenciaController
              .text
              .trim();
        }
      } else if (_tipoUsuario == 'Medico') {
        // Buscar la institución seleccionada
        final institucionData = _instituciones.firstWhere(
          (inst) => inst['_id'] == _institucionSeleccionada,
        );

        medicoDetalle = {
          'institucion': {
            'nombre': institucionData['nombre'],
            'tipo_institucion': institucionData['tipo_institucion'],
          },
          'especialidad': _especialidad,
        };
      }

      await _apiService.register(
        tipoUsuario: _tipoUsuario,
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        email: _emailController.text.trim(),
        run: _runController.text.trim(),
        telefono: _telefonoController.text.trim(),
        password: _passwordController.text,
        pacienteDetalle: pacienteDetalle,
        medicoDetalle: medicoDetalle,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso. Ahora puedes iniciar sesión'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Tabs fijos en la parte superior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2196F3),
                unselectedLabelColor: Colors.grey[400],
                labelStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: const Color(0xFF2196F3),
                indicatorWeight: 3,
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                tabs: const [
                  Tab(text: 'Iniciar sesión'),
                  Tab(text: 'Registro'),
                ],
              ),
            ),

            // Contenido con scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // Selector de tipo de usuario
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tipo de Usuario',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Paciente'),
                                    value: 'Paciente',
                                    groupValue: _tipoUsuario,
                                    activeColor: const Color(0xFF2196F3),
                                    onChanged: (value) {
                                      setState(() {
                                        _tipoUsuario = value!;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Médico'),
                                    value: 'Medico',
                                    groupValue: _tipoUsuario,
                                    activeColor: const Color(0xFF2196F3),
                                    onChanged: (value) {
                                      setState(() {
                                        _tipoUsuario = value!;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Nombre
                        _buildTextField(
                          label: 'Nombre',
                          controller: _nombreController,
                          hint: 'Juan',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu nombre';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Apellido
                        _buildTextField(
                          label: 'Apellido',
                          controller: _apellidoController,
                          hint: 'Pérez',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu apellido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Email
                        _buildTextField(
                          label: 'Email',
                          controller: _emailController,
                          hint: 'ejemplo@correo.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu email';
                            }
                            if (!value.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // RUN
                        _buildTextField(
                          label: 'RUN',
                          controller: _runController,
                          hint: '12345678-9',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu RUN';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Teléfono
                        _buildTextField(
                          label: 'Teléfono',
                          controller: _telefonoController,
                          hint: '+56912345678',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu teléfono';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ========== CAMPOS ESPECÍFICOS PACIENTE ==========
                        if (_tipoUsuario == 'Paciente') ...[
                          // Sexo
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sexo *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _sexo,
                                decoration: InputDecoration(
                                  hintText: 'Selecciona tu sexo',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
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
                                items: ['Masculino', 'Femenino', 'Otro']
                                    .map(
                                      (sexo) => DropdownMenuItem(
                                        value: sexo,
                                        child: Text(sexo),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _sexo = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecciona tu sexo';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Fecha de Nacimiento
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fecha de Nacimiento *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: _fechaNacimiento == null
                                      ? 'Selecciona tu fecha de nacimiento'
                                      : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
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
                                  suffixIcon: Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().subtract(
                                      const Duration(days: 365 * 25),
                                    ),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF2196F3),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _fechaNacimiento = picked;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (_fechaNacimiento == null) {
                                    return 'Selecciona tu fecha de nacimiento';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Dirección
                          _buildTextField(
                            label: 'Dirección *',
                            controller: _direccionController,
                            hint: 'Calle 123, Depto 45',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu dirección';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Teléfono de Emergencia
                          _buildTextField(
                            label: 'Teléfono de Emergencia',
                            controller: _telefonoEmergenciaController,
                            hint: '+56912345678',
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 20),
                        ],

                        // ========== CAMPOS ESPECÍFICOS MÉDICO ==========
                        if (_tipoUsuario == 'Medico') ...[
                          // Institución
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Institución *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _institucionSeleccionada,
                                decoration: InputDecoration(
                                  hintText: _loadingInstituciones
                                      ? 'Cargando instituciones...'
                                      : 'Selecciona tu institución',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
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
                                items: _instituciones
                                    .map(
                                      (inst) => DropdownMenuItem<String>(
                                        value: inst['_id'],
                                        child: Text(
                                          '${inst['nombre']} (${inst['tipo_institucion']})',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _loadingInstituciones
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _institucionSeleccionada = value;
                                        });
                                      },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecciona tu institución';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Especialidad
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Especialidad *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _especialidad,
                                decoration: InputDecoration(
                                  hintText: 'Selecciona tu especialidad',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
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
                                items:
                                    [
                                          'Cardiologia',
                                          'Neurologia',
                                          'Pediatria',
                                          'Ginecologia',
                                          'Obstetricia',
                                          'Traumatologia',
                                          'Dermatologia',
                                          'Oftalmologia',
                                          'Otorrinolaringologia',
                                          'Psiquiatria',
                                          'Urologia',
                                          'Nefrologia',
                                          'Gastroenterologia',
                                          'Endocrinologia',
                                          'Neumologia',
                                          'Reumatologia',
                                          'Hematologia',
                                          'Oncologia',
                                          'Infectologia',
                                          'Inmunologia',
                                          'Geriatria',
                                          'Medicina Interna',
                                          'Medicina Familiar',
                                          'Medicina General',
                                          'Cirugia General',
                                          'Cirugia Cardiovascular',
                                          'Cirugia Plastica',
                                          'Cirugia Pediatrica',
                                          'Neurocirugia',
                                          'Anestesiologia',
                                          'Radiologia',
                                          'Medicina Nuclear',
                                          'Patologia',
                                          'Medicina Legal',
                                          'Salud Publica',
                                          'Medicina del Trabajo',
                                          'Medicina del Deporte',
                                          'Medicina de Urgencia',
                                          'Cuidados Intensivos',
                                          'Neonatologia',
                                          'Medicina Fisica y Rehabilitacion',
                                          'Genetica Medica',
                                          'Nutricion',
                                          'Otra',
                                        ]
                                        .map(
                                          (esp) => DropdownMenuItem(
                                            value: esp,
                                            child: Text(esp),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _especialidad = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selecciona tu especialidad';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],

                        // Contraseña
                        _buildTextField(
                          label: 'Contraseña',
                          controller: _passwordController,
                          hint: '••••••••••',
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa una contraseña';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[400],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Confirmar Contraseña
                        _buildTextField(
                          label: 'Confirmar Contraseña',
                          controller: _confirmPasswordController,
                          hint: '••••••••••',
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirma tu contraseña';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[400],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Botón Continue
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Continuar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

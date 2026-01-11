import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../utils/rut_formatter.dart';

class CompartirInformeScreen extends StatefulWidget {
  final Map<String, dynamic> informe;

  const CompartirInformeScreen({super.key, required this.informe});

  @override
  State<CompartirInformeScreen> createState() => _CompartirInformeScreenState();
}

class _CompartirInformeScreenState extends State<CompartirInformeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _runController = TextEditingController();
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  String _nivelAcceso = 'Lectura';
  DateTime? _fechaLimite;
  bool _isLoading = false;
  List<Map<String, dynamic>> _archivosSeleccionados = [];

  final List<String> _nivelesAcceso = ['Lectura', 'Descarga', 'Escritura'];

  @override
  void initState() {
    super.initState();
    final archivos = widget.informe['archivos'] as List?;
    if (archivos != null) {
      _archivosSeleccionados = archivos.map((archivo) {
        return {
          'nombre': archivo['nombre'],
          'formato': archivo['formato'],
          'urlpath': archivo['urlpath'],
          'tipo':
              (archivo['tipo'] != null && archivo['tipo'].toString().isNotEmpty)
              ? archivo['tipo']
              : 'documento',
        };
      }).toList();
    }
  }

  @override
  void dispose() {
    _runController.dispose();
    super.dispose();
  }

  Future<void> _compartirInforme() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authStorage.getToken();

      if (token == null) {
        throw Exception('No se encontró el token de autenticación');
      }

      final runMedico = cleanRut(_runController.text);
      final informeId = widget.informe['_id'];

      await _apiService.compartirInforme(
        token: token,
        runMedico: runMedico,
        informeIdOriginal: informeId,
        nivelAcceso: _nivelAcceso,
        fechaLimite: _fechaLimite,
        archivos: _archivosSeleccionados.isNotEmpty
            ? _archivosSeleccionados
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Informe compartido exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _seleccionarFechaLimite() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() => _fechaLimite = fechaSeleccionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final archivos = widget.informe['archivos'] as List?;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Compartir Informe'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Información del informe
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.blue[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.informe['titulo'] ?? 'Sin título',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tipo: ${widget.informe['tipo_informe']}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            if (archivos != null && archivos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${archivos.length} archivo(s)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // RUT del médico
                    const Text(
                      'RUT del Médico',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _runController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [RutFormatter()],
                      decoration: InputDecoration(
                        hintText: 'Ej: 12.345.678-9',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el RUT del médico';
                        }
                        final clean = cleanRut(value);

                        if (clean.length < 7 || clean.length > 10) {
                          return 'RUT inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Nivel de acceso
                    const Text(
                      'Nivel de Acceso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _nivelAcceso,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.security),
                      ),
                      items: _nivelesAcceso.map((nivel) {
                        IconData icon;
                        String descripcion;

                        switch (nivel) {
                          case 'Lectura':
                            icon = Icons.visibility;
                            descripcion = 'Solo visualizar';
                            break;
                          case 'Descarga':
                            icon = Icons.download;
                            descripcion = 'Visualizar y descargar';
                            break;
                          case 'Escritura':
                            icon = Icons.edit;
                            descripcion = 'Todos los permisos';
                            break;
                          default:
                            icon = Icons.help;
                            descripcion = '';
                        }

                        return DropdownMenuItem(
                          value: nivel,
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: Colors.grey[700]),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    nivel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    descripcion,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _nivelAcceso = value);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Fecha límite (opcional)
                    const Text(
                      'Fecha Límite de Acceso (Opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _seleccionarFechaLimite,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fechaLimite == null
                                    ? 'Sin fecha límite'
                                    : 'Hasta: ${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _fechaLimite == null
                                      ? Colors.grey[600]
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (_fechaLimite != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _fechaLimite = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botón compartir
                    ElevatedButton(
                      onPressed: _compartirInforme,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text(
                            'Compartir Informe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nota informativa
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'El médico podrá acceder al informe según el nivel de acceso seleccionado. '
                              '${_fechaLimite != null ? 'El acceso expirará automáticamente en la fecha límite establecida.' : 'Sin fecha límite, el acceso será permanente hasta que lo revoque.'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

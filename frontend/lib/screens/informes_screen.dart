import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../models/informe_model.dart';
import '../models/user_model.dart';
import '../models/tipo_informe_model.dart';
import '../utils/rut_formatter.dart';
import 'compartir_informe_screen.dart';
import 'permisos_compartidos_screen.dart';

class InformesScreen extends StatefulWidget {
  final String? initialFilter;
  const InformesScreen({super.key, this.initialFilter});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();
  final TextEditingController _searchController = TextEditingController();

  bool _isUploading = false;
  bool _isLoading = true;
  final List<Informe> _informes = [];
  List<Informe> _informesFiltrados = [];
  UserModel? _currentUser;
  String _sortOrder = 'reciente';

  @override
  void initState() {
    super.initState();
    // Establecer el filtro inicial
    if (widget.initialFilter != null && widget.initialFilter!.isNotEmpty) {
      _searchController.text = widget.initialFilter!;
      debugPrint(
        '🔍 InformesScreen initState con filtro: "${widget.initialFilter}"',
      );
    } else {
      _searchController.text = '';
      debugPrint('🔍 InformesScreen initState sin filtro');
    }
    _loadUserData();
    _loadInformes();
  }

  /// Valida que todos los archivos tengan extensiones permitidas
  bool _validateFileExtensions(List<File> files) {
    final allowedExtensions = _getAllowedExtensions();
    final allowedExtensionsSet = allowedExtensions
        .map((e) => e.toLowerCase())
        .toSet();

    debugPrint('📄 Extensiones permitidas: $allowedExtensionsSet');

    for (final file in files) {
      final extension = file.path.split('.').last.toLowerCase();
      if (!allowedExtensionsSet.contains(extension)) {
        return false;
      }
    }

    return true;
  }

  List<String> _getAllowedExtensions() {
    return [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'dcm',
      'tiff',
      'bmp',
      'txt',
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterInformes(String query) {
    setState(() {
      if (query.isEmpty) {
        _informesFiltrados = List.from(_informes);
      } else {
        debugPrint('🔍 Filtrando informes por: "$query"');
        _informesFiltrados = _informes.where((informe) {
          final matchTitulo = informe.titulo.toLowerCase().contains(
            query.toLowerCase(),
          );
          final matchTipo = informe.tipoInforme.toLowerCase().contains(
            query.toLowerCase(),
          );
          return matchTitulo || matchTipo;
        }).toList();
        debugPrint(
          'Encontrados: ${_informesFiltrados.length} de ${_informes.length}',
        );
      }
      _sortInformes();
    });
  }

  void _sortInformes() {
    if (_sortOrder == 'reciente') {
      _informesFiltrados.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortOrder == 'antiguo') {
      _informesFiltrados.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortOrder == 'alfabetico') {
      _informesFiltrados.sort((a, b) => a.titulo.compareTo(b.titulo));
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ordenar por',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Más reciente'),
              trailing: _sortOrder == 'reciente'
                  ? const Icon(Icons.check, color: Color(0xFF2196F3))
                  : null,
              onTap: () {
                setState(() {
                  _sortOrder = 'reciente';
                  _sortInformes();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Más antiguo'),
              trailing: _sortOrder == 'antiguo'
                  ? const Icon(Icons.check, color: Color(0xFF2196F3))
                  : null,
              onTap: () {
                setState(() {
                  _sortOrder = 'antiguo';
                  _sortInformes();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Alfabético'),
              trailing: _sortOrder == 'alfabetico'
                  ? const Icon(Icons.check, color: Color(0xFF2196F3))
                  : null,
              onTap: () {
                setState(() {
                  _sortOrder = 'alfabetico';
                  _sortInformes();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    // Cargar usuario
    final user = await _authStorage.getUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      debugPrint('✅ Usuario cargado: ${user.nombre}');
      debugPrint(
        'RUN del usuario: ${user.run.isNotEmpty ? user.run : "VACÍO"}',
      );
    } else {
      debugPrint('⚠️ No se pudo cargar el usuario');
    }
  }

  Future<void> _loadInformes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      debugPrint('Cargando informes del usuario...');
      final informesData = await _apiService.getInformes(token);

      debugPrint('Informes recibidos: ${informesData.length}');

      final informes = informesData
          .map((data) => Informe.fromJson(data))
          .toList();

      setState(() {
        _informes.clear();
        _informes.addAll(informes);

        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text;
          _informesFiltrados = _informes.where((informe) {
            return informe.titulo.toLowerCase().contains(query.toLowerCase()) ||
                informe.tipoInforme.toLowerCase().contains(query.toLowerCase());
          }).toList();
        } else {
          _informesFiltrados = List.from(_informes);
        }

        _sortInformes();
        _isLoading = false;
      });

      debugPrint('Informes cargados en la UI: ${_informes.length}');
      debugPrint('Informes filtrados: ${_informesFiltrados.length}');
    } catch (e) {
      debugPrint('Error al cargar informes: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar informes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no identificado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que el usuario tenga RUN
    if (_currentUser!.run.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚠️ No se encontró tu RUN. Necesitas cerrar sesión y volver a iniciar sesión.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Ir a Configuración',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ),
        );
      }
      return;
    }

    debugPrint('Usuario actual: ${_currentUser!.nombre}');
    debugPrint('RUN del usuario: ${_currentUser!.run}');

    try {
      final allowedExtensions = _getAllowedExtensions();

      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (fileResult == null || fileResult.files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se seleccionaron archivos'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final files = fileResult.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudieron cargar los archivos seleccionados'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validar límite de archivos
      if (files.length > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Máximo 10 archivos por informe'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validar extensiones de archivo contra el backend
      if (!_validateFileExtensions(files)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Tipo de archivo no permitido. Extensiones válidas: ${allowedExtensions.join(", ")}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      List<TipoInforme> tiposInforme = [];
      try {
        final token = await _authStorage.getToken();
        if (token != null) {
          tiposInforme = await _apiService.getTiposInforme(token);
        }
      } catch (e) {
        debugPrint('Error fetching types: $e');
      }

      if (_currentUser!.tipoUsuario == 'Paciente') {
        try {
          final token = await _authStorage.getToken();
          if (token != null) {
            final profile = await _apiService.getUserProfile(token);
            final datosAnticoagulacion = profile['datos_anticoagulacion'];

            if (datosAnticoagulacion == null ||
                datosAnticoagulacion['mg_por_pastilla'] == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      '⚠️ Para crear informes de Control de Anticoagulación (TACO), '
                      'primero debes configurar tu tratamiento en tu perfil.',
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 7),
                    action: SnackBarAction(
                      label: 'Ir a Perfil',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ),
                );
              }
              return;
            }
          }
        } catch (e) {
          debugPrint('Error al verificar perfil médico: $e');
        }
      }

      final result = await _showInformeDialog(
        fileCount: files.length,
        tiposInforme: tiposInforme,
      );
      if (result == null) return;

      setState(() {
        _isUploading = true;
      });

      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      debugPrint('🔄 Enviando informe al servidor...');
      debugPrint('  Título: ${result['titulo']}');
      debugPrint('  Tipo: ${result['tipoInforme']}');
      debugPrint('  RUN Médico: ${result['runMedico']}');
      debugPrint('  Archivos: ${files.length}');

      final titulo = result['titulo'] as String? ?? '';
      final tipoInforme = result['tipoInforme'] as String? ?? '';
      final runMedico = result['runMedico'] as String? ?? '';
      final observaciones = result['observaciones'] as String? ?? '';
      final contenidoClinico =
          result['contenidoClinico'] as Map<String, dynamic>?;

      final informeData = await _apiService.createInforme(
        titulo: titulo,
        tipoInforme: tipoInforme,
        runMedico: runMedico,
        observaciones: observaciones,
        contenidoClinico: contenidoClinico,
        files: files,
        token: token,
      );

      debugPrint('Respuesta recibida del servidor');
      final nuevoInforme = Informe.fromJson(informeData);
      debugPrint('  Informe ID: ${nuevoInforme.id}');
      debugPrint('  Archivos guardados: ${nuevoInforme.archivos.length}');

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Informe "${nuevoInforme.titulo}" creado con ${nuevoInforme.archivos.length} archivo(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recargar la lista de informes desde el servidor
      await _loadInformes();
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear informe: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showInformeDialog({
    required int fileCount,
    required List<TipoInforme> tiposInforme,
  }) async {
    final tituloController = TextEditingController();
    final runMedicoController = TextEditingController();
    final observacionesController = TextEditingController();
    final inrController = TextEditingController();

    DateTime? fechaProximoControl;

    final List<String> opcionesDosis = [
      '0',
      '1/4',
      '1/2',
      '3/4',
      '1',
      '1 1/4',
      '1 1/2',
      '1 3/4',
      '2',
      '2 1/2',
      '3',
    ];

    final Map<String, String?> dosisSeleccionada = {
      'Lunes': null,
      'Martes': null,
      'Miércoles': null,
      'Jueves': null,
      'Viernes': null,
      'Sábado': null,
      'Domingo': null,
    };

    TipoInforme? selectedTipo;
    try {
      selectedTipo = tiposInforme.firstWhere(
        (t) => t.nombre == 'Control de Anticoagulación',
        orElse: () => tiposInforme.isNotEmpty
            ? tiposInforme.first
            : TipoInforme(id: '', nombre: 'Otro'),
      );
    } catch (e) {
      // Handle empty list
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isTaco = selectedTipo?.nombre == 'Control de Anticoagulación';

            return AlertDialog(
              title: const Text('Nuevo Informe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$fileCount archivo(s) seleccionado(s)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipoInforme>(
                      initialValue: selectedTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Informe *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: tiposInforme.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo.nombre),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedTipo = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Información General:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título del informe *',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Control Enero 2025',
                        prefixIcon: Icon(Icons.title),
                      ),
                      autofocus: false,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: runMedicoController,
                      decoration: const InputDecoration(
                        labelText: 'RUN del médico *',
                        border: OutlineInputBorder(),
                        hintText: '12345678-9',
                        prefixIcon: Icon(Icons.person),
                        helperText: 'RUN del médico que emitió el informe',
                        helperMaxLines: 2,
                      ),
                      keyboardType: TextInputType.text,
                      inputFormatters: [RutFormatter()],
                    ),
                    if (isTaco) ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: inrController,
                        decoration: const InputDecoration(
                          labelText: 'INR Actual (Ej: 2.5) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.speed),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 24),

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 7),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() => fechaProximoControl = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha Próximo Control *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month),
                          ),
                          child: Text(
                            fechaProximoControl != null
                                ? '${fechaProximoControl!.day}/${fechaProximoControl!.month}/${fechaProximoControl!.year}'
                                : 'Seleccionar fecha',
                            style: TextStyle(
                              color: fechaProximoControl != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Dosis Diaria (Pastillas):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...dosisSeleccionada.keys.map((dia) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  dia,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: dosisSeleccionada[dia],
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    hintText: 'Seleccionar',
                                  ),
                                  items: opcionesDosis.map((dosis) {
                                    return DropdownMenuItem(
                                      value: dosis,
                                      child: Text(dosis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(
                                      () => dosisSeleccionada[dia] = val,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Agrega notas adicionales si lo deseas',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedTipo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor selecciona un tipo de informe',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (tituloController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor ingresa un título para el informe',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (runMedicoController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa el RUN del médico'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Map<String, dynamic>? contenidoClinico;

                    if (isTaco) {
                      // 1. Validar INR
                      if (inrController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Debes ingresar el INR actual'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Validar rango de INR
                      final inrValue = double.tryParse(
                        inrController.text.replaceAll(',', '.'),
                      );
                      if (inrValue == null ||
                          inrValue < 0.5 ||
                          inrValue > 20.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El INR debe estar entre 0.5 y 20.0'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // 2. Validar Fecha Próximo Control
                      if (fechaProximoControl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Debes indicar la fecha del próximo control',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // 3. Recolectar Dosis (Usando el mapa de Strings)
                      final Map<String, String> dosisDiariaBackend = {};
                      bool hasDosis = false;

                      dosisSeleccionada.forEach((dia, valor) {
                        if (valor != null && valor.isNotEmpty) {
                          // Normalizar clave para el backend (lunes, martes...)
                          String key = dia
                              .toLowerCase()
                              .replaceAll('á', 'a')
                              .replaceAll('é', 'e')
                              .replaceAll('í', 'i')
                              .replaceAll('ó', 'o')
                              .replaceAll('ú', 'u');

                          dosisDiariaBackend[key] = valor;
                          hasDosis = true;
                        }
                      });

                      if (!hasDosis) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ingresa la dosis para al menos un día',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Construir objeto final
                      contenidoClinico = {
                        'inr_actual':
                            double.tryParse(
                              inrController.text.replaceAll(',', '.'),
                            ) ??
                            0.0,
                        'fecha_proximo_control': fechaProximoControl
                            ?.toIso8601String(),
                        'dosis_diaria': dosisDiariaBackend,
                      };
                    }

                    if (Navigator.canPop(context)) {
                      final retTitulo = tituloController.text.trim();
                      final retRun = cleanRut(runMedicoController.text);
                      final retObs = observacionesController.text.trim();

                      Navigator.pop(context, <String, dynamic>{
                        'titulo': retTitulo,
                        'tipoInforme': selectedTipo!.nombre,
                        'runMedico': retRun,
                        'observaciones': retObs,
                        'contenidoClinico': contenidoClinico,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear Informe'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _downloadFile(String path, String name) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      // Mostrar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Generando enlace de descarga...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Obtener extensión del archivo
      final extension = name.split('.').last;

      final url = await _apiService.getDownloadUrl(
        path: path,
        name: name.replaceAll('.$extension', ''),
        format: extension,
        token: token,
      );

      // Abrir archivo automáticamente en el navegador/visor del sistema
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abriendo archivo: $name'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('No se puede abrir el enlace');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadAllFiles(Informe informe) async {
    if (informe.archivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay archivos para descargar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación con opciones
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descargar archivos'),
        content: Text(
          '¿Deseas descargar los ${informe.archivos.length} archivo(s) de este informe?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Descargar todos los archivos
    for (var archivo in informe.archivos) {
      await _downloadFile(archivo.urlpath, archivo.nombre);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _showQRDialog(Informe informe) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Crear permiso público
      final permiso = await _apiService.createPermisoPublico(
        informeId: informe.id,
        token: token,
      );

      final shareUrl = permiso['Url'] as String? ?? permiso['url'] as String?;
      if (shareUrl == null) {
        throw Exception('No se pudo generar la URL de compartir');
      }

      if (mounted) Navigator.pop(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_2, color: Color(0xFF2196F3)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Compartir por QR',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: QrImageView(
                        data: shareUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      informe.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este QR expira en 90 minutos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Escanea este código para acceder al informe',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: shareUrl));
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('URL copiada al portapapeles'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar enlace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareDialog(Informe informe) {
    // Navegar a la pantalla de compartir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompartirInformeScreen(informe: informe.toJson()),
      ),
    ).then((_) {
      _loadInformes();
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildInformeCard(Informe informe) {
    // Obtener el icono del primer archivo para el preview
    final previewIcon = informe.archivos.isNotEmpty
        ? _getFileIcon(informe.archivos.first.nombre)
        : Icons.description_outlined;

    return GestureDetector(
      onTap: () => _showInformeDetail(informe),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview del archivo
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFBBDEFB),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  previewIcon,
                  size: 60,
                  color: const Color(0xFF64B5F6),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(informe.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          informe.titulo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInformeDetail(Informe informe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Contenido
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Título
                    Text(
                      informe.titulo,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tipo y fecha
                    Row(
                      children: [
                        Icon(
                          Icons.medical_information,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          informe.tipoInforme,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(informe.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Médico
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF2196F3)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Médico tratante',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'RUN: ${informe.runMedico}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (informe.contenidoClinico != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Control de Anticoagulación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (informe.contenidoClinico!.dosisSemanalMg !=
                                null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Dosis Semanal Total: ${informe.contenidoClinico!.dosisSemanalMg} mg',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Text(
                              'Dosis Diaria:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            ...informe.contenidoClinico!.dosisDiaria.entries
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key[0].toUpperCase() +
                                              entry.key.substring(1),
                                        ),
                                        Text('${entry.value} pastilla.'),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                    if (informe.observaciones != null &&
                        informe.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Observaciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          informe.observaciones!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Archivos
                    Row(
                      children: [
                        const Text(
                          'Archivos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${informe.archivos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...informe.archivos.map((archivo) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            _getFileIcon(archivo.nombre),
                            color: const Color(0xFF2196F3),
                            size: 32,
                          ),
                          title: Text(
                            archivo.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            archivo.formato.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            color: const Color(0xFF2196F3),
                            onPressed: () async {
                              await _downloadFile(
                                archivo.urlpath,
                                archivo.nombre,
                              );
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showQRDialog(informe);
                            },
                            icon: const Icon(Icons.qr_code),
                            label: const Text('QR'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2196F3),
                              side: const BorderSide(
                                color: Color(0xFF2196F3),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showShareDialog(informe);
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2196F3),
                              side: const BorderSide(
                                color: Color(0xFF2196F3),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _downloadAllFiles(informe);
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Descargar Todo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Informes',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showSortOptions,
            tooltip: 'Ordenar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadInformes,
            tooltip: 'Recargar',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final token = await _authStorage.getToken();
              if (!context.mounted) return;

              if (token == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes iniciar sesión para ver permisos'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PermisosCompartidosScreen(),
                ),
              );
            },
            tooltip: 'Permisos compartidos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando informes...'),
                ],
              ),
            )
          : _informes.isEmpty && !_isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay informes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primer informe médico',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Informe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Barra de búsqueda
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterInformes,
                    decoration: InputDecoration(
                      hintText: 'Buscar informes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterInformes('');
                              },
                            )
                          : null,
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
                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // Grid de informes
                Expanded(
                  child: _informesFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron informes',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _informesFiltrados.length,
                          itemBuilder: (context, index) {
                            final informe = _informesFiltrados[index];
                            return _buildInformeCard(informe);
                          },
                        ),
                ),
                if (_isUploading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Creando informe...'),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: _informes.isNotEmpty && !_isUploading
          ? FloatingActionButton.extended(
              onPressed: _pickAndUploadFile,
              backgroundColor: const Color(0xFF2196F3),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Informe'),
            )
          : null,
    );
  }
}

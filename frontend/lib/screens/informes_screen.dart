import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../models/informe_model.dart';
import '../models/user_model.dart';

class InformesScreen extends StatefulWidget {
  const InformesScreen({super.key});

  @override
  State<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends State<InformesScreen> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _isUploading = false;
  List<Informe> _informes = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authStorage.getUser();
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
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

    try {
      // Mostrar diálogo para ingresar información del informe
      final result = await _showInformeDialog();
      if (result == null) return;

      setState(() {
        _isUploading = true;
      });

      // Seleccionar archivos
      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (fileResult == null || fileResult.files.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final files = fileResult.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      // Obtener token
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      // Crear informe con archivos
      final informeData = await _apiService.createInforme(
        titulo: result['titulo']!,
        tipoInforme: result['tipoInforme']!,
        runMedico: result['runMedico']!,
        observaciones: result['observaciones'],
        files: files,
        token: token,
      );

      final nuevoInforme = Informe.fromJson(informeData);

      setState(() {
        _informes.add(nuevoInforme);
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Informe "${nuevoInforme.titulo}" creado con ${nuevoInforme.archivos.length} archivo(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear informe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, String>?> _showInformeDialog() async {
    final tituloController = TextEditingController();
    final runMedicoController = TextEditingController();
    final observacionesController = TextEditingController();
    String tipoInforme = 'Examen';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo Informe Médico'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingresa la información de tu informe médico',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título del informe *',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Examen de sangre - Enero 2025',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoInforme,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de informe *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_information),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Examen',
                          child: Text('Examen'),
                        ),
                        DropdownMenuItem(
                          value: 'Diagnostico',
                          child: Text('Diagnóstico'),
                        ),
                        DropdownMenuItem(
                          value: 'Receta',
                          child: Text('Receta'),
                        ),
                        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            tipoInforme = value;
                          });
                        }
                      },
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
                      ),
                      keyboardType: TextInputType.text,
                    ),
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
                    if (tituloController.text.trim().isEmpty ||
                        runMedicoController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor completa el título y el RUN del médico',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context, {
                      'titulo': tituloController.text.trim(),
                      'tipoInforme': tipoInforme,
                      'runMedico': runMedicoController.text.trim(),
                      'observaciones': observacionesController.text.trim(),
                    });
                  },
                  child: const Text('Continuar'),
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
      // Pequeña pausa entre descargas para no saturar
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _showShareDialog(Informe informe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Compartir Informe'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Funcionalidad en desarrollo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pronto podrás compartir tus informes con médicos de manera segura mediante:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('Seleccionar qué archivos compartir'),
            _buildFeatureItem('Elegir el período de acceso'),
            _buildFeatureItem('Compartir por correo electrónico'),
            _buildFeatureItem('Revocar acceso en cualquier momento'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta funcionalidad estará disponible próximamente',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _informes.isEmpty && !_isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_upload, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  Text(
                    'Subir Informes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestiona tus documentos médicos',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                    icon: const Icon(Icons.upload_file),
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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _informes.length,
                    itemBuilder: (context, index) {
                      final informe = _informes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2196F3),
                            child: const Icon(
                              Icons.folder_open,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            informe.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_information,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    informe.tipoInforme,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.attach_file,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${informe.archivos.length} archivo(s)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Médico: RUN ${informe.runMedico}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            // Información del informe
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Creado: ${_formatDate(informe.createdAt)}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (informe.observaciones != null &&
                                      informe.observaciones!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.note,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Observaciones:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            informe.observaciones!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Lista de archivos
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Archivos del informe:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...informe.archivos.map((archivo) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  _getFileIcon(archivo.nombre),
                                  color: const Color(0xFF2196F3),
                                ),
                                title: Text(
                                  archivo.nombre,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  archivo.formato,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadFile(
                                    archivo.urlpath,
                                    archivo.nombre,
                                  ),
                                  color: const Color(0xFF2196F3),
                                  tooltip: 'Descargar archivo',
                                ),
                              );
                            }).toList(),
                            const Divider(height: 1),
                            // Botones de acción
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _downloadAllFiles(informe),
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Descargar Todo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2196F3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _showShareDialog(informe),
                                    icon: const Icon(Icons.share, size: 18),
                                    label: const Text('Compartir'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2196F3),
                                      side: const BorderSide(
                                        color: Color(0xFF2196F3),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
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
}

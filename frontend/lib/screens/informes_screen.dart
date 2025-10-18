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
              title: const Text('Nuevo Informe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título del informe',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoInforme,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de informe',
                        border: OutlineInputBorder(),
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
                        labelText: 'RUN del médico',
                        border: OutlineInputBorder(),
                        hintText: '12345678-9',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        border: OutlineInputBorder(),
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
                    if (tituloController.text.isEmpty ||
                        runMedicoController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor complete los campos obligatorios',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context, {
                      'titulo': tituloController.text,
                      'tipoInforme': tipoInforme,
                      'runMedico': runMedicoController.text,
                      'observaciones': observacionesController.text,
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
                            ],
                          ),
                          children: [
                            if (informe.observaciones != null &&
                                informe.observaciones!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  8,
                                ),
                                child: Container(
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
                                      const Text(
                                        'Observaciones:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        informe.observaciones!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const Divider(height: 1),
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
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => _downloadFile(
                                    archivo.urlpath,
                                    archivo.nombre,
                                  ),
                                  color: const Color(0xFF2196F3),
                                  tooltip: 'Abrir archivo',
                                ),
                              );
                            }).toList(),
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

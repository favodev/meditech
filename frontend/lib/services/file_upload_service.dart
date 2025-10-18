import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class FileUploadHelper {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  /// Permite seleccionar un archivo del dispositivo
  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      return null;
    }
  }

  /// Sube un archivo al backend
  /// [destination] es la carpeta donde se guardará en GCS (ej: 'informes', 'perfiles', etc.)
  Future<String?> uploadFile(File file, String destination) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final filePath = await _apiService.uploadFile(
        file: file,
        destination: destination,
        token: token,
      );

      return filePath;
    } catch (e) {
      print('Error al subir archivo: $e');
      rethrow;
    }
  }

  /// Obtiene una URL firmada para descargar un archivo
  Future<String?> getDownloadUrl({
    required String path,
    required String name,
    required String format,
  }) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = await _apiService.getDownloadUrl(
        path: path,
        name: name,
        format: format,
        token: token,
      );

      return url;
    } catch (e) {
      print('Error al obtener URL de descarga: $e');
      rethrow;
    }
  }

  /// Obtiene una URL firmada para visualizar/abrir un archivo
  Future<String?> getOpenUrl(String path) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = await _apiService.getOpenUrl(path: path, token: token);

      return url;
    } catch (e) {
      print('Error al obtener URL: $e');
      rethrow;
    }
  }
}

/// Widget de ejemplo para subir archivos
class FileUploadWidget extends StatefulWidget {
  final String destination; // Carpeta de destino en GCS
  final Function(String filePath) onUploadSuccess;
  final List<String>? allowedExtensions; // ej: ['pdf', 'jpg', 'png']

  const FileUploadWidget({
    super.key,
    required this.destination,
    required this.onUploadSuccess,
    this.allowedExtensions,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final FileUploadHelper _uploadHelper = FileUploadHelper();
  bool _isUploading = false;
  String? _uploadedFilePath;

  Future<void> _handleFileUpload() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Seleccionar archivo
      final file = await _uploadHelper.pickFile(
        allowedExtensions: widget.allowedExtensions,
      );

      if (file == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Subir archivo
      final filePath = await _uploadHelper.uploadFile(file, widget.destination);

      if (filePath != null) {
        setState(() {
          _uploadedFilePath = filePath;
          _isUploading = false;
        });

        widget.onUploadSuccess(filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo subido exitosamente')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir archivo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _handleFileUpload,
          icon: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: Text(_isUploading ? 'Subiendo...' : 'Seleccionar archivo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_uploadedFilePath != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Archivo subido: ${_uploadedFilePath!.split('/').last}',
                    style: TextStyle(color: Colors.green[900], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

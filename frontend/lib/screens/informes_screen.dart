import 'dart:io';
import 'package:flutter/material.dart';
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
    if (widget.initialFilter != null) {
      _searchController.text = widget.initialFilter!;
    }
    _loadUserData();
    _loadInformes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- CARGA DE DATOS ---

  Future<void> _loadUserData() async {
    final user = await _authStorage.getUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _loadInformes() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authStorage.getToken();
      if (token == null) throw Exception("Sin sesión");

      final data = await _apiService.getInformes(token);
      final lista = data.map((json) => Informe.fromJson(json)).toList();

      setState(() {
        _informes.clear();
        _informes.addAll(lista);
        _filterInformes(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _filterInformes(String query) {
    if (query.isEmpty) {
      _informesFiltrados = List.from(_informes);
    } else {
      _informesFiltrados = _informes.where((i) =>
          i.titulo.toLowerCase().contains(query.toLowerCase()) ||
          i.tipoInforme.toLowerCase().contains(query.toLowerCase())).toList();
    }
    _sortInformes();
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

  // --- CREACIÓN DE INFORME ---

  Future<void> _pickAndUploadFile() async {
    if (_currentUser == null) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final files = result.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();

      // Cargar tipos
      List<TipoInforme> tipos = [];
      final token = await _authStorage.getToken();
      if (token != null) {
        try {
          tipos = await _apiService.getTiposInforme(token);
        } catch (_) {}
      }

      // Diálogo
      final formData = await _showInformeDialog(
        fileCount: files.length,
        tiposInforme: tipos,
      );

      if (formData == null) return;

      setState(() => _isUploading = true);

      // Lógica de Roles
      final isPaciente = _currentUser!.tipoUsuario == 'Paciente';
      final runTarget = formData['runTarget'];
      
      await _apiService.createInforme(
        titulo: formData['titulo'],
        tipoInforme: formData['tipoInforme'],
        runMedico: isPaciente ? runTarget : null,
        runPaciente: !isPaciente ? runTarget : null,
        observaciones: formData['observaciones'],
        contenidoClinico: formData['contenidoClinico'],
        files: files,
        token: token!,
      );

      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Informe creado'), backgroundColor: Colors.green));
        _loadInformes();
      }

    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // --- DIÁLOGO DE FORMULARIO CON ÍCONOS ---

  Future<Map<String, dynamic>?> _showInformeDialog({
    required int fileCount,
    required List<TipoInforme> tiposInforme,
  }) async {
    final tituloCtrl = TextEditingController();
    final runCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final inrCtrl = TextEditingController();

    TipoInforme? selectedTipo;
    try {
      selectedTipo = tiposInforme.firstWhere((t) => t.nombre == 'Control de Anticoagulación', orElse: () => tiposInforme.first);
    } catch (_) {}

    // Estado visual para dosis (Strings: "0", "1/4", "1/2", "3/4", "1")
    final Map<String, String> dosisMap = {
      'Lunes': '0', 'Martes': '0', 'Miércoles': '0', 'Jueves': '0', 
      'Viernes': '0', 'Sábado': '0', 'Domingo': '0'
    };
    final opciones = ['0', '1/4', '1/2', '3/4', '1'];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isTaco = selectedTipo?.nombre == 'Control de Anticoagulación';
          final isPaciente = _currentUser?.tipoUsuario == 'Paciente';

          return AlertDialog(
            title: const Text('Nuevo Informe'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.green[50],
                    child: Row(children: [
                      const Icon(Icons.attach_file, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('$fileCount archivos seleccionados')
                    ]),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<TipoInforme>(
                    value: selectedTipo,
                    decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                    items: tiposInforme.map((t) => DropdownMenuItem(value: t, child: Text(t.nombre))).toList(),
                    onChanged: (val) => setState(() => selectedTipo = val),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: runCtrl,
                    decoration: InputDecoration(
                      labelText: isPaciente ? 'RUN Médico *' : 'RUN Paciente *',
                      border: const OutlineInputBorder(),
                    ),
                    inputFormatters: [RutFormatter()],
                  ),

                  // SECCIÓN TACO VISUAL
                  if (isTaco) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const Text('Datos Clínicos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: inrCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'INR Actual *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bloodtype)
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Dosis Diaria:', style: TextStyle(fontWeight: FontWeight.w500)),
                    
                    // Tabla Visual de Círculos
                    Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {0: FixedColumnWidth(70)},
                      children: dosisMap.keys.map((dia) {
                        return TableRow(children: [
                          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(dia, style: const TextStyle(fontSize: 12))),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: opciones.map((op) {
                              final selected = dosisMap[dia] == op;
                              return InkWell(
                                onTap: () => setState(() => dosisMap[dia] = op),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Column(children: [
                                    _buildPillIcon(op, selected),
                                    if(selected) Text(op, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                                  ]),
                                ),
                              );
                            }).toList(),
                          )
                        ]);
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextField(
                    controller: obsCtrl,
                    decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  // Validaciones
                  if (tituloCtrl.text.isEmpty || runCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltan campos'))); return;
                  }

                  Map<String, dynamic>? contenidoClinico;
                  if (isTaco) {
                    final inr = double.tryParse(inrCtrl.text.replaceAll(',', '.'));
                    if (inr == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('INR inválido'))); return;
                    }
                    
                    // Normalizar llaves para backend
                    final Map<String, String> dosisBackend = {};
                    dosisMap.forEach((k, v) {
                      final key = k.toLowerCase()
                          .replaceAll('á', 'a').replaceAll('é', 'e')
                          .replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');
                      dosisBackend[key] = v;
                    });

                    contenidoClinico = {
                      'inr_actual': inr,
                      'dosis_diaria': dosisBackend
                    };
                  }

                  Navigator.pop(context, <String, dynamic>{
                    'titulo': tituloCtrl.text.trim(),
                    'tipoInforme': selectedTipo!.nombre,
                    'runTarget': cleanRut(runCtrl.text),
                    'observaciones': obsCtrl.text.trim(),
                    'contenidoClinico': contenidoClinico,
                  });
                },
                child: const Text('Crear'),
              )
            ],
          );
        }
      ),
    );
  }

  // --- VISUALIZACIÓN ---

  void _showInformeDetail(Informe informe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, ctrl) => Container(
          color: Colors.white,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Text(informe.titulo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Tipo: ${informe.tipoInforme}'),
              const SizedBox(height: 20),

              // DATOS TACO VISUALIZACIÓN
              if (informe.contenidoClinico != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INR: ${informe.contenidoClinico!.inrActual}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      if (informe.contenidoClinico!.dosisSemanalMg != null)
                        Text('Dosis Semanal: ${informe.contenidoClinico!.dosisSemanalMg} mg', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Tabla visual de lectura usando los mismos íconos
                      ...informe.contenidoClinico!.dosisDiaria.entries.map((e) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key.toUpperCase()),
                          Row(children: [
                            _buildStaticPillIcon(e.value), // Usa el helper estático
                            const SizedBox(width: 8),
                            Text('${e.value}'),
                          ])
                        ],
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Archivos
              ...informe.archivos.map((f) => ListTile(
                leading: const Icon(Icons.file_present),
                title: Text(f.nombre),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(f.urlpath, f.nombre),
                ),
              )),
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: ()=> _showQRDialog(informe), child: const Text('Ver QR'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: ()=> _showShareDialog(informe), child: const Text('Compartir'))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS VISUALES ---

  Widget _buildPillIcon(String val, bool selected) {
    IconData icon;
    Color color = selected ? const Color(0xFF2196F3) : Colors.grey[300]!;
    
    // Normalización por si acaso
    if (val == '0.25') val = '1/4';
    if (val == '0.5') val = '1/2';
    if (val == '0.75') val = '3/4';
    if (val == '1.0') val = '1';

    switch (val) {
      case '0': icon = Icons.radio_button_unchecked; break;
      case '1/4': return Transform.rotate(angle: 1.57, child: Icon(Icons.pie_chart, color: color, size: 28));
      case '1/2': icon = Icons.contrast; break;
      case '3/4': icon = Icons.data_usage; break;
      case '1': icon = Icons.circle; break;
      default: icon = Icons.radio_button_unchecked;
    }
    return Icon(icon, color: color, size: 28);
  }

  Widget _buildStaticPillIcon(dynamic valor) {
    return _buildPillIcon(valor.toString(), true);
  }

  Future<void> _downloadFile(String path, String name) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) return;
      final ext = name.split('.').last;
      final url = await _apiService.getDownloadUrl(path: path, name: name, format: ext, token: token);
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showQRDialog(Informe informe) async {
    final token = await _authStorage.getToken();
    if (token == null) return;
    try {
      final res = await _apiService.createPermisoPublico(informeId: informe.id, token: token);
      final url = res['Url'] ?? res['url'];
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          content: SizedBox(height: 250, width: 250, child: QrImageView(data: url)),
          actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cerrar'))]
        ));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showShareDialog(Informe informe) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CompartirInformeScreen(informe: informe.toJson())));
  }

  Widget _buildInformeCard(Informe informe) {
    return Card(
      child: InkWell(
        onTap: () => _showInformeDetail(informe),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 48, color: Colors.blue[300]),
            const SizedBox(height: 8),
            Text(informe.titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(informe.tipoInforme, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {} // Implementar lógica de orden si se desea
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informes')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _informes.isEmpty 
          ? const Center(child: Text('No hay informes')) 
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _informesFiltrados.length,
              itemBuilder: (c, i) => _buildInformeCard(_informesFiltrados[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}
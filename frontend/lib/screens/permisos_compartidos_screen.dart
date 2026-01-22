import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

import 'package:meditech/screens/edit_shared_report_screen.dart';
import 'informes_screen.dart';
import '../services/auth_storage.dart';

class PermisosCompartidosScreen extends StatefulWidget {
  final VoidCallback? onCreateInforme;
  const PermisosCompartidosScreen({super.key, this.onCreateInforme});

  @override
  State<PermisosCompartidosScreen> createState() =>
      _PermisosCompartidosScreenState();
}

class _PermisosCompartidosScreenState extends State<PermisosCompartidosScreen> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _isLoading = true;
  List<dynamic> _permisos = [];
  bool _isMedico = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadPermisos();
  }

  Future<void> _loadUserRole() async {
    final user = await _authStorage.getUser();
    if (mounted && user != null) {
      setState(() {
        _isMedico = user.tipoUsuario == 'Medico';
      });
    }
  }

  Future<void> _loadPermisos() async {
    try {
      setState(() => _isLoading = true);

      final token = await _authStorage.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final permisos = await _apiService.getPermisosCompartidos(token);

      setState(() {
        _permisos = permisos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar permisos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _revocarPermiso(String permisoId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revocar Acceso'),
        content: const Text(
          '¿Estás seguro que deseas revocar el acceso a este informe?',
        ),
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
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _authStorage.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      await _apiService.revocarPermiso(token, permisoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Acceso revocado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Actualizar el estado local
        setState(() {
          _permisos[index]['activo'] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarPermiso(String permisoId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Permiso'),
        content: const Text(
          '¿Estás seguro que deseas eliminar permanentemente este permiso?',
        ),
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _authStorage.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      await _apiService.deletePermiso(token, permisoId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Permiso eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Eliminar del estado local
        setState(() {
          _permisos.removeAt(index);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Compartidos Conmigo',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPermisos,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _permisos.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No hay informes compartidos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los pacientes pueden compartir sus informes contigo para que puedas revisarlos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    if (_isMedico && widget.onCreateInforme != null)
                      ElevatedButton.icon(
                        onPressed: widget.onCreateInforme,
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Informe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPermisos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _permisos.length,
                itemBuilder: (context, index) {
                  final permiso = _permisos[index];
                  final informe = permiso['informe'] ?? {};
                  final activo = permiso['activo'] ?? true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título e estado
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      informe['titulo'] ?? 'Sin título',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      informe['tipo_informe'] ?? 'Sin tipo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: activo
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  activo ? 'ACTIVO' : 'REVOCADO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: activo
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // Información del permiso
                          _buildInfoRow(
                            Icons.person,
                            'Paciente',
                            'RUN: ${permiso['run_paciente'] ?? 'N/A'}',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.security,
                            'Nivel de acceso',
                            ((permiso['nivel_acceso'] as String?) ?? 'N/A')
                                .toUpperCase(),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Compartido',
                            _formatDate(permiso['createdAt']),
                          ),
                          if (permiso['fecha_limite'] != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.event_busy,
                              'Expira',
                              _formatDate(permiso['fecha_limite']),
                            ),
                          ],
                          if (informe['archivos'] != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.attach_file,
                              'Archivos',
                              '${(informe['archivos'] as List).length} archivo(s)',
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Botones de acción
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showInformeDetails(
                                    informe,
                                    permiso,
                                    index,
                                  ),
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Abrir'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _isMedico && widget.onCreateInforme != null
          ? FloatingActionButton.extended(
              onPressed: widget.onCreateInforme,
              backgroundColor: const Color(0xFF2196F3),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Informe'),
            )
          : null,
    );
  }

  void _showInformeDetails(
    Map<String, dynamic> informe,
    dynamic permiso,
    int index,
  ) async {
    // Check access level for editing
    final nivelAcceso = ((permiso['nivel_acceso'] as String?) ?? '')
        .toLowerCase();
    final canEdit =
        nivelAcceso == 'escritura' || nivelAcceso == 'administracion';

    await showModalBottomSheet(
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            informe['titulo'] ?? 'Sin Título',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (canEdit)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context); // Close sheet
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditSharedReportScreen(
                                        informe: informe,
                                        permisoId: permiso['_id'],
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadPermisos(); // Reload to see changes
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar',
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await _eliminarPermiso(permiso['_id'], index);
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.medical_information, size: 16),
                        const SizedBox(width: 4),
                        Text(informe['tipo_informe'] ?? 'Desconocido'),
                        const SizedBox(width: 16),
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 4),
                        Text('Paciente: ${permiso['run_paciente']}'),
                      ],
                    ),
                    const Divider(height: 32),
                    if (informe['observaciones'] != null) ...[
                      const Text(
                        'Observaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(informe['observaciones']),
                      const SizedBox(height: 24),
                    ],
                    if (informe['archivos'] != null) ...[
                      const Text(
                        'Archivos Adjuntos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(informe['archivos'] as List).map((archivo) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.description,
                              color: Colors.blue,
                            ),
                            title: Text(archivo['nombre']),
                            subtitle: Text(archivo['tipo'] ?? 'Documento'),
                            trailing: IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () => _downloadFile(
                                archivo['urlpath'],
                                archivo['nombre'],
                                archivo['formato'],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFile(String path, String name, String format) async {
    try {
      final token = await _authStorage.getToken();
      if (token == null) return;

      final url = await _apiService.getDownloadUrl(
        path: path,
        name: name,
        format: format,
        token: token,
      );

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir la URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir archivo: $e')));
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

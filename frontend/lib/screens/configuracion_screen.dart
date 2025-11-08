import 'package:flutter/material.dart';
import '../services/auth_storage.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final AuthStorage _authStorage = AuthStorage();
  bool _is2FAEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  Future<void> _load2FAStatus() async {
    try {
      final user = await _authStorage.getUser();
      if (mounted) {
        setState(() {
          _is2FAEnabled = user?.isTwoFactorEnabled ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF2196F3)),
                  title: const Text('Perfil'),
                  subtitle: const Text('Ver y editar tu información'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.pushNamed(context, '/profile');
                    _load2FAStatus();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock, color: Color(0xFF2196F3)),
                  title: const Text('Cambiar Contraseña'),
                  subtitle: const Text('Actualiza tu contraseña'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/change-password');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.security,
                    color: _is2FAEnabled
                        ? Colors.green
                        : const Color(0xFF2196F3),
                  ),
                  title: const Text('Autenticación de Dos Factores (2FA)'),
                  subtitle: Text(
                    _is2FAEnabled
                        ? '✓ Activado - Tu cuenta está protegida'
                        : 'Protege tu cuenta con verificación adicional',
                    style: TextStyle(
                      color: _is2FAEnabled ? Colors.green : null,
                      fontWeight: _is2FAEnabled ? FontWeight.w500 : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_is2FAEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'ON',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.pushNamed(context, '/2fa-methods');
                    _load2FAStatus();
                  },
                ),
                const Divider(),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Cerrar Sesión'),
                          content: const Text(
                            '¿Estás seguro que deseas cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Cerrar Sesión'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _authStorage.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

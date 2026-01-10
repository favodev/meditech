import 'package:flutter/material.dart';
import '../services/auth_storage.dart';

class TwoFactorMethodsScreen extends StatefulWidget {
  const TwoFactorMethodsScreen({super.key});

  @override
  State<TwoFactorMethodsScreen> createState() => _TwoFactorMethodsScreenState();
}

class _TwoFactorMethodsScreenState extends State<TwoFactorMethodsScreen> {
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

  Future<void> _disable2FA() async {
    // Mostrar confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desactivar 2FA'),
        content: const Text(
          '¿Estás seguro que deseas desactivar la autenticación de dos factores?\n\nTu cuenta será menos segura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authStorage.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      throw Exception('Función no disponible aún en el backend');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Autenticación de Dos Factores',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _is2FAEnabled
          ? _build2FAEnabledView()
          : _buildMethodSelectionView(),
    );
  }

  Widget _build2FAEnabledView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono de éxito
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),

            // Título
            const Text(
              '2FA Activado',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            const Text(
              'Tu cuenta está protegida con autenticación de dos factores',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Card informativa
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code,
                          color: Color(0xFF2196F3),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Método Activo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'App Autenticadora',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Cada vez que inicies sesión, necesitarás:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCheckItem('Tu contraseña'),
                    _buildCheckItem('Código de 6 dígitos de tu app'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _disable2FA,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Desactivar 2FA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildMethodSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          const Text(
            'Elige tu método de autenticación',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona cómo quieres verificar tu identidad',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 32),

          _buildMethodCard(
            icon: Icons.qr_code_2,
            iconColor: const Color(0xFF2196F3),
            title: 'App de Autenticación',
            subtitle: 'Google Authenticator, Microsoft Authenticator, Authy',
            description:
                'Genera códigos de 6 dígitos que cambian cada 30 segundos',
            isRecommended: true,
            isAvailable: true,
            onTap: () {
              Navigator.pushNamed(context, '/setup-2fa');
            },
          ),
          const SizedBox(height: 16),

          _buildMethodCard(
            icon: Icons.sms,
            iconColor: Colors.grey,
            title: 'Mensaje de Texto (SMS)',
            subtitle: 'Recibe un código por SMS',
            description: 'Te enviaremos un código de 6 dígitos a tu teléfono',
            isRecommended: false,
            isAvailable: false,
            onTap: null,
          ),
          const SizedBox(height: 16),

          _buildMethodCard(
            icon: Icons.email,
            iconColor: Colors.grey,
            title: 'Correo Electrónico',
            subtitle: 'Recibe un código por email',
            description:
                'Te enviaremos un código de 6 dígitos a tu correo registrado',
            isRecommended: false,
            isAvailable: false,
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required bool isRecommended,
    required bool isAvailable,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: isAvailable ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? null : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAvailable)
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF2196F3),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isAvailable ? Colors.grey[700] : Colors.grey[400],
                    ),
                  ),
                  if (!isAvailable) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Próximamente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isRecommended)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RECOMENDADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

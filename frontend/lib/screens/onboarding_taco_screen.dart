import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class OnboardingTacoScreen extends StatefulWidget {
  const OnboardingTacoScreen({super.key});

  @override
  State<OnboardingTacoScreen> createState() => _OnboardingTacoScreenState();
}

class _OnboardingTacoScreenState extends State<OnboardingTacoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _isLoading = false;

  // Valores por defecto
  String _medicamento = 'Acenocumarol';
  final TextEditingController _mgController = TextEditingController(text: '4');
  final TextEditingController _minInrController = TextEditingController(text: '2.0');
  final TextEditingController _maxInrController = TextEditingController(text: '3.0');
  final TextEditingController _diagnosticoController = TextEditingController();

  @override
  void dispose() {
    _mgController.dispose();
    _minInrController.dispose();
    _maxInrController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }

  void _updateMgPorDefecto(String medicamento) {
    setState(() {
      _medicamento = medicamento;
      if (medicamento == 'Acenocumarol') {
        _mgController.text = '4';
      } else if (medicamento == 'Warfarina') {
        _mgController.text = '5';
      }
    });
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authStorage.getToken();
      if (token == null) throw Exception('No hay sesión activa');

      final Map<String, dynamic> datosAnticoagulacion = {
        'medicamento': _medicamento,
        'mg_por_pastilla': double.parse(_mgController.text.replaceAll(',', '.')),
        'rango_meta': {
          'min': double.parse(_minInrController.text.replaceAll(',', '.')),
          'max': double.parse(_maxInrController.text.replaceAll(',', '.'))
        },
        'diagnostico_base': _diagnosticoController.text.trim().isNotEmpty 
            ? _diagnosticoController.text.trim() 
            : null,
        'fecha_inicio_tratamiento': DateTime.now().toIso8601String(),
      };

      await _apiService.updateMyProfile(token, {
        'datos_anticoagulacion': datosAnticoagulacion
      });

      // IMPORTANTE: Actualizar el usuario localmente para que el splash no lo mande de vuelta aquí
      await _authStorage.reloadUserFromToken();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Configuración del Tratamiento'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Para activar tu Carnet Digital, necesitamos saber los detalles de tu tratamiento.',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('¿Qué medicamento tomas?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Acenocumarol'),
                          subtitle: const Text('Neo-Sintrom', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          value: 'Acenocumarol',
                          groupValue: _medicamento,
                          activeColor: const Color(0xFF2196F3),
                          onChanged: (val) => _updateMgPorDefecto(val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Warfarina'),
                          subtitle: const Text('Coumadin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          value: 'Warfarina',
                          groupValue: _medicamento,
                          activeColor: const Color(0xFF2196F3),
                          onChanged: (val) => _updateMgPorDefecto(val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Miligramos por pastilla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _mgController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Ej: 4',
                      suffixText: 'mg',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      final n = double.tryParse(value.replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('Rango Meta de INR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minInrController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Mínimo', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('-')),
                      Expanded(
                        child: TextFormField(
                          controller: _maxInrController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Máximo', border: OutlineInputBorder()),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final min = double.tryParse(_minInrController.text.replaceAll(',', '.'));
                            final max = double.tryParse(v.replaceAll(',', '.'));
                            if (min != null && max != null && min >= max) return 'Debe ser mayor al mínimo';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarConfiguracion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar y Comenzar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
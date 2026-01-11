import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ShareWithDoctorDialog extends StatefulWidget {
  final String reportId;
  const ShareWithDoctorDialog({super.key, required this.reportId});

  @override
  State<ShareWithDoctorDialog> createState() => _ShareWithDoctorDialogState();
}

class _ShareWithDoctorDialogState extends State<ShareWithDoctorDialog> {
  final _runController = TextEditingController();
  int _selectedDays = 30;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _submitSharing() async {
    if (_runController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final success = await _apiService.shareReportFormal(
        _runController.text.trim(),
        widget.reportId,
        _selectedDays,
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Acceso concedido exitosamente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al compartir informe. Verifique el RUN.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compartir con Profesional'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _runController,
            decoration: const InputDecoration(
              labelText: 'RUN del Médico',
              hintText: '12.345.678-9',
            ),
          ),
          const SizedBox(height: 20),
          DropdownButton<int>(
            value: _selectedDays,
            items: const [
              DropdownMenuItem(value: 30, child: Text('30 días')),
              DropdownMenuItem(value: 180, child: Text('6 meses')),
              DropdownMenuItem(value: 365, child: Text('1 año')),
            ],
            onChanged: (val) => setState(() => _selectedDays = val!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitSharing,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmar Acceso'),
        ),
      ],
    );
  }
}

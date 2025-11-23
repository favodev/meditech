import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();

  bool _isLoading = true;
  Map<String, dynamic>? _statsData;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        // Llamamos al endpoint que ya tienes listo en el backend
        final data = await _apiService.getEstadisticas(token);
        if (mounted) {
          setState(() {
            _statsData = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Seguimiento TACO',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isLoading ? null : _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tarjeta Principal (La misma del Home)
                  _buildTTRCard(),

                  const SizedBox(height: 24),

                  // 2. Título del Historial
                  const Text(
                    'Historial de Evolución',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Lista de Mediciones (Aprovechando el backend)
                  _buildHistoryList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTTRCard() {
    if (_statsData == null || _statsData!.isEmpty) {
      return _buildEmptyState();
    }

    final ttr = _statsData!['ttr_porcentaje'] ?? 0;
    final total = _statsData!['total_controles'] ?? 0;
    final isGood = ttr >= 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGood ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGood
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo en Rango (TTR)',
                    style: TextStyle(
                      color: isGood ? Colors.green[900] : Colors.orange[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$ttr%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isGood ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                  if (_statsData!['rango_meta'] != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Meta INR: ${_statsData!['rango_meta']['min']} - ${_statsData!['rango_meta']['max']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isGood
                              ? Colors.green[800]
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  // ----------------------------------------
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  isGood ? Icons.trending_up : Icons.warning_amber_rounded,
                  size: 32,
                  color: isGood ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: ttr / 100,
            backgroundColor: Colors.white,
            color: isGood ? Colors.green : Colors.orange,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 12),
          Text(
            'Basado en tus últimos $total controles',
            style: TextStyle(
              color: isGood ? Colors.green[800] : Colors.orange[800],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final historial = _statsData?['historial_grafico'] as List?;

    if (historial == null || historial.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay datos históricos suficientes.'),
      );
    }

    // Invertimos la lista para ver lo más reciente arriba
    final historialReverso = List.from(historial.reversed);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historialReverso.length,
      itemBuilder: (context, index) {
        final item = historialReverso[index];
        final double inr = (item['inr'] as num).toDouble();
        final String estado =
            item['estado'] ?? 'meta'; // 'bajo', 'meta', 'alto'
        final DateTime fecha = DateTime.parse(item['fecha']);

        Color colorEstado;
        IconData iconEstado;
        String textoEstado;

        if (estado == 'meta') {
          colorEstado = Colors.green;
          iconEstado = Icons.check_circle;
          textoEstado = 'En Rango';
        } else if (estado == 'bajo') {
          colorEstado = Colors.blue; // Sangre espesa
          iconEstado = Icons.arrow_downward;
          textoEstado = 'Bajo';
        } else {
          colorEstado = Colors.red; // Sangre líquida
          iconEstado = Icons.arrow_upward;
          textoEstado = 'Alto';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconEstado, color: colorEstado, size: 20),
            ),
            title: Text(
              'INR: $inr',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              '${fecha.day}/${fecha.month}/${fecha.year}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                textoEstado,
                style: TextStyle(
                  color: colorEstado,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.insights, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sin datos suficientes',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Crea informes de tipo "Control de Anticoagulación" para ver tu progreso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

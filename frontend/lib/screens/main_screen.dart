import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'informes_screen.dart';
import 'configuracion_screen.dart';
import 'qr_scanner_screen.dart';
import 'estadisticas_screen.dart';
import '../services/auth_storage.dart';
import '../services/api_service.dart';
import '../utils/rut_formatter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final AuthStorage _authStorage = AuthStorage();
  final ApiService _apiService = ApiService();
  final TextEditingController _runPacienteController = TextEditingController();
  final TextEditingController _inrController = TextEditingController();

  int _selectedIndex = 0;
  late TabController _tabController;
  String? _informesFilter;
  Key _informesKey = UniqueKey();
  bool _isMedico = false;

  void _navigateToInformes([String? filter]) {
    debugPrint('📍 MainScreen: Navegando a Informes con filtro: "$filter"');
    setState(() {
      _informesFilter = filter;
      _informesKey = UniqueKey();
    });
    _onItemTapped(2);
  }

  List<Widget> get _screens => [
    HomeScreen(onNavigateToInformes: _navigateToInformes),
    const QRScannerScreen(),
    InformesScreen(key: _informesKey, initialFilter: _informesFilter),
    const EstadisticasScreen(),
    const ConfiguracionScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadUserRole();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _runPacienteController.dispose();
    _inrController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = await _authStorage.getUser();
    if (user != null && mounted) {
      setState(() {
        _isMedico = user.tipoUsuario == 'Medico';
      });
    }
  }

  void _onItemTapped(int index) {
    if (_isMedico && index == 3) {
      _openTtrModal();
      return;
    }

    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  Future<void> _openTtrModal() async {
    _runPacienteController.clear();
    _inrController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        double? ttrIntervalo;
        String? infoMessage;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleCalculate() async {
              final runRaw = _runPacienteController.text.trim();
              final runClean = cleanRut(runRaw);
              final inrRaw = _inrController.text.trim().replaceAll(',', '.');
              final inrValue = double.tryParse(inrRaw);

              if (runClean.isEmpty || runClean.length < 7 || runClean.length > 10) {
                setStateDialog(() {
                  errorText = 'Ingrese un RUN válido';
                  ttrIntervalo = null;
                  infoMessage = null;
                });
                return;
              }

              if (inrValue == null || inrValue <= 0) {
                setStateDialog(() {
                  errorText = 'Ingrese un INR válido (> 0)';
                  ttrIntervalo = null;
                  infoMessage = null;
                });
                return;
              }

              setStateDialog(() {
                isLoading = true;
                errorText = null;
              });

              try {
                final result = await _apiService.calcularTtrIntervalo(
                  inrValue,
                  runPaciente: runClean,
                );

                final value = result['ttr_intervalo'];
                setStateDialog(() {
                  ttrIntervalo = value is num ? value.toDouble() : null;
                  infoMessage = result['mensaje'] as String?;
                  errorText = null;
                });
              } catch (e) {
                setStateDialog(() {
                  errorText = 'Error al calcular TTR: $e';
                  ttrIntervalo = null;
                  infoMessage = null;
                });
              } finally {
                setStateDialog(() {
                  isLoading = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Calcular TTR'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _runPacienteController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [RutFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'RUN del paciente',
                        hintText: '12.345.678-9',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _inrController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'INR actual',
                        hintText: 'Ej: 2.5',
                        prefixIcon: Icon(Icons.calculate),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (ttrIntervalo != null || infoMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2196F3).withOpacity(0.1),
                              const Color(0xFF1976D2).withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2196F3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TTR Intervalo',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ttrIntervalo != null
                                  ? '${ttrIntervalo!.toStringAsFixed(2)}%'
                                  : 'Sin datos previos para calcular',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: ttrIntervalo != null
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey[700],
                              ),
                            ),
                            if (infoMessage != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                infoMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleCalculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Calcular TTR'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home
                Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home,
                          color: _selectedIndex == 0
                              ? const Color(0xFF2196F3)
                              : Colors.grey,
                        ),
                        Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedIndex == 0
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Informes
                Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_upload,
                          color: _selectedIndex == 2
                              ? const Color(0xFF2196F3)
                              : Colors.grey,
                        ),
                        Text(
                          'Informes',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedIndex == 2
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // QR Scanner
                Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: const Color(0xFF2196F3),
                        ),
                        Text(
                          'Escanear',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedIndex == 1
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Seguimiento / TTR
                Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMedico ? Icons.calculate : Icons.insights,
                          color: _selectedIndex == 3
                              ? const Color(0xFF2196F3)
                              : Colors.grey,
                        ),
                        Text(
                          _isMedico ? 'TTR' : 'Seguimiento',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedIndex == 3
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Configuración
                Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings,
                          color: _selectedIndex == 4
                              ? const Color(0xFF2196F3)
                              : Colors.grey,
                        ),
                        Text(
                          'Config',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedIndex == 4
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

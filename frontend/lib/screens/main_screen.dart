import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'informes_screen.dart';
import 'configuracion_screen.dart';
import 'qr_scanner_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QRScannerScreen(),
    const InformesScreen(),
    const Center(child: Text('Chat - Próximamente')),
    const ConfiguracionScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _onItemTapped(1),
          backgroundColor: const Color(0xFF2196F3),
          elevation: 6,
          child: const Icon(
            Icons.qr_code_scanner,
            size: 32,
            color: Colors.white,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                // Espacio para el FAB
                const SizedBox(width: 80),
                // Chat
                Expanded(
                  child: InkWell(
                    onTap: () => _onItemTapped(3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: _selectedIndex == 3
                              ? const Color(0xFF2196F3)
                              : Colors.grey,
                        ),
                        Text(
                          'Chat',
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

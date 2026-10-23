import 'package:flutter/material.dart';
import 'persona_list_screen.dart';
import 'estado_civil_screen.dart';
import 'correo_screen.dart';
import 'sexo_screen.dart';
import '../widgets/server_config_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Índice de la sección seleccionada en la navegación inferior.
  int _currentIndex = 0;
// Pantallas disponibles en el orden de la barra de navegación.
  final List<Widget> _pages = const [
    PersonaListScreen(),
    EstadoCivilScreen(),
    CorreoScreen(),
    SexoScreen(),
  ];

  final List<String> _titles = const [
  'Administracion de personas',
  'Gestión de estados civiles',
  'Administración de correos electrónicos',
  'Administracion del catálogo de sexo',
];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
  'EYSFLUIS - EYSFWIS',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  ),
),
              ],
            ),
            Text(
              _titles[_currentIndex],
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns),
            tooltip: 'Configurar conexión con el servidor de base de datos',
            onPressed: () => ServerConfigDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información de EYSFLUIS-MAIN',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'EYSFLUIS - Sistema de Gestión Móvil',
                applicationVersion: 'Versión 2.1',
                applicationIcon: const CircleAvatar(
                  backgroundColor: Color(0xFF1E3A8A),
                  child: Icon(Icons.storage, color: Colors.amber),
                ),
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Aplicación móvil EYSFLUIS conectada a la base de datos eysfwis.\n'
'Permite consultar y gestionar información mediante una API REST.\n\n'
                    'Tablas gestionadas:\n'
                    '• persona (Datos personales)\n'
                    '• estadocivil (Catálogo de estado civil)\n'
                    '• correo / correoelectronico (Correos electrónicos)\n'
                    '• sexo (Catálogo de sexos)\n\n'
                    'Soporta CRUD completo con validación y conectividad API REST.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    body: AnimatedSwitcher(
  duration: const Duration(milliseconds: 400),
  child: IndexedStack(
    key: ValueKey<int>(_currentIndex),
    index: _currentIndex,
    children: _pages,
  ),
),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
  NavigationDestination(
    icon: Tooltip(
      message: 'Ver lista de personas',
      child: Icon(Icons.person_outline),
    ),
    selectedIcon: Tooltip(
      message: 'Sección de personas seleccionada',
      child: Icon(Icons.person),
    ),
    label: 'Personas',
  ),
  NavigationDestination(
    icon: Tooltip(
      message: 'Consultar estados civiles',
      child: Icon(Icons.favorite_outline),
    ),
    selectedIcon: Tooltip(
      message: 'Sección de estado civil seleccionada',
      child: Icon(Icons.favorite),
    ),
    label: 'Estado Civil',
  ),
  NavigationDestination(
    icon: Tooltip(
      message: 'Consultar correos electrónicos',
      child: Icon(Icons.email_outlined),
    ),
    selectedIcon: Tooltip(
      message: 'Sección de correos seleccionada',
      child: Icon(Icons.email),
    ),
    label: 'Correos',
  ),
  NavigationDestination(
    icon: Tooltip(
      message: 'Consultar catálogo de sexo',
      child: Icon(Icons.people_outline),
    ),
    selectedIcon: Tooltip(
      message: 'Sección de sexo seleccionada',
      child: Icon(Icons.people),
    ),
    label: 'Sexo',
  ),
],
      ),
    );
  }
}

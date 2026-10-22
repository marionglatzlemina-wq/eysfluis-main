import 'package:flutter/material.dart';
import '../models/persona_model.dart';
import '../models/sexo_model.dart';
import '../services/api_service.dart';
import 'persona_form_screen.dart';
import 'persona_detail_screen.dart';

class PersonaListScreen extends StatefulWidget {
  const PersonaListScreen({super.key});

  @override
  State<PersonaListScreen> createState() => _PersonaListScreenState();
}

class _PersonaListScreenState extends State<PersonaListScreen> {
  List<Persona> _personas = [];
  List<Persona> _filtered = [];
  List<Sexo> _sexos = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedSexoFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _personas.where((p) {
        final matchesQuery = q.isEmpty ||
            p.cedula.toLowerCase().contains(q) ||
            p.nombres.toLowerCase().contains(q) ||
            p.apellidos.toLowerCase().contains(q) ||
            p.nombreCompleto.toLowerCase().contains(q);

        final matchesSexo = _selectedSexoFilter == null ||
            _selectedSexoFilter == 0 ||
            p.idsexo == _selectedSexoFilter;

        return matchesQuery && matchesSexo;
      }).toList();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final personasFuture = ApiService.fetchPersonas();
      final sexosFuture = ApiService.fetchSexos();

      final results = await Future.wait([personasFuture, sexosFuture]);
      _personas = results[0] as List<Persona>;
      _sexos = results[1] as List<Sexo>;

      setState(() {
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(Persona persona) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Persona'),
        content: Text(
          '¿Estás seguro de eliminar a "${persona.nombreCompleto}" (Cédula: ${persona.cedula}) de la base de datos eysfwis?\n\n'
          'Se eliminarán también sus registros asociados en cascada según las reglas de la BD.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.deletePersona(persona.idpersona);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Persona "${persona.nombreCompleto}" eliminada'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Banner Informativo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.badge, color: Colors.blue.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tabla: persona (Base de datos eysfwis)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        'Entidad principal para personas registradas en el sistema',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${_personas.length} reg.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),

          // Buscador y Selector de Sexo
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por cédula, nombres o apellidos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtro por Sexo (Chips)
          if (_sexos.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedSexoFilter == null,
                    onSelected: (sel) {
                      setState(() {
                        _selectedSexoFilter = null;
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  ..._sexos.map((s) {
                    final isSel = _selectedSexoFilter == s.idsexo;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        label: Text(s.nombre),
                        selected: isSel,
                        onSelected: (sel) {
                          setState(() {
                            _selectedSexoFilter = sel ? s.idsexo : null;
                            _applyFilters();
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

          // Lista de Personas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                'Error al consultar la tabla persona:',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('No se encontraron personas registradas'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              itemCount: _filtered.length,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              itemBuilder: (context, index) {
                                final p = _filtered[index];
                                return Card(
                                  elevation: 1.5,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PersonaDetailScreen(
                                            personaId: p.idpersona,
                                          ),
                                        ),
                                      );
                                      _loadData();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            foregroundColor: Colors.white,
                                            child: Text(
                                              p.nombres.isNotEmpty
                                                  ? p.nombres[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.nombreCompleto,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Cédula: ${p.cedula} • ID: #${p.idpersona}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 6,
                                                  children: [
                                                    Chip(
                                                      label: Text(
                                                        p.sexoNombre ?? 'Sin Sexo',
                                                        style: const TextStyle(
                                                            fontSize: 11),
                                                      ),
                                                      backgroundColor:
                                                          Colors.blue.shade50,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                    if (p.age != null)
                                                      Chip(
                                                        label: Text(
                                                          '${p.age} años',
                                                          style: const TextStyle(
                                                              fontSize: 11),
                                                        ),
                                                        backgroundColor:
                                                            Colors.grey.shade100,
                                                        visualDensity:
                                                          VisualDensity.compact,
                                                      ),
                                                    if (p.isCliente)
                                                      const Chip(
                                                        label: Text(
                                                          'Socio',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            Color(0xFFE8F5E9),
                                                        visualDensity:
                                                          VisualDensity.compact,
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.blue, size: 20),
                                                tooltip: 'Editar',
                                                onPressed: () async {
                                                  final updated =
                                                      await Navigator.push<bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PersonaFormScreen(
                                                        persona: p,
                                                      ),
                                                    ),
                                                  );
                                                  if (updated == true) {
                                                    _loadData();
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                    size: 20),
                                                tooltip: 'Eliminar',
                                                onPressed: () =>
                                                    _confirmDelete(p),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const PersonaFormScreen(),
            ),
          );
          if (created == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Nueva Persona'),
      ),
    );
  }
}

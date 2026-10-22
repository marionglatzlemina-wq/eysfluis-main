import 'package:flutter/material.dart';
import '../models/estado_civil_model.dart';
import '../services/api_service.dart';

class EstadoCivilScreen extends StatefulWidget {
  const EstadoCivilScreen({super.key});

  @override
  State<EstadoCivilScreen> createState() => _EstadoCivilScreenState();
}

class _EstadoCivilScreenState extends State<EstadoCivilScreen> {
  List<EstadoCivil> _estados = [];
  List<EstadoCivil> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_estados);
      } else {
        _filtered = _estados.where((e) {
          return e.nombre.toLowerCase().contains(q) ||
              e.idestadocivil.toString().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService.fetchEstadosCiviles();
      setState(() {
        _estados = list;
        _filtered = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({EstadoCivil? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?.nombre ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit : Icons.add_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Editar Estado Civil' : 'Nuevo Estado Civil'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEdit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text('ID: ${item.idestadocivil}'),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                TextFormField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Estado Civil *',
                    hintText: 'Ej. Soltero/a, Casado/a, Unión de Hecho',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.favorite_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    if (v.trim().length < 2) {
                      return 'Mínimo 2 caracteres';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final nombre = nameCtrl.text.trim();
                        if (isEdit) {
                          await ApiService.updateEstadoCivil(
                            item.idestadocivil,
                            nombre,
                          );
                        } else {
                          await ApiService.createEstadoCivil(nombre);
                        }

                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Estado civil actualizado correctamente'
                                  : 'Estado civil registrado con éxito',
                            ),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                        _loadData();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(EstadoCivil item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar "${item.nombre}" (ID: ${item.idestadocivil})?\n\n'
          'Nota: Si alguna persona tiene asignado este estado civil, la base de datos impedirá la eliminación.',
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
                await ApiService.deleteEstadoCivil(item.idestadocivil);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Registro "${item.nombre}" eliminado'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (errCtx) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          SizedBox(width: 8),
                          Text('No se puede eliminar'),
                        ],
                      ),
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(errCtx),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
              color: Colors.purple.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.purple.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.purple.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tabla: estadocivil (Base de datos eysfwis)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                      Text(
                        'Estado conyugal y civil para registro de personas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${_estados.length} reg.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar estado civil por nombre o ID...',
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

          // Contenido principal
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
                                'Error al consultar la tabla estadocivil:',
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
                                Icon(Icons.search_off,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('No se encontraron estados civiles'),
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
                                final item = _filtered[index];
                                return Card(
                                  elevation: 1.5,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.purple.shade100,
                                      foregroundColor: Colors.purple.shade800,
                                      child: const Icon(Icons.favorite, size: 20),
                                    ),
                                    title: Text(
                                      item.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID en BD: ${item.idestadocivil}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          tooltip: 'Editar',
                                          onPressed: () =>
                                              _showAddEditDialog(item: item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red),
                                          tooltip: 'Eliminar',
                                          onPressed: () => _confirmDelete(item),
                                        ),
                                      ],
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
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Estado Civil'),
      ),
    );
  }
}

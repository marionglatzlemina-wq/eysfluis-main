import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/correo_model.dart';
import '../models/persona_model.dart';
import '../services/api_service.dart';

class CorreoScreen extends StatefulWidget {
  final int? initialPersonaId;

  const CorreoScreen({super.key, this.initialPersonaId});

  @override
  State<CorreoScreen> createState() => _CorreoScreenState();
}

class _CorreoScreenState extends State<CorreoScreen> {
  List<Correo> _correos = [];
  List<Correo> _filtered = [];
  List<Persona> _personas = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedPersonaFilter;

  @override
  void initState() {
    super.initState();
    _selectedPersonaFilter = widget.initialPersonaId;
    _loadData();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _correos.where((c) {
        final matchesSearch = q.isEmpty ||
            c.correo.toLowerCase().contains(q) ||
            (c.cedula?.toLowerCase().contains(q) ?? false) ||
            (c.personaNombres?.toLowerCase().contains(q) ?? false) ||
            c.idcorreo.toString().contains(q);

        final matchesPersona = _selectedPersonaFilter == null ||
            _selectedPersonaFilter == 0 ||
            c.idpersona == _selectedPersonaFilter;

        return matchesSearch && matchesPersona;
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
      final correosFuture = ApiService.fetchCorreos(
        idpersona: _selectedPersonaFilter,
      );

      final results = await Future.wait([personasFuture, correosFuture]);
      _personas = results[0] as List<Persona>;
      _correos = results[1] as List<Correo>;

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

  void _showAddEditDialog({Correo? item, int? preselectedPersonaId}) {
    final isEdit = item != null;
    final emailCtrl = TextEditingController(text: item?.correo ?? '');
    final dateCtrl = TextEditingController(
      text: item?.fechaoptencion ??
          DateTime.now().toIso8601String().substring(0, 10),
    );

    int? selectedIdPersona = isEdit
        ? item.idpersona
        : (preselectedPersonaId ??
            _selectedPersonaFilter ??
            (_personas.isNotEmpty ? _personas.first.idpersona : null));

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
                color: Colors.teal.shade700,
              ),
              const SizedBox(width: 8),
              Text(isEdit ? 'Editar Correo' : 'Nuevo Correo'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selección de Persona
                  const Text(
                    'Asignar a Persona *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedIdPersona,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: _personas.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.idpersona,
                        child: Text(
                          '${p.cedula} - ${p.nombreCompleto}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: isEdit
                        ? null // Al editar, mantener la persona vinculada o permitir si se requiere
                        : (val) {
                            setDialogState(() {
                              selectedIdPersona = val;
                            });
                          },
                    validator: (v) =>
                        v == null ? 'Debe seleccionar una persona' : null,
                  ),
                  const SizedBox(height: 16),

                  // Dirección de Correo
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: isEdit,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de Correo *',
                      hintText: 'ejemplo@correo.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return 'Ingrese un formato de correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fecha de Obtención
                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Obtención',
                      hintText: 'AAAA-MM-DD',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      DateTime initialDate = now;
                      try {
                        if (dateCtrl.text.isNotEmpty) {
                          initialDate = DateTime.parse(dateCtrl.text);
                        }
                      } catch (_) {}

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          dateCtrl.text =
                              picked.toIso8601String().substring(0, 10);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final email = emailCtrl.text.trim();
                        final fecha = dateCtrl.text.trim();

                        if (isEdit) {
                          await ApiService.updateCorreo(
                            idcorreo: item.idcorreo,
                            correo: email,
                            fechaoptencion: fecha,
                            idpersona: selectedIdPersona,
                          );
                        } else {
                          await ApiService.createCorreo(
                            idpersona: selectedIdPersona!,
                            correo: email,
                            fechaoptencion: fecha,
                          );
                        }

                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Correo actualizado con éxito'
                                  : 'Correo registrado exitosamente',
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? 'Actualizar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Correo item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Correo'),
        content: Text(
          '¿Estás seguro de eliminar el correo "${item.correo}" (ID: ${item.idcorreo}) de la base de datos eysfwis?',
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
                await ApiService.deleteCorreo(item.idcorreo);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Correo "${item.correo}" eliminado'),
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
              color: Colors.teal.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.teal.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: Colors.teal.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tabla: correo (Base de datos eysfwis)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      Text(
                        'Direcciones de correo electrónico asociadas a personas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${_correos.length} reg.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),

          // Filtros y Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar correo, persona, cédula...',
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
                const SizedBox(width: 8),
                if (_selectedPersonaFilter != null)
                  IconButton.filledTonal(
                    icon: const Icon(Icons.filter_alt_off),
                    tooltip: 'Limpiar filtro de persona',
                    onPressed: () {
                      setState(() {
                        _selectedPersonaFilter = null;
                        _applyFilters();
                      });
                    },
                  ),
              ],
            ),
          ),

          // Indicador de filtro activo
          if (_selectedPersonaFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('Filtrando por persona: ',
                      style: TextStyle(fontSize: 12)),
                  Chip(
                    label: Text(
                      'ID Persona: $_selectedPersonaFilter',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedPersonaFilter = null;
                        _applyFilters();
                      });
                    },
                  ),
                ],
              ),
            ),

          // Lista de Correos
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
                                'Error al consultar la tabla correo:',
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
                                Icon(Icons.mail_lock_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text('No se encontraron correos registrados'),
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
                                      backgroundColor: Colors.teal.shade100,
                                      foregroundColor: Colors.teal.shade900,
                                      child: const Icon(Icons.email, size: 20),
                                    ),
                                    title: Text(
                                      item.correo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.person,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                item.personaNombres != null
                                                    ? '${item.personaNombres} (CI: ${item.cedula ?? 'N/A'})'
                                                    : 'ID Persona: ${item.idpersona}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade800,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.fechaoptencion != null &&
                                            item.fechaoptencion!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              'Fecha registro: ${item.fechaoptencion}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.copy,
                                              size: 20, color: Colors.grey),
                                          tooltip: 'Copiar correo',
                                          onPressed: () {
                                            Clipboard.setData(
                                              ClipboardData(text: item.correo),
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Correo copiado al portapapeles'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue, size: 20),
                                          tooltip: 'Editar',
                                          onPressed: () =>
                                              _showAddEditDialog(item: item),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red, size: 20),
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
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Correo'),
      ),
    );
  }
}

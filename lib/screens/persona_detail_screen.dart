import 'package:flutter/material.dart';
import '../models/persona_model.dart';
import '../models/correo_model.dart';
import '../services/api_service.dart';
import 'persona_form_screen.dart';

class PersonaDetailScreen extends StatefulWidget {
  final int personaId;

  const PersonaDetailScreen({super.key, required this.personaId});

  @override
  State<PersonaDetailScreen> createState() => _PersonaDetailScreenState();
}

class _PersonaDetailScreenState extends State<PersonaDetailScreen> {
  PersonaDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.fetchPersonaDetail(widget.personaId);
      setState(() {
        _detail = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddCorreoDialog() {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Colors.teal),
              SizedBox(width: 8),
              Text('Agregar Correo'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Asignar a: ${_detail?.persona.nombreCompleto}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico *',
                    hintText: 'ejemplo@correo.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El correo es requerido';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Formato inválido';
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
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
                        await ApiService.createCorreo(
                          idpersona: widget.personaId,
                          correo: emailCtrl.text.trim(),
                        );
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Correo agregado con éxito'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadDetail();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCorreo(Correo correo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Correo'),
        content: Text('¿Desea eliminar el correo ${correo.correo}?'),
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
                await ApiService.deleteCorreo(correo.idcorreo);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correo eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDetail();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Persona')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de Persona')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error ?? 'No se pudo cargar la información'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetail,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _detail!.persona;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombreCompleto),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Persona',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonaFormScreen(persona: p),
                ),
              );
              if (updated == true) {
                _loadDetail();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        child: Text(
                          p.nombres.isNotEmpty
                              ? p.nombres[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombreCompleto,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cédula: ${p.cedula}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.wc, size: 16),
                                  label: Text(p.sexoNombre ?? 'Sin Sexo'),
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (p.isCliente)
                                  const Chip(
                                    avatar: Icon(Icons.verified_user,
                                        size: 16, color: Colors.blue),
                                    label: Text(
                                      'eysfwis',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                    backgroundColor: Color(0xFFE3F2FD),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información General
              Text(
                'Datos Demográficos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Identificador ID'),
                      trailing: Text(
                        '#${p.idpersona}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cake_outlined),
                      title: const Text('Fecha de Nacimiento'),
                      trailing: Text(
                        p.fechanacimiento ?? 'No registrada',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: p.age != null ? Text('${p.age} años') : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite_outline),
                      title: const Text('Estado Civil'),
                      trailing: Text(
                        _detail!.estadosCiviles.isNotEmpty
                            ? _detail!.estadosCiviles.first
                            : 'No asignado',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sección: Correos Electrónicos (Tabla correo)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Correos Electrónicos (Tabla correo)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddCorreoDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              if (_detail!.correos.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No tiene correos registrados en la tabla correo.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ..._detail!.correos.map(
                  (c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.email, color: Colors.teal),
                      title: Text(
                        c.correo,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'ID Correo: #${c.idcorreo}${c.fechaoptencion != null ? " • Fecha: ${c.fechaoptencion}" : ""}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteCorreo(c),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Sección: Direcciones (Tabla direccion)
              Text(
                'Direcciones Domiciliarias (Tabla direccion)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_detail!.direcciones.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No registra direcciones en la tabla direccion.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ..._detail!.direcciones.map(
                  (dir) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                      title: Text(dir),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

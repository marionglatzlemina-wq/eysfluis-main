import 'package:flutter/material.dart';
import '../models/persona_model.dart';
import '../models/sexo_model.dart';
import '../models/estado_civil_model.dart';
import '../services/api_service.dart';

class PersonaFormScreen extends StatefulWidget {
  final Persona? persona;

  const PersonaFormScreen({super.key, this.persona});

  @override
  State<PersonaFormScreen> createState() => _PersonaFormScreenState();
}

class _PersonaFormScreenState extends State<PersonaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cedulaCtrl;
  late TextEditingController _nombresCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _fechaNacCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _direccionCtrl;

  int? _selectedSexo;
  int? _selectedEstadoCivil;
  bool _esCliente = false;

  List<Sexo> _sexos = [];
  List<EstadoCivil> _estadosCiviles = [];
  bool _isLoadingCatalogs = true;
  bool _isSaving = false;

  bool get isEdit => widget.persona != null;

  @override
  void initState() {
    super.initState();
    final p = widget.persona;
    _cedulaCtrl = TextEditingController(text: p?.cedula ?? '');
    _nombresCtrl = TextEditingController(text: p?.nombres ?? '');
    _apellidosCtrl = TextEditingController(text: p?.apellidos ?? '');
    _fechaNacCtrl = TextEditingController(text: p?.fechanacimiento ?? '');
    _correoCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();

    _selectedSexo = p?.idsexo;
    _esCliente = p?.isCliente ?? false;

    _loadCatalogs();
  }

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _fechaNacCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    try {
      final sexos = await ApiService.fetchSexos();
      final ec = await ApiService.fetchEstadosCiviles();

      if (mounted) {
        setState(() {
          _sexos = sexos;
          _estadosCiviles = ec;
          _isLoadingCatalogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCatalogs = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando catálogos: $e')),
        );
      }
    }
  }

  Future<void> _selectFechaNacimiento() async {
    final now = DateTime.now();
    DateTime initial = DateTime(2000, 1, 1);
    if (_fechaNacCtrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_fechaNacCtrl.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _fechaNacCtrl.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (isEdit) {
        final res = await ApiService.updatePersona(
          idpersona: widget.persona!.idpersona,
          cedula: _cedulaCtrl.text,
          nombres: _nombresCtrl.text,
          apellidos: _apellidosCtrl.text,
          fechanacimiento: _fechaNacCtrl.text,
          idsexo: _selectedSexo,
          esCliente: _esCliente,
        );

        if (!mounted) return;
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Persona actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['error'] ?? 'Error al actualizar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final res = await ApiService.createPersona(
          cedula: _cedulaCtrl.text,
          nombres: _nombresCtrl.text,
          apellidos: _apellidosCtrl.text,
          fechanacimiento: _fechaNacCtrl.text,
          idsexo: _selectedSexo,
          idestadocivil: _selectedEstadoCivil,
          correo: _correoCtrl.text,
          direccion: _direccionCtrl.text,
          esCliente: _esCliente,
        );

        if (!mounted) return;
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Persona registrada con éxito en eysfwis'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['error'] ?? 'Error al registrar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Persona' : 'Nueva Persona'),
      ),
      body: _isLoadingCatalogs
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.badge, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEdit
                                    ? 'Modificando registro ID: ${widget.persona!.idpersona} en BD eysfwis'
                                    : 'Los datos se guardarán directamente en la tabla persona y tablas vinculadas.',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cédula
                    TextFormField(
                      controller: _cedulaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cédula de Identidad *',
                        hintText: 'Ej. 0801234567',
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'La cédula es obligatoria';
                        }
                        if (v.trim().length < 5) {
                          return 'Debe tener al menos 5 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Apellidos
                    TextFormField(
                      controller: _apellidosCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos *',
                        hintText: 'Ej. Francis Quinde',
                        prefixIcon: Icon(Icons.person_pin),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Los apellidos son obligatorios';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nombres
                    TextFormField(
                      controller: _nombresCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombres *',
                        hintText: 'Ej. Stalin Adalberto',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Los nombres son obligatorios';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Fecha de Nacimiento
                    TextFormField(
                      controller: _fechaNacCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Nacimiento',
                        hintText: 'AAAA-MM-DD',
                        prefixIcon: Icon(Icons.cake),
                        border: OutlineInputBorder(),
                      ),
                      onTap: _selectFechaNacimiento,
                    ),
                    const SizedBox(height: 14),

                    // Sexo (Dropdown vinculado a tabla sexo)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedSexo,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sexo (Tabla sexo) *',
                        prefixIcon: Icon(Icons.wc),
                        border: OutlineInputBorder(),
                      ),
                      items: _sexos.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.idsexo,
                          child: Text('${s.nombre} (ID: ${s.idsexo})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedSexo = val);
                      },
                      validator: (v) =>
                          v == null ? 'Seleccione un sexo' : null,
                    ),
                    const SizedBox(height: 14),

                    // Estado Civil inicial (solo en creación)
                    if (!isEdit) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedEstadoCivil,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Estado Civil (Tabla estadocivil)',
                          prefixIcon: Icon(Icons.favorite),
                          border: OutlineInputBorder(),
                        ),
                        items: _estadosCiviles.map((ec) {
                          return DropdownMenuItem<int>(
                            value: ec.idestadocivil,
                            child: Text('${ec.nombre} (ID: ${ec.idestadocivil})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedEstadoCivil = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Correo inicial (tabla correo)
                      TextFormField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico (Tabla correo)',
                          hintText: 'ejemplo@correo.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Dirección inicial
                      TextFormField(
                        controller: _direccionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dirección Domiciliaria (Tabla direccion)',
                          hintText: 'Calle principal y secundaria',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 10),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving
                              ? 'Guardando...'
                              : (isEdit ? 'Actualizar Persona' : 'Registrar Persona'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

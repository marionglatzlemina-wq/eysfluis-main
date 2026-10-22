import 'correo_model.dart';

class Persona {
  final int idpersona;
  final String cedula;
  final String apellidos;
  final String nombres;
  final String? fechanacimiento;
  final int? idsexo;
  final String? sexoNombre;
  final int? idcliente;

  Persona({
    required this.idpersona,
    required this.cedula,
    required this.apellidos,
    required this.nombres,
    this.fechanacimiento,
    this.idsexo,
    this.sexoNombre,
    this.idcliente,
  });

  String get nombreCompleto => '$apellidos $nombres'.trim().isNotEmpty
      ? '$apellidos $nombres'.trim()
      : nombres;

  bool get isCliente => idcliente != null && idcliente! > 0;

  int? get age {
    if (fechanacimiento == null || fechanacimiento!.isEmpty) return null;
    try {
      final birth = DateTime.parse(fechanacimiento!);
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        years--;
      }
      return years >= 0 ? years : null;
    } catch (_) {
      return null;
    }
  }

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      idpersona: int.tryParse(json['idpersona']?.toString() ?? '') ?? 0,
      cedula: json['cedula']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      fechanacimiento: json['fechanacimiento']?.toString(),
      idsexo: int.tryParse(json['idsexo']?.toString() ?? ''),
      sexoNombre: json['sexo_nombre']?.toString(),
      idcliente: int.tryParse(json['idcliente']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idpersona': idpersona,
      'cedula': cedula,
      'apellidos': apellidos,
      'nombres': nombres,
      'fechanacimiento': fechanacimiento,
      'idsexo': idsexo,
      'es_cliente': isCliente ? 1 : 0,
    };
  }
}

class PersonaDetail {
  final Persona persona;
  final List<Correo> correos;
  final List<String> direcciones;
  final List<String> estadosCiviles;
  final List<String> generos;

  PersonaDetail({
    required this.persona,
    required this.correos,
    required this.direcciones,
    required this.estadosCiviles,
    required this.generos,
  });

  factory PersonaDetail.fromJson(Map<String, dynamic> json) {
    final personaMap = (json['persona'] as Map<String, dynamic>?) ?? {};
    final persona = Persona.fromJson(personaMap);

    final rawCorreos = json['correos'] as List<dynamic>? ?? [];
    final correos = rawCorreos
        .map((c) => Correo.fromJson(c as Map<String, dynamic>))
        .toList();

    final rawDirecciones = json['direcciones'] as List<dynamic>? ?? [];
    final direcciones = rawDirecciones
        .map((d) => d['direccion']?.toString() ?? '')
        .where((d) => d.isNotEmpty)
        .toList();

    final rawEC = json['estadosCiviles'] as List<dynamic>? ?? [];
    final estadosCiviles = rawEC
        .map((ec) => ec['estadocivil_nombre']?.toString() ?? '')
        .where((ec) => ec.isNotEmpty)
        .toList();

    final rawGen = json['generos'] as List<dynamic>? ?? [];
    final generos = rawGen
        .map((g) => g['genero_nombre']?.toString() ?? '')
        .where((g) => g.isNotEmpty)
        .toList();

    return PersonaDetail(
      persona: persona,
      correos: correos,
      direcciones: direcciones,
      estadosCiviles: estadosCiviles,
      generos: generos,
    );
  }
}

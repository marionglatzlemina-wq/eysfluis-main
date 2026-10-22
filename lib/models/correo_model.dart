class Correo {
  final int idcorreo;
  final int idpersona;
  final String correo;
  final String? fechaoptencion;
  final String? cedula;
  final String? personaNombres;

  Correo({
    required this.idcorreo,
    required this.idpersona,
    required this.correo,
    this.fechaoptencion,
    this.cedula,
    this.personaNombres,
  });

  factory Correo.fromJson(Map<String, dynamic> json) {
    return Correo(
      idcorreo: int.tryParse(json['idcorreo']?.toString() ?? '') ?? 0,
      idpersona: int.tryParse(json['idpersona']?.toString() ?? '') ?? 0,
      correo: json['correo']?.toString() ?? '',
      fechaoptencion: json['fechaoptencion']?.toString(),
      cedula: json['cedula']?.toString(),
      personaNombres: json['persona_nombres']?.toString() ??
          json['persona']?['nombres']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idcorreo': idcorreo,
      'idpersona': idpersona,
      'correo': correo,
      'fechaoptencion': fechaoptencion,
    };
  }
}

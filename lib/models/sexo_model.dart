class Sexo {
  final int idsexo;
  final String nombre;

  Sexo({
    required this.idsexo,
    required this.nombre,
  });

  factory Sexo.fromJson(Map<String, dynamic> json) {
    return Sexo(
      idsexo: int.tryParse(json['idsexo']?.toString() ?? '') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idsexo': idsexo,
      'nombre': nombre,
    };
  }
}

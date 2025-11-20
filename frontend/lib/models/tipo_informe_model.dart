class TipoInforme {
  final String id;
  final String nombre;
  final String? descripcion;

  TipoInforme({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory TipoInforme.fromJson(Map<String, dynamic> json) {
    return TipoInforme(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
    );
  }
}

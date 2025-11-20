class Archivo {
  final String nombre;
  final String formato;
  final String urlpath;

  Archivo({required this.nombre, required this.formato, required this.urlpath});

  factory Archivo.fromJson(Map<String, dynamic> json) {
    return Archivo(
      nombre: json['nombre'] ?? '',
      formato: json['formato'] ?? '',
      urlpath: json['urlpath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'nombre': nombre, 'formato': formato, 'urlpath': urlpath};
  }
}

class ContenidoClinico {
  final Map<String, double> dosisDiaria;
  final double? dosisSemanalMg;

  ContenidoClinico({required this.dosisDiaria, this.dosisSemanalMg});

  factory ContenidoClinico.fromJson(Map<String, dynamic> json) {
    return ContenidoClinico(
      dosisDiaria:
          (json['dosis_diaria'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ) ??
          {},
      dosisSemanalMg: (json['dosis_semanal_mg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'dosis_diaria': dosisDiaria, 'dosis_semanal_mg': dosisSemanalMg};
  }
}

class Informe {
  final String id;
  final String titulo;
  final String tipoInforme;
  final String? observaciones;
  final String runPaciente;
  final String runMedico;
  final List<Archivo> archivos;
  final ContenidoClinico? contenidoClinico;
  final DateTime createdAt;
  final DateTime updatedAt;

  Informe({
    required this.id,
    required this.titulo,
    required this.tipoInforme,
    this.observaciones,
    required this.runPaciente,
    required this.runMedico,
    required this.archivos,
    this.contenidoClinico,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Informe.fromJson(Map<String, dynamic> json) {
    return Informe(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      tipoInforme: json['tipo_informe'] ?? '',
      observaciones: json['observaciones'],
      runPaciente: json['run_paciente'] ?? '',
      runMedico: json['run_medico'] ?? '',
      archivos:
          (json['archivos'] as List<dynamic>?)
              ?.map((archivo) => Archivo.fromJson(archivo))
              .toList() ??
          [],
      contenidoClinico: json['contenido_clinico'] != null
          ? ContenidoClinico.fromJson(json['contenido_clinico'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'tipo_informe': tipoInforme,
      'observaciones': observaciones,
      'run_paciente': runPaciente,
      'run_medico': runMedico,
      'archivos': archivos.map((archivo) => archivo.toJson()).toList(),
      'contenido_clinico': contenidoClinico?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Archivo {
  final String nombre;
  final String formato;
  final String tipo;
  final String urlpath;

  Archivo({
    required this.nombre,
    required this.formato,
    this.tipo = 'Documento',
    required this.urlpath,
  });

  factory Archivo.fromJson(Map<String, dynamic> json) {
    return Archivo(
      nombre: json['nombre']?.toString() ?? '',
      formato: json['formato']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'Documento',
      urlpath: json['urlpath']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'formato': formato,
        'tipo': tipo,
        'urlpath': urlpath,
      };
}

class ContenidoClinico {
  // CAMBIO: Usamos dynamic para aceptar "1/2" (String) o 0.5 (Number)
  final Map<String, dynamic> dosisDiaria;
  final double inrActual;
  final double? dosisSemanalMg;

  ContenidoClinico({
    required this.dosisDiaria,
    this.inrActual = 0.0,
    this.dosisSemanalMg,
  });

  factory ContenidoClinico.fromJson(Map<String, dynamic> json) {
    return ContenidoClinico(
      dosisDiaria: json['dosis_diaria'] is Map
          ? Map<String, dynamic>.from(json['dosis_diaria'])
          : {},
      inrActual: (json['inr_actual'] as num?)?.toDouble() ?? 0.0,
      dosisSemanalMg: (json['dosis_semanal_total_mg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dosis_diaria': dosisDiaria,
        'inr_actual': inrActual,
        'dosis_semanal_total_mg': dosisSemanalMg,
      };
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
      id: json['_id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Sin Título',
      tipoInforme: json['tipo_informe']?.toString() ?? 'General',
      observaciones: json['observaciones']?.toString(),
      runPaciente: json['run_paciente']?.toString() ?? '',
      runMedico: json['run_medico']?.toString() ?? '',
      archivos: (json['archivos'] as List<dynamic>?)
              ?.map((x) => Archivo.fromJson(x))
              .toList() ??
          [],
      contenidoClinico: json['contenido_clinico'] != null
          ? ContenidoClinico.fromJson(json['contenido_clinico'])
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
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
      'archivos': archivos.map((x) => x.toJson()).toList(),
      'contenido_clinico': contenidoClinico?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
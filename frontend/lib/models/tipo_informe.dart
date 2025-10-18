class TipoInforme {
  // Valores que deben coincidir con el backend
  static const String consultaGeneral = 'Consulta General';
  static const String consultaEspecialidad = 'Consulta de Especialidad';
  static const String atencionUrgencia = 'Atencion de Urgencia';
  static const String procedimiento = 'Procedimiento Medico';
  static const String hospitalizacion = 'Hospitalizacion';
  static const String teleconsulta = 'Teleconsulta';
  static const String entregaResultados = 'Entrega de Resultados';
  static const String controlSeguimiento = 'Control o Seguimiento';

  /// Lista de todos los tipos disponibles para usar en dropdowns
  static const List<TipoInformeOption> opciones = [
    TipoInformeOption(value: consultaGeneral, label: 'Consulta General'),
    TipoInformeOption(
      value: consultaEspecialidad,
      label: 'Consulta de Especialidad',
    ),
    TipoInformeOption(value: atencionUrgencia, label: 'Atención de Urgencia'),
    TipoInformeOption(value: procedimiento, label: 'Procedimiento Médico'),
    TipoInformeOption(value: hospitalizacion, label: 'Hospitalización'),
    TipoInformeOption(value: teleconsulta, label: 'Teleconsulta'),
    TipoInformeOption(value: entregaResultados, label: 'Entrega de Resultados'),
    TipoInformeOption(
      value: controlSeguimiento,
      label: 'Control o Seguimiento',
    ),
  ];
}

/// Clase auxiliar para opciones del dropdown
class TipoInformeOption {
  final String value; // Valor que se envía al backend
  final String label; // Texto que se muestra al usuario

  const TipoInformeOption({required this.value, required this.label});
}

/// Constantes para los estados de los viajes
class TripStatus {
  /// Viaje publicado, esperando pasajeros
  static const String activo = 'activo';
  
  /// Viaje iniciado por el conductor
  static const String enCurso = 'en_curso';
  
  /// Viaje finalizado exitosamente
  static const String completado = 'completado';
  
  /// Viaje cancelado por el conductor
  static const String cancelado = 'cancelado';

  /// Lista de todos los estados posibles
  static const List<String> allStatus = [
    activo,
    enCurso,
    completado,
    cancelado,
  ];

  /// Verifica si un estado es válido
  static bool isValid(String status) {
    return allStatus.contains(status);
  }

  /// Obtiene el texto legible de un estado
  static String getDisplayText(String status) {
    switch (status) {
      case activo:
        return 'Activo';
      case enCurso:
        return 'En Curso';
      case completado:
        return 'Completado';
      case cancelado:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene el color asociado a un estado
  static String getColorHex(String status) {
    switch (status) {
      case activo:
        return '#4CAF50'; // Verde
      case enCurso:
        return '#2196F3'; // Azul
      case completado:
        return '#9E9E9E'; // Gris
      case cancelado:
        return '#F44336'; // Rojo
      default:
        return '#9E9E9E';
    }
  }
}
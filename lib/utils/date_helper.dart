import 'package:intl/intl.dart';

/// Helper para manejo y formateo de fechas
class DateHelper {
  /// Formatea una fecha completa con día de la semana
  /// Ejemplo: "Lunes 15 de Enero"
  static String formatearFecha(DateTime fecha) {
    final formatoDia = DateFormat('EEEE d \'de\' MMMM', 'es');
    return _capitalize(formatoDia.format(fecha));
  }

  /// Formatea una fecha de forma corta
  /// Ejemplo: "15 Ene"
  static String formatearFechaCorta(DateTime fecha) {
    final formato = DateFormat('d MMM', 'es');
    return formato.format(fecha);
  }

  /// Formatea solo el mes y año
  /// Ejemplo: "Enero 2025"
  static String formatearMesAnio(DateTime fecha) {
    final formato = DateFormat('MMMM yyyy', 'es');
    return _capitalize(formato.format(fecha));
  }

  /// Formatea la hora en formato 12h
  /// Ejemplo: "2:30 PM"
  static String formatearHora(DateTime fecha) {
    final formato = DateFormat('h:mm a', 'es');
    return formato.format(fecha);
  }

  /// Formatea un rango de fechas
  /// Ejemplo: "15 Ene - 15 Feb"
  static String formatearRango(DateTime inicio, DateTime fin) {
    final inicioStr = formatearFechaCorta(inicio);
    final finStr = formatearFechaCorta(fin);
    return '$inicioStr - $finStr';
  }

  /// Calcula la cantidad de días entre dos fechas (inclusive)
  static int getDiasEntreFechas(DateTime inicio, DateTime fin) {
    final inicioSinHora = getStartOfDay(inicio);
    final finSinHora = getStartOfDay(fin);
    return finSinHora.difference(inicioSinHora).inDays + 1;
  }

  /// Compara si dos fechas son el mismo día (ignorando hora)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Retorna el inicio del día (00:00:00)
  static DateTime getStartOfDay(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day);
  }

  /// Retorna el fin del día (23:59:59)
  static DateTime getEndOfDay(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59, 999);
  }

  /// Retorna el primer día del mes
  static DateTime getStartOfMonth(DateTime fecha) {
    return DateTime(fecha.year, fecha.month, 1);
  }

  /// Retorna el último día del mes
  static DateTime getEndOfMonth(DateTime fecha) {
    return DateTime(fecha.year, fecha.month + 1, 0);
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime fecha) {
    return isSameDay(fecha, DateTime.now());
  }

  /// Verifica si una fecha es en el futuro
  static bool isFuturo(DateTime fecha) {
    return getStartOfDay(fecha).isAfter(getStartOfDay(DateTime.now()));
  }

  /// Verifica si una fecha es en el pasado
  static bool isPasado(DateTime fecha) {
    return getStartOfDay(fecha).isBefore(getStartOfDay(DateTime.now()));
  }

  /// Capitaliza la primera letra de un texto
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

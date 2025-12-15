import 'package:intl/intl.dart';

/// Helper para formateo de montos de dinero
class CurrencyHelper {
  /// Formatea un monto con símbolo de dólar
  /// Ejemplo: $1,234.56
  static String formatearMonto(double monto) {
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formato.format(monto);
  }

  /// Formatea un monto sin decimales
  /// Ejemplo: $1,235
  static String formatearMontoSinDecimales(double monto) {
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formato.format(monto);
  }

  /// Formatea un monto sin símbolo
  /// Ejemplo: 1,234.56
  static String formatearMontoSinSimbolo(double monto) {
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    );
    return formato.format(monto).trim();
  }

  /// Parsea un string a double validando el formato
  /// Acepta formatos: "1234.56", "$1,234.56", "1,234.56"
  static double? parseMonto(String texto) {
    if (texto.isEmpty) return null;
    
    // Remover símbolos de moneda y espacios
    String limpio = texto
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .trim();
    
    try {
      return double.parse(limpio);
    } catch (e) {
      return null;
    }
  }

  /// Valida si un texto es un monto válido
  static bool isMontoValido(String texto) {
    final monto = parseMonto(texto);
    return monto != null && monto > 0;
  }

  /// Formatea un porcentaje
  /// Ejemplo: 75.5%
  static String formatearPorcentaje(double porcentaje) {
    return '${porcentaje.toStringAsFixed(1)}%';
  }

  /// Formatea la diferencia entre dos montos con signo
  /// Ejemplo: +$150.00 o -$50.00
  static String formatearDiferencia(double diferencia) {
    final signo = diferencia >= 0 ? '+' : '';
    return '$signo${formatearMonto(diferencia)}';
  }
}

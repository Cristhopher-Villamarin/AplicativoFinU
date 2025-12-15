import 'package:flutter/material.dart';

/// Helper para determinar colores según el nivel de gasto
class ColorHelper {
  /// Colores para niveles de gasto en el calendario
  static const Color sinGastos = Color(0xFFC8E6C9); // Verde claro
  static const Color gastoBajo = Color(0xFFB3E5FC); // Azul claro
  static const Color gastoModerado = Color(0xFFFFF9C4); // Amarillo
  static const Color gastoAlto = Color(0xFFFFE0B2); // Naranja
  static const Color gastoExcesivo = Color(0xFFFFCDD2); // Rojo

  /// Colores para el estado del presupuesto
  static const Color saludable = Color(0xFF43A047); // Verde
  static const Color moderado = Color(0xFFFFA726); // Naranja
  static const Color riesgo = Color(0xFFEF5350); // Rojo
  static const Color sobregiro = Color(0xFFD32F2F); // Rojo oscuro

  /// Colores primarios de la app
  static const Color primario = Color(0xFF2E7D32);
  static const Color secundario = Color(0xFF43A047);
  static const Color acento = Color(0xFF66BB6A);

  /// Retorna el color según el nivel de gasto comparado con el promedio
  /// - Verde claro: Sin gastos ($0)
  /// - Azul claro: Gasto bajo (1-33% del promedio)
  /// - Amarillo: Gasto moderado (34-80% del promedio)
  /// - Naranja: Gasto alto (81-120% del promedio)
  /// - Rojo: Gasto excesivo (>120% del promedio)
  static Color getColorNivelGasto(double montoGasto, double promedioDiario) {
    if (montoGasto == 0) {
      return sinGastos;
    }

    if (promedioDiario == 0) {
      return gastoBajo;
    }

    final porcentaje = (montoGasto / promedioDiario) * 100;

    if (porcentaje <= 33) {
      return gastoBajo;
    } else if (porcentaje <= 80) {
      return gastoModerado;
    } else if (porcentaje <= 120) {
      return gastoAlto;
    } else {
      return gastoExcesivo;
    }
  }

  /// Retorna el color según el porcentaje de presupuesto usado
  static Color getColorPorcentajeGastado(double porcentajeUsado) {
    if (porcentajeUsado <= 50) {
      return saludable;
    } else if (porcentajeUsado <= 80) {
      return moderado;
    } else if (porcentajeUsado <= 100) {
      return riesgo;
    } else {
      return sobregiro;
    }
  }

  /// Retorna un gradiente para el dashboard según el estado
  static LinearGradient getGradienteDashboard(double porcentajeUsado) {
    if (porcentajeUsado <= 50) {
      return const LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (porcentajeUsado <= 80) {
      return const LinearGradient(
        colors: [Color(0xFFF57C00), Color(0xFFFF9800), Color(0xFFFFA726)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFC62828), Color(0xFFD32F2F), Color(0xFFEF5350)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  /// Retorna el color de texto apropiado para un fondo dado
  /// (blanco o negro según el contraste)
  static Color getColorTexto(Color fondo) {
    // Calcular luminancia
    final luminancia = (0.299 * fondo.red + 
                        0.587 * fondo.green + 
                        0.114 * fondo.blue) / 255;
    
    // Si la luminancia es alta, usar texto oscuro, sino texto claro
    return luminancia > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Retorna un color más oscuro para efectos de presión
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    
    return hslDark.toColor();
  }

  /// Retorna un color más claro para efectos de hover
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    
    return hslLight.toColor();
  }

  /// Color para días fuera del período del presupuesto
  static const Color diaFueraPeriodo = Color(0xFFEEEEEE);

  /// Color de borde para el día actual
  static const Color bordeaDiaActual = Color(0xFF1976D2);
}

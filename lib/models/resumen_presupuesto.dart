import 'presupuesto.dart';
import 'gasto.dart';

/// Modelo para calcular y mostrar el resumen del presupuesto
class ResumenPresupuesto {
  final Presupuesto presupuesto;
  final double montoGastado;
  final double montoDisponible;
  final double porcentajeUsado;
  final double promedioDiarioDisponible;
  final double promedioDiarioReal;
  final int diasConGastos;
  final int diasSinGastos;

  ResumenPresupuesto({
    required this.presupuesto,
    required this.montoGastado,
    required this.montoDisponible,
    required this.porcentajeUsado,
    required this.promedioDiarioDisponible,
    required this.promedioDiarioReal,
    required this.diasConGastos,
    required this.diasSinGastos,
  });

  /// Calcula el resumen desde un presupuesto y lista de gastos
  factory ResumenPresupuesto.calcular(Presupuesto presupuesto, List<Gasto> gastos) {
    // Filtrar solo gastos no eliminados
    final gastosActivos = gastos.where((g) => !g.deleted).toList();

    // Calcular monto total gastado
    final montoGastado = gastosActivos.fold<double>(
      0,
      (sum, gasto) => sum + gasto.monto,
    );

    // Calcular monto disponible
    final montoDisponible = presupuesto.montoTotal - montoGastado;

    // Calcular porcentaje usado
    final porcentajeUsado = presupuesto.montoTotal > 0
        ? ((montoGastado / presupuesto.montoTotal) * 100).toDouble()
        : 0.0;

    // Calcular promedio diario disponible
    final diasRestantes = presupuesto.getDiasRestantes();
    final promedioDiarioDisponible = diasRestantes > 0
        ? (montoDisponible / diasRestantes).toDouble()
        : 0.0;

    // Calcular promedio diario real
    final diasTranscurridos = presupuesto.getDiasTranscurridos();
    final promedioDiarioReal = diasTranscurridos > 0
        ? (montoGastado / diasTranscurridos).toDouble()
        : 0.0;

    // Calcular días con y sin gastos
    final fechasConGastos = gastosActivos
        .map((g) => DateTime(g.fecha.year, g.fecha.month, g.fecha.day))
        .toSet();
    final diasConGastos = fechasConGastos.length;
    final diasSinGastos = diasTranscurridos - diasConGastos;

    return ResumenPresupuesto(
      presupuesto: presupuesto,
      montoGastado: montoGastado,
      montoDisponible: montoDisponible,
      porcentajeUsado: porcentajeUsado,
      promedioDiarioDisponible: promedioDiarioDisponible,
      promedioDiarioReal: promedioDiarioReal,
      diasConGastos: diasConGastos,
      diasSinGastos: diasSinGastos > 0 ? diasSinGastos : 0,
    );
  }

  /// Retorna si el presupuesto está en riesgo (>80% usado)
  bool get estaEnRiesgo => porcentajeUsado > 80;

  /// Retorna si el presupuesto está en sobregiro
  bool get estaSobregiro => montoDisponible < 0;

  /// Retorna el estado del presupuesto como texto
  String get estadoTexto {
    if (estaSobregiro) return 'Sobregiro';
    if (estaEnRiesgo) return 'En riesgo';
    if (porcentajeUsado > 50) return 'Moderado';
    return 'Saludable';
  }

  /// Retorna una proyección de cuánto sobrará o faltará al final
  double get proyeccionFinal {
    if (presupuesto.getDiasRestantes() <= 0) {
      return montoDisponible;
    }
    
    final diasTranscurridos = presupuesto.getDiasTranscurridos();
    if (diasTranscurridos == 0) return montoDisponible;

    final gastoProyectado = promedioDiarioReal * presupuesto.getDiasTotales();
    return presupuesto.montoTotal - gastoProyectado;
  }

  /// Retorna el texto de la proyección
  String get proyeccionTexto {
    final proyeccion = proyeccionFinal;
    if (proyeccion > 0) {
      return 'A este ritmo, ahorrarás \$${proyeccion.toStringAsFixed(2)}';
    } else if (proyeccion < 0) {
      return 'A este ritmo, tendrás un sobregiro de \$${(-proyeccion).toStringAsFixed(2)}';
    } else {
      return 'A este ritmo, gastarás exactamente tu presupuesto';
    }
  }
}

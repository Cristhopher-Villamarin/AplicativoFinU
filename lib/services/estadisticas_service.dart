import '../models/presupuesto.dart';
import '../models/gasto.dart';
import '../models/resumen_presupuesto.dart';
import '../utils/date_helper.dart';

/// Datos para gráfica de tendencia (gastos por día)
class DatoTendencia {
  final DateTime fecha;
  final double monto;

  DatoTendencia(this.fecha, this.monto);
}

/// Información del día con mayor gasto
class DiaMayorGasto {
  final DateTime fecha;
  final double monto;
  final List<Gasto> gastos;

  DiaMayorGasto(this.fecha, this.monto, this.gastos);
}

/// Servicio para cálculos de estadísticas
class EstadisticasService {
  /// Calcula el resumen completo del presupuesto
  ResumenPresupuesto calcularResumen(Presupuesto presupuesto, List<Gasto> gastos) {
    return ResumenPresupuesto.calcular(presupuesto, gastos);
  }

  /// Obtiene los gastos agrupados por categoría con montos
  Map<CategoriaGasto, double> getGastosPorCategoria(List<Gasto> gastos) {
    final gastosActivos = gastos.where((g) => !g.deleted).toList();
    final Map<CategoriaGasto, double> resultado = {};

    // Inicializar todas las categorías en 0
    for (var categoria in CategoriaGasto.values) {
      resultado[categoria] = 0;
    }

    // Sumar gastos por categoría
    for (var gasto in gastosActivos) {
      resultado[gasto.categoria] = (resultado[gasto.categoria] ?? 0) + gasto.monto;
    }

    return resultado;
  }

  /// Obtiene las categorías ordenadas por monto (de mayor a menor)
  List<MapEntry<CategoriaGasto, double>> getCategoriasOrdenadas(List<Gasto> gastos) {
    final gastosPorCategoria = getGastosPorCategoria(gastos);
    final lista = gastosPorCategoria.entries.toList();
    lista.sort((a, b) => b.value.compareTo(a.value));
    return lista;
  }

  /// Obtiene las top 3 categorías más gastadas
  List<MapEntry<CategoriaGasto, double>> getTop3Categorias(List<Gasto> gastos) {
    final ordenadas = getCategoriasOrdenadas(gastos);
    return ordenadas.take(3).toList();
  }

  /// Obtiene el día con mayor gasto
  DiaMayorGasto? getDiaMayorGasto(List<Gasto> gastos) {
    final gastosActivos = gastos.where((g) => !g.deleted).toList();
    if (gastosActivos.isEmpty) return null;

    // Agrupar gastos por día
    final Map<DateTime, List<Gasto>> gastosPorDia = {};
    for (var gasto in gastosActivos) {
      final fechaSinHora = DateHelper.getStartOfDay(gasto.fecha);
      gastosPorDia.putIfAbsent(fechaSinHora, () => []).add(gasto);
    }

    // Encontrar el día con mayor total
    DateTime? fechaMayor;
    double montoMayor = 0;

    gastosPorDia.forEach((fecha, gastosDelDia) {
      final total = gastosDelDia.fold<double>(0, (sum, g) => sum + g.monto);
      if (total > montoMayor) {
        montoMayor = total;
        fechaMayor = fecha;
      }
    });

    if (fechaMayor == null) return null;

    return DiaMayorGasto(
      fechaMayor!,
      montoMayor,
      gastosPorDia[fechaMayor!]!,
    );
  }

  /// Obtiene el día con menor gasto (excluyendo días con $0)
  DiaMayorGasto? getDiaMenorGasto(List<Gasto> gastos) {
    final gastosActivos = gastos.where((g) => !g.deleted).toList();
    if (gastosActivos.isEmpty) return null;

    // Agrupar gastos por día
    final Map<DateTime, List<Gasto>> gastosPorDia = {};
    for (var gasto in gastosActivos) {
      final fechaSinHora = DateHelper.getStartOfDay(gasto.fecha);
      gastosPorDia.putIfAbsent(fechaSinHora, () => []).add(gasto);
    }

    // Encontrar el día con menor total (mayor a 0)
    DateTime? fechaMenor;
    double? montoMenor;

    gastosPorDia.forEach((fecha, gastosDelDia) {
      final total = gastosDelDia.fold<double>(0, (sum, g) => sum + g.monto);
      if (total > 0 && (montoMenor == null || total < montoMenor!)) {
        montoMenor = total;
        fechaMenor = fecha;
      }
    });

    if (fechaMenor == null) return null;

    return DiaMayorGasto(
      fechaMenor!,
      montoMenor!,
      gastosPorDia[fechaMenor!]!,
    );
  }

  /// Obtiene datos para gráfica de tendencia (gastos por día)
  List<DatoTendencia> getTendenciaGasto(Presupuesto presupuesto, List<Gasto> gastos) {
    final gastosActivos = gastos.where((g) => !g.deleted).toList();
    
    // Agrupar gastos por día
    final Map<DateTime, double> gastosPorDia = {};
    for (var gasto in gastosActivos) {
      final fechaSinHora = DateHelper.getStartOfDay(gasto.fecha);
      gastosPorDia[fechaSinHora] = (gastosPorDia[fechaSinHora] ?? 0) + gasto.monto;
    }

    // Crear lista de todos los días en el período
    final List<DatoTendencia> tendencia = [];
    final inicio = DateHelper.getStartOfDay(presupuesto.fechaInicio);
    final fin = DateHelper.getStartOfDay(presupuesto.fechaFin);
    final diasTranscurridos = presupuesto.getDiasTranscurridos();

    DateTime fechaActual = inicio;
    int contador = 0;

    while ((fechaActual.isBefore(fin) || DateHelper.isSameDay(fechaActual, fin)) 
           && contador < diasTranscurridos) {
      final monto = gastosPorDia[fechaActual] ?? 0;
      tendencia.add(DatoTendencia(fechaActual, monto));
      fechaActual = fechaActual.add(const Duration(days: 1));
      contador++;
    }

    return tendencia;
  }

  /// Calcula la proyección de cómo terminará el presupuesto
  double getProyeccion(Presupuesto presupuesto, List<Gasto> gastos) {
    final resumen = calcularResumen(presupuesto, gastos);
    return resumen.proyeccionFinal;
  }

  /// Obtiene el porcentaje de días con gastos vs total de días transcurridos
  double getPorcentajeDiasConGastos(Presupuesto presupuesto, List<Gasto> gastos) {
    final gastosActivos = gastos.where((g) => !g.deleted).toList();
    final diasTranscurridos = presupuesto.getDiasTranscurridos();
    
    if (diasTranscurridos == 0) return 0;

    final fechasConGastos = gastosActivos
        .map((g) => DateHelper.getStartOfDay(g.fecha))
        .toSet();
    
    return (fechasConGastos.length / diasTranscurridos) * 100;
  }

  /// Calcula el promedio de gasto por día con gastos (excluyendo días sin gastos)
  double getPromedioPorDiaConGastos(List<Gasto> gastos) {
    final gastosActivos = gastos.where((g) => !g.deleted).toList();
    if (gastosActivos.isEmpty) return 0;

    final fechasConGastos = gastosActivos
        .map((g) => DateHelper.getStartOfDay(g.fecha))
        .toSet();
    
    if (fechasConGastos.isEmpty) return 0;

    final totalGastado = gastosActivos.fold<double>(0, (sum, g) => sum + g.monto);
    return totalGastado / fechasConGastos.length;
  }

  /// Verifica si el usuario está gastando más que el promedio recomendado
  bool estaGastandoDeMas(Presupuesto presupuesto, List<Gasto> gastos) {
    final resumen = calcularResumen(presupuesto, gastos);
    final promedioRecomendado = presupuesto.montoTotal / presupuesto.getDiasTotales();
    return resumen.promedioDiarioReal > promedioRecomendado;
  }

  /// Calcula cuántos días puede seguir gastando al ritmo actual
  int getDiasRestantesAlRitmoActual(Presupuesto presupuesto, List<Gasto> gastos) {
    final resumen = calcularResumen(presupuesto, gastos);
    
    if (resumen.promedioDiarioReal == 0) {
      return presupuesto.getDiasRestantes();
    }

    final diasQueAlcanza = (resumen.montoDisponible / resumen.promedioDiarioReal).floor();
    return diasQueAlcanza;
  }
}

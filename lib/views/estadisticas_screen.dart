import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/presupuesto.dart';
import '../models/gasto.dart';
import '../models/resumen_presupuesto.dart';
import '../services/presupuesto_service.dart';
import '../services/gasto_service.dart';
import '../services/estadisticas_service.dart';
import '../utils/currency_helper.dart';
import '../utils/date_helper.dart';
import 'widgets/grafica_circular.dart';
import 'widgets/grafica_barras.dart';
import 'widgets/grafica_linea.dart';

/// Pantalla de estadísticas completas del presupuesto
class EstadisticasScreen extends StatelessWidget {
  final User user;
  final Presupuesto presupuesto;

  const EstadisticasScreen({
    super.key,
    required this.user,
    required this.presupuesto,
  });

  @override
  Widget build(BuildContext context) {
    final GastoService gastoService = GastoService();
    final EstadisticasService estadisticasService = EstadisticasService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Gasto>>(
        stream: gastoService.getTodosGastos(user.uid, presupuesto.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final gastos = snapshot.data ?? [];
          final resumen = estadisticasService.calcularResumen(presupuesto, gastos);
          final gastosPorCategoria = estadisticasService.getGastosPorCategoria(gastos);
          final top3Categorias = estadisticasService.getTop3Categorias(gastos);
          final diaMayorGasto = estadisticasService.getDiaMayorGasto(gastos);
          final diaMenorGasto = estadisticasService.getDiaMenorGasto(gastos);
          final tendencia = estadisticasService.getTendenciaGasto(presupuesto, gastos);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Resumen general
                _buildResumenGeneral(resumen),

                const Divider(height: 1),

                // Gráfica circular
                _buildSeccion(
                  titulo: 'Uso del Presupuesto',
                  child: GraficaCircular(
                    porcentajeUsado: resumen.porcentajeUsado,
                    montoGastado: resumen.montoGastado,
                    montoDisponible: resumen.montoDisponible,
                  ),
                ),

                const Divider(height: 1),

                // Gráfica de barras por categoría
                _buildSeccion(
                  titulo: 'Gastos por Categoría',
                  child: GraficaBarras(
                    gastosPorCategoria: gastosPorCategoria,
                  ),
                ),

                const Divider(height: 1),

                // Top 3 categorías
                if (top3Categorias.isNotEmpty)
                  _buildSeccion(
                    titulo: 'Top 3 Categorías',
                    child: Column(
                      children: top3Categorias.asMap().entries.map((entry) {
                        final index = entry.key;
                        final categoria = entry.value.key;
                        final monto = entry.value.value;
                        final total = gastosPorCategoria.values.fold<double>(0, (sum, val) => sum + val);
                        final porcentaje = (monto / total) * 100;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: categoria.color.withOpacity(0.2),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: categoria.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            categoria.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${porcentaje.toStringAsFixed(1)}% del total'),
                          trailing: Text(
                            CurrencyHelper.formatearMonto(monto),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const Divider(height: 1),

                // Estadísticas detalladas
                _buildSeccion(
                  titulo: 'Estadísticas Detalladas',
                  child: Column(
                    children: [
                      _buildEstadisticaItem(
                        icono: Icons.trending_up,
                        label: 'Promedio diario real',
                        valor: CurrencyHelper.formatearMonto(resumen.promedioDiarioReal),
                        color: Colors.blue,
                      ),
                      _buildEstadisticaItem(
                        icono: Icons.calendar_today,
                        label: 'Días con gastos',
                        valor: '${resumen.diasConGastos} de ${presupuesto.getDiasTranscurridos()}',
                        color: Colors.green,
                      ),
                      _buildEstadisticaItem(
                        icono: Icons.calendar_today_outlined,
                        label: 'Días sin gastos',
                        valor: '${resumen.diasSinGastos}',
                        color: Colors.grey,
                      ),
                      if (diaMayorGasto != null)
                        _buildEstadisticaItem(
                          icono: Icons.arrow_upward,
                          label: 'Día con mayor gasto',
                          valor: '${DateHelper.formatearFechaCorta(diaMayorGasto.fecha)} - ${CurrencyHelper.formatearMonto(diaMayorGasto.monto)}',
                          color: Colors.red,
                        ),
                      if (diaMenorGasto != null)
                        _buildEstadisticaItem(
                          icono: Icons.arrow_downward,
                          label: 'Día con menor gasto',
                          valor: '${DateHelper.formatearFechaCorta(diaMenorGasto.fecha)} - ${CurrencyHelper.formatearMonto(diaMenorGasto.monto)}',
                          color: Colors.orange,
                        ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Proyección
                _buildSeccion(
                  titulo: 'Proyección',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: resumen.proyeccionFinal >= 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          resumen.proyeccionFinal >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 48,
                          color: resumen.proyeccionFinal >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          resumen.proyeccionTexto,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: resumen.proyeccionFinal >= 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumenGeneral(ResumenPresupuesto resumen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF43A047),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            presupuesto.nombre.isEmpty ? 'Resumen del Presupuesto' : presupuesto.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateHelper.formatearFechaCorta(presupuesto.fechaInicio)} - ${DateHelper.formatearFechaCorta(presupuesto.fechaFin)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResumenItem(
                label: 'Presupuesto',
                valor: CurrencyHelper.formatearMonto(presupuesto.montoTotal),
              ),
              _buildResumenItem(
                label: 'Gastado',
                valor: CurrencyHelper.formatearMonto(resumen.montoGastado),
              ),
              _buildResumenItem(
                label: 'Disponible',
                valor: CurrencyHelper.formatearMonto(resumen.montoDisponible),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem({required String label, required String valor}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSeccion({required String titulo, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem({
    required IconData icono,
    required String label,
    required String valor,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

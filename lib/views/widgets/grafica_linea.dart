import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../services/estadisticas_service.dart';
import '../../utils/currency_helper.dart';
import '../../utils/date_helper.dart';

/// Widget de gráfica de línea para tendencia de gastos
class GraficaLinea extends StatelessWidget {
  final List<DatoTendencia> datosTendencia;

  const GraficaLinea({
    super.key,
    required this.datosTendencia,
  });

  @override
  Widget build(BuildContext context) {
    if (datosTendencia.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No hay datos de tendencia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: datosTendencia.isNotEmpty 
                ? (datosTendencia.map((d) => d.monto).reduce((a, b) => a > b ? a : b) / 5).clamp(1.0, double.infinity)
                : 10.0,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (datosTendencia.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= datosTendencia.length) {
                    return const SizedBox();
                  }
                  final fecha = datosTendencia[index].fecha;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${fecha.day}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _buildSpots(),
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Theme.of(context).primaryColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index < 0 || index >= datosTendencia.length) {
                    return null;
                  }
                  final dato = datosTendencia[index];
                  return LineTooltipItem(
                    '${DateHelper.formatearFechaCorta(dato.fecha)}\n${CurrencyHelper.formatearMonto(dato.monto)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return List.generate(
      datosTendencia.length,
      (index) => FlSpot(
        index.toDouble(),
        datosTendencia[index].monto,
      ),
    );
  }
}

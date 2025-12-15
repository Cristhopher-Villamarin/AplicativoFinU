import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/gasto.dart';
import '../../utils/currency_helper.dart';

/// Widget de gráfica de barras para gastos por categoría
class GraficaBarras extends StatefulWidget {
  final Map<CategoriaGasto, double> gastosPorCategoria;

  const GraficaBarras({
    super.key,
    required this.gastosPorCategoria,
  });

  @override
  State<GraficaBarras> createState() => _GraficaBarrasState();
}

class _GraficaBarrasState extends State<GraficaBarras> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Filtrar categorías con gastos
    final categoriasConGastos = widget.gastosPorCategoria.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (categoriasConGastos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No hay gastos por categoría',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final categoria = categoriasConGastos[groupIndex].key;
                    final monto = categoriasConGastos[groupIndex].value;
                    return BarTooltipItem(
                      '${categoria.nombre}\n${CurrencyHelper.formatearMonto(monto)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= categoriasConGastos.length) {
                        return const SizedBox();
                      }
                      final categoria = categoriasConGastos[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          categoria.icono,
                          size: 20,
                          color: categoria.color,
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
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: categoriasConGastos.isNotEmpty
                    ? (categoriasConGastos.map((e) => e.value).reduce((a, b) => a > b ? a : b) / 5)
                    : 10,
              ),
              barGroups: _buildBarGroups(categoriasConGastos),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(categoriasConGastos),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<MapEntry<CategoriaGasto, double>> categorias) {
    return List.generate(categorias.length, (index) {
      final categoria = categorias[index].key;
      final monto = categorias[index].value;
      final isTouched = index == _touchedIndex;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monto,
            color: categoria.color,
            width: isTouched ? 30 : 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });
  }

  Widget _buildLegend(List<MapEntry<CategoriaGasto, double>> categorias) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categorias.map((entry) {
        final total = widget.gastosPorCategoria.values.fold<double>(0, (sum, val) => sum + val);
        final porcentaje = total > 0 ? (entry.value / total) * 100 : 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(entry.key.icono, size: 16, color: entry.key.color),
            const SizedBox(width: 4),
            Text(
              '${entry.key.nombre}: ${porcentaje.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        );
      }).toList(),
    );
  }
}

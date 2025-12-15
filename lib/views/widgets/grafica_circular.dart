import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/currency_helper.dart';

/// Widget de gráfica circular (pie chart) para porcentaje de presupuesto usado
class GraficaCircular extends StatefulWidget {
  final double porcentajeUsado;
  final double montoGastado;
  final double montoDisponible;

  const GraficaCircular({
    super.key,
    required this.porcentajeUsado,
    required this.montoGastado,
    required this.montoDisponible,
  });

  @override
  State<GraficaCircular> createState() => _GraficaCircularState();
}

class _GraficaCircularState extends State<GraficaCircular> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: _buildSections(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    final porcentajeGastado = widget.porcentajeUsado.clamp(0.0, 100.0);
    final porcentajeDisponible = 100.0 - porcentajeGastado;

    return [
      PieChartSectionData(
        color: Colors.red.shade400,
        value: porcentajeGastado,
        title: '${porcentajeGastado.toStringAsFixed(1)}%',
        radius: _touchedIndex == 0 ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: _touchedIndex == 0 ? 18 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.green.shade400,
        value: porcentajeDisponible,
        title: '${porcentajeDisponible.toStringAsFixed(1)}%',
        radius: _touchedIndex == 1 ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: _touchedIndex == 1 ? 18 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          color: Colors.red.shade400,
          label: 'Gastado',
          valor: CurrencyHelper.formatearMonto(widget.montoGastado),
        ),
        _buildLegendItem(
          color: Colors.green.shade400,
          label: 'Disponible',
          valor: CurrencyHelper.formatearMonto(widget.montoDisponible),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String valor,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

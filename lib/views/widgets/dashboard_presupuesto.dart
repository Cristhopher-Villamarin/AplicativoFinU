import 'package:flutter/material.dart';
import '../../models/presupuesto.dart';
import '../../models/resumen_presupuesto.dart';
import '../../utils/currency_helper.dart';
import '../../utils/date_helper.dart';
import '../../utils/color_helper.dart';

/// Widget del dashboard de presupuesto colapsable
class DashboardPresupuesto extends StatefulWidget {
  final Presupuesto presupuesto;
  final ResumenPresupuesto resumen;
  final bool inicialmenteColapsado;

  const DashboardPresupuesto({
    super.key,
    required this.presupuesto,
    required this.resumen,
    this.inicialmenteColapsado = false,
  });

  @override
  State<DashboardPresupuesto> createState() => _DashboardPresupuestoState();
}

class _DashboardPresupuestoState extends State<DashboardPresupuesto>
    with SingleTickerProviderStateMixin {
  late bool _isColapsado;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isColapsado = widget.inicialmenteColapsado;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (!_isColapsado) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleColapsar() {
    setState(() {
      _isColapsado = !_isColapsado;
      if (_isColapsado) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = widget.resumen.porcentajeUsado;
    final gradient = ColorHelper.getGradienteDashboard(porcentaje);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Swipe hacia arriba para colapsar
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          if (!_isColapsado) {
            _toggleColapsar();
          }
        }
        // Swipe hacia abajo para expandir
        else if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          if (_isColapsado) {
            _toggleColapsar();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header siempre visible
              _buildHeader(),
              
              // Contenido expandible
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildContenidoExpandido(),
              ),
              
              // Indicador de colapsar/expandir
              _buildIndicadorColapsar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre y rango de fechas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.presupuesto.nombre.isEmpty
                          ? 'Presupuesto'
                          : widget.presupuesto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateHelper.formatearRango(
                        widget.presupuesto.fechaInicio,
                        widget.presupuesto.fechaFin,
                      ),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Días restantes
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.presupuesto.getDiasRestantes()} días',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Monto disponible destacado
          Text(
            CurrencyHelper.formatearMonto(widget.resumen.montoDisponible),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Barra de progreso
          _buildBarraProgreso(),
        ],
      ),
    );
  }

  Widget _buildBarraProgreso() {
    final porcentaje = widget.resumen.porcentajeUsado.clamp(0.0, 100.0);
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: porcentaje / 100,
            minHeight: 20,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.resumen.estaSobregiro
                  ? Colors.red.shade900
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${porcentaje.toStringAsFixed(1)}% usado',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              CurrencyHelper.formatearMonto(widget.resumen.montoGastado),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContenidoExpandido() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          const Divider(color: Colors.white24, height: 24),
          
          // Estadísticas en dos columnas
          Row(
            children: [
              Expanded(
                child: _buildEstadisticaItem(
                  'Total',
                  CurrencyHelper.formatearMonto(widget.presupuesto.montoTotal),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildEstadisticaItem(
                  'Gastado',
                  CurrencyHelper.formatearMonto(widget.resumen.montoGastado),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildEstadisticaItem(
                  'Promedio diario',
                  CurrencyHelper.formatearMonto(
                    widget.resumen.promedioDiarioDisponible,
                  ),
                  subtitle: 'disponible',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildEstadisticaItem(
                  'Promedio real',
                  CurrencyHelper.formatearMonto(
                    widget.resumen.promedioDiarioReal,
                  ),
                  subtitle: 'gastado/día',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem(String label, String valor, {String? subtitle}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
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
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIndicadorColapsar() {
    return GestureDetector(
      onTap: _toggleColapsar,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
        ),
        child: Icon(
          _isColapsado
              ? Icons.keyboard_arrow_down
              : Icons.keyboard_arrow_up,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

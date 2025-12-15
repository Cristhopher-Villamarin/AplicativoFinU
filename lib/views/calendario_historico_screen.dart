import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/presupuesto.dart';
import '../models/gasto.dart';
import '../models/resumen_presupuesto.dart';
import '../services/gasto_service.dart';
import '../services/estadisticas_service.dart';
import '../utils/date_helper.dart';
import '../utils/currency_helper.dart';
import 'widgets/dashboard_presupuesto.dart';
import 'widgets/calendario_widget.dart';
import 'widgets/dia_detalle_bottom_sheet.dart';
import 'estadisticas_screen.dart';

/// Pantalla de calendario histórico (solo lectura)
class CalendarioHistoricoScreen extends StatefulWidget {
  final User user;
  final Presupuesto presupuesto;

  const CalendarioHistoricoScreen({
    super.key,
    required this.user,
    required this.presupuesto,
  });

  @override
  State<CalendarioHistoricoScreen> createState() => _CalendarioHistoricoScreenState();
}

class _CalendarioHistoricoScreenState extends State<CalendarioHistoricoScreen> {
  final GastoService _gastoService = GastoService();
  final EstadisticasService _estadisticasService = EstadisticasService();

  List<Gasto> _gastosDelMes = [];
  Map<DateTime, double> _totalesPorDia = {};
  DateTime _mesFocused = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mesFocused = widget.presupuesto.fechaInicio;
    _cargarGastosDelMes(widget.presupuesto.id, _mesFocused);
  }

  Future<void> _cargarGastosDelMes(String presupuestoId, DateTime mes) async {
    final gastos = await _gastoService.getGastosPorMes(
widget.user.uid,
      presupuestoId,
      mes.month,
      mes.year,
    );
    
    if (mounted) {
      setState(() {
        _gastosDelMes = gastos;
        _totalesPorDia = {};
        for (var gasto in gastos) {
          final fechaSinHora = DateHelper.getStartOfDay(gasto.fecha);
          _totalesPorDia[fechaSinHora] = (_totalesPorDia[fechaSinHora] ?? 0) + gasto.monto;
        }
      });
    }
  }

  void _mostrarDetallesDia(DateTime fecha) {
    final gastosDelDia = _gastosDelMes
        .where((g) => DateHelper.isSameDay(g.fecha, fecha))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StreamBuilder<List<Gasto>>(
            stream: _gastoService.getTodosGastos(
              widget.user.uid,
              widget.presupuesto.id,
            ),
            builder: (context, snapshot) {
              final todosGastos = snapshot.data ?? [];
              final gastosDelDia = todosGastos
                  .where((g) => DateHelper.isSameDay(g.fecha, fecha))
                  .toList();

              return DiaDetalleBottomSheet(
                fecha: fecha,
                presupuesto: widget.presupuesto,
                gastos: gastosDelDia,
                onAgregarGasto: (monto, categoria, descripcion) async {
                  await _agregarGasto(fecha, monto, categoria, descripcion);
                },
                onEditarGasto: (gasto, nuevoMonto, nuevaCategoria, nuevaDescripcion) async {
                  await _editarGasto(gasto, nuevoMonto, nuevaCategoria, nuevaDescripcion);
                },
                onEliminarGasto: (gasto) async {
                  await _eliminarGasto(gasto);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _agregarGasto(
    DateTime fecha,
    double monto,
    CategoriaGasto categoria,
    String descripcion,
  ) async {
    try {
      final nuevoGasto = Gasto(
        id: '',
        monto: monto,
        categoria: categoria,
        descripcion: descripcion,
        fecha: DateHelper.getStartOfDay(fecha),
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deleted: false,
      );

      await _gastoService.crearGasto(
        widget.user.uid,
        widget.presupuesto.id,
        nuevoGasto,
      );

      await _cargarGastosDelMes(widget.presupuesto.id, _mesFocused);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editarGasto(
    Gasto gasto,
    double nuevoMonto,
    CategoriaGasto nuevaCategoria,
    String nuevaDescripcion,
  ) async {
    try {
      final gastoActualizado = gasto.copyWith(
        monto: nuevoMonto,
        categoria: nuevaCategoria,
        descripcion: nuevaDescripcion,
        updatedAt: DateTime.now(),
      );

      await _gastoService.actualizarGasto(
        widget.user.uid,
        widget.presupuesto.id,
        gasto.id,
        gastoActualizado,
      );

      await _cargarGastosDelMes(widget.presupuesto.id, _mesFocused);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al editar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarGasto(Gasto gasto) async {
    try {
      await _gastoService.eliminarGasto(
        widget.user.uid,
        widget.presupuesto.id,
        gasto.id,
      );

      await _cargarGastosDelMes(widget.presupuesto.id, _mesFocused);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar gasto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.presupuesto.nombre.isEmpty
              ? 'Presupuesto Histórico'
              : widget.presupuesto.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EstadisticasScreen(
                    user: widget.user,
                    presupuesto: widget.presupuesto,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Gasto>>(
        future: _gastoService.getTodosGastos(widget.user.uid, widget.presupuesto.id).first,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todosGastos = snapshot.data ?? [];
          final resumen = _estadisticasService.calcularResumen(
            widget.presupuesto,
            todosGastos,
          );

          final promedioDiarioSugerido = widget.presupuesto.montoTotal / widget.presupuesto.getDiasTotales();

          return Column(
            children: [
              // Dashboard (no colapsable en histórico)
              DashboardPresupuesto(
                presupuesto: widget.presupuesto,
                resumen: resumen,
                inicialmenteColapsado: false,
              ),

              // Mensaje informativo
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Presupuesto finalizado - Puedes agregar/editar gastos',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Calendario
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CalendarioWidget(
                        presupuesto: widget.presupuesto,
                        totalesPorDia: _totalesPorDia,
                        promedioDiarioSugerido: promedioDiarioSugerido,
                        mesVisible: _mesFocused,
                        onDiaSeleccionado: _mostrarDetallesDia,
                        onMesCambiado: (nuevoMes) {
                          setState(() {
                            _mesFocused = nuevoMes;
                          });
                          _cargarGastosDelMes(widget.presupuesto.id, nuevoMes);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

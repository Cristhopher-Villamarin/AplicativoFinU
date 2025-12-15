import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/presupuesto.dart';
import '../models/gasto.dart';
import '../models/resumen_presupuesto.dart';
import '../services/presupuesto_service.dart';
import '../services/gasto_service.dart';
import '../services/estadisticas_service.dart';
import '../services/auth_service.dart';
import '../utils/date_helper.dart';
import 'widgets/dashboard_presupuesto.dart';
import 'widgets/calendario_widget.dart';
import 'widgets/dia_detalle_bottom_sheet.dart';
import 'estadisticas_screen.dart';
import 'historial_presupuestos_screen.dart';
import 'main_home_page.dart';
import 'login_screen.dart';

/// Pantalla principal del calendario con presupuesto activo
class CalendarioPresupuestoScreen extends StatefulWidget {
  final User user;

  const CalendarioPresupuestoScreen({
    super.key,
    required this.user,
  });

  @override
  State<CalendarioPresupuestoScreen> createState() => _CalendarioPresupuestoScreenState();
}

class _CalendarioPresupuestoScreenState extends State<CalendarioPresupuestoScreen> {
  final PresupuestoService _presupuestoService = PresupuestoService();
  final GastoService _gastoService = GastoService();
  final EstadisticasService _estadisticasService = EstadisticasService();

  Presupuesto? _presupuestoActual;
  List<Gasto> _gastosDelMes = [];
  Map<DateTime, double> _totalesPorDia = {};
  DateTime _mesFocused = DateTime.now();
  
  // Flags para evitar bucles de carga
  String? _ultimoPresupuestoId;
  bool _cargandoGastos = false;

  @override
  void initState() {
    super.initState();
    _verificarPresupuestoVencido();
  }

  Future<void> _verificarPresupuestoVencido() async {
    await _presupuestoService.verificarYFinalizarPresupuestosVencidos(widget.user.uid);
  }

  Future<void> _cargarGastosDelMes(String presupuestoId, DateTime mes) async {
    // Evitar cargas duplicadas
    if (_cargandoGastos) return;
    
    _cargandoGastos = true;
    
    try {
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
    } finally {
      _cargandoGastos = false;
    }
  }

  void _onDiaSeleccionado(DateTime fecha) {
    if (_presupuestoActual == null) return;

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
              _presupuestoActual!.id,
            ),
            builder: (context, snapshot) {
              final todosGastos = snapshot.data ?? [];
              final gastosDelDia = todosGastos
                  .where((g) => DateHelper.isSameDay(g.fecha, fecha))
                  .toList();

              return DiaDetalleBottomSheet(
                fecha: fecha,
                presupuesto: _presupuestoActual!,
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
    if (_presupuestoActual == null) return;

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
        _presupuestoActual!.id,
        nuevoGasto,
      );

      // Recargar gastos del mes
      await _cargarGastosDelMes(_presupuestoActual!.id, _mesFocused);
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
    if (_presupuestoActual == null) return;

    try {
      final gastoActualizado = gasto.copyWith(
        monto: nuevoMonto,
        categoria: nuevaCategoria,
        descripcion: nuevaDescripcion,
        updatedAt: DateTime.now(),
      );

      await _gastoService.actualizarGasto(
        widget.user.uid,
        _presupuestoActual!.id,
        gasto.id,
        gastoActualizado,
      );

      // Recargar gastos del mes
      await _cargarGastosDelMes(_presupuestoActual!.id, _mesFocused);
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
    if (_presupuestoActual == null) return;

    try {
      await _gastoService.eliminarGasto(
        widget.user.uid,
        _presupuestoActual!.id,
        gasto.id,
      );

      // Recargar gastos del mes
      await _cargarGastosDelMes(_presupuestoActual!.id, _mesFocused);
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
    final AuthService authService = AuthService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Presupuesto',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'historial') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialPresupuestosScreen(user: widget.user),
                  ),
                );
              } else if (value == 'finalizar') {
                // Obtener presupuesto actual antes de finalizar
                final presupuesto = await _presupuestoService
                    .getPresupuestoActivo(widget.user.uid)
                    .first;
                
                if (presupuesto != null && context.mounted) {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Finalizar Presupuesto'),
                      content: const Text(
                        '¿Estás seguro de finalizar este presupuesto? '
                        'Se moverá al historial y no podrás agregar más gastos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                          ),
                          child: const Text('Finalizar'),
                        ),
                      ],
                    ),
                  );

                  if (confirmar == true) {
                    await _presupuestoService.finalizarPresupuestoManual(
                      widget.user.uid,
                      presupuesto.id,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Presupuesto finalizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Usar pushAndRemoveUntil para volver a MainHomePage sin errores
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MainHomePage(user: widget.user),
                        ),
                        (route) => false,
                      );
                    }
                  }
                }
              } else if (value == 'logout') {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'historial',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 12),
                    Text('Historial'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'finalizar',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Color(0xFF2E7D32)),
                    SizedBox(width: 12),
                    Text('Finalizar Presupuesto', style: TextStyle(color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<Presupuesto?>(
        stream: _presupuestoService.getPresupuestoActivo(widget.user.uid),
        builder: (context, snapshot) {
          final presupuesto = snapshot.data;
          if (presupuesto == null) return const SizedBox();
          
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EstadisticasScreen(
                    user: widget.user,
                    presupuesto: presupuesto,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Estadísticas'),
            backgroundColor: const Color(0xFF2E7D32),
          );
        },
      ),
      body: WillPopScope(
        onWillPop: () async {
          // Navegar a MainHomePage en lugar de simplemente hacer pop
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MainHomePage(user: widget.user),
            ),
            (route) => false,
          );
          return false;
        },
        child: StreamBuilder<Presupuesto?>(
          key: const ValueKey('presupuesto_activo'),
          stream: _presupuestoService.getPresupuestoActivo(widget.user.uid),
          builder: (context, presupuestoSnapshot) {
            if (presupuestoSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final presupuesto = presupuestoSnapshot.data;

            if (presupuesto == null) {
              // No hay presupuesto activo, regresar a MainHomePage
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainHomePage(user: widget.user),
                    ),
                  );
                }
              });
              return const Center(child: CircularProgressIndicator());
            }

            _presupuestoActual = presupuesto;

            // Cargar gastos solo si es un presupuesto diferente o es la primera vez
            if (_ultimoPresupuestoId != presupuesto.id) {
              _ultimoPresupuestoId = presupuesto.id;
              _mesFocused = presupuesto.fechaInicio;
              // Usar addPostFrameCallback para cargar después del build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _cargarGastosDelMes(presupuesto.id, _mesFocused);
              });
            }

            return StreamBuilder<List<Gasto>>(
              key: ValueKey('gastos_${presupuesto.id}'),
              stream: _gastoService.getTodosGastos(widget.user.uid, presupuesto.id),
              builder: (context, gastosSnapshot) {
                // Casting correcto de List<dynamic> a List<Gasto>
                final gastosData = gastosSnapshot.data;
                final todosGastos = gastosData?.cast<Gasto>().toList() ?? <Gasto>[];
                final resumen = _estadisticasService.calcularResumen(
                  presupuesto,
                  todosGastos,
                );

                final promedioDiarioSugerido = presupuesto.montoTotal / presupuesto.getDiasTotales();

                return Column(
                  children: [
                    // Dashboard colapsable
                    DashboardPresupuesto(
                      presupuesto: presupuesto,
                      resumen: resumen,
                    ),

                    // Calendario
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CalendarioWidget(
                              presupuesto: presupuesto,
                              totalesPorDia: _totalesPorDia,
                              promedioDiarioSugerido: promedioDiarioSugerido,
                              mesVisible: _mesFocused,
                              onDiaSeleccionado: _onDiaSeleccionado,
                              onMesCambiado: (nuevoMes) {
                                setState(() {
                                  _mesFocused = nuevoMes;
                                });
                                _cargarGastosDelMes(presupuesto.id, nuevoMes);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

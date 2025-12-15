import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/presupuesto.dart';
import '../models/gasto.dart';
import '../services/presupuesto_service.dart';
import '../services/gasto_service.dart';
import '../services/estadisticas_service.dart';
import '../utils/date_helper.dart';
import '../utils/currency_helper.dart';
import 'calendario_historico_screen.dart';
import 'estadisticas_screen.dart';

/// Pantalla de historial de presupuestos finalizados
class HistorialPresupuestosScreen extends StatefulWidget {
  final User user;

  const HistorialPresupuestosScreen({
    super.key,
    required this.user,
  });

  @override
  State<HistorialPresupuestosScreen> createState() => _HistorialPresupuestosScreenState();
}

class _HistorialPresupuestosScreenState extends State<HistorialPresupuestosScreen> {
  final PresupuestoService _presupuestoService = PresupuestoService();
  final GastoService _gastoService = GastoService();
  final EstadisticasService _estadisticasService = EstadisticasService();
  
  final _busquedaController = TextEditingController();
  List<Presupuesto> _presupuestosFiltrados = [];
  List<Presupuesto> _todosPresupuestos = [];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _filtrarPresupuestos(String query) {
    setState(() {
      if (query.isEmpty) {
        _presupuestosFiltrados = _todosPresupuestos;
      } else {
        _presupuestosFiltrados = _todosPresupuestos
            .where((p) => p.nombre.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _duplicarPresupuesto(Presupuesto presupuesto) async {
    try {
      await _presupuestoService.duplicarPresupuesto(widget.user.uid, presupuesto.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presupuesto duplicado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volver al calendario con el nuevo presupuesto
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Presupuesto presupuesto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Presupuesto'),
        content: Text(
          '¿Estás seguro de eliminar "${presupuesto.nombre}"? Esta acción eliminará también todos los gastos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _presupuestoService.eliminarPresupuesto(widget.user.uid, presupuesto.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presupuesto eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Presupuestos',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Presupuesto>>(
        future: _presupuestoService.getPresupuestosHistoricos(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final presupuestos = snapshot.data ?? [];
          
          if (_todosPresupuestos.isEmpty && presupuestos.isNotEmpty) {
            _todosPresupuestos = presupuestos;
            _presupuestosFiltrados = presupuestos;
          }

          if (presupuestos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay presupuestos finalizados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Campo de búsqueda
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: _filtrarPresupuestos,
                ),
              ),

              // Lista de presupuestos
              Expanded(
                child: _presupuestosFiltrados.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron resultados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _presupuestosFiltrados.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final presupuesto = _presupuestosFiltrados[index];
                          return _buildPresupuestoCard(presupuesto);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresupuestoCard(Presupuesto presupuesto) {
    return StreamBuilder(
      stream: _gastoService.getTodosGastos(widget.user.uid, presupuesto.id),
      builder: (context, AsyncSnapshot snapshot) {
        final gastosData = snapshot.data as List?;
        final gastos = gastosData?.cast<Gasto>().toList() ?? <Gasto>[];
        final resumen = _estadisticasService.calcularResumen(presupuesto, gastos);
        
        final esAhorro = resumen.montoDisponible >= 0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalendarioHistoricoScreen(
                    user: widget.user,
                    presupuesto: presupuesto,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              presupuesto.nombre.isEmpty
                                  ? 'Presupuesto'
                                  : presupuesto.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateHelper.formatearRango(
                                presupuesto.fechaInicio,
                                presupuesto.fechaFin,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Menú de opciones
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'calendario') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CalendarioHistoricoScreen(
                                  user: widget.user,
                                  presupuesto: presupuesto,
                                ),
                              ),
                            );
                          } else if (value == 'estadisticas') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EstadisticasScreen(
                                  user: widget.user,
                                  presupuesto: presupuesto,
                                ),
                              ),
                            );
                          } else if (value == 'duplicar') {
                            _duplicarPresupuesto(presupuesto);
                          } else if (value == 'eliminar') {
                            _confirmarEliminar(presupuesto);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'calendario',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20),
                                SizedBox(width: 12),
                                Text('Ver calendario'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'estadisticas',
                            child: Row(
                              children: [
                                Icon(Icons.bar_chart, size: 20),
                                SizedBox(width: 12),
                                Text('Ver estadísticas'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicar',
                            child: Row(
                              children: [
                                Icon(Icons.content_copy, size: 20),
                                SizedBox(width: 12),
                                Text('Duplicar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'eliminar',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Montos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMontoItem(
                        'Presupuesto',
                        CurrencyHelper.formatearMonto(presupuesto.montoTotal),
                      ),
                      _buildMontoItem(
                        'Gastado',
                        CurrencyHelper.formatearMonto(resumen.montoGastado),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Estado final
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: esAhorro ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          esAhorro ? Icons.check_circle : Icons.warning,
                          color: esAhorro ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          esAhorro
                              ? 'Ahorro de ${CurrencyHelper.formatearMonto(resumen.montoDisponible)}'
                              : 'Sobregiro de ${CurrencyHelper.formatearMonto(-resumen.montoDisponible)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: esAhorro ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMontoItem(String label, String valor) {
    return Column(
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

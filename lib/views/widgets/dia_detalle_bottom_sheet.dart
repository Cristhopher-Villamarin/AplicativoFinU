import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gasto.dart';
import '../../models/presupuesto.dart';
import '../../utils/date_helper.dart';
import '../../utils/currency_helper.dart';
import 'categoria_selector.dart';

/// Bottom sheet para mostrar y gestionar gastos de un día específico
class DiaDetalleBottomSheet extends StatefulWidget {
  final DateTime fecha;
  final Presupuesto presupuesto;
  final List<Gasto> gastos;
  final Function(double monto, CategoriaGasto categoria, String descripcion) onAgregarGasto;
  final Function(Gasto gasto, double nuevoMonto, CategoriaGasto nuevaCategoria, String nuevaDescripcion) onEditarGasto;
  final Function(Gasto gasto) onEliminarGasto;

  const DiaDetalleBottomSheet({
    super.key,
    required this.fecha,
    required this.presupuesto,
    required this.gastos,
    required this.onAgregarGasto,
    required this.onEditarGasto,
    required this.onEliminarGasto,
  });

  @override
  State<DiaDetalleBottomSheet> createState() => _DiaDetalleBottomSheetState();
}

class _DiaDetalleBottomSheetState extends State<DiaDetalleBottomSheet> {
  bool _mostrandoFormulario = false;
  Gasto? _gastoEditando;
  
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  CategoriaGasto _categoriaSeleccionada = CategoriaGasto.otros;

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  double get _totalDia {
    return widget.gastos.fold<double>(0, (sum, gasto) => sum + gasto.monto);
  }

  void _mostrarFormularioNuevo() {
    setState(() {
      _mostrandoFormulario = true;
      _gastoEditando = null;
      _montoController.clear();
      _descripcionController.clear();
      _categoriaSeleccionada = CategoriaGasto.otros;
    });
  }

  void _mostrarFormularioEditar(Gasto gasto) {
    setState(() {
      _mostrandoFormulario = true;
      _gastoEditando = gasto;
      _montoController.text = gasto.monto.toStringAsFixed(2);
      _descripcionController.text = gasto.descripcion;
      _categoriaSeleccionada = gasto.categoria;
    });
  }

  void _cancelarFormulario() {
    setState(() {
      _mostrandoFormulario = false;
      _gastoEditando = null;
      _montoController.clear();
      _descripcionController.clear();
    });
  }

  void _guardarGasto() {
    final montoTexto = _montoController.text.trim();
    final monto = CurrencyHelper.parseMonto(montoTexto);

    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final descripcion = _descripcionController.text.trim();

    if (_gastoEditando != null) {
      // Editar gasto existente
      widget.onEditarGasto(
        _gastoEditando!,
        monto,
        _categoriaSeleccionada,
        descripcion,
      );
    } else {
      // Crear nuevo gasto
      widget.onAgregarGasto(
        monto,
        _categoriaSeleccionada,
        descripcion,
      );
    }

    _cancelarFormulario();
    
    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_gastoEditando != null
            ? 'Gasto actualizado'
            : 'Gasto agregado'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle para arrastrar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Encabezado
          _buildEncabezado(),
          
          const Divider(height: 1),
          
          // Contenido scrollable
          Flexible(
            child: _mostrandoFormulario
                ? _buildFormularioGasto()
                : _buildListaGastos(),
          ),
          
          // Botón de acción
          if (!_mostrandoFormulario) _buildBotonAgregar(),
        ],
      ),
    );
  }

  Widget _buildEncabezado() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateHelper.formatearFecha(widget.fecha),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.gastos.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${CurrencyHelper.formatearMonto(_totalDia)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildListaGastos() {
    if (widget.gastos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay gastos registrados este día',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.gastos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final gasto = widget.gastos[index];
        return Dismissible(
          key: Key(gasto.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _mostrarDialogoEliminar(gasto);
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: _buildGastoItem(gasto),
        );
      },
    );
  }

  Widget _buildGastoItem(Gasto gasto) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: gasto.categoria.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          gasto.categoria.icono,
          color: gasto.categoria.color,
        ),
      ),
      title: Text(
        gasto.descripcion.isEmpty
            ? gasto.categoria.nombre
            : gasto.descripcion,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${DateHelper.formatearHora(gasto.timestamp)} • ${gasto.categoria.nombre}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyHelper.formatearMonto(gasto.monto),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'editar') {
                _mostrarFormularioEditar(gasto);
              } else if (value == 'eliminar') {
                _confirmarEliminar(gasto);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Editar'),
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
    );
  }

  Widget _buildFormularioGasto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _gastoEditando != null ? 'Editar Gasto' : 'Agregar Gasto',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Campo de monto
          TextField(
            controller: _montoController,
            autofocus: _gastoEditando == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Monto',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Selector de categoría
          const Text(
            'Categoría',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          CategoriaSelector(
            categoriaSeleccionada: _categoriaSeleccionada,
            onCategoriaSeleccionada: (categoria) {
              setState(() {
                _categoriaSeleccionada = categoria;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Campo de descripción
          TextField(
            controller: _descripcionController,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            maxLines: 1,
          ),
          
          const SizedBox(height: 24),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelarFormulario,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _guardarGasto,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_gastoEditando != null
                      ? 'Guardar Cambios'
                      : 'Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAgregar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _mostrarFormularioNuevo,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Gasto'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<bool?> _mostrarDialogoEliminar(Gasto gasto) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Estás seguro de eliminar este gasto de ${CurrencyHelper.formatearMonto(gasto.monto)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              widget.onEliminarGasto(gasto);
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(Gasto gasto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Estás seguro de eliminar este gasto de ${CurrencyHelper.formatearMonto(gasto.monto)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              widget.onEliminarGasto(gasto);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

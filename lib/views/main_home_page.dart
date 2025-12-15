import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/presupuesto.dart';
import '../services/presupuesto_service.dart';
import '../services/auth_service.dart';
import '../utils/date_helper.dart';
import '../utils/currency_helper.dart';
import 'calendario_presupuesto_screen.dart';
import 'login_screen.dart';

/// Pantalla principal que detecta el presupuesto activo
class MainHomePage extends StatefulWidget {
  final User user;

  const MainHomePage({
    super.key,
    required this.user,
  });

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  final PresupuestoService _presupuestoService = PresupuestoService();
  final AuthService _authService = AuthService();

  bool _mostrandoFormulario = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  
  int _periodoMeses = 1;
  bool _periodoPersonalizado = false;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _crearPresupuesto() async {
    if (!_formKey.currentState!.validate()) return;

    final monto = CurrencyHelper.parseMonto(_montoController.text.trim());
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime fechaInicio;
    DateTime fechaFin;

    if (_periodoPersonalizado) {
      if (_fechaInicio == null || _fechaFin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona las fechas del presupuesto'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      fechaInicio = _fechaInicio!;
      fechaFin = _fechaFin!;
    } else {
      fechaInicio = DateHelper.getStartOfDay(DateTime.now());
      fechaFin = DateHelper.getStartOfDay(
        DateTime(
          fechaInicio.year,
          fechaInicio.month + _periodoMeses,
          fechaInicio.day,
        ).subtract(const Duration(days: 1)),
      );
    }

    // Validar que fecha fin sea posterior a fecha inicio
    if (fechaFin.isBefore(fechaInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior a la fecha de inicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final nuevoPresupuesto = Presupuesto(
        id: '',
        nombre: _nombreController.text.trim(),
        montoTotal: monto,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: 'activo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _presupuestoService.crearPresupuesto(
        widget.user.uid,
        nuevoPresupuesto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Presupuesto creado exitosamente!'),
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

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = DateHelper.getStartOfDay(fechaSeleccionada);
        } else {
          _fechaFin = DateHelper.getStartOfDay(fechaSeleccionada);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FinU - Gestión de Presupuestos',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF43A047),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<Presupuesto?>(
        stream: _presupuestoService.getPresupuestoActivo(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final presupuesto = snapshot.data;

          if (presupuesto != null) {
            // Hay presupuesto activo, navegar al calendario
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CalendarioPresupuestoScreen(user: widget.user),
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          // No hay presupuesto activo, mostrar formulario de creación
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E9),
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _buildFormularioCreacion(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormularioCreacion() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ícono y título
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,size: 64,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Crear Nuevo Presupuesto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Define tu presupuesto para empezar a gestionar tus gastos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Campo nombre (opcional)
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre del presupuesto (opcional)',
              hintText: 'Ej: Presupuesto Enero',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Campo monto
          TextFormField(
            controller: _montoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Monto total *',
              hintText: '1000.00',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El monto es obligatorio';
              }
              final monto = CurrencyHelper.parseMonto(value);
              if (monto == null || monto <= 0) {
                return 'Ingresa un monto válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Selector de período
          const Text(
            'Período del presupuesto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          if (!_periodoPersonalizado) ...[
            // Opciones predefinidas
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('1 mes'),
                  selected: _periodoMeses == 1,
                  onSelected: (selected) {
                    setState(() {
                      _periodoMeses = 1;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('2 meses'),
                  selected: _periodoMeses == 2,
                  onSelected: (selected) {
                    setState(() {
                      _periodoMeses = 2;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('3 meses'),
                  selected: _periodoMeses == 3,
                  onSelected: (selected) {
                    setState(() {
                      _periodoMeses = 3;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _periodoPersonalizado = true;
                });
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Personalizar período'),
            ),
          ] else ...[
            // Selector de rango personalizado
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarFecha(true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _fechaInicio != null
                          ? DateHelper.formatearFechaCorta(_fechaInicio!)
                          : 'Fecha inicio',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarFecha(false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _fechaFin != null
                          ? DateHelper.formatearFechaCorta(_fechaFin!)
                          : 'Fecha fin',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _periodoPersonalizado = false;
                  _fechaInicio = null;
                  _fechaFin = null;
                });
              },
              icon: const Icon(Icons.close),
              label: const Text('Usar período predefinido'),
            ),
          ],

          const SizedBox(height: 32),

          // Botón crear
          ElevatedButton(
            onPressed: _crearPresupuesto,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text(
              'Crear Presupuesto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

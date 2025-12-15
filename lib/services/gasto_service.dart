import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gasto.dart';
import '../utils/date_helper.dart';

/// Servicio para gestionar gastos en Firestore
class GastoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene la referencia a la colección de gastos de un presupuesto
  CollectionReference _getGastosCollection(String userId, String presupuestoId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('presupuestos')
        .doc(presupuestoId)
        .collection('gastos');
  }

  /// Crea un nuevo gasto
  Future<String> crearGasto(String userId, String presupuestoId, Gasto gasto) async {
    final docRef = await _getGastosCollection(userId, presupuestoId).add(
      gasto.toFirestore(),
    );
    return docRef.id;
  }

  /// Obtiene todos los gastos de un presupuesto como Stream
  /// No incluye los gastos eliminados (soft delete)
  Stream<List<Gasto>> getTodosGastos(String userId, String presupuestoId) {
    return _getGastosCollection(userId, presupuestoId)
        .where('deleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Gasto.fromFirestore(doc))
              .toList();
        });
  }

  /// Obtiene los gastos de un día específico
  Future<List<Gasto>> getGastosPorDia(String userId, String presupuestoId, DateTime fecha) async {
    final startOfDay = DateHelper.getStartOfDay(fecha);
    final endOfDay = DateHelper.getEndOfDay(fecha);

    final snapshot = await _getGastosCollection(userId, presupuestoId)
        .where('deleted', isEqualTo: false)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('fecha')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
  }

  /// Obtiene los gastos de un mes específico
  Future<List<Gasto>> getGastosPorMes(String userId, String presupuestoId, int mes, int anio) async {
    final startOfMonth = DateTime(anio, mes, 1);
    final endOfMonth = DateHelper.getEndOfMonth(startOfMonth);

    final snapshot = await _getGastosCollection(userId, presupuestoId)
        .where('deleted', isEqualTo: false)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('fecha')
        .get();

    return snapshot.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
  }

  /// Obtiene el total gastado en un día específico
  Future<double> getTotalPorDia(String userId, String presupuestoId, DateTime fecha) async {
    final gastos = await getGastosPorDia(userId, presupuestoId, fecha);
    return gastos.fold<double>(0, (sum, gasto) => sum + gasto.monto);
  }

  /// Obtiene los gastos agrupados por categoría
  Future<Map<CategoriaGasto, double>> getGastosPorCategoria(String userId, String presupuestoId) async {
    final snapshot = await _getGastosCollection(userId, presupuestoId)
        .where('deleted', isEqualTo: false)
        .get();

    final gastos = snapshot.docs.map((doc) => Gasto.fromFirestore(doc)).toList();

    // Agrupar por categoría
    final Map<CategoriaGasto, double> gastosCategoria = {};
    for (var categoria in CategoriaGasto.values) {
      gastosCategoria[categoria] = 0;
    }

    for (var gasto in gastos) {
      gastosCategoria[gasto.categoria] = 
          (gastosCategoria[gasto.categoria] ?? 0) + gasto.monto;
    }

    return gastosCategoria;
  }

  /// Actualiza un gasto existente
  Future<void> actualizarGasto(String userId, String presupuestoId, String gastoId, Gasto gasto) async {
    await _getGastosCollection(userId, presupuestoId)
        .doc(gastoId)
        .update(gasto.toFirestore());
  }

  /// Elimina un gasto (soft delete)
  Future<void> eliminarGasto(String userId, String presupuestoId, String gastoId) async {
    await _getGastosCollection(userId, presupuestoId)
        .doc(gastoId)
        .update({
          'deleted': true,
          'updatedAt': Timestamp.now(),
        });
  }

  /// Obtiene un gasto específico por ID
  Future<Gasto?> getGastoPorId(String userId, String presupuestoId, String gastoId) async {
    final doc = await _getGastosCollection(userId, presupuestoId)
        .doc(gastoId)
        .get();
    
    if (!doc.exists) return null;
    return Gasto.fromFirestore(doc);
  }

  /// Obtiene el total gastado en todo el presupuesto
  Future<double> getTotalGastado(String userId, String presupuestoId) async {
    final snapshot = await _getGastosCollection(userId, presupuestoId)
        .where('deleted', isEqualTo: false)
        .get();

    final gastos = snapshot.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
    return gastos.fold<double>(0, (sum, gasto) => sum + gasto.monto);
  }

  /// Obtiene un mapa de fecha -> total gastado para todo el período
  Future<Map<DateTime, double>> getTotalesPorDia(String userId, String presupuestoId) async {
    final snapshot = await _getGastosCollection(userId, presupuestoId)
        .where('deleted', isEqualTo: false)
        .get();

    final gastos = snapshot.docs.map((doc) => Gasto.fromFirestore(doc)).toList();
    final Map<DateTime, double> totales = {};

    for (var gasto in gastos) {
      final fechaSinHora = DateHelper.getStartOfDay(gasto.fecha);
      totales[fechaSinHora] = (totales[fechaSinHora] ?? 0) + gasto.monto;
    }

    return totales;
  }

  /// Obtiene la cantidad de días con gastos
  Future<int> getDiasConGastos(String userId, String presupuestoId) async {
    final totales = await getTotalesPorDia(userId, presupuestoId);
    return totales.length;
  }
}

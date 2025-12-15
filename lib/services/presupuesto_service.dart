import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/presupuesto.dart';

/// Servicio para gestionar presupuestos en Firestore
class PresupuestoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene la referencia a la colección de presupuestos de un usuario
  CollectionReference _getPresupuestosCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('presupuestos');
  }

  /// Crea un nuevo presupuesto
  /// Valida que no exista otro presupuesto activo antes de crear
  Future<String> crearPresupuesto(String userId, Presupuesto presupuesto) async {
    // Validar que no exista un presupuesto activo
    final presupuestoActivo = await getPresupuestoActivo(userId).first;
    if (presupuestoActivo != null) {
      throw Exception('Ya existe un presupuesto activo. Finaliza el presupuesto actual antes de crear uno nuevo.');
    }

    final docRef = await _getPresupuestosCollection(userId).add(
      presupuesto.toFirestore(),
    );

    return docRef.id;
  }

  /// Obtiene el presupuesto activo del usuario como Stream
  Stream<Presupuesto?> getPresupuestoActivo(String userId) {
    return _getPresupuestosCollection(userId)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Presupuesto.fromFirestore(snapshot.docs.first);
        });
  }

  /// Obtiene un presupuesto específico por ID
  Future<Presupuesto?> getPresupuestoPorId(String userId, String presupuestoId) async {
    final doc = await _getPresupuestosCollection(userId).doc(presupuestoId).get();
    if (!doc.exists) return null;
    return Presupuesto.fromFirestore(doc);
  }

  /// Obtiene todos los presupuestos históricos (finalizados o cancelados)
  Future<List<Presupuesto>> getPresupuestosHistoricos(String userId) async {
    final snapshot = await _getPresupuestosCollection(userId)
        .where('estado', whereIn: ['finalizado', 'cancelado'])
        .orderBy('fechaFin', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Presupuesto.fromFirestore(doc))
        .toList();
  }

  /// Busca presupuestos históricos por nombre
  Future<List<Presupuesto>> buscarPresupuestosPorNombre(String userId, String nombre) async {
    final snapshot = await _getPresupuestosCollection(userId)
        .where('estado', whereIn: ['finalizado', 'cancelado'])
        .orderBy('fechaFin', descending: true)
        .get();

    // Filtrar por nombre en el cliente (Firestore no soporta búsqueda de texto parcial)
    return snapshot.docs
        .map((doc) => Presupuesto.fromFirestore(doc))
        .where((p) => p.nombre.toLowerCase().contains(nombre.toLowerCase()))
        .toList();
  }

  /// Finaliza un presupuesto cambiando su estado a 'finalizado'
  Future<void> finalizarPresupuesto(String userId, String presupuestoId) async {
    await _getPresupuestosCollection(userId).doc(presupuestoId).update({
      'estado': 'finalizado',
      'updatedAt': Timestamp.now(),
    });
  }

  /// Cancela un presupuesto cambiando su estado a 'cancelado'
  Future<void> cancelarPresupuesto(String userId, String presupuestoId) async {
    await _getPresupuestosCollection(userId).doc(presupuestoId).update({
      'estado': 'cancelado',
      'updatedAt': Timestamp.now(),
    });
  }

  /// Actualiza un presupuesto existente
  Future<void> actualizarPresupuesto(String userId, String presupuestoId, Presupuesto presupuesto) async {
    await _getPresupuestosCollection(userId).doc(presupuestoId).update(
      presupuesto.toFirestore(),
    );
  }

  /// Duplica un presupuesto existente creando uno nuevo con los mismos parámetros
  Future<String> duplicarPresupuesto(String userId, String presupuestoId) async {
    final presupuestoOriginal = await getPresupuestoPorId(userId, presupuestoId);
    if (presupuestoOriginal == null) {
      throw Exception('Presupuesto no encontrado');
    }

    // Calcular nuevas fechas (mismo período pero desde hoy)
    final diasPeriodo = presupuestoOriginal.getDiasTotales();
    final nuevaFechaInicio = DateTime.now();
    final nuevaFechaFin = nuevaFechaInicio.add(Duration(days: diasPeriodo - 1));

    final nuevoPresupuesto = Presupuesto(
      id: '', // Se generará automáticamente
      nombre: '${presupuestoOriginal.nombre} (Copia)',
      montoTotal: presupuestoOriginal.montoTotal,
      fechaInicio: nuevaFechaInicio,
      fechaFin: nuevaFechaFin,
      estado: 'activo',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await crearPresupuesto(userId, nuevoPresupuesto);
  }

  /// Elimina un presupuesto y todos sus gastos asociados
  Future<void> eliminarPresupuesto(String userId, String presupuestoId) async {
    // Primero eliminar todos los gastos
    final gastosSnapshot = await _getPresupuestosCollection(userId)
        .doc(presupuestoId)
        .collection('gastos')
        .get();

    final batch = _firestore.batch();

    // Agregar eliminación de cada gasto al batch
    for (var doc in gastosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Agregar eliminación del presupuesto al batch
    batch.delete(_getPresupuestosCollection(userId).doc(presupuestoId));

    // Ejecutar todas las eliminaciones
    await batch.commit();
  }

  /// Verifica y finaliza automáticamente presupuestos vencidos
  /// Este método debería llamarse al iniciar la app
  Future<void> verificarYFinalizarPresupuestosVencidos(String userId) async {
    final presupuestoActivo = await getPresupuestoActivo(userId).first;
    
    if (presupuestoActivo != null && presupuestoActivo.haFinalizado()) {
      await finalizarPresupuesto(userId, presupuestoActivo.id);
    }
  }

  /// Finaliza manualmente un presupuesto activo
  Future<void> finalizarPresupuestoManual(String userId, String presupuestoId) async {
    await _getPresupuestosCollection(userId).doc(presupuestoId).update({
      'estado': 'finalizado',
      'updatedAt': Timestamp.now(),
    });
  }
}

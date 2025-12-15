import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar un Presupuesto
class Presupuesto {
  final String id;
  final String nombre;
  final double montoTotal;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String estado; // 'activo', 'finalizado', 'cancelado'
  final DateTime createdAt;
  final DateTime updatedAt;

  Presupuesto({
    required this.id,
    required this.nombre,
    required this.montoTotal,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea un Presupuesto desde un documento de Firestore
  factory Presupuesto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Presupuesto(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      montoTotal: (data['montoTotal'] ?? 0).toDouble(),
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      estado: data['estado'] ?? 'activo',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convierte el Presupuesto a un Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'montoTotal': montoTotal,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'estado': estado,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Retorna el total de días del presupuesto
  int getDiasTotales() {
    return fechaFin.difference(fechaInicio).inDays + 1;
  }

  /// Retorna los días transcurridos desde el inicio
  int getDiasTranscurridos() {
    final now = DateTime.now();
    if (now.isBefore(fechaInicio)) return 0;
    if (now.isAfter(fechaFin)) return getDiasTotales();
    return now.difference(fechaInicio).inDays + 1;
  }

  /// Retorna los días restantes hasta el fin
  int getDiasRestantes() {
    final now = DateTime.now();
    if (now.isAfter(fechaFin)) return 0;
    return fechaFin.difference(now).inDays + 1;
  }

  /// Verifica si el presupuesto está activo
  bool isActivo() {
    return estado == 'activo';
  }

  /// Verifica si el presupuesto ha finalizado por fecha
  bool haFinalizado() {
    return DateTime.now().isAfter(fechaFin);
  }

  /// Verifica si una fecha está dentro del periodo del presupuesto
  bool estaEnPeriodo(DateTime fecha) {
    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final inicioSinHora = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final finSinHora = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    
    return (fechaSinHora.isAtSameMomentAs(inicioSinHora) || fechaSinHora.isAfter(inicioSinHora)) &&
           (fechaSinHora.isAtSameMomentAs(finSinHora) || fechaSinHora.isBefore(finSinHora));
  }

  /// Crea una copia del presupuesto con campos modificados
  Presupuesto copyWith({
    String? id,
    String? nombre,
    double? montoTotal,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Presupuesto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      montoTotal: montoTotal ?? this.montoTotal,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

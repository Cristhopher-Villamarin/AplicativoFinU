import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Categorías predefinidas para gastos
enum CategoriaGasto {
  alimentacion,
  transporte,
  educacion,
  entretenimiento,
  salud,
  otros,
}

/// Extensión para obtener detalles de cada categoría
extension CategoriaGastoExtension on CategoriaGasto {
  /// Nombre legible de la categoría
  String get nombre {
    switch (this) {
      case CategoriaGasto.alimentacion:
        return 'Alimentación';
      case CategoriaGasto.transporte:
        return 'Transporte';
      case CategoriaGasto.educacion:
        return 'Educación';
      case CategoriaGasto.entretenimiento:
        return 'Entretenimiento';
      case CategoriaGasto.salud:
        return 'Salud';
      case CategoriaGasto.otros:
        return 'Otros';
    }
  }

  /// Icono asociado a la categoría
  IconData get icono {
    switch (this) {
      case CategoriaGasto.alimentacion:
        return Icons.restaurant;
      case CategoriaGasto.transporte:
        return Icons.directions_bus;
      case CategoriaGasto.educacion:
        return Icons.school;
      case CategoriaGasto.entretenimiento:
        return Icons.movie;
      case CategoriaGasto.salud:
        return Icons.local_hospital;
      case CategoriaGasto.otros:
        return Icons.shopping_bag;
    }
  }

  /// Color asociado a la categoría
  Color get color {
    switch (this) {
      case CategoriaGasto.alimentacion:
        return const Color(0xFFFF6B6B); // Rojo suave
      case CategoriaGasto.transporte:
        return const Color(0xFF4ECDC4); // Turquesa
      case CategoriaGasto.educacion:
        return const Color(0xFF45B7D1); // Azul
      case CategoriaGasto.entretenimiento:
        return const Color(0xFFFFA07A); // Naranja suave
      case CategoriaGasto.salud:
        return const Color(0xFF98D8C8); // Verde menta
      case CategoriaGasto.otros:
        return const Color(0xFF95A5A6); // Gris
    }
  }

  /// Convierte el enum a string para guardar en Firestore
  String toFirestore() {
    return toString().split('.').last;
  }

  /// Convierte un string de Firestore a enum
  static CategoriaGasto fromFirestore(String value) {
    return CategoriaGasto.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => CategoriaGasto.otros,
    );
  }
}

/// Modelo para representar un Gasto
class Gasto {
  final String id;
  final double monto;
  final CategoriaGasto categoria;
  final String descripcion;
  final DateTime fecha; // Fecha del gasto (sin hora específica)
  final DateTime timestamp; // Timestamp completo del registro
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  Gasto({
    required this.id,
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  /// Crea un Gasto desde un documento de Firestore
  factory Gasto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gasto(
      id: doc.id,
      monto: (data['monto'] ?? 0).toDouble(),
      categoria: CategoriaGastoExtension.fromFirestore(data['categoria'] ?? 'otros'),
      descripcion: data['descripcion'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deleted: data['deleted'] ?? false,
    );
  }

  /// Convierte el Gasto a un Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'monto': monto,
      'categoria': categoria.toFirestore(),
      'descripcion': descripcion,
      'fecha': Timestamp.fromDate(fecha),
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deleted': deleted,
    };
  }

  /// Crea una copia del gasto con campos modificados
  Gasto copyWith({
    String? id,
    double? monto,
    CategoriaGasto? categoria,
    String? descripcion,
    DateTime? fecha,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Gasto(
      id: id ?? this.id,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Retorna el icono de la categoría
  IconData getCategoriaIcon() {
    return categoria.icono;
  }

  /// Retorna el color de la categoría
  Color getCategoriaColor() {
    return categoria.color;
  }

  /// Retorna el nombre de la categoría
  String getCategoriaNombre() {
    return categoria.nombre;
  }
}

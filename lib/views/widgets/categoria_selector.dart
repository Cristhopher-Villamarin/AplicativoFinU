import 'package:flutter/material.dart';
import '../../models/gasto.dart';

/// Widget selector horizontal de categorías para gastos
class CategoriaSelector extends StatelessWidget {
  final CategoriaGasto? categoriaSeleccionada;
  final Function(CategoriaGasto) onCategoriaSeleccionada;

  const CategoriaSelector({
    super.key,
    this.categoriaSeleccionada,
    required this.onCategoriaSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: CategoriaGasto.values.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final categoria = CategoriaGasto.values[index];
          final isSeleccionada = categoria == categoriaSeleccionada;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => onCategoriaSeleccionada(categoria),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                decoration: BoxDecoration(
                  color: isSeleccionada
                      ? categoria.color
                      : categoria.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSeleccionada
                        ? categoria.color
                        : categoria.color.withOpacity(0.5),
                    width: isSeleccionada ? 3 : 2,
                  ),
                  boxShadow: isSeleccionada
                      ? [
                          BoxShadow(
                            color: categoria.color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categoria.icono,
                      size: 32,
                      color: isSeleccionada
                          ? Colors.white
                          : categoria.color,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categoria.nombre,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSeleccionada
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSeleccionada
                            ? Colors.white
                            : categoria.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/presupuesto.dart';
import '../../utils/date_helper.dart';
import '../../utils/currency_helper.dart';
import '../../utils/color_helper.dart';

/// Widget del calendario interactivo
class CalendarioWidget extends StatefulWidget {
  final Presupuesto presupuesto;
  final Map<DateTime, double> totalesPorDia;
  final double promedioDiarioSugerido;
  final DateTime? mesVisible;
  final Function(DateTime) onDiaSeleccionado;
  final Function(DateTime)? onMesCambiado;

  const CalendarioWidget({
    super.key,
    required this.presupuesto,
    required this.totalesPorDia,
    required this.promedioDiarioSugerido,
    this.mesVisible,
    required this.onDiaSeleccionado,
    this.onMesCambiado,
  });

  @override
  State<CalendarioWidget> createState() => _CalendarioWidgetState();
}

class _CalendarioWidgetState extends State<CalendarioWidget> {
  late DateTime _fechaFocused;
  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    _fechaFocused = widget.mesVisible ?? DateHelper.getStartOfDay(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: widget.presupuesto.fechaInicio,
      lastDay: widget.presupuesto.fechaFin,
      focusedDay: _fechaFocused,
      locale: 'es_ES',
      
      // Configuración de formato
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mes',
      },
      
      // Configuración de encabezado
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextFormatter: (date, locale) =>
            DateHelper.formatearMesAnio(date),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          color: ColorHelper.primario,
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          color: ColorHelper.primario,
        ),
      ),
      
      // Configuración de días de la semana
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        weekendStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.red,
        ),
      ),
      
      // Estilo de celdas
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(4),
        cellPadding: const EdgeInsets.all(0),
        
        // Día seleccionado
        selectedDecoration: BoxDecoration(
          border: Border.all(
            color: ColorHelper.bordeaDiaActual,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        
        // Día de hoy
        todayDecoration: BoxDecoration(
          border: Border.all(
            color: ColorHelper.bordeaDiaActual,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        todayTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        
        // Días fuera del mes
        outsideDecoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        outsideTextStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
        
        // Días deshabilitados
        disabledDecoration: BoxDecoration(
          color: ColorHelper.diaFueraPeriodo,
          borderRadius: BorderRadius.circular(8),
        ),
        disabledTextStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
        
        // Días normales
        defaultDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        
        // Fines de semana
        weekendDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Builder personalizado para cada celda
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) =>
            _buildCelda(day, false, false),
        todayBuilder: (context, day, focusedDay) =>
            _buildCelda(day, true, false),
        selectedBuilder: (context, day, focusedDay) =>
            _buildCelda(day, false, true),
        outsideBuilder: (context, day, focusedDay) =>
            _buildCeldaExterna(day),
        disabledBuilder: (context, day, focusedDay) =>
            _buildCeldaDeshabilitada(day),
      ),
      
      // Determinar si un día está habilitado
      enabledDayPredicate: (day) {
        return widget.presupuesto.estaEnPeriodo(day);
      },
      
      // Día seleccionado
      selectedDayPredicate: (day) {
        return _fechaSeleccionada != null &&
               DateHelper.isSameDay(day, _fechaSeleccionada!);
      },
      
      // Callbacks
      onDaySelected: (selectedDay, focusedDay) {
        if (widget.presupuesto.estaEnPeriodo(selectedDay)) {
          setState(() {
            _fechaSeleccionada = selectedDay;
            _fechaFocused = focusedDay;
          });
          widget.onDiaSeleccionado(selectedDay);
        }
      },
      
      onPageChanged: (focusedDay) {
        setState(() {
          _fechaFocused = focusedDay;
        });
        widget.onMesCambiado?.call(focusedDay);
      },
    );
  }

  Widget _buildCelda(DateTime dia, bool esHoy, bool estaSeleccionado) {
    final fechaSinHora = DateHelper.getStartOfDay(dia);
    final total = widget.totalesPorDia[fechaSinHora] ?? 0;
    final color = ColorHelper.getColorNivelGasto(
      total,
      widget.promedioDiarioSugerido,
    );
    
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: esHoy
              ? ColorHelper.bordeaDiaActual
              : (estaSeleccionado
                  ? ColorHelper.bordeaDiaActual
                  : color),
          width: esHoy ? 2 : (estaSeleccionado ? 3 : 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${dia.day}',
            style: TextStyle(
              fontWeight: esHoy || estaSeleccionado
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: ColorHelper.getColorTexto(color),
              fontSize: 14,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 2),
            Text(
              CurrencyHelper.formatearMontoSinDecimales(total),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: ColorHelper.getColorTexto(color),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCeldaExterna(DateTime dia) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${dia.day}',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCeldaDeshabilitada(DateTime dia) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorHelper.diaFueraPeriodo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${dia.day}',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

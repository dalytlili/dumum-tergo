import 'dart:async';
import 'package:dumum_tergo/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class RentalCalendarView extends StatefulWidget {
  final Function(DateTime, DateTime) onPeriodSelected;

  const RentalCalendarView({Key? key, required this.onPeriodSelected}) : super(key: key);

  @override
  _RentalCalendarViewState createState() => _RentalCalendarViewState();
}

class _RentalCalendarViewState extends State<RentalCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isArrowVisible = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final int _minRentalDays = 3; // Minimum de 3 jours de location

  @override
  void initState() {
    super.initState();
    _startArrowAnimation();
  }

  void _startArrowAnimation() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _isArrowVisible = !_isArrowVisible;
        });
      }
    });
  }

  Widget _buildTimeSlider(BuildContext context, String label, TimeOfDay time, bool isStartTime) {
    // Convertir TimeOfDay en double pour le slider (0-23.99)
    double sliderValue = time.hour + time.minute / 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                _formatTime(time),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Slider(
                min: 0,
                max: 23.99,
                value: sliderValue,
                divisions: 24 * 4, // 15 minutes intervals
                label: _formatTime(time),
                onChanged: (value) {
                  final hour = value.floor();
                  final minute = ((value - hour) * 60).round();
                  final newTime = TimeOfDay(hour: hour, minute: minute);
                  
                  setState(() {
                    if (isStartTime) {
                      _startTime = newTime;
                    } else {
                      _endTime = newTime;
                    }
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('00:00', style: TextStyle(color: Colors.grey[600])),
                  Text('12:00', style: TextStyle(color: Colors.grey[600])),
                  Text('23:59', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
          final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Container(
         decoration: BoxDecoration(
          // fond selon le thème (clair/sombre)
          color: theme.cardTheme.color ?? (theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "Sélectionnez une période (minimum 3 jours)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day);
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  if (_rangeStart == null || _rangeEnd != null) {
                    _rangeStart = selectedDay;
                    _rangeEnd = null;
                  } else if (selectedDay.isAfter(_rangeStart!)) {
                    // Vérifier que la durée est d'au moins 3 jours
                    final daysDifference = selectedDay.difference(_rangeStart!).inDays + 1;
                    if (daysDifference >= _minRentalDays) {
                      _endTime = _startTime; // Set end time same as start by default
                      _rangeEnd = selectedDay;
                    } else {
                      // Afficher un message si la période est trop courte
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('La location minimale est de $_minRentalDays jours'),
                          duration: const Duration(seconds: 2),
                      ));
                    }
                  } else if (selectedDay.isBefore(_rangeStart!)) {
                    // Vérifier que la durée est d'au moins 3 jours
                    final daysDifference = _rangeStart!.difference(selectedDay).inDays + 1;
                    if (daysDifference >= _minRentalDays) {
                      _rangeEnd = _rangeStart;
                      _rangeStart = selectedDay;
                      // Swap times if dates are swapped
                      final tempTime = _startTime;
                      _startTime = _endTime;
                      _endTime = tempTime;
                    } else {
                      // Afficher un message si la période est trop courte
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('La location minimale est de $_minRentalDays jours'),
                          duration: const Duration(seconds: 2),
                      ));
                    }
                  } else {
                    _rangeStart = null;
                    _rangeEnd = null;
                  }
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                rangeStartDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: Theme.of(context).primaryColor.withOpacity(0.2),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (_rangeStart != null) ...[
              _buildTimeSlider(context, 'Heure de départ', _startTime, true),
              const SizedBox(height: 12),
            ],
            if (_rangeEnd != null) ...[
              _buildTimeSlider(context, 'Heure de retour', _endTime, false),
              const SizedBox(height: 12),
            ],
            Text(
              _rangeStart == null
                  ? 'Sélectionnez une période (minimum 3 jours)'
                  : _rangeEnd == null
                      ? 'Du ${_formatDate(_rangeStart!)} à ${_formatTime(_startTime)} au ...'
                      : 'Du ${_formatDate(_rangeStart!)} à ${_formatTime(_startTime)} au ${_formatDate(_rangeEnd!)} à ${_formatTime(_endTime)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
          ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: _rangeStart != null && _rangeEnd != null
        ? AppColors.primary
        : Colors.grey,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    minimumSize: Size(double.infinity, 50), // Largeur maximale + hauteur de 50
  ),


              onPressed: () {
                if (_rangeStart != null && _rangeEnd != null) {
                  // Vérifier à nouveau la durée minimale (au cas où)
                  final daysDifference = _rangeEnd!.difference(_rangeStart!).inDays.abs() + 1;
                  if (daysDifference >= _minRentalDays) {
                    // Combine dates with times
                    final startDateTime = DateTime(
                      _rangeStart!.year,
                      _rangeStart!.month,
                      _rangeStart!.day,
                      _startTime.hour,
                      _startTime.minute,
                    );
                    final endDateTime = DateTime(
                      _rangeEnd!.year,
                      _rangeEnd!.month,
                      _rangeEnd!.day,
                      _endTime.hour,
                      _endTime.minute,
                    );
                    widget.onPeriodSelected(startDateTime, endDateTime);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('La location minimale est de $_minRentalDays jours'),
                        duration: const Duration(seconds: 2),
                    ));
                  }
                }
              },
              child: const Text(
                "Confirmer",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16), // Espace supplémentaire en bas pour le défilement
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day) {
    bool isStart = _rangeStart != null && isSameDay(day, _rangeStart);
    bool isEnd = _rangeEnd != null && isSameDay(day, _rangeEnd);
    bool isNextToStart = _rangeStart != null &&
        _rangeEnd == null &&
        day.isAfter(_rangeStart!) &&
        day.difference(_rangeStart!).inDays == 1;

    return Stack(
      alignment: Alignment.center,
      children: [
   Container(
  decoration: BoxDecoration(
    color: isStart || isEnd
        ? AppColors.primary
        : Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]  // Couleur de fond en mode sombre
            : AppColors.background, // Couleur normale
    shape: BoxShape.circle,
  ),
  child: Center(
    child: Text(
      '${day.day}',
      style: TextStyle(
        color: isStart || isEnd 
            ? Colors.white 
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white70 // Texte plus doux en mode sombre
                : Colors.black, // Texte normal en mode clair
        fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  ),
),

        if (isNextToStart) _buildFlashingArrow(),
      ],
    );
  }

  Widget _buildFlashingArrow() {
    return Positioned(
      bottom: -5,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isArrowVisible ? 1.0 : 0.0,
        child: const Icon(
          Icons.arrow_forward,
          color: AppColors.primary,
          size: 16,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
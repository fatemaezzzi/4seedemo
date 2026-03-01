import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared_widgets.dart';

/// Shared CalendarPage — used by both TeacherProfilePage and AdminProfilePage.
/// Import path: pages/profile_subpages/shared/calendar_page.dart
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, List<Map<String, String>>> _events = {
    '2025-02-14': [
      {'title': 'Mid-term Exam – X A', 'type': 'exam'},
      {'title': 'Parent-Teacher Meeting', 'type': 'meeting'},
    ],
    '2025-02-18': [
      {'title': 'Science Lab Session', 'type': 'class'},
    ],
    '2025-02-21': [
      {'title': 'Staff Meeting 3 PM', 'type': 'meeting'},
    ],
    '2025-02-25': [
      {'title': 'Annual Sports Day', 'type': 'event'},
    ],
  };

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _typeColor(String t) {
    switch (t) {
      case 'exam':
        return Colors.red.shade400;
      case 'meeting':
        return Colors.orange.shade400;
      case 'class':
        return Colors.blue.shade400;
      default:
        return Colors.green.shade400;
    }
  }

  String _monthName(int m) => [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ][m];

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
    DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
    final selectedEvents =
    _selectedDay != null ? (_events[_key(_selectedDay!)] ?? []) : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => setState(() => _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                    ),
                    Text(
                      '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => setState(() => _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                    ),
                  ],
                ),
                // Day headers
                Row(
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                // Calendar grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: firstWeekday + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < firstWeekday) return const SizedBox();
                    final day = index - firstWeekday + 1;
                    final date =
                    DateTime(_focusedMonth.year, _focusedMonth.month, day);
                    final hasEvent = _events.containsKey(_key(date));
                    final isSelected = _selectedDay != null &&
                        _selectedDay!.year == date.year &&
                        _selectedDay!.month == date.month &&
                        _selectedDay!.day == date.day;
                    final isToday = date.year == DateTime.now().year &&
                        date.month == DateTime.now().month &&
                        date.day == DateTime.now().day;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = date),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : isToday
                              ? AppColors.surface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.accent, width: 1)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textDark
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasEvent)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.textDark
                                      : AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Events for selected day
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
              child: Text(
                _selectedDay == null
                    ? 'Tap a date to view events'
                    : 'No events on this day',
                style:
                const TextStyle(color: AppColors.textMuted),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: selectedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = selectedEvents[i];
                return TealCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _typeColor(e['type']!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['title']!,
                                style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              e['type']!.toUpperCase(),
                              style: TextStyle(
                                  color: _typeColor(e['type']!),
                                  fontSize: 10,
                                  letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
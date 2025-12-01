import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HeatmapCalendar extends StatefulWidget {
  final Map<DateTime, int> completionData;
  final int maxIntensity;

  const HeatmapCalendar({
    super.key,
    required this.completionData,
    this.maxIntensity = 5,
  });

  @override
  State<HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends State<HeatmapCalendar> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  void _onPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
  }

  void _onNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
  }

  Color _getColorForIntensity(int count, bool isCurrentMonth) {
    if (count == 0) {
      return isCurrentMonth ? Colors.grey[200]! : Colors.grey[100]!;
    }

    // Calculate intensity as percentage of max
    final intensity = (count / widget.maxIntensity).clamp(0.0, 1.0);

    final baseOpacity = isCurrentMonth ? 1.0 : 0.4;

    // GitHub-style green color gradient
    if (intensity <= 0.25) {
      return AppColors.primary.withOpacity(0.3 * baseOpacity);
    } else if (intensity <= 0.5) {
      return AppColors.primary.withOpacity(0.5 * baseOpacity);
    } else if (intensity <= 0.75) {
      return AppColors.primary.withOpacity(0.7 * baseOpacity);
    } else {
      return AppColors.primary.withOpacity(baseOpacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = _focusedDay.month;
    final currentYear = _focusedDay.year;

    // First day of the current month
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);

    // Last day of the current month
    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    // Find the Monday of the week containing the first day
    final startDate = firstDayOfMonth.subtract(
      Duration(days: (firstDayOfMonth.weekday - 1) % 7),
    );

    // Find the Sunday of the week containing the last day
    final endDate = lastDayOfMonth.add(
      Duration(days: (7 - lastDayOfMonth.weekday) % 7),
    );

    // Calculate number of weeks
    final totalDays = endDate.difference(startDate).inDays + 1;
    final weeks = totalDays ~/ 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _onPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              color: AppColors.textSecondaryLight,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              '${_getMonthName(currentMonth)} $currentYear',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            IconButton(
              onPressed: _onNextMonth,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.textSecondaryLight,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Day labels
        Row(
          children: const [
            Expanded(
                child: Center(
                    child: Text('Mon',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
            Expanded(
                child: Center(
                    child: Text('Tue',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
            Expanded(
                child: Center(
                    child: Text('Wed',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
            Expanded(
                child: Center(
                    child: Text('Thu',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
            Expanded(
                child: Center(
                    child: Text('Fri',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
            Expanded(
                child: Center(
                    child: Text('Sat',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
            Expanded(
                child: Center(
                    child: Text('Sun',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)))),
          ],
        ),
        const SizedBox(height: 12),

        // Calendar grid - weeks as rows, days as columns
        Column(
          children: List.generate(weeks, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final currentDate = startDate.add(
                    Duration(days: weekIndex * 7 + dayIndex),
                  );

                  final isCurrentMonth = currentDate.month == currentMonth;
                  final count = widget.completionData[DateTime(
                        currentDate.year,
                        currentDate.month,
                        currentDate.day,
                      )] ??
                      0;

                  return Expanded(
                    child: Center(
                      child: Tooltip(
                        message:
                            '${_getMonthName(currentDate.month)} ${currentDate.day}: $count habit${count == 1 ? '' : 's'}',
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _getColorForIntensity(count, isCurrentMonth),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${currentDate.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrentMonth
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isCurrentMonth
                                    ? (count > 0
                                        ? Colors.white
                                        : AppColors.textPrimaryLight)
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Less',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.grey[200]
                        : AppColors.primary.withOpacity(0.2 + (index * 0.2)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
            const SizedBox(width: 4),
            const Text(
              'More',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

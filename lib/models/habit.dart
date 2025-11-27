import 'package:hive/hive.dart';

part 'habit.g.dart';

const Object _undefined = Object();

@HiveType(typeId: 0)
enum HabitType {
  @HiveField(0)
  boolean,
  @HiveField(1)
  quantity,
}

@HiveType(typeId: 1)
class Habit {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final int color;
  @HiveField(4)
  final int iconCodePoint;
  @HiveField(5)
  final List<int> schedule;
  @HiveField(6)
  final HabitType type;
  @HiveField(7)
  final int target;
  @HiveField(8)
  final int order;
  @HiveField(9)
  final DateTime? reminderTime;
  @HiveField(10)
  final List<DateTime> completedDates;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime? archivedAt;
  @HiveField(13)
  final List<Map<String, dynamic>> scheduleHistory;

  Habit({
    required this.id,
    required this.title,
    required this.category,
    required this.color,
    required this.iconCodePoint,
    required this.schedule,
    required this.type,
    this.target = 1,
    this.order = 0,
    this.reminderTime,
    this.completedDates = const [],
    DateTime? createdAt,
    this.archivedAt,
    List<Map<String, dynamic>>? scheduleHistory,
  })  : createdAt = createdAt ?? DateTime.now(),
        scheduleHistory = scheduleHistory ??
            [
              {'start': createdAt ?? DateTime.now(), 'days': schedule}
            ];

  bool isCompletedOn(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool isScheduledOn(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    final sortedHistory = List<Map<String, dynamic>>.from(scheduleHistory)
      ..sort(
          (a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));

    for (var entry in sortedHistory) {
      final startDate = entry['start'] as DateTime;
      final normalizedStart =
          DateTime(startDate.year, startDate.month, startDate.day);

      if (!checkDate.isBefore(normalizedStart)) {
        final days = List<int>.from(entry['days'] as List);
        return days.contains(checkDate.weekday);
      }
    }

    return schedule.contains(checkDate.weekday);
  }

  Habit copyWith({
    String? id,
    String? title,
    String? category,
    int? color,
    int? iconCodePoint,
    List<int>? schedule,
    HabitType? type,
    int? target,
    int? order,
    Object? reminderTime = _undefined,
    List<DateTime>? completedDates,
    DateTime? createdAt,
    Object? archivedAt = _undefined,
    List<Map<String, dynamic>>? scheduleHistory,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      schedule: schedule ?? this.schedule,
      type: type ?? this.type,
      target: target ?? this.target,
      order: order ?? this.order,
      reminderTime: reminderTime == _undefined
          ? this.reminderTime
          : reminderTime as DateTime?,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      archivedAt:
          archivedAt == _undefined ? this.archivedAt : archivedAt as DateTime?,
      scheduleHistory: scheduleHistory ?? this.scheduleHistory,
    );
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    if (isCompletedOn(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      final yesterday = checkDate.subtract(const Duration(days: 1));
      if (isCompletedOn(yesterday)) {
        checkDate = yesterday;
      } else {
        return 0;
      }
    }

    while (true) {
      bool found = isCompletedOn(checkDate);

      if (!found) {
        if (schedule.contains(checkDate.weekday)) {
          break;
        }
      }

      checkDate = checkDate.subtract(const Duration(days: 1));
      if (isCompletedOn(checkDate)) {
        streak++;
      } else {
        if (schedule.contains(checkDate.weekday)) {
          break;
        }
      }
    }
    return streak;
  }
}

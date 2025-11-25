//import 'package:flutter/material.dart';

enum HabitType { boolean, quantity }

class Habit {
  final String id;
  final String title;
  final String category;
  final int color; // Store as int (0xAARRGGBB)
  final int iconCodePoint; // Store IconData codePoint
  final List<int> schedule; // 1 = Mon, 7 = Sun
  final HabitType type;
  final int target; // For quantity habits
  final int order; // Position in the list for ordering
  final DateTime?
      reminderTime; // Notification time (TimeOfDay not serializable easily)
  final List<DateTime>
      completedDates; // For boolean: just dates. For quantity: could be complex, simplifying for now.

  final DateTime createdAt; // Date when the habit was created
  final DateTime? archivedAt; // Date when the habit was archived (soft deleted)
  final List<Map<String, dynamic>>
      scheduleHistory; // [{'start': DateTime, 'days': List<int>}]

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

  // Helper to check if completed on a specific date
  bool isCompletedOn(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  // Helper to check if scheduled on a specific date using history
  bool isScheduledOn(DateTime date) {
    // Normalize date to midnight
    final checkDate = DateTime(date.year, date.month, date.day);

    // Find the schedule entry that was active on this date
    // Sort history by start date descending to find the latest applicable one
    final sortedHistory = List<Map<String, dynamic>>.from(scheduleHistory)
      ..sort(
          (a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));

    for (var entry in sortedHistory) {
      final startDate = entry['start'] as DateTime;
      final normalizedStart =
          DateTime(startDate.year, startDate.month, startDate.day);

      // If the check date is on or after this schedule's start date, this is the one
      if (!checkDate.isBefore(normalizedStart)) {
        final days = List<int>.from(entry['days'] as List);
        return days.contains(checkDate.weekday);
      }
    }

    // Fallback to current schedule if no history matches (shouldn't happen if initialized correctly)
    return schedule.contains(checkDate.weekday);
  }

  // CopyWith for immutability
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
    DateTime? reminderTime,
    List<DateTime>? completedDates,
    DateTime? createdAt,
    DateTime? archivedAt,
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
      reminderTime: reminderTime ?? this.reminderTime,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduleHistory: scheduleHistory ?? this.scheduleHistory,
    );
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a)); // Newest first

    if (sortedDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Normalize to start of day
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // Check if completed today
    if (isCompletedOn(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // If not completed today, check yesterday (streak might be active but not done today yet)
      final yesterday = checkDate.subtract(const Duration(days: 1));
      if (isCompletedOn(yesterday)) {
        checkDate = yesterday;
      } else {
        return 0; // Streak broken
      }
    }

    // Count backwards
    while (true) {
      // Find if checkDate is in history
      bool found = isCompletedOn(checkDate);

      // If not found, check if it was a scheduled day
      if (!found) {
        // If it was a scheduled day and not done -> streak broken
        if (schedule.contains(checkDate.weekday)) {
          break;
        }
        // If not scheduled, skip this day and continue checking previous day
        // (Streaks don't break on non-scheduled days)
      } else {
        // If found (and we already counted the first one if it was today/yesterday)
        // We need to be careful not to double count if we already incremented
        // But for the loop, we just check previous days.
      }

      // Actually, a simpler approach for "daily" habits vs "scheduled" habits:
      // For now, let's assume daily streak for simplicity, or strictly follow schedule.
      // Let's stick to: Consecutive scheduled days completed.

      // Re-implementation for strict scheduled days:
      // 1. Get all past scheduled dates up to today/yesterday.
      // 2. Check completion.

      // Simplified version:
      // Just count consecutive entries in sortedDates that are 1 day apart (ignoring non-scheduled days?)
      // This is complex. Let's do a simple "Consecutive Days" streak for now.

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

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../models/habit.dart';
import '../../../services/notification_service.dart';

class HabitProvider extends ChangeNotifier {
  // MOCK DATA - Commented out to test onboarding screen
  final List<Habit> _habits = [];
  late Box<Habit> _habitsBox;
  /* final List<Habit> _habits = [
    Habit(
      id: '1',
      title: 'Drink Water',
      category: 'Health',
      color: 0xFF2196F3, // Blue
      iconCodePoint: Icons.local_drink.codePoint,
      schedule: [1, 2, 3, 4, 5, 6, 7], // Daily
      type: HabitType.quantity,
      target: 8,
      order: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    Habit(
      id: '2',
      title: 'Read Book',
      category: 'Growth',
      color: 0xFF9C27B0, // Purple
      iconCodePoint: Icons.book.codePoint,
      schedule: [1, 2, 3, 4, 5], // Weekdays
      type: HabitType.boolean,
      order: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    Habit(
      id: '3',
      title: 'Morning Jog',
      category: 'Health',
      color: 0xFF4CAF50, // Green
      iconCodePoint: Icons.directions_run.codePoint,
      schedule: [1, 3, 5], // Mon, Wed, Fri
      type: HabitType.boolean,
      order: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ]; */

  HabitProvider() {
    _habitsBox = Hive.box<Habit>('habits');
    _loadHabits();
  }

  void _loadHabits() {
    _habits.clear();
    _habits.addAll(_habitsBox.values.toList());
    notifyListeners();
  }

  Future<void> _saveHabits() async {
    await _habitsBox.clear();
    for (var habit in _habits) {
      await _habitsBox.put(habit.id, habit);
    }
  }

  // DEBUG METHOD: Populate habits with sample completion data
  void _populateTestData() {
    final now = DateTime.now();

    // Add completions for the past 14 days
    for (int i = 13; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      // Complete habits based on their schedule and some randomness
      for (var habit in _habits) {
        // Check if this day is in the habit's schedule
        if (habit.schedule.contains(date.weekday)) {
          // Complete 80% of scheduled habits (simulate realistic usage)
          if (i % 3 != 0 || i == 0) {
            // Skip every 3rd day to simulate missing some
            _toggleHabitForDate(habit.id, date);
          }
        }
      }
    }
  }

  // Helper method to toggle a habit for a specific date
  void _toggleHabitForDate(String id, DateTime date) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      List<DateTime> completedDates = List.from(habit.completedDates);

      // Normalize the date
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Add if not already completed
      if (!habit.isCompletedOn(normalizedDate)) {
        completedDates.add(normalizedDate);
        _habits[index] = habit.copyWith(completedDates: completedDates);
      }
    }
  }

  List<Habit> get habits => _habits;

  List<Habit> getTodayHabits() {
    final today = DateTime.now().weekday;
    return _habits
        .where((h) => h.archivedAt == null && h.schedule.contains(today))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Habit> getOtherHabits() {
    final today = DateTime.now().weekday;
    return _habits
        .where((h) => h.archivedAt == null && !h.schedule.contains(today))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  void addHabit(Habit habit) {
    final maxOrder = _habits.isEmpty
        ? -1
        : _habits.map((h) => h.order).reduce((a, b) => a > b ? a : b);
    final newHabit = habit.copyWith(order: maxOrder + 1);
    _habits.add(newHabit);
    _saveHabits();

    // Schedule notification if needed
    if (newHabit.reminderTime != null) {
      NotificationService().scheduleReminder(
        id: newHabit.id.hashCode,
        title: 'Time for ${newHabit.title}!',
        body: 'Don\'t forget to complete your habit.',
        scheduledDate: newHabit.reminderTime!,
      );
    }

    notifyListeners();
  }

  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      // Check if schedule changed
      if (habit.schedule.toString() != _habits[index].schedule.toString()) {
        // Add new schedule history entry
        List<Map<String, dynamic>> history =
            List.from(habit.scheduleHistory ?? []);
        history.add({
          'start': DateTime.now(),
          'days': habit.schedule,
        });

        // Update habit with new history
        habit = habit.copyWith(scheduleHistory: history);
      }

      // Check if schedule changed (for today's completion removal logic)
      // Note: We already updated the habit object above, but we need to check if the NEW schedule excludes today
      final today = DateTime.now();
      final weekday = today.weekday;

      List<DateTime> updatedCompletedDates = List.from(habit.completedDates);

      if (!habit.schedule.contains(weekday)) {
        // If today is not in the new schedule, remove today from completed dates if present
        updatedCompletedDates.removeWhere((d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day);
      }

      _habits[index] = habit.copyWith(completedDates: updatedCompletedDates);
      _saveHabits();

      // Update notification
      final notificationService = NotificationService();
      // Always cancel old one first to be safe (or if time changed)
      notificationService.cancelReminder(habit.id.hashCode);

      if (habit.reminderTime != null) {
        notificationService.scheduleReminder(
          id: habit.id.hashCode,
          title: 'Time for ${habit.title}!',
          body: 'Don\'t forget to complete your habit.',
          scheduledDate: habit.reminderTime!,
        );
      }

      notifyListeners();
    }
  }

  void deleteHabit(String id) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      var habit = _habits[index];

      // If completed today, remove the completion before archiving
      // This ensures "checked and deleted same day" doesn't count for today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (habit.isCompletedOn(today)) {
        List<DateTime> updatedCompletedDates = List.from(habit.completedDates);
        updatedCompletedDates.removeWhere((d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day);
        habit = habit.copyWith(completedDates: updatedCompletedDates);
      }

      _habits[index] = habit.copyWith(archivedAt: DateTime.now());
      _saveHabits();

      // Cancel notification
      NotificationService().cancelReminder(habit.id.hashCode);

      notifyListeners();
    }
  }

  void reorderHabits(int oldIndex, int newIndex) {
    // Get today's habits (the ones being reordered)
    final todayHabits = getTodayHabits();

    // Adjust newIndex if moving down (ReorderableListView quirk)
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Move the habit in the list
    final habit = todayHabits.removeAt(oldIndex);
    todayHabits.insert(newIndex, habit);

    // Update order values for all today's habits
    for (int i = 0; i < todayHabits.length; i++) {
      final habitIndex = _habits.indexWhere((h) => h.id == todayHabits[i].id);
      if (habitIndex != -1) {
        _habits[habitIndex] = _habits[habitIndex].copyWith(order: i);
      }
    }

    _saveHabits();
    notifyListeners();
  }

  void toggleHabit(String id, DateTime date) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      List<DateTime> completedDates = List.from(habit.completedDates);

      // Check if already completed today
      final isCompleted = habit.isCompletedOn(date);

      if (isCompleted) {
        completedDates.removeWhere((d) =>
            d.year == date.year && d.month == date.month && d.day == date.day);
      } else {
        completedDates.add(date);
      }

      _habits[index] = habit.copyWith(completedDates: completedDates);
      _saveHabits();

      // Handle notification logic
      if (habit.reminderTime != null) {
        final notificationService = NotificationService();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Cancel existing notification first
        notificationService.cancelReminder(habit.id.hashCode);

        if (isCompleted) {
          // If completed today, schedule for TOMORROW
          // We use the original reminder time but set the date to tomorrow
          final reminderTime = habit.reminderTime!;
          final scheduledDate = DateTime(
            today.year,
            today.month,
            today.day + 1,
            reminderTime.hour,
            reminderTime.minute,
          );

          notificationService.scheduleReminder(
            id: habit.id.hashCode,
            title: 'Time for ${habit.title}!',
            body: 'Don\'t forget to complete your habit.',
            scheduledDate: scheduledDate,
          );
        } else {
          // If un-completed today, schedule for TODAY (if time hasn't passed) or TOMORROW
          // Actually, we just schedule for "Today at ReminderTime".
          // If that time has passed, the notification plugin (with matchDateTimeComponents)
          // will automatically schedule it for the next occurrence (tomorrow).
          // If it hasn't passed, it will schedule for today.
          final reminderTime = habit.reminderTime!;
          final scheduledDate = DateTime(
            today.year,
            today.month,
            today.day,
            reminderTime.hour,
            reminderTime.minute,
          );

          notificationService.scheduleReminder(
            id: habit.id.hashCode,
            title: 'Time for ${habit.title}!',
            body: 'Don\'t forget to complete your habit.',
            scheduledDate: scheduledDate,
          );
        }
      }

      notifyListeners();
    }
  }

  Map<int, int> getWeeklyCompletion() {
    final Map<int, int> data = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();
    // Get start of week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    for (var habit in _habits) {
      for (var date in habit.completedDates) {
        if (date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          data[date.weekday] = (data[date.weekday] ?? 0) + 1;
        }
      }
    }
    return data;
  }

  DateTime? getFirstActivityDate() {
    // Find the earliest completion date across all habits
    DateTime? firstDate;

    for (var habit in _habits) {
      for (var date in habit.completedDates) {
        if (firstDate == null || date.isBefore(firstDate)) {
          firstDate = date;
        }
      }
    }

    return firstDate != null
        ? DateTime(firstDate.year, firstDate.month, firstDate.day)
        : null;
  }

  Map<int, double?> getWeeklyCompletionRate() {
    final Map<int, double?> data = {
      1: null,
      2: null,
      3: null,
      4: null,
      5: null,
      6: null,
      7: null
    };
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 1; i <= 7; i++) {
      final date = startOfWeek.add(Duration(days: i - 1));
      // Normalize date
      final checkDate = DateTime(date.year, date.month, date.day);

      // Get habits scheduled for this day AND created on/before this day
      final scheduledHabits = _habits.where((h) {
        final normalizedCreatedAt =
            DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);

        // Check if habit was active on this date (created before/on date AND not archived before date)
        bool isActive = !checkDate.isBefore(normalizedCreatedAt);
        if (h.archivedAt != null) {
          final normalizedArchivedAt = DateTime(
              h.archivedAt!.year, h.archivedAt!.month, h.archivedAt!.day);
          if (!checkDate.isBefore(normalizedArchivedAt)) {
            isActive = false;
          }
        }

        return h.isScheduledOn(checkDate) && isActive;
      }).toList();

      if (scheduledHabits.isEmpty) {
        data[i] = null;
        continue;
      }

      int completedCount = 0;
      for (var habit in scheduledHabits) {
        if (habit.isCompletedOn(checkDate)) {
          completedCount++;
        }
      }

      data[i] = completedCount / scheduledHabits.length;
    }
    return data;
  }

  int getCurrentStreak() {
    // Global streak: Consecutive days where at least one SCHEDULED habit was completed
    int streak = 0;
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // Helper to check if any habit was completed AND scheduled for a specific date
    bool isDayActive(DateTime date) {
      return _habits.any((h) => h.isCompletedOn(date) && h.isScheduledOn(date));
    }

    // Check if any habit was completed today
    bool todayActive = isDayActive(checkDate);

    if (!todayActive) {
      // If not active today, check yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
      bool yesterdayActive = isDayActive(checkDate);

      if (!yesterdayActive) {
        return 0; // Streak is broken
      }
    }

    // Count consecutive days backwards from checkDate
    while (isDayActive(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int getBestStreak() {
    // Scan all completed dates of all habits, merge them into a set of "Active Days", and find max consecutive
    // Only count days where the habit was SCHEDULED

    Set<DateTime> activeDays = {};
    for (var h in _habits) {
      for (var d in h.completedDates) {
        // Only add if it was scheduled for that day
        if (h.isScheduledOn(d)) {
          activeDays.add(DateTime(d.year, d.month, d.day));
        }
      }
    }

    if (activeDays.isEmpty) return 0;

    final sortedDays = activeDays.toList()..sort();

    int maxStreak = 0;
    int currentRun = 0;

    for (int i = 0; i < sortedDays.length; i++) {
      if (i == 0) {
        currentRun = 1;
      } else {
        final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
        if (diff == 1) {
          currentRun++;
        } else {
          if (currentRun > maxStreak) maxStreak = currentRun;
          currentRun = 1;
        }
      }
    }
    if (currentRun > maxStreak) maxStreak = currentRun;

    return maxStreak;
  }

  int getHabitsFinishedThisWeek() {
    int count = 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Normalize
    final start =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end =
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

    for (var h in _habits) {
      for (var d in h.completedDates) {
        if (d.isAfter(start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(end)) {
          count++;
        }
      }
    }
    return count;
  }

  double getTodaysCompletionRate() {
    final today = DateTime.now();
    final scheduledHabits = getTodayHabits();
    if (scheduledHabits.isEmpty) return 0.0;

    int completed = 0;
    for (var h in scheduledHabits) {
      if (h.isCompletedOn(today)) {
        completed++;
      }
    }
    return completed / scheduledHabits.length;
  }

  int getPerfectDaysThisWeek() {
    int count = 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Check each day of this week up to today
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      if (date.isAfter(now)) break; // Don't count future days

      final checkDate = DateTime(date.year, date.month, date.day);
      final scheduledHabits = _habits.where((h) {
        final normalizedCreatedAt =
            DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);

        // Check if habit was active on this date
        bool isActive = !checkDate.isBefore(normalizedCreatedAt);
        if (h.archivedAt != null) {
          final normalizedArchivedAt = DateTime(
              h.archivedAt!.year, h.archivedAt!.month, h.archivedAt!.day);
          if (!checkDate.isBefore(normalizedArchivedAt)) {
            isActive = false;
          }
        }

        return h.isScheduledOn(checkDate) && isActive;
      }).toList();

      if (scheduledHabits.isEmpty)
        continue; // No habits = not a perfect day? Or yes? Let's say no.

      bool allDone = true;
      for (var h in scheduledHabits) {
        if (!h.isCompletedOn(checkDate)) {
          allDone = false;
          break;
        }
      }

      if (allDone) count++;
    }
    return count;
  }

  int getTotalPerfectDays() {
    // Calculate all perfect days across all time
    int count = 0;

    // Get all unique dates where at least one habit was completed
    Set<DateTime> activeDays = {};
    for (var habit in _habits) {
      for (var date in habit.completedDates) {
        activeDays.add(DateTime(date.year, date.month, date.day));
      }
    }

    // For each active day, check if all scheduled habits were completed
    for (var date in activeDays) {
      final scheduledHabits = _habits.where((h) {
        final normalizedCreatedAt =
            DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);

        // Check if habit was active on this date
        bool isActive = !date.isBefore(normalizedCreatedAt);
        if (h.archivedAt != null) {
          final normalizedArchivedAt = DateTime(
              h.archivedAt!.year, h.archivedAt!.month, h.archivedAt!.day);
          if (!date.isBefore(normalizedArchivedAt)) {
            isActive = false;
          }
        }

        return h.isScheduledOn(date) && isActive;
      }).toList();

      if (scheduledHabits.isEmpty) continue;

      bool allDone = true;
      for (var h in scheduledHabits) {
        if (!h.isCompletedOn(date)) {
          allDone = false;
          break;
        }
      }

      if (allDone) count++;
    }

    return count;
  }

  int getHabitsScheduledThisWeek() {
    int count = 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final scheduledForDay = _habits.where((h) {
        // Check if habit is active for this day
        if (h.archivedAt != null) {
          final normalizedArchivedAt = DateTime(
              h.archivedAt!.year, h.archivedAt!.month, h.archivedAt!.day);
          final checkDate = DateTime(date.year, date.month, date.day);
          if (!checkDate.isBefore(normalizedArchivedAt)) {
            return false;
          }
        }
        return h.isScheduledOn(date);
      }).length;
      count += scheduledForDay;
    }
    return count;
  }

  Set<DateTime> getDaysWithCompletions() {
    Set<DateTime> activeDays = {};
    for (var habit in _habits) {
      for (var date in habit.completedDates) {
        // Normalize to midnight to ensure proper comparison
        activeDays.add(DateTime(date.year, date.month, date.day));
      }
    }
    return activeDays;
  }

  Map<DateTime, int> getCompletionCountPerDay() {
    Map<DateTime, int> completionCounts = {};
    for (var habit in _habits) {
      for (var date in habit.completedDates) {
        final normalizedDay = DateTime(date.year, date.month, date.day);
        completionCounts[normalizedDay] =
            (completionCounts[normalizedDay] ?? 0) + 1;
      }
    }
    return completionCounts;
  }
}

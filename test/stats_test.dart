import 'package:flutter_test/flutter_test.dart';
import 'package:smart_habit_tracker/features/habits/providers/habit_provider.dart';
import 'package:smart_habit_tracker/models/habit.dart';

void main() {
  test('Adding a new habit does not affect past statistics', () {
    final provider = HabitProvider();

    // 1. Get initial stats
    final initialPerfectDays = provider.getTotalPerfectDays();
    final initialWeeklyCompletion = provider.getWeeklyCompletionRate();

    print('Initial Perfect Days: $initialPerfectDays');
    print('Initial Weekly Completion: $initialWeeklyCompletion');

    // 2. Add a new habit (created now)
    final newHabit = Habit(
      id: 'new_habit',
      title: 'New Habit',
      category: 'Test',
      color: 0xFF000000,
      iconCodePoint: 0,
      schedule: [1, 2, 3, 4, 5, 6, 7], // Daily
      type: HabitType.boolean,
      createdAt: DateTime.now(), // Explicitly now
    );

    provider.addHabit(newHabit);

    // 3. Get new stats
    final newPerfectDays = provider.getTotalPerfectDays();
    final newWeeklyCompletion = provider.getWeeklyCompletionRate();

    print('New Perfect Days: $newPerfectDays');
    print('New Weekly Completion: $newWeeklyCompletion');

    // 4. Assertions

    // Day 1 (Monday) was 1.0 initially. It should remain 1.0 because the new habit
    // (created on Tuesday) should not count towards Monday's stats.
    expect(newWeeklyCompletion[1], equals(initialWeeklyCompletion[1]),
        reason: "Monday's completion rate should be unchanged");

    // Day 2 (Tuesday/Today) dropped from 1.0 to ~0.66. This is expected because
    // the new habit exists today and hasn't been done yet.
    expect(newWeeklyCompletion[2], lessThan(initialWeeklyCompletion[2]!),
        reason: "Today's completion rate should drop");

    // Total perfect days might drop by 1 (if today was perfect and became imperfect),
    // but should not drop by more than 1.
    expect(newPerfectDays, greaterThanOrEqualTo(initialPerfectDays - 1),
        reason: "Perfect days should not drop by more than 1 (only today)");
  });
}

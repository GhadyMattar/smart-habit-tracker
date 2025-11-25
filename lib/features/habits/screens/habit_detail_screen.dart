import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';

import '../../../models/habit.dart';
import '../providers/habit_provider.dart';
import 'edit_habit_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, child) {
        final habit = provider.habits.firstWhere(
          (h) => h.id == habitId,
          orElse: () => Habit(
            id: 'deleted',
            title: 'Deleted',
            category: '',
            color: 0,
            iconCodePoint: 0,
            schedule: [],
            type: HabitType.boolean,
          ),
        );

        if (habit.id == 'deleted') {
          return const Scaffold(body: Center(child: Text('Habit not found')));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Custom Header Bar
              Container(
                color: Color(habit.color),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        habit.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditHabitScreen(habit: habit),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Habit'),
                            content: const Text(
                                'Are you sure you want to delete this habit?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deleteHabit(habit.id);
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context); // Close overlay
                                },
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Stats Section
              Container(
                color: Color(habit.color),
                padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        'Streak', '${habit.currentStreak} days', Colors.white),
                    _buildStatItem('Total', '${habit.completedDates.length}',
                        Colors.white),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Calendar Section
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: DateTime.now(),
                          calendarFormat: CalendarFormat.month,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              if (habit.isCompletedOn(day)) {
                                return Container(
                                  margin: const EdgeInsets.all(6.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Color(habit.color),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    day.day.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                              return null;
                            },
                            todayBuilder: (context, day, focusedDay) {
                              // If today is completed, it will be handled by defaultBuilder logic if we check there too?
                              // Actually todayBuilder overrides defaultBuilder for today.
                              // So we need to check completion here too.
                              final isCompleted = habit.isCompletedOn(day);
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Color(habit.color)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: isCompleted
                                      ? null
                                      : Border.all(color: AppColors.primary),
                                ),
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                          selectedDayPredicate: (day) =>
                              false, // Disable selection
                          onDaySelected: (selectedDay, focusedDay) {},
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

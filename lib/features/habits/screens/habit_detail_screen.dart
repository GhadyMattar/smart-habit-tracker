import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Absorb taps on the card
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  constraints: BoxConstraints(
                    // ADJUST HEIGHT HERE: Change 0.6 to your desired fraction of screen height (e.g., 0.5 for 50%, 0.8 for 80%)
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom Header Bar
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 0,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                habit.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 0),

                      // Calendar Section
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const columns = 24;
                                    const rows = 7;
                                    const gap = 4.0;
                                    final availableWidth = constraints.maxWidth;
                                    final itemSize =
                                        (availableWidth - (columns - 1) * gap) /
                                            columns;

                                    // Calculate start date (Monday of the week 23 weeks ago)
                                    final now = DateTime.now();
                                    final currentWeekday = now.weekday;
                                    final daysSinceMonday = currentWeekday - 1;
                                    final lastMonday = now.subtract(
                                        Duration(days: daysSinceMonday));
                                    final startDate = lastMonday
                                        .subtract(const Duration(days: 23 * 7));

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children:
                                          List.generate(columns, (colIndex) {
                                        return Column(
                                          children:
                                              List.generate(rows, (rowIndex) {
                                            final date = startDate.add(Duration(
                                                days:
                                                    (colIndex * 7) + rowIndex));

                                            final bottomMargin =
                                                rowIndex == rows - 1
                                                    ? 0.0
                                                    : gap;

                                            final isCompleted =
                                                habit.isCompletedOn(date);

                                            return Container(
                                              width: itemSize,
                                              height: itemSize,
                                              margin: EdgeInsets.only(
                                                  bottom: bottomMargin),
                                              decoration: BoxDecoration(
                                                color: isCompleted
                                                    ? Color(habit.color)
                                                    : Color(habit.color)
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            );
                                          }),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                          ),
                        ),
                      ),

                      // Footer Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Completion Checkbox
                            if (habit.isScheduledOn(DateTime.now()))
                              Row(
                                children: [
                                  Checkbox(
                                    value: habit.isCompletedOn(DateTime.now()),
                                    activeColor: Color(habit.color),
                                    onChanged: (bool? value) {
                                      provider.toggleHabit(
                                          habit.id, DateTime.now());
                                    },
                                  ),
                                  Text(
                                    habit.isCompletedOn(DateTime.now())
                                        ? 'Completed'
                                        : 'Complete',
                                    style: TextStyle(
                                      color: habit.isCompletedOn(DateTime.now())
                                          ? Colors.black
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'Not scheduled today',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            // Edit/Delete Buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: Color(habit.color)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditHabitScreen(habit: habit),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Color(habit.color)),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Habit'),
                                        content: const Text(
                                            'Are you sure you want to delete this habit?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              provider.deleteHabit(habit.id);
                                              Navigator.pop(
                                                  context); // Close dialog
                                              Navigator.pop(
                                                  context); // Close overlay
                                            },
                                            child: const Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

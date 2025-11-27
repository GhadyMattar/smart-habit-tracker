import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../habits/providers/habit_provider.dart';
import '../../habits/screens/add_habit_screen.dart';
import '../../habits/screens/edit_habit_screen.dart';
import '../../home/screens/main_wrapper.dart';

class CreateFirstHabitScreen extends StatelessWidget {
  const CreateFirstHabitScreen({super.key});

  void _continueToApp(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
  }

  Future<void> _showAddHabitDialog(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddHabitScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: const Text(
          'Create Your Habits',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bg.withOpacity(1.0),
                bg.withOpacity(0.0),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
        ),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          // Filter out archived habits
          final habits =
              habitProvider.habits.where((h) => h.archivedAt == null).toList();

          return Padding(
            padding: EdgeInsets.only(
              top: 10 + MediaQuery.of(context).padding.top,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encouraging message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        habits.isEmpty
                            ? Icons.rocket_launch
                            : Icons.check_circle,
                        color: AppColors.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        habits.isEmpty
                            ? 'Start Your Journey!'
                            : 'Great Progress!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        habits.isEmpty
                            ? 'Create your first habit and begin building better routines today'
                            : 'You\'ve created ${habits.length} habit${habits.length > 1 ? 's' : ''}! Keep adding more or continue to the app',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Add Habit Button
                ElevatedButton.icon(
                  onPressed: () => _showAddHabitDialog(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    habits.isEmpty
                        ? 'Create Your First Habit'
                        : 'Add Another Habit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),

                if (habits.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Your Habits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Habits List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero, // Remove default padding
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to edit screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditHabitScreen(habit: habit),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(habit.color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    IconData(habit.iconCodePoint,
                                        fontFamily: 'MaterialIcons'),
                                    color: Color(habit.color),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        habit.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        habit.category,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditHabitScreen(habit: habit),
                                          fullscreenDialog: true,
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      // Show delete confirmation
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Habit'),
                                          content: Text(
                                              'Are you sure you want to delete "${habit.title}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Provider.of<HabitProvider>(
                                                        context,
                                                        listen: false)
                                                    .deleteHabit(habit.id);
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color:
                                  AppColors.textSecondaryLight.withOpacity(0.3),
                              width: 2,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _continueToApp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Continue to App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Empty state helper text
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tap the button above to create your first habit',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Back button for empty state
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: AppColors.textSecondaryLight.withOpacity(0.3),
                          width: 2,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

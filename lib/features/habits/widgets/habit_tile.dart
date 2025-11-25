import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/habit.dart';
import '../screens/habit_detail_screen.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final VoidCallback? onToggle;
  final bool showDragHandle;

  const HabitTile({
    super.key,
    required this.habit,
    required this.isCompleted,
    this.onToggle,
    this.showDragHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Habit Card (smaller from right)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => HabitDetailScreen(habitId: habit.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // Drag Handle
                  if (showDragHandle) ...[
                    Icon(
                      Icons.drag_indicator,
                      color: AppColors.textSecondaryLight.withOpacity(0.5),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(habit.color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconData(habit.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: Color(habit.color),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habit.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // External Checkbox on the right
        const SizedBox(width: 16),
        if (onToggle != null)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.success : Colors.white,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : AppColors.textSecondaryLight.withOpacity(0.3),
                  width: 2,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          )
        else
          const SizedBox(width: 24), // Placeholder when no toggle
      ],
    );
  }
}

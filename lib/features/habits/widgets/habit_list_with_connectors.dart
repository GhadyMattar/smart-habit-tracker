import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/habit.dart';
import 'habit_tile.dart';

class HabitListWithConnectors extends StatelessWidget {
  final List<Habit> habits;
  final DateTime currentDate;
  final Function(String habitId, DateTime date) onToggle;

  const HabitListWithConnectors({
    super.key,
    required this.habits,
    required this.currentDate,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(habits.length, (index) {
        final habit = habits[index];
        final isCompleted = habit.isCompletedOn(currentDate);
        final isFirst = index == 0;
        final isLast = index == habits.length - 1;

        return Stack(
          children: [
            // Dotted line connector
            Positioned.fill(
              child: CustomPaint(
                painter: ConnectorPainter(
                  color: AppColors.textSecondaryLight.withOpacity(0.3),
                  isFirst: isFirst,
                  isLast: isLast,
                ),
              ),
            ),
            // Habit Tile with padding
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: HabitTile(
                habit: habit,
                isCompleted: isCompleted,
                onToggle: () => onToggle(habit.id, currentDate),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class ConnectorPainter extends CustomPainter {
  final Color color;
  final bool isFirst;
  final bool isLast;
  final double dashHeight;
  final double dashSpace;

  ConnectorPainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
    this.dashHeight = 4,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final x = size.width - 12; // Center of 24px checkbox
    final centerY =
        (size.height - 16) / 2; // Center of content (excluding padding)
    final checkboxTop = centerY - 12;
    final checkboxBottom = centerY + 12;

    // Draw top segment (from top of checkbox upwards to top of tile)
    if (!isFirst) {
      _drawDots(canvas, paint, Offset(x, checkboxTop), 0, false);
    }

    // Draw bottom segment (from bottom of checkbox downwards to bottom of tile)
    if (!isLast) {
      _drawDots(canvas, paint, Offset(x, checkboxBottom), size.height, true);
    }
  }

  void _drawDots(
      Canvas canvas, Paint paint, Offset start, double endY, bool isDown) {
    const double dotRadius = 1.5;
    const double spacing = 8.0; // Center to center spacing

    double currentY = start.dy;

    // Initial offset to not touch the checkbox
    if (isDown) {
      currentY += spacing;
    } else {
      currentY -= spacing;
    }

    while (isDown ? currentY < endY : currentY > endY) {
      canvas.drawCircle(Offset(start.dx, currentY), dotRadius, paint);
      if (isDown) {
        currentY += spacing;
      } else {
        currentY -= spacing;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

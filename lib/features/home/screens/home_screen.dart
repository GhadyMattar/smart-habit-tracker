import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../habits/providers/habit_provider.dart';
import '../../habits/widgets/habit_tile.dart';
import '../../habits/widgets/habit_list_with_connectors.dart';
import '../../habits/screens/add_habit_screen.dart';
import '../../user/providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _currentDate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    // Check every minute if the day has changed
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDateChange();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDateChange();
    }
  }

  void _checkDateChange() {
    final now = DateTime.now();
    if (now.day != _currentDate.day ||
        now.month != _currentDate.month ||
        now.year != _currentDate.year) {
      setState(() {
        _currentDate = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM').format(_currentDate);
    final userProvider = Provider.of<UserProvider>(context);
    final firstName = userProvider.user?.firstName ?? 'there';
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final topPadding = MediaQuery.of(context).padding.top +
        90; // Toolbar height + status bar + extra

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg.withOpacity(1.0),
                    bg.withOpacity(0.0),
                  ],
                  stops: const [0.8, 1.0],
                ),
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $firstName!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Consumer<HabitProvider>(
                builder: (context, habitProvider, child) {
                  // Check if any habit was completed today
                  final today = DateTime.now();
                  final hasCompletedToday = habitProvider.habits.any(
                    (habit) => habit.isCompletedOn(today),
                  );

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.local_fire_department,
                      key: ValueKey(hasCompletedToday),
                      size: 32,
                      color: hasCompletedToday ? Colors.orange : Colors.grey,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          final todayHabits = provider.getTodayHabits();
          final otherHabits = provider.getOtherHabits();

          if (todayHabits.isEmpty && otherHabits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_satisfied_alt,
                    size: 64,
                    color: AppColors.textSecondaryLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No habits for today!',
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Build the list
          if (todayHabits.isEmpty) {
            return ListView(
              padding: EdgeInsets.only(
                  top: topPadding, left: 24, right: 24, bottom: 100),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No habits scheduled for today',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (otherHabits.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Other Habits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: otherHabits.map((habit) {
                      final isCompleted = habit.isCompletedOn(_currentDate);
                      return HabitTile(
                        habit: habit,
                        isCompleted: isCompleted,
                        onToggle: null, // Disabled
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
                top: topPadding, left: 24, right: 24, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Habits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                HabitListWithConnectors(
                  habits: todayHabits,
                  currentDate: _currentDate,
                  onToggle: (habitId, date) {
                    provider.toggleHabit(habitId, date);
                  },
                ),
                if (otherHabits.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Other Habits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...otherHabits.map((habit) {
                    final isCompleted = habit.isCompletedOn(_currentDate);
                    return HabitTile(
                      habit: habit,
                      isCompleted: isCompleted,
                      onToggle: null, // Disabled
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddHabitScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

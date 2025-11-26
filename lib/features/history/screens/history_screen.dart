import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../habits/providers/habit_provider.dart';
import '../widgets/heatmap_calendar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late ScrollController _scrollController;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2.2;
    // Calculate viewport fraction based on PageView width (screenWidth - 24)
    // Item width is cardWidth + 16 (right padding)
    final viewportFraction = (cardWidth + 24) / (screenWidth - 24);

    // Recreate controller if viewport fraction changes or if it's null
    if (_pageController == null ||
        _pageController!.viewportFraction != viewportFraction) {
      _pageController?.dispose();
      _pageController = PageController(viewportFraction: viewportFraction);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryLight,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundLight.withOpacity(1.0),
                    AppColors.backgroundLight.withOpacity(0.0),
                  ],
                  stops: const [0.7, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, provider, child) {
          final weeklyRate = provider.getWeeklyCompletionRate();
          final currentStreak = provider.getCurrentStreak();
          final bestStreak = provider.getBestStreak();
          final finishedThisWeek = provider.getHabitsFinishedThisWeek();
          final todaysRate = provider.getTodaysCompletionRate();
          final perfectDays = provider.getTotalPerfectDays();
          final perfectDaysThisWeek = provider.getPerfectDaysThisWeek();

          // Daily Stats
          final now = DateTime.now();
          final todayHabits = provider.getTodayHabits();
          final scheduledToday = todayHabits.length;
          final finishedToday =
              todayHabits.where((h) => h.isCompletedOn(now)).length;

          // Check if streak is active today (any habit completed today)
          final isStreakActiveToday =
              provider.habits.any((h) => h.isCompletedOn(now));

          // Get first activity date
          // final firstActivityDate = provider.getFirstActivityDate();

          // Calculate week start: Always Monday of the current week
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          // Calculate average completion rate (Sum of elapsed daily rates / elapsed days)
          double totalRate = 0;
          int daysToCount = 0;

          // Count from Monday (1) to Today (now.weekday)
          // This ignores future days in the average calculation
          for (int i = 1; i <= now.weekday; i++) {
            if (weeklyRate[i] != null) {
              totalRate += weeklyRate[i]!;
              daysToCount++;
            }
          }
          final avgRate = daysToCount > 0 ? totalRate / daysToCount : 0.0;

          // Dates
          final dateFormat = DateFormat('MMM d');
          final monthYearFormat = DateFormat('MMMM yyyy');

          // Card Width Calculation
          // Padding is 24 on each side = 48.
          // We want to show roughly 2.2 cards.

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight - 32,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStreakCard(
                      currentStreak, bestStreak, isStreakActiveToday),
                ),
                const SizedBox(height: 24),

                // Horizontal Scrollable Stats
                SizedBox(
                  height: 180,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: PageView.builder(
                      controller: _pageController,
                      padEnds: false,
                      clipBehavior: Clip.none,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        Widget card;
                        if (index == 0) {
                          card = _buildStatCard(
                            'Habits Finished',
                            '$finishedThisWeek',
                            Icons.check_circle_outline,
                            Colors.blue,
                            'This week: $finishedThisWeek',
                          );
                        } else if (index == 1) {
                          card = _buildStatCard(
                            'Completion Rate',
                            '${(todaysRate * 100).toInt()}%',
                            Icons.pie_chart_outline,
                            Colors.orange,
                            '$finishedToday/$scheduledToday Habits',
                          );
                        } else {
                          card = _buildStatCard(
                            'Perfect Days',
                            '$perfectDays',
                            Icons.star_outline,
                            Colors.purple,
                            'This week: $perfectDaysThisWeek',
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: card,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Calendar Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity Calendar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        HeatmapCalendar(
                          completionData: provider.getCompletionCountPerDay(),
                          maxIntensity: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        monthYearFormat.format(now),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Weekly Completion Chart
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${now.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(avgRate * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Avg. completion rate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Chart
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceBetween,
                            maxY: 1.05,
                            barTouchData: BarTouchData(
                              enabled: false,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Colors.transparent,
                                tooltipPadding: EdgeInsets.zero,
                                tooltipMargin: 8,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${(rod.toY * 100).toInt()}%',
                                    TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    const days = [
                                      'M',
                                      'T',
                                      'W',
                                      'T',
                                      'F',
                                      'S',
                                      'S'
                                    ];
                                    if (value.toInt() >= 1 &&
                                        value.toInt() <= 7) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          days[value.toInt() - 1],
                                          style: TextStyle(
                                            color: AppColors.textSecondaryLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 0.5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: weeklyRate.entries.map((e) {
                              final isSelected = e.key == now.weekday;
                              return BarChartGroupData(
                                x: e.key,
                                showingTooltipIndicators: isSelected ? [0] : [],
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value ?? 0.0,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[300],
                                    width: 12,
                                    borderRadius: BorderRadius.circular(6),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 1.0,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer Stats
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Habits Finished',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '$finishedToday',
                                  style: TextStyle(
                                    color: AppColors.textPrimaryLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Habits scheduled',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '$scheduledToday',
                                  style: TextStyle(
                                    color: AppColors.textPrimaryLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard(int current, int best, bool isActiveToday) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Current Streak',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.local_fire_department,
                      color:
                          isActiveToday ? Colors.orange[400] : Colors.white30,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$current Days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white24,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFF6B00),
                          Color(0xFFFFD700),
                          Color(0xFFFF1744),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const Text(
                      'Best Streak',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$best Days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String footer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            footer,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

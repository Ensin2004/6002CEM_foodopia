import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';

class MealPlanCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final List<MealPlanDay> days;

  const MealPlanCalendar({
    super.key,
    required this.selectedDate,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TableCalendar<MealPlanDay>(
        firstDay: DateTime(selectedDate.year - 1),
        lastDay: DateTime(selectedDate.year + 1, 12, 31),
        focusedDay: selectedDate,
        currentDay: selectedDate,
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.horizontalSwipe,
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: 34,
        daysOfWeekHeight: 24,
        selectedDayPredicate: (day) => isSameDay(day, selectedDate),
        eventLoader: (day) => days
            .where(
              (mealDay) => mealDay.hasMeals && isSameDay(mealDay.date, day),
            )
            .toList(),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: EdgeInsets.zero,
          leftChevronPadding: EdgeInsets.zero,
          rightChevronPadding: EdgeInsets.zero,
          leftChevronMargin: EdgeInsets.zero,
          rightChevronMargin: EdgeInsets.zero,
          leftChevronIcon: const _CalendarArrow(icon: Icons.chevron_left),
          rightChevronIcon: const _CalendarArrow(icon: Icons.chevron_right),
          titleTextFormatter: (date, locale) =>
              DateFormat('MMMM\nyyyy', locale).format(date),
          titleTextStyle:
              textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                height: 1.1,
              ) ??
              const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 10, color: Color(0xFF9AA3AF)),
          weekendStyle: TextStyle(fontSize: 10, color: Color(0xFF9AA3AF)),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          markerDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          defaultTextStyle:
              context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ) ??
              const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          weekendTextStyle:
              context.text.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ) ??
              const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          outsideTextStyle:
              context.text.bodySmall?.copyWith(
                color: const Color(0xFFB8C0CC),
                fontWeight: FontWeight.w500,
              ) ??
              const TextStyle(fontSize: 12, color: Color(0xFFB8C0CC)),
          todayTextStyle:
              context.text.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ) ??
              const TextStyle(fontSize: 12, color: Colors.white),
          selectedTextStyle:
              context.text.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ) ??
              const TextStyle(fontSize: 12, color: Colors.white),
          cellMargin: const EdgeInsets.all(3),
          markersMaxCount: 1,
          markerSize: 4,
          markerMargin: const EdgeInsets.only(top: 24),
        ),
        onDaySelected: (_, __) {},
        onPageChanged: (_) {},
      ),
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  final IconData icon;

  const _CalendarArrow({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AppColors.textPrimary),
    );
  }
}

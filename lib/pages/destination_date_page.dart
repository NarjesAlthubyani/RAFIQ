import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../controllers/destination_date_controller.dart';
import '../pages/budget_interest_page.dart';
import 'package:intl/intl.dart';

class DestinationDatePage extends StatelessWidget {
  const DestinationDatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DestinationDateController(),
      child: const _DestinationDateView(),
    );
  }
}

class _DestinationDateView extends StatelessWidget {
  const _DestinationDateView({Key? key}) : super(key: key);

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DestinationDateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(context),
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.greyLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.destination,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: AppColors.secondary),
                            onChanged: (value) {
                              if (value != null) {
                                controller.setDestination(value);
                              }
                            },
                            items: ['Jeddah', 'Riyadh', 'AlUla']
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            color: AppColors.accent, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          value,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'From - To',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.pickDate(
                                context: context,
                                from: true,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.accent),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: AppColors.textSecondary,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        controller.fromDate != null
                                            ? _formatDate(controller.fromDate!)
                                            : 'From',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: controller.fromDate != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.pickDate(
                                context: context,
                                from: false,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.accent),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        color: AppColors.textSecondary,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        controller.toDate != null
                                            ? _formatDate(controller.toDate!)
                                            : 'To',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: controller.toDate != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatMonthYear(controller.currentMonth),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    controller.changeMonth(-1),
                                icon: Icon(Icons.chevron_left,
                                    size: 32, color: AppColors.primary),
                              ),
                              IconButton(
                                onPressed: () =>
                                    controller.changeMonth(1),
                                icon: Icon(Icons.chevron_right,
                                    size: 32, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      _buildCalendar(context, controller),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Center(
                  child: SizedBox(
                    width: 180,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.fromDate != null &&
                              controller.toDate != null
                          ? () async {
                              final id =
                                  await controller.saveTripRequest();
                              if (id != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BudgetInterestPage(
                                      preferenceId: id,
                                      destination: controller.destination,
                                      fromDate: controller.fromDate!,
                                      toDate: controller.toDate!,
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.fromDate != null &&
                                    controller.toDate != null
                                ? AppColors.secondary
                                : AppColors.greyLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: controller.fromDate != null &&
                                  controller.toDate != null
                              ? AppColors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }}

  Widget _buildStepIndicator(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Text(
              'Step 1/2',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 8.5,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you plan to go?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
      BuildContext context, DestinationDateController controller) {
    final firstDay = DateTime(
        controller.currentMonth.year, controller.currentMonth.month, 1);
    final lastDay = DateTime(
        controller.currentMonth.year, controller.currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;

    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index -
                      (startingWeekday == 7 ? 0 : startingWeekday) +
                  1;
              final isCurrentMonth =
                  dayOffset > 0 && dayOffset <= daysInMonth;
              final day = isCurrentMonth ? dayOffset : null;

              bool isSelectable = false;
              if (isCurrentMonth) {
                if (controller.currentMonth.year > today.year ||
                    (controller.currentMonth.year == today.year &&
                        controller.currentMonth.month > today.month) ||
                    (controller.currentMonth.year == today.year &&
                        controller.currentMonth.month == today.month &&
                        day! >= today.day)) {
                  isSelectable = true;
                }
              }

              final isFrom = isCurrentMonth &&
                  controller.fromDate != null &&
                  day == controller.fromDate!.day &&
                  controller.currentMonth.month ==
                      controller.fromDate!.month &&
                  controller.currentMonth.year ==
                      controller.fromDate!.year;

              final isTo = isCurrentMonth &&
                  controller.toDate != null &&
                  day == controller.toDate!.day &&
                  controller.currentMonth.month ==
                      controller.toDate!.month &&
                  controller.currentMonth.year ==
                      controller.toDate!.year;

              final isInRange = isCurrentMonth &&
                  controller.fromDate != null &&
                  controller.toDate != null &&
                  day! >= controller.fromDate!.day &&
                  day <= controller.toDate!.day &&
                  controller.currentMonth.month ==
                      controller.fromDate!.month &&
                  controller.currentMonth.year ==
                      controller.fromDate!.year;

              return GestureDetector(
                onTap: isSelectable
                    ? () => controller.selectDay(day!)
                    : null,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isFrom || isTo
                        ? AppColors.accent
                        : isInRange
                            ? AppColors.accent.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      day != null ? '$day' : '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isFrom || isTo ? FontWeight.bold : FontWeight.normal,
                        color: isSelectable
                            ? (isFrom || isTo
                                ? AppColors.white
                                : isInRange
                                    ? AppColors.accent
                                    : AppColors.textPrimary)
                            : AppColors.greyDark,
                         ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
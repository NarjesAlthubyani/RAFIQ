import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/budget_interest_controller.dart';
import '../theme/app_colors.dart';
import 'trip_loading_page.dart';

class BudgetInterestPage extends StatelessWidget {
  final String preferenceId;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;

  const BudgetInterestPage({
    Key? key,
    required this.preferenceId,
    required this.destination,
    required this.fromDate,
    required this.toDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTripController()
        ..initialize(
          prefId: preferenceId,
          dest: destination,
          from: fromDate,
          to: toDate,
        ),
      child: const _MyTripView(),
    );
  }
}

class _MyTripView extends StatelessWidget {
  const _MyTripView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MyTripController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(context),
              const SizedBox(height: 28),
              _buildCard(context, controller),
              const SizedBox(height: 28),
              _buildSubmitButton(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Text(
              'Step 2/2',
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
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, MyTripController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
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
          const SizedBox(height: 4),

          Text(
            'Budget Range',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildBudgetDropdown(controller),
          const SizedBox(height: 22),

          Text(
            'Select your interests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Choose as many as you'd like.",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          controller.interests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Loading interests...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    controller.interests.length,
                    (index) {
                      final interest = controller.interests[index];
                      return GestureDetector(
                        onTap: () => controller.toggleInterest(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: interest.isSelected
                                ? AppColors.accent.withOpacity(0.08)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent,
                              width: 1.6,
                            ),
                          ),
                          child: Text(
                            interest.name,
                            style: TextStyle(
                              fontSize: 16,
                              color: interest.isSelected
                                  ? AppColors.secondary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBudgetDropdown(MyTripController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent),
        color: AppColors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_money,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedBudgetRange,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
                onChanged: (value) {
                  if (value != null) controller.setBudget(value);
                },
                items: controller.budgetOptions.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      'SAR $value',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
      BuildContext context, MyTripController controller) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 52,
        child: ElevatedButton(
          onPressed: controller.canSubmit
              ? () => _showReviewDialog(context, controller)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.canSubmit
                ? AppColors.secondary
                : AppColors.greyLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'Submit',
            style: TextStyle(
              fontSize: 18,
              color: controller.canSubmit
                  ? AppColors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showReviewDialog(
      BuildContext context, MyTripController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(30),
        title: Text(
          'Review Your Trip',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destination: ${controller.reviewDestination}',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Budget: SAR ${controller.reviewBudget}',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Dates: ${controller.reviewDates}',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Selected Interests',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: controller.reviewInterests
                  .map(
                    (s) => Chip(
                      label: Text(
                        s,
                        style: const TextStyle(color: AppColors.white),
                      ),
                      backgroundColor: AppColors.accent,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
  onPressed: () async {
    final success = await controller.submitTrip();

    if (!context.mounted) return;

    Navigator.pop(context); // close dialog AFTER submit

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripLoadingPage(
            tripId: controller.tripId,
            destination: controller.destination,
            fromDate: controller.fromDate,
            toDate: controller.toDate,
            budgetRange: controller.selectedBudgetRange!,
            selectedInterests: controller.selectedInterests,
          ),
        ),
      );
    } else if (controller.errorMessage != null) {
      _showErrorDialog(context, controller.errorMessage!);
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text(
    'Create Trip Plan',
    style: TextStyle(
      color: AppColors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
)
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

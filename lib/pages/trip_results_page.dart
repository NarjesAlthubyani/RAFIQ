import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../controllers/trip_results_controller.dart';
import '../models/activity.dart';
import '../models/trip_day.dart';
import '../models/trip_plan.dart';
import 'home_page.dart';

class TripResultsPage extends StatelessWidget {
  final String tripId;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String budgetRange;
  final List<String> selectedInterests;

  const TripResultsPage({
    Key? key,
    required this.tripId,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.budgetRange,
    required this.selectedInterests,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripResultsController(
        tripId: tripId,
        fromDate: fromDate,
        destinationCity: destination,
        budgetRange: budgetRange,
        selectedInterests: selectedInterests,
      )..loadTrip(),
      child: const _TripResultsView(),
    );
  }
}

class _TripResultsView extends StatelessWidget {
  const _TripResultsView({Key? key}) : super(key: key);

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'history':
        return Icons.history;
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant;
      case 'nature':
        return Icons.nature;
      case 'adventure':
        return Icons.hiking;
      case 'relaxation':
        return Icons.spa;
      case 'entertainment':
        return Icons.attractions;
      case 'culture':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripResultsController>();

    if (controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final plan = controller.tripPlan;
    if (plan == null) {
      return const Scaffold(
        body: Center(child: Text('No trip data found')),
      );
    }

    final days = plan.days;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(plan, context),
          _buildDayTabs(context, days),
          Expanded(child: _buildDayList(days, controller)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () {},
          shape: const CircleBorder(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader(TripPlan plan, BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/${plan.destinationCity.toLowerCase()}.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.accent.withOpacity(0.3),
                child: Center(
                  child: Icon(Icons.image, size: 64, color: AppColors.accent),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withOpacity(0.2),
                  AppColors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      plan.destinationCity,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.attach_money, color: AppColors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  plan.budgetRange,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${_formatDate(plan.startDate)} - ${_formatDate(plan.endDate)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomePage(initialIndex: 3),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: IconButton(
                    onPressed: () {
                      final controller = context.read<TripResultsController>();
                      _showTripOptions(context, controller, plan);
                    },
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppColors.white,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTripOptions(BuildContext context, TripResultsController controller, TripPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete trip',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteTrip(context, controller, plan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTrip(BuildContext context, TripResultsController controller, TripPlan plan) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: Text('Are you sure you want to delete your trip to ${plan.destinationCity}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel',style: TextStyle(color: AppColors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await controller.deleteTrip();
                if (success) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete trip. Try again.')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayTabs(BuildContext context, List<TripDay> days) {
    final controller = context.watch<TripResultsController>();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length + 1,
              itemBuilder: (context, index) {
                final isSelected = controller.selectedDay == index;
                final label = index == 0 ? 'All' : 'Day ${days[index - 1].day}';

                return GestureDetector(
                  onTap: () => controller.selectDay(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.add, color: Colors.grey.shade600, size: 20),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayList(List<TripDay> days, TripResultsController controller) {
    final filteredDays = controller.selectedDay == 0
        ? days
        : [days[controller.selectedDay - 1]];

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 94),
      itemCount: filteredDays.length,
      itemBuilder: (context, index) {
        final day = filteredDays[index];
        final isExpanded = controller.expandedDays[day.day] ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => controller.toggleDay(day.day),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day ${day.day} - ${_formatDate(day.date)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Column(
                children: day.activities
                    .map((activity) => _buildActivityCard(context, activity, controller))
                    .toList(),
              ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, Activity activity, TripResultsController controller) {
    final icon = _getIconForCategory(activity.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                    ? Image.network(
                        activity.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, size: 40),
                        ),
                      )
                    : Container(
                        height: 160,
                        color: AppColors.accent.withOpacity(0.3),
                        child: const Icon(Icons.image, size: 40),
                      ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: IconButton(
                  onPressed: () => _showActivityOptions(context, controller, activity),
                  icon: const Icon(Icons.more_horiz, color: AppColors.white, size: 32),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(icon, color: AppColors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            activity.category,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (activity.ticketBooking && activity.ticketLink != null && activity.ticketLink!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _openTicketWeb(activity.ticketLink!, activity.name),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.confirmation_number,
                                color: AppColors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Ticket',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _viewOnMap(context, activity),
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('View on map', style: TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.w500,)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    backgroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.white, width: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openTicketWeb(String ticketLink, String activityName) async {
    final Uri? url = Uri.tryParse(ticketLink);
    if (url != null) {
      print('Opening ticket: $ticketLink');
    }
  }

  void _viewOnMap(BuildContext context, Activity activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View on map not implemented yet for ${activity.name}'),
      ),
    );
  }

  void _showActivityOptions(BuildContext context, TripResultsController controller, Activity activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete activity',
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteActivity(context, controller, activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteActivity(BuildContext context, TripResultsController controller, Activity activity) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Are you sure you want to delete "${activity.name}" from your trip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                controller.deleteActivity(activity);
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }
}

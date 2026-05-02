import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../controllers/trip_results_controller.dart';
import '../models/activity.dart';
import '../models/trip_day.dart';
import '../models/trip_plan.dart';
import '../models/nearby_activity.dart';
import 'home_page.dart';
import 'add_activity_page.dart';

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
    // Provide TripResultsController to the widget tree
    return ChangeNotifierProvider(
      create: (_) => TripResultsController(
        tripId: tripId,
        fromDate: fromDate,
        destinationCity: destination,
        budgetRange: budgetRange,
        selectedInterests: selectedInterests,
      )..loadTrip(),
      child: _TripResultsView(tripId: tripId, destinationCity: destination),
    );
  }
}

class _TripResultsView extends StatelessWidget {
  final String tripId;
  final String destinationCity;

  const _TripResultsView({Key? key, required this.tripId, required this.destinationCity}) 
      : super(key: key);

  // Returns appropriate icon for activity category
  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'history': return Icons.history;
      case 'shopping': return Icons.shopping_bag;
      case 'food': case 'restaurant': case 'cafe': return Icons.restaurant;
      case 'nature': return Icons.nature;
      case 'adventure': return Icons.hiking;
      case 'entertainment': return Icons.attractions;
      case 'culture': return Icons.museum;
      default: return Icons.place;
    }
  }

  // Formats date as month/day
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // Day Selection Dialog to allows user to choose which day to add activities to
  void _showDaySelectionDialog(
    BuildContext context,
    TripResultsController controller,
    List<TripDay> days,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Day', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...days.map((day) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text('${day.day}', style: const TextStyle(color: AppColors.white)),
                ),
                title: Text('Day ${day.day}'),
                subtitle: Text(_formatDate(day.date)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  
                  // Navigate to AddActivityPage and wait for result
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddActivityPage(
                        tripId: tripId,
                        dayNumber: day.day,
                        dayDate: day.date,
                        existingActivities: day.activities,
                        destinationCity: destinationCity,
                        onActivitiesAdded: (activities) async {
                          // Add each selected activity to the day
                          for (var activity in activities) {
                            await controller.addActivity(day.day, activity);
                          }
                          await controller.loadTrip();
                        },
                      ),
                    ),
                  );
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  // Trip Options Menu
  void _showTripOptions(BuildContext context, TripResultsController controller, TripPlan plan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const Text('Delete trip', style: TextStyle(color: AppColors.red, fontSize: 16, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteTrip(context, controller, plan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
  }

  // Shows confirmation dialog before deleting entire trip
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
              child: const Text('Cancel', style: TextStyle(color: AppColors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await controller.deleteTrip();
                if (success && context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 3)),
                    (route) => false,
                  );
                } else if (context.mounted) {
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

  // Activity Options Menu
  void _showActivityOptions(BuildContext context, TripResultsController controller, Activity activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const Text('Delete activity', style: TextStyle(color: AppColors.red, fontSize: 16, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteActivity(context, controller, activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
  }

  // Shows confirmation dialog before deleting a single activity
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                controller.deleteActivity(activity);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity deleted'), backgroundColor: AppColors.secondary),
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

  // Main Build Method
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripResultsController>();

    // Show loading indicator while fetching trip data
    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plan = controller.tripPlan;
    if (plan == null) {
      return const Scaffold(body: Center(child: Text('No trip data found')));
    }

    final days = plan.days;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(plan, context),
          _buildDayTabs(context, days, controller),
          Expanded(child: _buildDayList(days, controller)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
        child: FloatingActionButton(
          heroTag: null,  // Prevents Hero animation conflicts
          onPressed: () => _showDaySelectionDialog(context, controller, days),
          shape: const CircleBorder(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
 
  // Header Widget 
  Widget _buildHeader(TripPlan plan, BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(color: AppColors.greyLight),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image of the destination city
          Image.asset(
            'assets/${plan.destinationCity.toLowerCase()}.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.accent.withOpacity(0.3),
                child: Center(child: Icon(Icons.image, size: 64, color: AppColors.accent)),
              );
            },
          ),

          // Dark gradient overlay for text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.black.withOpacity(0.2), AppColors.black.withOpacity(0.6)],
              ),
            ),
          ),

          // City name and trip info overlay
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
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: -0.5, height: 1.1),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Budget display
                            Row(
                              children: [
                                const Icon(Icons.attach_money, color: AppColors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(plan.budgetRange, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Date range display
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.white, size: 16),
                                const SizedBox(width: 6),
                                Text('${_formatDate(plan.startDate)} - ${_formatDate(plan.endDate)}', 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.white)),
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

          // Back and menu buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage(initialIndex: 3)));
                  },
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: const Icon(Icons.arrow_back, color: AppColors.white, size: 32),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: IconButton(
                    onPressed: () {
                      final controller = context.read<TripResultsController>();
                      _showTripOptions(context, controller, plan);
                    },
                    icon: const Icon(Icons.more_horiz, color: AppColors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Day Tabs 
  Widget _buildDayTabs(BuildContext context, List<TripDay> days, TripResultsController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.greyLight, width: 1)),
      ),
      child: Row(
        children: [
          // Scrollable list of day tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length + 1,  // +1 for "All" tab
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
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.greyLight, width: 1.5),
                    ),
                    child: Center(
                      child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, 
                        color: isSelected ? AppColors.white : AppColors.greyDark)),
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick add button for current selected day
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(20)),
            child: IconButton(
              onPressed: () async {
                if (controller.selectedDay > 0 && controller.selectedDay - 1 < days.length) {
                  final selectedDay = days[controller.selectedDay - 1];
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddActivityPage(
                        tripId: tripId,
                        dayNumber: selectedDay.day,
                        dayDate: selectedDay.date,
                        existingActivities: selectedDay.activities,
                        destinationCity: destinationCity,
                        onActivitiesAdded: (activities) async {
                          for (var activity in activities) {
                            await controller.addActivity(selectedDay.day, activity);
                          }
                          await controller.loadTrip();
                        },
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Activities added successfully!'), backgroundColor: AppColors.secondary),
                    );
                  }
                } else {
                  _showDaySelectionDialog(context, controller, days);
                }
              },
              icon: Icon(Icons.add, color: AppColors.greyDark, size: 20),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Day List
  Widget _buildDayList(List<TripDay> days, TripResultsController controller) {
    // Filter days based on selected tab, All or specific day
    final filteredDays = controller.selectedDay == 0 ? days : [days[controller.selectedDay - 1]];
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 94),
      itemCount: filteredDays.length,
      itemBuilder: (context, index) {
        final day = filteredDays[index];
        final isExpanded = controller.expandedDays[day.day] ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header with expand/collapse toggle
            GestureDetector(
              onTap: () => controller.toggleDay(day.day),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Day ${day.day} - ${_formatDate(day.date)}', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary, size: 24),
                  ],
                ),
              ),
            ),
            // Activities (visible when expanded)
            if (isExpanded)
              Column(children: day.activities.map((activity) => _buildActivityCard(context, activity, controller)).toList()),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  // Activity Card Widget
  Widget _buildActivityCard(BuildContext context, Activity activity, TripResultsController controller) {
    final icon = _getIconForCategory(activity.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight, width: 1),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Activity image with options menu
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                    ? Image.network(activity.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 160, color: AppColors.greyLight, child: const Icon(Icons.image, size: 40)))
                    : Container(height: 160, color: AppColors.accent.withOpacity(0.3), child: const Icon(Icons.image, size: 40)),
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
          // Activity details and action buttons
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: activity name and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.white, height: 1)),
                      const SizedBox(height:6),
                      Row(
                        children: [
                          Icon(icon, color: AppColors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(activity.category, style: const TextStyle(fontSize: 16, color: AppColors.white, fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side: action buttons, View on map, Book Ticket
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View on map button
                    if (activity.locationLink != null && activity.locationLink!.isNotEmpty)
                      ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(activity.locationLink!);
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'View on map',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Book Ticket button
                    if (activity.ticketBooking && activity.ticketLink != null && activity.ticketLink!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(activity.ticketLink!);
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.confirmation_num_outlined, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Book Ticket',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../pages/destination_date_page.dart';
import '../pages/trip_results_page.dart';
import '../services/trip_service.dart';
import 'package:intl/intl.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({Key? key}) : super(key: key);

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserTrips();
  }

  Future<void> _loadUserTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trips = await TripService.getUserTrips();

      if (!mounted) return; 

      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load trips.';
        _isLoading = false;
      });
    }
  }

  String _formatDateRange(String startDate, String endDate) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return '${DateFormat('MMM d').format(start)} to ${DateFormat('MMM d, y').format(end)}';
    } catch (_) {
      return '$startDate - $endDate';
    }
  }

  String _formatBudget(dynamic budget) {
    double value = 0.0;

    if (budget is int) value = budget.toDouble();
    if (budget is double) value = budget;
    if (budget is String) value = double.tryParse(budget) ?? 0.0;

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My trips',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_trips.isNotEmpty && !_isLoading && _errorMessage == null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DestinationDatePage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.greyDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.greyDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserTrips,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_trips.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 80,
                        color:AppColors.greyDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No trips yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start planning your next adventure',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.greyDark,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DestinationDatePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 28,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadUserTrips,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    itemCount: _trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildTripCard(_trips[index]);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final raw = trip['ai_responses'];
    final List<Map<String, dynamic>> aiResponses =
        raw is List ? List<Map<String, dynamic>>.from(raw) : [];
    final Map<String, dynamic>? aiResponse =
        aiResponses.isNotEmpty ? aiResponses.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripResultsPage(
              tripId: trip['trip_id'] ?? '',
              destination: trip['city'] ?? '',
              fromDate: DateTime.parse(trip['start_date']),
              toDate: DateTime.parse(trip['end_date']),
              budgetRange: trip['budget'].toString(),
              selectedInterests: const [],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                'assets/${(trip['city'] ?? 'jeddah').toString().toLowerCase()}.jpg',
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.accent.withOpacity(0.3),
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: AppColors.accent.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip['city'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.attach_money, color: AppColors.white, size: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatBudget(trip['budget'])} SAR',
                              style: const TextStyle(color: AppColors.white, fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.calendar_today, color: AppColors.white, size: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateRange(trip['start_date'], trip['end_date']),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                        if (aiResponse != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Total: ${_formatBudget(aiResponse['total_cost'])} SAR',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showTripOptions(context, trip),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.more_horiz, color: AppColors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripOptions(BuildContext context, Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.primary),
                title: const Text(
                  'Delete trip',
                  style: TextStyle(color:Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTrip(trip);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteTrip(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: Text('Are you sure you want to delete your trip to ${trip['city']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  final success = await TripService.deleteTrip(trip['trip_id']);

                  if (!mounted) return; 

                  if (success) {
                    setState(() {
                      _trips.removeWhere((t) => t['trip_id'] == trip['trip_id']);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip deleted successfully'),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete trip'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor:Colors.red,
                    ),
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
}
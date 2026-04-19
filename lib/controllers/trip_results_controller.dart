import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/trip_plan.dart';
import '../models/trip_day.dart';
import '../models/activity.dart';
import '../services/trip_service.dart';

class TripResultsController extends ChangeNotifier {
  final String tripId;
  final DateTime fromDate;
  final String destinationCity;
  final String budgetRange;
  final List<String> selectedInterests;

  TripPlan? tripPlan;
  bool isLoading = true;
  bool isDisposed = false;

  int selectedDay = 0; 
  Map<int, bool> expandedDays = {};

  TripResultsController({
    required this.tripId,
    required this.fromDate,
    required this.destinationCity,
    required this.budgetRange,
    required this.selectedInterests,
  });

  void safeNotify() {
    if (!isDisposed) notifyListeners();
  }

  Future<void> loadTrip() async {
  isLoading = true;

  final tripData = await TripService.getTripDetails(tripId);

  if (tripData == null) {
    isLoading = false;
    safeNotify();
    return;
  }

  final aiResponses = tripData['ai_responses'];

  if (aiResponses == null || aiResponses.isEmpty) {
    isLoading = false;
    safeNotify();
    return;
  }

  final fullResponse = aiResponses.first['full_response'];

  Map<String, dynamic> decoded = {};

  if (fullResponse is String) {
    try {
      decoded = jsonDecode(fullResponse);
    } catch (e) {
      isLoading = false;
      safeNotify();
      return;
    }
  }

  final daysList = decoded['days'] as List? ?? [];

  if (daysList.isEmpty) {
    isLoading = false;
    safeNotify();
    return;
  }

    final days = <TripDay>[];

    for (int i = 0; i < daysList.length; i++) {
      final dayData = daysList[i];
      days.add(TripDay.fromJson(
        dayData,
        dayNum: dayData['day'] ?? i + 1,
        date: fromDate.add(Duration(days: i)),
      ));
    }

    tripPlan = TripPlan(
      tripId: int.tryParse(tripId) ?? 0,
      destinationCity: destinationCity,
      startDate: fromDate,
      endDate: fromDate.add(Duration(days: days.length - 1)),
      daysCount: days.length,
      totalCost: (decoded['total_cost'] ?? 0).toDouble(),
      summary: decoded['summary'] ?? 'Amazing trip to $destinationCity',
      days: days,
      budgetRange: budgetRange,
      selectedInterests: selectedInterests,
    );

    for (var day in tripPlan!.days) {
      expandedDays[day.day] = false;
    }

    isLoading = false;
    safeNotify();
  }

  void toggleDay(int day) {
    expandedDays[day] = !(expandedDays[day] ?? false);
    safeNotify();
  }

  void selectDay(int index) {
    selectedDay = index;
    safeNotify();
  }

  Future<Map<String, dynamic>> getTicketInfo(String name) async {
    return await TripService.getTicketInfo(name);
  }

  Future<bool> deleteTrip() async {
    try {
      final success = await TripService.deleteTrip(tripId);
      return success;
    } catch (e) {
      return false;
    }
  }

  void deleteActivity(Activity activity) {
    if (tripPlan == null) return;
    for (var day in tripPlan!.days) {
      day.activities.remove(activity);
    }
    safeNotify();
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/trip_plan.dart';
import '../models/trip_day.dart';
import '../models/activity.dart';
import '../models/nearby_activity.dart';
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

  // Currently selected tab 0 = All days
  int selectedDay = 0;     
  // Tracks which days are expanded          
  Map<int, bool> expandedDays = {};  
  
  TripResultsController({
    required this.tripId,
    required this.fromDate,
    required this.destinationCity,
    required this.budgetRange,
    required this.selectedInterests,
  });

  // Notifies listeners only if controller hasn't been disposed
  void safeNotify() {
    if (!isDisposed) notifyListeners();
  }

  // Trip Loading 
  // Sets up tripPlan with days and activities
  Future<void> loadTrip() async {
    isLoading = true;
    safeNotify();

    // Fetch trip data from Supabase
    final tripData = await TripService.getTripDetails(tripId);

    if (tripData == null) {
      isLoading = false;
      safeNotify();
      return;
    }

    // Extract AI-generated plan
    final aiResponses = tripData['ai_responses'];
    if (aiResponses == null || aiResponses.isEmpty) {
      isLoading = false;
     safeNotify();
      return;
    }

    final fullResponse = aiResponses.first['full_response'];
    
    // Parse JSON response from AI
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

    // Extract days list
    final daysList = decoded['days'] as List? ?? [];
    if (daysList.isEmpty) {
      isLoading = false;
      safeNotify();
      return;
    }

    // Build TripDay objects with correct dates
    final days = <TripDay>[];
    for (int i = 0; i < daysList.length; i++) {
      final dayData = daysList[i];
      days.add(TripDay.fromJson(
        dayData,
        dayNum: dayData['day'] ?? i + 1,
        date: fromDate.add(Duration(days: i)),
      ));
    }

    // Build complete TripPlan object
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

    // Initialize all days as collapsed
    for (var day in tripPlan!.days) {
      expandedDays[day.day] = false;  
    }

    isLoading = false;
    safeNotify();
  }

  // Toggles expansion state of a day (show/hide activities)
  void toggleDay(int day) {
    expandedDays[day] = !(expandedDays[day] ?? false);
    safeNotify();
  }

  // Changes the selected day filter: 0 = All days, >0 = specific day
  void selectDay(int index) {
    selectedDay = index;
    safeNotify();
  }

  // Fetches ticket booking info for an activity
  Future<Map<String, dynamic>> getTicketInfo(String name) async {
    return await TripService.getTicketInfo(name);
  }

  // Deletes entire trip from database
  Future<bool> deleteTrip() async {
    try {
      final success = await TripService.deleteTrip(tripId);
      return success;
    } catch (e) {
      return false;
    }
  }

  // Removes an activity from the trip and saves changes
  void deleteActivity(Activity activity) {
    if (tripPlan == null) return;
    
    // Remove activity from all days 
    for (var day in tripPlan!.days) {
      day.activities.remove(activity);
    }
    
    // Persist changes to database
    _saveToDatabase();
    safeNotify();
  }

  // Adds a new activity to a specific day
  Future<bool> addActivity(int dayNumber, NearbyActivity nearbyActivity) async {
    try {
      if (tripPlan == null) return false;

      // Find the target day
      int dayIndex = tripPlan!.days.indexWhere((day) => day.day == dayNumber);
      if (dayIndex == -1) return false;

      // Convert NearbyActivity to internal Activity model
      final tripActivity = Activity(
        name: nearbyActivity.title,
        category: nearbyActivity.category,
        description: nearbyActivity.duration ?? '',
        cost: 0.0,
        durationMinutes: 60,
        imageUrl: nearbyActivity.imageUrl,
        locationLink: nearbyActivity.detailsUrl,
        ticketLink: nearbyActivity.ticketLink,
        ticketBooking: nearbyActivity.ticketBooking,
        lat: 0.0,
        lng: 0.0,
        time: '',
        type: nearbyActivity.category,
      );

      // Add to the day's activities
      tripPlan!.days[dayIndex].activities.add(tripActivity);
      
      // Save changes
      await _saveToDatabase();
      safeNotify();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Saves current tripPlan back to the database
  Future<void> _saveToDatabase() async {
    if (tripPlan == null) return;
    
    try {
      // Get existing AI response from database
      final existingResponse = await TripService.getAiResponse(tripId);
      if (existingResponse == null) return;
      
      // Parse existing plan
      Map<String, dynamic> existingPlan = jsonDecode(existingResponse['full_response']);
      
      // Build updated days list with current activities
      List<Map<String, dynamic>> updatedDays = [];
      for (var day in tripPlan!.days) {
        updatedDays.add({
          'day': day.day,
          'date': day.date.toIso8601String(),
          'activities': day.activities.map((a) => a.toJson()).toList(),
        });
      }
      
      // Replace days and save
      existingPlan['days'] = updatedDays;
      await TripService.updateAiResponse(tripId, existingPlan);
    } catch (e) {
      rethrow;  
    }
  }

  @override
  void dispose() {
    isDisposed = true;  
    super.dispose();
  }
}
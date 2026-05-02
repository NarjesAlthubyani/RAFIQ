import 'package:flutter/material.dart';
import '../services/trip_service.dart';

class DestinationDateController extends ChangeNotifier {
   
  // Trip Data 
  DateTime? fromDate;      
  DateTime? toDate;        
  DateTime currentMonth = DateTime.now();  
  String destination = 'Jeddah';  

  // UI State 
  bool isLoading = false;
  String? errorMessage;    

  // Destination 
  // Updates selected destination and refreshes UI
  void setDestination(String value) {
    destination = value;
    notifyListeners();
  }

  // Date Picker 
  
  // Opens native date picker dialog for selecting From or To date
  Future<void> pickDate({
    required BuildContext context,
    required bool from,
  }) async {
    final today = DateTime.now();

    // Show date picker with appropriate initial date
    final selected = await showDatePicker(
      context: context,
      initialDate: from
          ? (fromDate ?? today)           
          : (toDate ?? fromDate ?? today), 
      firstDate: today,                   
      lastDate: DateTime(2026),           
    );

    if (selected != null) {
      if (from) {
        fromDate = selected;
        // If To date is before new From date, reset it
        if (toDate != null && toDate!.isBefore(fromDate!)) {
          toDate = null;
        }
      } else {
        toDate = selected;
      }
      notifyListeners(); 
    }
  }

  // Calendar Selection 
  void selectDay(int day) {
    final selectedDate =
        DateTime(currentMonth.year, currentMonth.month, day);
    final today = DateTime.now();

    // Prevent selecting past dates
    if (selectedDate.isBefore(DateTime(today.year, today.month, today.day))) {
      return;
    }

    // Case 1: No start date selected → set as start
    if (fromDate == null) {
      fromDate = selectedDate;
      toDate = null;
    } 
    // Case 2: Start selected, no end → set as end
    else if (toDate == null) {
      if (selectedDate.isBefore(fromDate!)) {
        // If selected date is before start, swap them
        toDate = fromDate;
        fromDate = selectedDate;
      } else {
        toDate = selectedDate;
      }
    } 
    // Case 3: Both dates selected → start new range
    else {
      fromDate = selectedDate;
      toDate = null;
    }
    notifyListeners(); 
  }

  // Calendar Navigation 
  void changeMonth(int offset) {
    currentMonth =
        DateTime(currentMonth.year, currentMonth.month + offset, 1);
    notifyListeners(); 
  }

  // Save to Database
  
  /// Saves trip request to database and returns preference ID
  Future<String?> saveTripRequest() async {
    if (fromDate == null || toDate == null) {
      errorMessage = "Please select both dates.";
      notifyListeners();
      return null;
    }

    try {
      isLoading = true;
      notifyListeners();  

      final result = await TripService.saveTripRequest(
        destination: destination,
        fromDate: fromDate!,
        toDate: toDate!,
      );

      isLoading = false;
      notifyListeners();

      return result['preference_id'];  
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
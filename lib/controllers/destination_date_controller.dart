import 'package:flutter/material.dart';
import '../services/trip_service.dart';

class DestinationDateController extends ChangeNotifier {
  DateTime? fromDate;
  DateTime? toDate;
  DateTime currentMonth = DateTime.now();
  String destination = 'Jeddah';

  bool isLoading = false;
  String? errorMessage;

  void setDestination(String value) {
    destination = value;
    notifyListeners();
  }

  Future<void> pickDate({
    required BuildContext context,
    required bool from,
  }) async {
    final today = DateTime.now();

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
        if (toDate != null && toDate!.isBefore(fromDate!)) {
          toDate = null;
        }
      } else {
        toDate = selected;
      }
      notifyListeners();
    }
  }

  void selectDay(int day) {
    final selectedDate =
        DateTime(currentMonth.year, currentMonth.month, day);
    final today = DateTime.now();

    if (selectedDate.isBefore(DateTime(today.year, today.month, today.day))) {
      return;
    }

    if (fromDate == null) {
      fromDate = selectedDate;
      toDate = null;
    } else if (toDate == null) {
      if (selectedDate.isBefore(fromDate!)) {
        toDate = fromDate;
        fromDate = selectedDate;
      } else {
        toDate = selectedDate;
      }
    } else {
      fromDate = selectedDate;
      toDate = null;
    }

    notifyListeners();
  }

  void changeMonth(int offset) {
    currentMonth =
        DateTime(currentMonth.year, currentMonth.month + offset, 1);
    notifyListeners();
  }

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

import 'package:flutter/material.dart';
import '../services/ai_planner_service.dart';
import '../services/trip_service.dart';

class TripLoadingController extends ChangeNotifier {
  late String tripId;
  late String destination;
  late DateTime fromDate;
  late DateTime toDate;
  late String budgetRange;
  late List<String> selectedInterests;

  bool isLoading = true;
  String? errorMessage;

  final List<String> _loadingMessages = [
    "Analyzing your preferences...",
    "Discovering hidden gems in {destination}...",
    "Finding the best restaurants...",
    "Adding local experiences...",
    "Almost there...",
  ];

  int currentMessageIndex = 0;

  String get loadingMessage =>
      _loadingMessages[currentMessageIndex].replaceAll(
        '{destination}',
        destination,
      );

  int dotCount = 0;

  bool navigateToResults = false;

  void initialize({
    required String id,
    required String dest,
    required DateTime from,
    required DateTime to,
    required String budget,
    required List<String> interests,
  }) {
    tripId = id;
    destination = dest;
    fromDate = from;
    toDate = to;
    budgetRange = budget;
    selectedInterests = interests;

    _startMessageRotation();
    _startDotAnimation();
    _generateTripWithAI();
  }

  void _startMessageRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));

      if (!isLoading) return false;

      currentMessageIndex =
          (currentMessageIndex + 1) % _loadingMessages.length;

      notifyListeners();
      return true;
    });
  }

  void _startDotAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!isLoading) return false;

      dotCount = (dotCount + 1) % 4;

      notifyListeners();
      return true;
    });
  }

  Future<void> _generateTripWithAI() async {
    try {
      final days = toDate.difference(fromDate).inDays + 1;
      final double budget = TripService.parseBudget(budgetRange);

      final result = await AIPlannerService.planTrip(
        city: destination,
        days: days,
        interests: selectedInterests,
        budget: budget,
      );

      await TripService.saveAIPlan(
        tripId: tripId,
        plan: result,
      );

      isLoading = false;
      navigateToResults = true;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> retry() async {
    errorMessage = null;
    isLoading = true;
    navigateToResults = false;
    notifyListeners();

    _startMessageRotation();
    _startDotAnimation();
    _generateTripWithAI();
  }
}

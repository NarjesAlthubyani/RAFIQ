import 'package:flutter/material.dart';
import '../services/ai_planner_service.dart';
import '../services/trip_service.dart';

class TripLoadingController extends ChangeNotifier {
  
  // Trip Data 
  late String tripId;               
  late String destination;          
  late DateTime fromDate;           
  late DateTime toDate;             
  late String budgetRange;          
  late List<String> selectedInterests; 

  bool _isGenerating = false;       
  bool isLoading = true;            
  String? errorMessage;             

  // Loading Animations 
  final List<String> _loadingMessages = [
    "Analyzing your preferences...",
    "Discovering hidden places in {destination}...",
    "Finding the best restaurants...",
    "Adding local experiences...",
    "Almost there...",
  ];

  int currentMessageIndex = 0;  

  // Returns current loading message with destination inserted
  String get loadingMessage =>
      _loadingMessages[currentMessageIndex].replaceAll(
        '{destination}',
        destination,
      );

  int dotCount = 0;              
  bool navigateToResults = false;   
  
  // Initializes controller with trip data and starts generation process
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

    // Start UI animations
    _startMessageRotation();
    _startDotAnimation();
    
    // Start AI generation
    _generateTripWithAI();
  }

  // Rotates loading messages every 4 seconds
  void _startMessageRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!isLoading) return false;  

      currentMessageIndex =
          (currentMessageIndex + 1) % _loadingMessages.length;

      notifyListeners();  
      return true;        
    });
  }

  void _startDotAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!isLoading) return false;  
      dotCount = (dotCount + 1) % 4; 

      notifyListeners();  
      return true;       
    });
  }

  // AI Trip Generation 
  // Calls AI service to generate trip plan and saves to database
  Future<void> _generateTripWithAI() async {
    // Prevent multiple simultaneous generation attempts
    if (_isGenerating) return;
    _isGenerating = true;

    try {
      // Calculate number of days from date range
      final days = toDate.difference(fromDate).inDays + 1;
      
      // Convert budget range to numeric value
      final double budget = TripService.parseBudget(budgetRange);

      // Call AI planner service
      final result = await AIPlannerService.planTrip(
        city: destination,
        days: days,
        interests: selectedInterests,
        budget: budget,
      );

      // Save generated plan to database
      await TripService.saveAIPlan(
        tripId: tripId,
        plan: result,
      );

      // Generation complete - navigate to results
      isLoading = false;
      navigateToResults = true;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Retries AI generation after failure
  Future<void> retry() async {
    // Reset state
    errorMessage = null;
    isLoading = true;
    navigateToResults = false;
    notifyListeners();

    // Restart animations
    _startMessageRotation();
    _startDotAnimation();
    
    // Retry generation
    _generateTripWithAI();
  }
}
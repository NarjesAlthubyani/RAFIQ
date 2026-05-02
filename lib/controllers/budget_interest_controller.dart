import 'package:flutter/material.dart';
import '../services/trip_service.dart';
import '../pages/trip_loading_page.dart';

// Interest Model
class Interest {
  //Interest name & whether user has selected this interest
  final String name; 
  final bool isSelected;   

  Interest({required this.name, this.isSelected = false});

  // Creates a copy of this interest with updated fields
  Interest copyWith({String? name, bool? isSelected}) {
    return Interest(
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class MyTripController extends ChangeNotifier {
  
  // Trip Data 
  late String tripId;          
  late String preferenceId;     
  late String destination;      
  late DateTime fromDate;       
  late DateTime toDate;         

  // Budget 
  
  String? selectedBudgetRange = '2000 - 5000';  // Currently selected budget
  
  // Available budget options for dropdown
  final List<String> budgetOptions = [
    '500 - 1000',
    '1000 - 2000',
    '2000 - 5000',
    '5000 - 10000',
    '10000+'
  ];

  // Updates selected budget and notifies UI
  void setBudget(String value) {
    selectedBudgetRange = value;
    notifyListeners();
  }

  // List of available interests
  List<Interest> interests = [];  

  // Initializes interest list based on destination city
  void initializeInterests(String destination) {
    List<Interest> base = [
      Interest(name: 'Culture'),
      Interest(name: 'Food'),
      Interest(name: 'History'),
      Interest(name: 'Entertainment'),
      Interest(name: 'Adventure'),
      Interest(name: 'Nature'),
    ];

    if (destination != 'AlUla') {
      base.insert(3, Interest(name: 'Shopping'));
    }

    interests = base;
    notifyListeners();
  }

  void toggleInterest(int index) {
    final current = interests[index];
    interests[index] = current.copyWith(isSelected: !current.isSelected);
    notifyListeners();
  }

  // Returns list of selected interest names
  List<String> get selectedInterests =>
      interests.where((i) => i.isSelected).map((i) => i.name).toList();

  // Returns true if at least one interest is selected
  bool get canSubmit => selectedInterests.isNotEmpty;

  // Review Data for confirmation dialog
  
  String get reviewDestination => destination;
  String get reviewBudget => selectedBudgetRange ?? '';
  String get reviewDates =>
      '${fromDate.month}/${fromDate.day} - ${toDate.month}/${toDate.day}';
  List<String> get reviewInterests => selectedInterests;

  // Submission 
  
  bool isSubmitting = false;    
  String? errorMessage;     

  // Submits trip details to backend and navigates to loading page
  Future<bool> submitTrip() async {
    try {
      isSubmitting = true;
      // Update UI to show loading state
      notifyListeners();  

      // Save trip details to database
      final result = await TripService.saveTripDetails(
        preferenceId: preferenceId,
        budgetRange: selectedBudgetRange!,
        selectedInterests: selectedInterests,
      );

      // Store generated trip ID
      tripId = result['trip']['trip_id'];  

      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // Initializes controller 
  void initialize({
    required String prefId,
    required String dest,
    required DateTime from,
    required DateTime to,
  }) {
    preferenceId = prefId;
    destination = dest;
    fromDate = from;
    toDate = to;

    // Set up interests 
    initializeInterests(dest);  
  }
}
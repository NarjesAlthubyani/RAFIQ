import 'package:flutter/material.dart';
import '../services/trip_service.dart';
import '../pages/trip_loading_page.dart';

class Interest {
  final String name;
  final bool isSelected;

  Interest({required this.name, this.isSelected = false});

  Interest copyWith({String? name, bool? isSelected}) {
    return Interest(
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class MyTripController extends ChangeNotifier {
  late String tripId;
  late String preferenceId;
  late String destination;
  late DateTime fromDate;
  late DateTime toDate;

  String? selectedBudgetRange = '2000 - 5000';

  final List<String> budgetOptions = [
    '500 - 1000',
    '1000 - 2000',
    '2000 - 5000',
    '5000 - 10000',
    '10000+'
  ];

  void setBudget(String value) {
    selectedBudgetRange = value;
    notifyListeners();
  }

  List<Interest> interests = [];

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

  List<String> get selectedInterests =>
      interests.where((i) => i.isSelected).map((i) => i.name).toList();

  bool get canSubmit => selectedInterests.isNotEmpty;

  String get reviewDestination => destination;

  String get reviewBudget => selectedBudgetRange ?? '';

  String get reviewDates =>
      '${fromDate.month}/${fromDate.day} - ${toDate.month}/${toDate.day}';

  List<String> get reviewInterests => selectedInterests;

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> submitTrip() async {
    try {
      isSubmitting = true;
      notifyListeners();

      final result = await TripService.saveTripDetails(
        preferenceId: preferenceId,
        budgetRange: selectedBudgetRange!,
        selectedInterests: selectedInterests,
      );

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

    initializeInterests(dest);
  }
}

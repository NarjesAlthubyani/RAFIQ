import 'trip_day.dart';

class TripPlan {
  final int tripId;
  final String destinationCity;
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final double totalCost;
  final String summary;
  final List<TripDay> days;
  final String budgetRange;
  final List<String> selectedInterests;

  TripPlan({
    required this.tripId,
    required this.destinationCity,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.totalCost,
    required this.summary,
    required this.days,
    required this.budgetRange,
    required this.selectedInterests,
  });

  factory TripPlan.fromJson(Map<String, dynamic> json, {
    required String tripId,
    required String destinationCity,
    required DateTime startDate,
    required String budgetRange,
    required List<String> selectedInterests,
  }) {
    final daysList = json['days'] as List? ?? [];
    final days = <TripDay>[];

    for (int i = 0; i < daysList.length; i++) {
      final dayData = daysList[i];
      days.add(TripDay.fromJson(
        dayData,
        dayNum: dayData['day'] ?? i + 1,
        date: startDate.add(Duration(days: i)),
      ));
    }

    return TripPlan(
      tripId: int.tryParse(tripId) ?? 0,
      destinationCity: destinationCity,
      startDate: startDate,
      endDate: startDate.add(Duration(days: days.length - 1)),
      daysCount: days.length,
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      summary: json['summary'] ?? 'Amazing trip to $destinationCity',
      days: days,
      budgetRange: budgetRange,
      selectedInterests: selectedInterests,
    );
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'destination_city': destinationCity,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'days_count': daysCount,
    'total_estimated_cost': totalCost,
    'summary': summary,
    'days': days.map((d) => d.toJson()).toList(),
  };
}
import 'user.dart';
import 'trip_day.dart';
import 'activity.dart';

class TripPlan {
  final int tripId;
  final AppUser user;
  final String destinationCity;
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  double totalEstimatedCost;
  final List<TripDay> days;
  String? summary;
  DateTime createdAt;

  TripPlan({
    required this.tripId,
    required this.user,
    required this.destinationCity,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    this.totalEstimatedCost = 0.0,
    required this.days,
    this.summary,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  void addActivityToDay(int dayNumber, Activity activity) {
    final day = days.firstWhere((d) => d.dayNumber == dayNumber);
    day.addActivity(activity);
    _recalculateTotalCost();
  }

  void removeActivityFromDay(int dayNumber, int activityId) {
    final day = days.firstWhere((d) => d.dayNumber == dayNumber);
    day.removeActivity(activityId);
    _recalculateTotalCost();
  }

  void editActivityInDay(int dayNumber, int activityId, String newDetails) {
    final day = days.firstWhere((d) => d.dayNumber == dayNumber);
    day.editActivity(activityId, newDetails);
  }

  void updateActivityTime(int dayNumber, int activityId, String startTime, String endTime) {
    final day = days.firstWhere((d) => d.dayNumber == dayNumber);
    day.updateActivityTime(activityId, startTime, endTime);
  }

  void _recalculateTotalCost() {
    totalEstimatedCost = days.fold(0.0, (sum, day) => sum + day.getTotalCost());
  }

  TripDay? getDay(int dayNumber) {
    try {
      return days.firstWhere((d) => d.dayNumber == dayNumber);
    } catch (e) {
      return null;
    }
  }

  List<Activity> getAllActivities() {
    return days.expand((day) => day.activities).toList();
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'user_id': user.userId,
    'destination_city': destinationCity,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'days_count': daysCount,
    'total_estimated_cost': totalEstimatedCost,
    'days': days.map((d) => d.toJson()).toList(),
    'summary': summary,
    'created_at': createdAt.toIso8601String(),
  };

  factory TripPlan.fromJson(Map<String, dynamic> json, AppUser user) {
    final daysList = json['days'] as List? ?? [];
    final startDate = DateTime.parse(json['start_date']);
    
    final days = <TripDay>[];
    for (int i = 0; i < daysList.length; i++) {
      days.add(TripDay.fromJson(
        daysList[i],
        dayNum: i + 1,
        date: startDate.add(Duration(days: i)),
      ));
    }

    return TripPlan(
      tripId: json['trip_id'],
      user: user,
      destinationCity: json['destination_city'],
      startDate: startDate,
      endDate: DateTime.parse(json['end_date']),
      daysCount: json['days_count'],
      totalEstimatedCost: (json['total_estimated_cost'] ?? 0.0).toDouble(),
      days: days,
      summary: json['summary'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  factory TripPlan.empty({
    required int tripId,
    required AppUser user,
    required String destinationCity,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final daysCount = endDate.difference(startDate).inDays + 1;
    final days = <TripDay>[];
    
    for (int i = 0; i < daysCount; i++) {
      days.add(TripDay.empty(i + 1, startDate.add(Duration(days: i))));
    }
    
    return TripPlan(
      tripId: tripId,
      user: user,
      destinationCity: destinationCity,
      startDate: startDate,
      endDate: endDate,
      daysCount: daysCount,
      days: days,
    );
  }
}
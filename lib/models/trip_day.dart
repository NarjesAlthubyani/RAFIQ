import 'activity.dart';

class TripDay {
  final int dayNumber;
  final DateTime date;
  final List<Activity> activities;
  double? dailyCost;

  TripDay({
    required this.dayNumber,
    required this.date,
    required this.activities,
    this.dailyCost,
  });

  void addActivity(Activity activity) {
    activities.add(activity);
    _recalculateDailyCost();
  }

  void removeActivity(int activityId) {
    activities.removeWhere((a) => a.activityId == activityId);
    _recalculateDailyCost();
  }

  void editActivity(int activityId, String newDetails) {
    final index = activities.indexWhere((a) => a.activityId == activityId);
    if (index != -1) {
      activities[index].description = newDetails;
    }
  }

  void updateActivityTime(int activityId, String startTime, String endTime) {
    final index = activities.indexWhere((a) => a.activityId == activityId);
    if (index != -1) {
      activities[index].startTime = startTime;
      activities[index].endTime = endTime;
    }
  }

  void _recalculateDailyCost() {
    dailyCost = activities.fold<double>(0.0, (sum, a) => sum + a.estimatedCost);
  }

  double getTotalCost() {
    if (dailyCost == null) {
      _recalculateDailyCost();
    }
    return dailyCost ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
    'day': dayNumber,
    'day_number': dayNumber,
    'date': date.toIso8601String(),
    'activities': activities.map((a) => a.toJson()).toList(),
    'daily_cost': getTotalCost(),
  };

  factory TripDay.fromJson(Map<String, dynamic> json, {required int dayNum, required DateTime date}) {
    final activitiesList = json['activities'] as List? ?? [];
    return TripDay(
      dayNumber: dayNum,
      date: date,
      activities: activitiesList.map((a) => Activity.fromJson(a)).toList(),
      dailyCost: (json['daily_cost'] ?? 0.0).toDouble(),
    );
  }

  factory TripDay.empty(int dayNum, DateTime date) {
    return TripDay(
      dayNumber: dayNum,
      date: date,
      activities: [],
      dailyCost: 0.0,
    );
  }
}
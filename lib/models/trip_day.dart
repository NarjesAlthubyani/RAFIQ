import 'activity.dart';

class TripDay {

  // Identification 
  final int day;              
  final DateTime date;       
  
  // Content 
  final List<Activity> activities;  
  final double dailyCost;           

  TripDay({
    required this.day,
    required this.date,
    required this.activities,
    required this.dailyCost,
  });

  // Creates a TripDay from JSON data
  factory TripDay.fromJson(Map<String, dynamic> json, {
    required int dayNum,
    required DateTime date,
  }) {
    // Extract activities list, default to empty if missing
    final activitiesList = json['activities'] as List? ?? [];
    
    return TripDay(
      day: dayNum,
      date: date,
      activities: activitiesList.map((a) => Activity.fromJson(a)).toList(),
      dailyCost: (json['daily_cost'] ?? 0).toDouble(),
    );
  }

  // Converts TripDay to JSON for database storage
  Map<String, dynamic> toJson() => {
    'day_number': day,
    'date': date.toIso8601String(),
    'activities': activities.map((a) => a.toJson()).toList(),
    'daily_cost': dailyCost,
  };
}
import '../models/trip_plan.dart';
import '../models/trip_day.dart';
import '../models/activity.dart';
import '../models/user.dart';
import '../adapters/ai_adapter.dart';

class _PlannedSlot {
  _PlannedSlot({
    required this.activity,
    required this.day,
    required this.slotType,
    required this.sequence,
  });

  final Activity activity;
  final int day;
  final String? slotType;
  final int sequence;
}

class TripPlanner {
  final AIAdapter _aiAdapter;

  TripPlanner({AIAdapter? aiAdapter}) : _aiAdapter = aiAdapter ?? AIAdapter();

  Future<TripPlan> createTripPlan({
    required AppUser user,
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
    required List<Activity> places,
    required List<Activity> foodVenues,
    required List<String> interests,
    required double budget,
  }) async {
    final days = toDate.difference(fromDate).inDays + 1;

    List<Map<String, dynamic>> selectedByAI = [];

    try {
      selectedByAI = await _aiAdapter.selectActivities(
        city: city,
        interests: interests,
        budget: budget,
        days: days,
        availablePlaces: places.map((p) => p.toJson()).toList(),
        availableFoodVenues: foodVenues.map((f) => f.toJson()).toList(),
      );
    } catch (e) {
    }

    if (selectedByAI.isEmpty) {
      selectedByAI = _fallbackSelection(places, foodVenues, days);
    }

    final slots = _buildSlotsFromSelection(
      selectedByAI,
      places,
      foodVenues,
      days,
    );

    final tripDays = _scheduleSlotsIntoDays(slots, fromDate, days);

    String summary = '';
    try {
      summary = await _aiAdapter.generateTripSummary(city, interests, days);
    } catch (e) {}
    if (summary.isEmpty) {
      summary =
          'A wonderful $days-day trip to $city exploring the best attractions and local cuisine.';
    }

    double totalCost = 0;
    for (var day in tripDays) {
      for (var activity in day.activities) {
        totalCost += activity.estimatedCost;
      }
    }

    return TripPlan(
      tripId: DateTime.now().millisecondsSinceEpoch,
      user: user,
      destinationCity: city,
      startDate: fromDate,
      endDate: toDate,
      daysCount: days,
      days: tripDays,
      summary: summary,
      totalEstimatedCost: totalCost,
    );
  }

  List<Map<String, dynamic>> _fallbackSelection(
    List<Activity> places,
    List<Activity> foodVenues,
    int days,
  ) {
    final selected = <Map<String, dynamic>>[];

    final cafes = foodVenues
        .where(
          (f) =>
              f.category.toLowerCase().contains('cafe') ||
              f.category.toLowerCase().contains('bakery'),
        )
        .toList();

    final restaurants = foodVenues
        .where((f) => f.category.toLowerCase().contains('restaurant'))
        .toList();

    final breakfastPool = cafes.isNotEmpty ? cafes : restaurants;

    final limitedPlaces = places.take(20).toList();

    if (limitedPlaces.isEmpty) {
      return selected;
    }

    for (int day = 1; day <= days; day++) {
      if (breakfastPool.isNotEmpty) {
        final idx = (day - 1) % breakfastPool.length;
        selected.add({
          'name': breakfastPool[idx].name,
          'type': 'breakfast',
          'day': day,
        });
      }

      for (int i = 0; i < 2; i++) {
        final placeIndex = ((day - 1) * 2 + i) % limitedPlaces.length;
        selected.add({
          'name': limitedPlaces[placeIndex].name,
          'type': 'attraction',
          'day': day,
        });
      }

      if (restaurants.isNotEmpty) {
        final lunchIndex = (day - 1) % restaurants.length;
        selected.add({
          'name': restaurants[lunchIndex].name,
          'type': 'lunch',
          'day': day,
        });
      }

      if (restaurants.isNotEmpty) {
        final dinnerIndex = day % restaurants.length;
        selected.add({
          'name': restaurants[dinnerIndex].name,
          'type': 'dinner',
          'day': day,
        });
      }
    }

    return selected;
  }

  List<_PlannedSlot> _buildSlotsFromSelection(
    List<Map<String, dynamic>> selected,
    List<Activity> places,
    List<Activity> foodVenues,
    int tripLengthDays,
  ) {
    final seenKeys = <String>{};
    final slots = <_PlannedSlot>[];
    var seq = 0;

    for (final raw in selected) {
      final name = raw['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;

      final type = raw['type']?.toString();
      final day = _parseDayField(raw['day'], tripLengthDays);
      final key = '$day|${type ?? ''}|${name.toLowerCase()}';
      if (!seenKeys.add(key)) continue;

      final matched = _matchCatalogActivity(name, places, foodVenues);
      final activity =
          matched ??
          _syntheticActivity(name: name, type: type, sequence: seq);

      slots.add(
        _PlannedSlot(
          activity: activity,
          day: day,
          slotType: type,
          sequence: seq++,
        ),
      );
    }

    return slots;
  }

  int _parseDayField(dynamic raw, int tripLengthDays) {
    if (raw == null) return 1;
    final v = raw is int ? raw : int.tryParse(raw.toString());
    if (v == null) return 1;
    return v.clamp(1, tripLengthDays);
  }

  Activity? _matchCatalogActivity(
    String name,
    List<Activity> places,
    List<Activity> foodVenues,
  ) {
    final n = name.toLowerCase().trim();
    for (final p in places) {
      if (p.name.toLowerCase().trim() == n) return p;
    }
    for (final f in foodVenues) {
      if (f.name.toLowerCase().trim() == n) return f;
    }
    for (final p in places) {
      final pn = p.name.toLowerCase();
      if (pn.contains(n) || n.contains(pn)) return p;
    }
    for (final f in foodVenues) {
      final fn = f.name.toLowerCase();
      if (fn.contains(n) || n.contains(fn)) return f;
    }
    return null;
  }

  Activity _syntheticActivity({
    required String name,
    required String? type,
    required int sequence,
  }) {
    final t = type?.toLowerCase();
    return Activity(
      activityId: Object.hash(name.hashCode, t, sequence),
      name: name,
      category: _categoryForType(t),
      duration: _durationMinutesForType(t),
      estimatedCost: 100,
    );
  }

  String _categoryForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'breakfast':
        return 'Cafe';
      case 'lunch':
      case 'dinner':
        return 'Restaurant';
      default:
        return 'Attraction';
    }
  }

  int _durationMinutesForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'breakfast':
        return 45;
      case 'lunch':
        return 75;
      case 'dinner':
        return 90;
      default:
        return 90;
    }
  }

  int _typeRank(String? slotType) {
    switch (slotType?.toLowerCase()) {
      case 'breakfast':
        return 0;
      case 'attraction':
        return 10;
      case 'lunch':
        return 30;
      case 'dinner':
        return 40;
      default:
        return 20;
    }
  }

  List<TripDay> _scheduleSlotsIntoDays(
    List<_PlannedSlot> slots,
    DateTime fromDate,
    int days,
  ) {
    final tripDays = <TripDay>[];

    if (slots.isEmpty) {
      for (int d = 0; d < days; d++) {
        tripDays.add(
          TripDay(
            dayNumber: d + 1,
            date: fromDate.add(Duration(days: d)),
            activities: [],
          ),
        );
      }
      return tripDays;
    }

    final byDay = <int, List<_PlannedSlot>>{
      for (var d = 1; d <= days; d++) d: [],
    };

    for (final s in slots) {
      final d = s.day.clamp(1, days);
      byDay[d]!.add(s);
    }

    for (var d = 1; d <= days; d++) {
      final daySlots = byDay[d]!
        ..sort((a, b) {
          final c = _typeRank(a.slotType).compareTo(_typeRank(b.slotType));
          if (c != 0) return c;
          return a.sequence.compareTo(b.sequence);
        });

      final scheduled = _assignTimesForDay(daySlots, fromDate, d - 1);

      tripDays.add(
        TripDay(
          dayNumber: d,
          date: fromDate.add(Duration(days: d - 1)),
          activities: scheduled,
        ),
      );

    }

    return tripDays;
  }

  List<Activity> _assignTimesForDay(
    List<_PlannedSlot> daySlots,
    DateTime fromDate,
    int dayIndex,
  ) {
    final scheduled = <Activity>[];
    var cursor = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day + dayIndex,
      9,
      0,
    );

    for (final slot in daySlots) {
      final minutes = slot.activity.duration.clamp(15, 600);
      final end = cursor.add(Duration(minutes: minutes));
      scheduled.add(
        slot.activity.copyWith(
          startTime: _formatTime(cursor),
          endTime: _formatTime(end),
        ),
      );
      cursor = end.add(const Duration(minutes: 30));
    }
    return scheduled;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
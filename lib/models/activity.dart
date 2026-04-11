class Activity {
  final int activityId;
  final String name;
  String? locationLink;
  final String category;
  final int duration;
  final double estimatedCost;
  String? description;
  double? lat;
  double? lng;
  String? imageUrl;
  String? startTime;
  String? endTime;

  Activity({
    required this.activityId,
    required this.name,
    this.locationLink,
    required this.category,
    required this.duration,
    required this.estimatedCost,
    this.description,
    this.lat,
    this.lng,
    this.imageUrl,
    this.startTime,
    this.endTime,
  });

  int getDuration() => duration;
  
  String getActivityDetails() => description ?? name;

  Map<String, dynamic> toJson() => {
    'activity_id': activityId,
    'name': name,
    'location_link': locationLink,
    'category': category,
    'duration': duration,
    'estimated_cost': estimatedCost,
    'description': description,
    'lat': lat,
    'lng': lng,
    'image_url': imageUrl,
    'start_time': startTime,
    'end_time': endTime,
  };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    activityId: json['activity_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    name: json['name'] ?? json['title'] ?? 'Unknown',
    locationLink: json['location_link'],
    category: json['category'] ?? 'General',
    duration: (json['duration'] ?? 60).toInt(),
    estimatedCost: (json['cost'] ?? json['estimated_cost'] ?? 0.0).toDouble(),
    description: json['description'],
    lat: json['lat']?.toDouble(),
    lng: json['lng']?.toDouble(),
    imageUrl: json['image_url'],
    startTime: json['start_time'],
    endTime: json['end_time'],
  );

  Activity copyWith({
    int? activityId,
    String? name,
    String? locationLink,
    String? category,
    int? duration,
    double? estimatedCost,
    String? description,
    double? lat,
    double? lng,
    String? imageUrl,
    String? startTime,
    String? endTime,
  }) {
    return Activity(
      activityId: activityId ?? this.activityId,
      name: name ?? this.name,
      locationLink: locationLink ?? this.locationLink,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrl: imageUrl ?? this.imageUrl,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
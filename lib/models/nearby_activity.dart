class NearbyActivity {
  // Activity Information
  
  final String title;         
  final String category;      
  
  // Duration 
  final String? duration;      
  
  // Media & Links 
  final String? imageUrl;      
  final String? detailsUrl;    
  final bool ticketBooking;    
  final String? ticketLink;     
  
  // Location 
  final double? distanceKm;     

  NearbyActivity({
    required this.title,
    required this.category,
    this.duration,
    this.imageUrl,
    this.detailsUrl,
    this.distanceKm,
    required this.ticketBooking,
    this.ticketLink,
  });

  // Creates a NearbyActivity from API JSON response
  factory NearbyActivity.fromJson(Map<String, dynamic> json) {
    return NearbyActivity(
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      
      // Duration: convert bucket format 
      duration: _bucketToUi(json['durationBucket']?.toString() ?? ''),
      
      imageUrl: json['imageUrl']?.toString(),
      detailsUrl: json['detailsUrl']?.toString(),
      
      // Distance: safely parse as double
      distanceKm: json['distanceKm'] != null 
          ? double.tryParse(json['distanceKm'].toString())
          : null,
      
      // Ticket booking: handles both true and "true" string values
      ticketBooking: json['ticketBooking'] == true || 
          json['ticketBooking']?.toString().toLowerCase() == 'true',
      ticketLink: json['ticketLink']?.toString(),
    );
  }

  // Converts API duration bucket format to user-friendly text
  static String _bucketToUi(String bucket) {
    switch (bucket) {
      case '<1h':
        return '<1 hour';
      case '1-2h':
        return '1-2 hours';
      case '2-3h':
        return '2-3 hours';
      case '3h+':
        return 'More than 3 hours';
      default:
        return '';  
    }
  }
}
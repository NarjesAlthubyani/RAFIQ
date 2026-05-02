import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/nav_bar.dart';
import '../theme/app_colors.dart';
import 'nearby_page.dart';
import 'profile_page.dart';
import 'my_trips_page.dart';
import 'scan_page.dart';
import 'smart_alerts_page.dart';
import 'destination_date_page.dart';
import '../services/trip_service.dart';
import '../models/nearby_activity.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final int initialIndex; 

  const HomePage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables
  late int _currentIndex;                   
  String _userName = "User";                 
  Map<String, dynamic>? _upcomingTrip;      
  bool _isLoadingTrips = true;              
  
  late List<Widget> _pages;                 

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadUserData();
    _loadUpcomingTrip();
    
    // Initialize navigation pages
    _pages = [
      HomeContent(
        userName: _userName,
        upcomingTrip: _upcomingTrip,
        isLoadingTrips: _isLoadingTrips,
        onViewPlanTap: _navigateToMyTrips,
      ),
      const NearbyPage(),
      const ScanPage(),
      const MyTripsPage(),
      const ProfilePage(),
    ];
  }

  // Navigate to My Trips tab 
  void _navigateToMyTrips() {
    setState(() {
      _currentIndex = 3;
    });
  }

  // Load user data from Supabase
  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userName = user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.email?.split('@').first ??
            'User';

        if (mounted) {
          setState(() {
            _userName = userName;
          });
        }
      }
    } catch (e) {}
  }

  // Load user's upcoming trip from database
  Future<void> _loadUpcomingTrip() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingTrips = true;
    });

    try {
      final trips = await TripService.getUserTrips();
      
      if (trips.isNotEmpty && mounted) {
        final latestTrip = trips.first;
        
        // Get full trip details
        final tripDetails = await TripService.getTripDetails(latestTrip['trip_id']);
        
        if (tripDetails != null && mounted) {
          setState(() {
            _upcomingTrip = {
              'trip_id': latestTrip['trip_id'],
              'city': latestTrip['city'],
              'days': latestTrip['days'],
              'budget': latestTrip['budget'],
              'start_date': latestTrip['start_date'],
              'end_date': latestTrip['end_date'],
              'ai_response': tripDetails['ai_responses']?.isNotEmpty == true
                  ? tripDetails['ai_responses'].first
                  : null,
            };
            _isLoadingTrips = false;
          });
        } else {
          setState(() {
            _isLoadingTrips = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingTrips = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrips = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update home content with latest data
    _pages[0] = HomeContent(
      userName: _userName,
      upcomingTrip: _upcomingTrip,
      isLoadingTrips: _isLoadingTrips,
      onViewPlanTap: _navigateToMyTrips,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh trips when returning to home tab
          if (index == 0) {
            _loadUpcomingTrip();
          }
        },
      ),
    );
  }
}

// Home Content Widget 
class HomeContent extends StatefulWidget {
  final String userName;
  final Map<String, dynamic>? upcomingTrip;
  final bool isLoadingTrips;
  final VoidCallback onViewPlanTap;

  const HomeContent({
    super.key,
    required this.userName,
    this.upcomingTrip,
    this.isLoadingTrips = true,
    required this.onViewPlanTap,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // API configuration
  static const String _baseUrl = 'http://10.0.2.2:8000';
  
  // Recommendations data
  List<NearbyActivity> _recommendations = [];
  bool _isLoadingRecommendations = false;
  String? _recommendationError;

  // City coordinates for location-based recommendations
  final Map<String, Map<String, double>> _cityCoordinates = {
    'Riyadh': {'lat': 24.7136, 'lng': 46.6753},
    'Jeddah': {'lat': 21.5433, 'lng': 39.1728},
    'AlUla': {'lat': 26.6515, 'lng': 37.9081},
  };

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  // Reload recommendations when upcoming trip changes
  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.upcomingTrip != oldWidget.upcomingTrip) {
      _loadRecommendations();
    }
  }

  // Fetch recommendations from API based on trip city
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = null;
    });

    try {
      // Determine city for recommendations
      String city;
      if (widget.upcomingTrip != null && widget.upcomingTrip!['city'] != null) {
        city = widget.upcomingTrip!['city'];
      } else {
        city = 'Jeddah';
      }

      final coordinates = _cityCoordinates[city];
      if (coordinates == null) {
        throw Exception('City coordinates not found');
      }

      final lat = coordinates['lat']!;
      final lng = coordinates['lng']!;

      // API request parameters
      final params = <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
        'limit': '2', 
      };

      final uri = Uri.parse('$_baseUrl/activities').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final fetched = data.map((item) => NearbyActivity.fromJson(item)).toList();
        
        setState(() {
          _recommendations = fetched.take(2).toList();
          _isLoadingRecommendations = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingRecommendations = false;
        _recommendationError = e.toString();
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
        children: [
          _buildHeader(),
          const SizedBox(height: 30), 

          // Show trip card or create trip button
          if (widget.isLoadingTrips)
            _buildLoadingIndicator()
          else if (widget.upcomingTrip != null)
            _buildUpcomingTripCard()
          else
            _buildCreateTripCard(),
          
          const SizedBox(height: 24), 

          // Recommendations section
          _buildRecommendationsSection(),
          
          const SizedBox(height: 20), 
        ],
      ),
    ),
  );
}


  // Header Widget User Profile & Notifications
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      // User avatar and name - TAP TO GO TO PROFILE
        GestureDetector(
          onTap: () {
           // Change bottom navigation index to Profile
            final homePageState = context.findAncestorStateOfType<_HomePageState>();
            if (homePageState != null) {
              homePageState.setState(() {
                homePageState._currentIndex = 4; 
              });
            }
        } ,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.white,
                child: Icon(Icons.person, color: AppColors.accent, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back",
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Notification button
      _notificationButton(),
    ],
  );
}

  // Notification bell icon button
  Widget _notificationButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SmartAlertsPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.notifications_none,
          color: AppColors.accent,
          size: 26,
        ),
      ),
    );
  }

  // Upcoming Trip Card displays user's next trip
  Widget _buildUpcomingTripCard() {
    final trip = widget.upcomingTrip!;
    final city = trip['city'] ?? 'Unknown';
    final days = trip['days'] ?? 0;
    final budget = trip['budget'] ?? 0;
    
    // Format date range
    String dateRange = "";
    if (trip['start_date'] != null && trip['end_date'] != null) {
      final start = DateTime.parse(trip['start_date']);
      final end = DateTime.parse(trip['end_date']);
      dateRange = "${start.month}/${start.day} - ${end.month}/${end.day}";
    }

    final cityImagePath = 'assets/${city.toLowerCase()}.jpg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Next Trip",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: widget.onViewPlanTap,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // City background image
                  Image.asset(
                    cityImagePath,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_city,
                          size: 60,
                          color: AppColors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.transparent,
                          AppColors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Trip information 
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left side: trip details
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                city,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: AppColors.white, size: 12),
                                  const SizedBox(width: 6),
                                  Text(dateRange, style: const TextStyle(color: AppColors.white, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, color: AppColors.white, size: 12),
                                  const SizedBox(width: 6),
                                  Text("$budget SAR", style: const TextStyle(color: AppColors.white, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: AppColors.white, size: 12),
                                  const SizedBox(width: 6),
                                  Text("$days days", style: const TextStyle(color: AppColors.white, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Right side: View Plan button
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                "View Plan",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Create Trip Card Shown when user has no trips
  Widget _buildCreateTripCard() {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DestinationDatePage(),
        ),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:AppColors.background, // soft beige background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            "AI Powered",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Where do you want to go?",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Let AI plan your perfect trip",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "Create Your Trip",
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward,
                              color: AppColors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

            ],
          ),

          const SizedBox(height: 16),

          // Bottom features
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            
            children: const [
              _FeatureItem(icon: Icons.auto_awesome, text: "Smart Itineraries"),
              SizedBox(width: 16),
              _FeatureItem(icon: Icons.calendar_today, text: "Personalized"),
            ],
          ),
        ],
      ),
    ),
  );
}

  // Recommendations Section
  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recommended for You",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyPage()),
                );
              },
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Show loading, error, empty, or recommendations
        if (_isLoadingRecommendations)
          _buildLoadingIndicator()
        else if (_recommendationError != null)
          _buildErrorState()
        else if (_recommendations.isEmpty)
          _buildEmptyRecommendations()
        else
          _buildRecommendationsVertical(), 
      ],
    );
  }

  // recommendation cards
  Widget _buildRecommendationsVertical() {
    return Column(
      children: [
        _buildRecommendationCard(_recommendations[0]),
        const SizedBox(height: 14),
        if (_recommendations.length > 1)
          _buildRecommendationCard(_recommendations[1]),
      ],
    );
  }

  // recommendation card
  Widget _buildRecommendationCard(NearbyActivity activity) {
    return GestureDetector(
      onTap: () {
      },
      child: Container(
        height: 200, 
        width: double.infinity, 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22), 
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background image
              (activity.imageUrl != null && activity.imageUrl!.isNotEmpty)
                  ? Image.network(
                      activity.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: AppColors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_city,
                          size: 60,
                          color: AppColors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.transparent,
                      AppColors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Container(
                height: 200,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity title
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category and distance 
                    Padding(
                      padding: const EdgeInsets.only(left: 6.5), 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.category,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                            ),
                          ),
                          if (activity.distanceKm != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              "${activity.distanceKm!.toStringAsFixed(1)} km away",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading, Error, and Empty States
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            "Failed to load recommendations",
            style: TextStyle(color: AppColors.greyDark),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadRecommendations,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.search, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            "No recommendations available",
            style: TextStyle(color: AppColors.greyDark),
          ),
        ],
      ),
    );
  }
}
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}
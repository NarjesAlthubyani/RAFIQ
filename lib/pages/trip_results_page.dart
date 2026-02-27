import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rafiq/theme/app_colors.dart';
import 'package:rafiq/pages/home_page.dart';
import 'package:rafiq/services/trip_service.dart';
import 'package:intl/intl.dart';

class TripResultsPage extends StatefulWidget {
  final String tripId;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String budgetRange;
  final List<String> selectedInterests;

  const TripResultsPage({
    Key? key,
    required this.tripId,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.budgetRange,
    required this.selectedInterests,
  }) : super(key: key);

  @override
  _TripResultsPageState createState() => _TripResultsPageState();
}

class _TripResultsPageState extends State<TripResultsPage> {
  int _selectedDay = 0;
  List<String> _days = ['All'];
  Map<int, bool> _expandedDays = {};
  
  List<Map<String, dynamic>> _allActivities = [];
  Map<String, dynamic>? _tripData;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isDisposed = false;

  @override
  void initState() {
  super.initState();
  _loadTripData();
}

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadTripData() async {
    _safeSetState(() => _isLoading = true);

    try {
      print('Loading trip data for ID: ${widget.tripId}');
      final tripData = await TripService.getTripDetails(widget.tripId);
      
      if (!_isDisposed && mounted) {
        if (tripData != null) {
          print('Trip data loaded successfully');
          _tripData = tripData;
          
          // Get ai_responses - could be List or Map
          dynamic aiResponses = tripData['ai_responses'];
          print('ai_responses type: ${aiResponses.runtimeType}');
          
          Map<String, dynamic>? aiResponseMap;
          
          if (aiResponses != null) {
            // Handle different response structures
            if (aiResponses is List && aiResponses.isNotEmpty) {
              print('ai_responses is a List with ${aiResponses.length} items');
              final firstItem = aiResponses.first;
              if (firstItem is Map) {
                // Fix: Properly cast to Map<String, dynamic>
                aiResponseMap = Map<String, dynamic>.from(firstItem as Map);
                print('Extracted first item from list');
              }
            } else if (aiResponses is Map) {
              print('ai_responses is a Map');
              // Fix: Properly cast to Map<String, dynamic>
              aiResponseMap = Map<String, dynamic>.from(aiResponses as Map);
            }
            
            // Now extract the full_response
            if (aiResponseMap != null && aiResponseMap['full_response'] != null) {
              print('Found full_response in aiResponseMap');
              final fullResponse = aiResponseMap['full_response'];
              print('full_response type: ${fullResponse.runtimeType}');
              
              // Parse the full_response
              Map<String, dynamic> responseData = {};
              
              if (fullResponse is String) {
                print('Attempting to parse JSON string');
                try {
                  responseData = jsonDecode(fullResponse);
                  print('Successfully parsed JSON string');
                  print('Response keys: ${responseData.keys}');
                } catch (e) {
                  print('Error parsing JSON string: $e');
                }
              } else if (fullResponse is Map) {
                print('Using Map directly');
                // Fix: Properly cast to Map<String, dynamic>
                responseData = Map<String, dynamic>.from(fullResponse as Map);
                print('Response keys: ${responseData.keys}');
              }
              
              // Extract itinerary
              if (responseData.isNotEmpty) {
                // Check if response has 'itinerary' field
                dynamic itineraryData = responseData['itinerary'];
                
                // If no itinerary, check if it might be using a different key
                if (itineraryData == null) {
                  print('No "itinerary" key found, checking alternative keys...');
                  // Try common alternative keys
                  if (responseData.containsKey('days')) {
                    itineraryData = responseData['days'];
                    print('Using "days" instead of itinerary');
                  } else if (responseData.containsKey('plan')) {
                    itineraryData = responseData['plan'];
                    print('Using "plan" instead of itinerary');
                  } else if (responseData.containsKey('trip')) {
                    itineraryData = responseData['trip'];
                    print('Using "trip" instead of itinerary');
                  }
                }
                
                print('itineraryData type: ${itineraryData.runtimeType}');
                
                List<dynamic> itineraryList = [];
                
                if (itineraryData is List) {
                  itineraryList = itineraryData;
                  print('Found itinerary list with ${itineraryList.length} days');
                } else if (itineraryData != null) {
                  // If it's a single day object, wrap it in a list
                  itineraryList = [itineraryData];
                  print('Found single itinerary item, wrapped in list');
                } else {
                  print('No itinerary data found in response');
                  // Create a default itinerary
                  itineraryList = [
                    {
                      'day': 1,
                      'date': widget.fromDate.toIso8601String().split('T')[0],
                      'activities': [
                        {
                          'title': 'Explore ${widget.destination}',
                          'category': 'Culture',
                          'description': 'Discover the beauty of ${widget.destination}',
                          'location': 'City Center',
                          'cost': 0,
                          'duration': 4,
                        }
                      ]
                    }
                  ];
                  print('Created default itinerary');
                }
                
                // Parse activities from itinerary
                if (itineraryList.isNotEmpty) {
                  List<Map<String, dynamic>> parsedActivities = _parseActivitiesFromAI(itineraryList);
                  
                  // If no activities were parsed but we have itinerary days, create placeholder activities
                  if (parsedActivities.isEmpty && itineraryList.isNotEmpty) {
                    print('No activities parsed, creating placeholder activities from days');
                    for (var dayData in itineraryList) {
                      if (dayData is Map) {
                        int dayNum = 1;
                        if (dayData.containsKey('day')) {
                          dayNum = dayData['day'] is int 
                              ? (dayData['day'] as int) 
                              : int.tryParse(dayData['day'].toString()) ?? 1;
                        }
                        
                        // Try to extract activities if they exist in a different format
                        if (dayData.containsKey('activities') && dayData['activities'] is List) {
                          // Activities already exist, they'll be parsed in _parseActivitiesFromAI
                          continue;
                        } else {
                          // Create a placeholder activity for this day
                          parsedActivities.add({
                            'day': dayNum,
                            'title': 'Day $dayNum in ${widget.destination}',
                            'category': 'General',
                            'description': dayData['description']?.toString() ?? 'Explore ${widget.destination}',
                            'location': widget.destination,
                            'cost': 0.0,
                            'duration': 4.0,
                            'icon': Icons.place,
                            'image': 'assets/${widget.destination.toLowerCase()}.jpg',
                          });
                        }
                      }
                    }
                  }
                  
                  // Also try to extract meal recommendations if they exist
                  if (responseData.containsKey('meals') || responseData.containsKey('restaurants')) {
                    print('Found meal/restaurant recommendations to add');
                    List<Map<String, dynamic>> mealActivities = _extractMealRecommendations(
                      responseData, 
                      itineraryList.length
                    );
                    parsedActivities.addAll(mealActivities);
                  }
                  
                  // Fix: Create a new variable for sorted days
                  List<int> sortedDaysList = [];
                  
                  _safeSetState(() {
                    _allActivities = parsedActivities;
                    
                    // Determine unique days from parsed activities
                    Set<int> uniqueDays = parsedActivities.map((a) => a['day'] as int).toSet();
                    sortedDaysList = uniqueDays.toList()..sort();
                    
                    if (sortedDaysList.isEmpty && itineraryList.isNotEmpty) {
                      // If no days from activities, use days from itinerary
                      sortedDaysList = List.generate(itineraryList.length, (i) => i + 1);
                    }
                    
                    _days = ['All', ...sortedDaysList.map((day) => 'Day $day')];
                    
                    // Initialize all days as collapsed (false)
                    _expandedDays = {for (var day in sortedDaysList) day: false};
                    
                    // Auto-expand first day by default for better UX
                    if (sortedDaysList.isNotEmpty) {
                      _expandedDays[sortedDaysList.first] = true;
                    }
                    
                    _isLoading = false;
                  });
                  
                  print('Final: Parsed ${parsedActivities.length} activities across ${sortedDaysList.length} days');
                } else {
                  print('No itinerary items to parse');
                  _safeSetState(() => _isLoading = false);
                }
              } else {
                print('responseData is empty');
                _safeSetState(() => _isLoading = false);
              }
            } else {
              print('No full_response found in aiResponseMap');
              _safeSetState(() => _isLoading = false);
            }
          } else {
            print('No ai_responses found in tripData');
            _safeSetState(() => _isLoading = false);
          }
        } else {
          print('tripData is null');
          _safeSetState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading trip: $e');
      if (!_isDisposed && mounted) {
        _safeSetState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to extract meal recommendations
  List<Map<String, dynamic>> _extractMealRecommendations(
    Map<String, dynamic> responseData, 
    int numDays
  ) {
    List<Map<String, dynamic>> mealActivities = [];
    
    try {
      // Check for meals array
      if (responseData.containsKey('meals') && responseData['meals'] is List) {
        final meals = responseData['meals'] as List;
        for (var meal in meals) {
          if (meal is Map) {
            int dayNum = 1;
            if (meal.containsKey('day')) {
              dayNum = meal['day'] is int 
                  ? (meal['day'] as int) 
                  : int.tryParse(meal['day'].toString()) ?? 1;
            }
            
            double cost = 0.0;
            if (meal.containsKey('cost')) {
              cost = meal['cost'] is num 
                  ? (meal['cost'] as num).toDouble() 
                  : double.tryParse(meal['cost'].toString()) ?? 0.0;
            }
            
            mealActivities.add({
              'day': dayNum,
              'title': meal['name']?.toString() ?? 'Restaurant',
              'category': 'Food',
              'description': meal['description']?.toString() ?? 'Enjoy local cuisine',
              'location': meal['location']?.toString() ?? widget.destination,
              'cost': cost,
              'duration': 1.5,
              'icon': Icons.restaurant,
              'image': 'assets/${widget.destination.toLowerCase()}.jpg',
            });
          }
        }
      }
      
      // Check for restaurants array
      if (responseData.containsKey('restaurants') && responseData['restaurants'] is List) {
        final restaurants = responseData['restaurants'] as List;
        for (var restaurant in restaurants) {
          if (restaurant is Map) {
            int dayNum = 1;
            if (restaurant.containsKey('day')) {
              dayNum = restaurant['day'] is int 
                  ? (restaurant['day'] as int) 
                  : int.tryParse(restaurant['day'].toString()) ?? 1;
            }
            
            double cost = 0.0;
            if (restaurant.containsKey('cost')) {
              cost = restaurant['cost'] is num 
                  ? (restaurant['cost'] as num).toDouble() 
                  : double.tryParse(restaurant['cost'].toString()) ?? 0.0;
            }
            
            mealActivities.add({
              'day': dayNum,
              'title': restaurant['name']?.toString() ?? 'Restaurant',
              'category': 'Food',
              'description': restaurant['description']?.toString() ?? 'Dining experience',
              'location': restaurant['location']?.toString() ?? widget.destination,
              'cost': cost,
              'duration': 1.5,
              'icon': Icons.restaurant,
              'image': 'assets/${widget.destination.toLowerCase()}.jpg',
            });
          }
        }
      }
      
      // If no structured meals, create placeholder meals for each day
      if (mealActivities.isEmpty) {
        for (int day = 1; day <= numDays; day++) {
          mealActivities.add({
            'day': day,
            'title': 'Local Restaurant',
            'category': 'Food',
            'description': 'Enjoy authentic Saudi cuisine',
            'location': widget.destination,
            'cost': 150.0,
            'duration': 1.5,
            'icon': Icons.restaurant,
            'image': 'assets/${widget.destination.toLowerCase()}.jpg',
          });
        }
      }
    } catch (e) {
      print('Error extracting meal recommendations: $e');
    }
    
    return mealActivities;
  }

  List<Map<String, dynamic>> _parseActivitiesFromAI(List<dynamic> itinerary) {
    List<Map<String, dynamic>> activities = [];
    
    try {
      print('Parsing itinerary with ${itinerary.length} items');
      
      for (var dayData in itinerary) {
        if (dayData is! Map) {
          print('dayData is not a Map: ${dayData.runtimeType}');
          continue;
        }
        
        int day = 1;
        if (dayData.containsKey('day')) {
          day = dayData['day'] is int 
              ? (dayData['day'] as int) 
              : int.tryParse(dayData['day'].toString()) ?? 1;
        }
        
        print('Processing Day $day');
        
        // Try different possible keys for activities
        dynamic dayActivities;
        
        if (dayData.containsKey('activities')) {
          dayActivities = dayData['activities'];
          print('  Found "activities" key');
        } else if (dayData.containsKey('items')) {
          dayActivities = dayData['items'];
          print('  Found "items" key');
        } else if (dayData.containsKey('schedule')) {
          dayActivities = dayData['schedule'];
          print('  Found "schedule" key');
        } else if (dayData.containsKey('places')) {
          dayActivities = dayData['places'];
          print('  Found "places" key');
        } else {
          // If no activities array, treat the whole day as an activity
          print('  No activities array found, creating default activity');
          activities.add(_createActivityFromDayData(dayData, day));
          continue;
        }
        
        print('  activities type: ${dayActivities.runtimeType}');
        
        List<dynamic> activitiesList = [];
        if (dayActivities is List) {
          activitiesList = dayActivities;
          print('  Found ${activitiesList.length} activities in list');
        } else if (dayActivities != null) {
          activitiesList = [dayActivities];
          print('  Found single activity (converted to list)');
        } else {
          print('  No activities found for day $day, creating default');
          activities.add(_createDefaultActivity(day));
          continue;
        }
        
        for (var activity in activitiesList) {
          if (activity is! Map) {
            print('  Activity is not a Map: ${activity.runtimeType}');
            continue;
          }
          
          // Fix: Cast to Map<String, dynamic> for helper methods
          Map<String, dynamic> typedActivity = Map<String, dynamic>.from(activity as Map);
          
          String title = _extractTitle(typedActivity);
          print('  ➕ Adding activity: $title');
          
          activities.add({
            'day': day,
            'title': title,
            'category': _extractCategory(typedActivity),
            'description': _extractDescription(typedActivity),
            'location': _extractLocation(typedActivity, dayData),
            'cost': _extractCost(typedActivity),
            'duration': _extractDuration(typedActivity),
            'icon': _getCategoryIcon(_extractCategory(typedActivity)),
            'image': 'assets/${widget.destination.toLowerCase()}.jpg',
          });
        }
      }
    } catch (e) {
      print('Error parsing activities: $e');
    }
    
    // If no activities were parsed, create default ones
    if (activities.isEmpty && itinerary.isNotEmpty) {
      print('No activities parsed, creating defaults for each day');
      for (int i = 0; i < itinerary.length; i++) {
        activities.add(_createDefaultActivity(i + 1));
      }
    }
    
    print('Total parsed activities: ${activities.length}');
    return activities;
  }

  // Helper methods for parsing
  String _extractTitle(Map<String, dynamic> activity) {
    if (activity.containsKey('title') && activity['title'] != null) {
      return activity['title'].toString();
    }
    if (activity.containsKey('name') && activity['name'] != null) {
      return activity['name'].toString();
    }
    if (activity.containsKey('place') && activity['place'] != null) {
      return activity['place'].toString();
    }
    return 'Activity';
  }

  String _extractCategory(Map<String, dynamic> activity) {
    if (activity.containsKey('category') && activity['category'] != null) {
      return activity['category'].toString();
    }
    if (activity.containsKey('type') && activity['type'] != null) {
      return activity['type'].toString();
    }
    // Try to infer from title
    String title = _extractTitle(activity).toLowerCase();
    if (title.contains('restaurant') || title.contains('cafe') || title.contains('food')) {
      return 'Food';
    }
    if (title.contains('museum') || title.contains('history')) {
      return 'History';
    }
    if (title.contains('shop') || title.contains('market')) {
      return 'Shopping';
    }
    return 'General';
  }

  String _extractDescription(Map<String, dynamic> activity) {
    if (activity.containsKey('description') && activity['description'] != null) {
      return activity['description'].toString();
    }
    if (activity.containsKey('details') && activity['details'] != null) {
      return activity['details'].toString();
    }
    if (activity.containsKey('notes') && activity['notes'] != null) {
      return activity['notes'].toString();
    }
    return '';
  }

  String _extractLocation(Map<String, dynamic> activity, Map<dynamic, dynamic> dayData) {
    if (activity.containsKey('location') && activity['location'] != null) {
      return activity['location'].toString();
    }
    if (activity.containsKey('place') && activity['place'] != null) {
      return activity['place'].toString();
    }
    if (activity.containsKey('area') && activity['area'] != null) {
      return activity['area'].toString();
    }
    if (dayData.containsKey('location') && dayData['location'] != null) {
      return dayData['location'].toString();
    }
    return widget.destination;
  }

  double _extractCost(Map<String, dynamic> activity) {
    if (activity.containsKey('cost') && activity['cost'] != null) {
      return activity['cost'] is num 
          ? (activity['cost'] as num).toDouble() 
          : double.tryParse(activity['cost'].toString()) ?? 0.0;
    }
    if (activity.containsKey('price') && activity['price'] != null) {
      return activity['price'] is num 
          ? (activity['price'] as num).toDouble() 
          : double.tryParse(activity['price'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  double _extractDuration(Map<String, dynamic> activity) {
    if (activity.containsKey('duration') && activity['duration'] != null) {
      return activity['duration'] is num 
          ? (activity['duration'] as num).toDouble() 
          : double.tryParse(activity['duration'].toString()) ?? 1.0;
    }
    if (activity.containsKey('hours') && activity['hours'] != null) {
      return activity['hours'] is num 
          ? (activity['hours'] as num).toDouble() 
          : double.tryParse(activity['hours'].toString()) ?? 1.0;
    }
    return 1.0;
  }

  Map<String, dynamic> _createActivityFromDayData(Map<dynamic, dynamic> dayData, int day) {
    double cost = 0.0;
    if (dayData.containsKey('cost')) {
      cost = dayData['cost'] is num 
          ? (dayData['cost'] as num).toDouble() 
          : double.tryParse(dayData['cost'].toString()) ?? 0.0;
    }
    
    double duration = 4.0;
    if (dayData.containsKey('duration')) {
      duration = dayData['duration'] is num 
          ? (dayData['duration'] as num).toDouble() 
          : double.tryParse(dayData['duration'].toString()) ?? 4.0;
    }
    
    return {
      'day': day,
      'title': dayData['title']?.toString() ?? 'Day $day in ${widget.destination}',
      'category': dayData['category']?.toString() ?? 'General',
      'description': dayData['description']?.toString() ?? 'Explore ${widget.destination}',
      'location': dayData['location']?.toString() ?? widget.destination,
      'cost': cost,
      'duration': duration,
      'icon': Icons.place,
      'image': 'assets/${widget.destination.toLowerCase()}.jpg',
    };
  }

  Map<String, dynamic> _createDefaultActivity(int day) {
    return {
      'day': day,
      'title': 'Day $day in ${widget.destination}',
      'category': 'General',
      'description': 'Explore and enjoy ${widget.destination}',
      'location': widget.destination,
      'cost': 0.0,
      'duration': 4.0,
      'icon': Icons.place,
      'image': 'assets/${widget.destination.toLowerCase()}.jpg',
    };
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'history':
        return Icons.history;
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      case 'nature':
        return Icons.nature;
      case 'adventure':
        return Icons.hiking;
      case 'relaxation':
        return Icons.spa;
      case 'entertainment':
        return Icons.attractions;
      case 'culture':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }

  Future<void> _saveTrip() async {
    try {
      final success = await TripService.saveTrip(tripId: widget.tripId);
      if (!_isDisposed && mounted) {
        if (success) {
          _safeSetState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save trip'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '${date.month}/${date.day}';
    }
  }

  String _getDayDate(int dayNum) {
    try {
      final date = widget.fromDate.add(Duration(days: dayNum - 1));
      return _formatDate(date);
    } catch (e) {
      return 'Day $dayNum';
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateRange = '${_formatDate(widget.fromDate)} to ${_formatDate(widget.toDate)}';

    Set<int> uniqueDays = _allActivities.map((a) => a['day'] as int).toSet();
    List<int> daysToShow = [];
    if (_selectedDay == 0) {
        daysToShow = uniqueDays.toList();
        daysToShow.sort();
    } else {
        daysToShow = [_selectedDay];
    }

    bool hasExpandedDay = _expandedDays.values.any((isExpanded) => isExpanded);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your trip...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _allActivities.isEmpty
              ? _buildEmptyState()
              : Stack(
                  children: [
                    Column(
                      children: [
                        _buildHeroHeader(dateRange),
                        _buildDayTabs(),
                        Expanded(
                          child: _buildActivitiesList(daysToShow),
                        ),
                      ],
                    ),
                    
                    // Add Activity FAB (only shown when a day is expanded)
                    if (hasExpandedDay)
                      Positioned(
                        left: 24,
                        bottom: 40,
                        child: GestureDetector(
                          onTap: () {
                            int? expandedDay = _expandedDays.entries
                                .firstWhere(
                                  (e) => e.value == true,
                                  orElse: () => const MapEntry(1, false),
                                )
                                .key;
                            if (_expandedDays[expandedDay] == true) {
                              _addActivityForDay(expandedDay);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add activity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildHeroHeader(String dateRange) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/${widget.destination.toLowerCase()}.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.accent.withOpacity(0.3),
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.destination,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _tripData?['budget']?.toString() ?? widget.budgetRange,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateRange,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Top Navigation Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () {
                    if (!_isDisposed && mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(initialIndex: 3),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                
                // Save and Menu Buttons
                Row(
                  children: [
                    // Three Dots Menu
                    GestureDetector(
                      onTap: () {
                        if (!_isDisposed && mounted) {
                          _showHeaderMenu(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Day Tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedDay == index;
                
                return GestureDetector(
                  onTap: () {
                    if (!_isDisposed && mounted) {
                      _safeSetState(() {
                        _selectedDay = index;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _days[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Plus Button for adding new day
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _addNewDay,
              icon: Icon(
                Icons.add,
                color: Colors.grey.shade600,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(List<int> daysToShow) {
    if (daysToShow.isEmpty) {
      return Center(
        child: Text(
          'No activities found',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      itemCount: daysToShow.length,
      itemBuilder: (context, index) {
        int dayNum = daysToShow[index];
        bool isExpanded = _expandedDays[dayNum] ?? false;
        List<Map<String, dynamic>> dayActivities = 
            _allActivities.where((a) => a['day'] == dayNum).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header (click to expand/collapse)
            GestureDetector(
              onTap: () {
                if (!_isDisposed && mounted) {
                  _safeSetState(() {
                    _expandedDays[dayNum] = !isExpanded;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $dayNum - ${_getDayDate(dayNum)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            
            // Activities for this day (shown when expanded)
            if (isExpanded && dayActivities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(
                children: List.generate(dayActivities.length, (actIndex) {
                  var activity = dayActivities[actIndex];
                  return _buildActivityCard(activity);
                }),
              ),
            ] else if (isExpanded && dayActivities.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No activities for this day',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ],
            
            // Divider between days (except last)
            if (index < daysToShow.length - 1)
              Container(
                height: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(vertical: 16),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Section
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: AssetImage(activity['image'] ?? 'assets/placeholder.jpg'),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
              ),
              
              // Three Dots Menu
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      if (!_isDisposed && mounted) {
                        _showActivityMenu(context, activity);
                      }
                    },
                    child: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Info Section
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side - Title and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'] ?? 'Activity',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            activity['icon'] ?? Icons.place,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            activity['category'] ?? 'General',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // View on Map Button
                OutlinedButton.icon(
                  onPressed: () {
                    _viewOnMap(activity);
                  },
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('View on map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                    side: const BorderSide(color: Colors.white, width: 0.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No itinerary yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI-generated trip will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // ================= Action Methods =================

  void _addNewDay() {
    showDialog(
      context: context,
      builder: (context) {
        String newDayName = 'Day ${_days.length}';
        
        return AlertDialog(
          title: const Text('Add New Day'),
          content: Text('Add $newDayName to your trip?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _safeSetState(() {
                  _days.add(newDayName);
                  _expandedDays[_days.length - 1] = false;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewOnMap(Map<String, dynamic> activity) {
    print('View ${activity['title']} on map');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${activity['title']} on map...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addActivityForDay(int dayNum) {
    print('Add activity for day $dayNum');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add activity feature coming soon for Day $dayNum'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHeaderMenu(BuildContext context) {
    if (!_isDisposed && mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete trip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _confirmDeleteTrip(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(modalContext),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _showActivityMenu(BuildContext context, Map<String, dynamic> activity) {
    if (!_isDisposed && mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _confirmDeleteActivity(context, activity);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(modalContext),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _confirmDeleteTrip(BuildContext context) {
    if (!_isDisposed && mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Trip'),
            content: const Text(
              'Are you sure you want to delete this trip? This action cannot be undone.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  
                  try {
                    final success = await TripService.deleteTrip(widget.tripId);
                    
                    if (!_isDisposed && mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trip deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(initialIndex: 3),
                          ),
                          (route) => false,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete trip'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (!_isDisposed && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _confirmDeleteActivity(BuildContext context, Map<String, dynamic> activity) {
    if (!_isDisposed && mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Activity'),
            content: Text(
              'Are you sure you want to delete "${activity['title']}"?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (!_isDisposed && mounted) {
                    _safeSetState(() {
                      _allActivities.remove(activity);
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activity deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
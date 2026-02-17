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
                aiResponseMap = Map<String, dynamic>.from(firstItem);
                print('Extracted first item from list');
              }
            } else if (aiResponses is Map) {
              print('ai_responses is a Map');
              aiResponseMap = Map<String, dynamic>.from(aiResponses);
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
                responseData = Map<String, dynamic>.from(fullResponse);
                print('Response keys: ${responseData.keys}');
              }
              
              // Extract itinerary
              if (responseData.isNotEmpty) {
                final itinerary = responseData['itinerary'];
                print('itinerary type: ${itinerary.runtimeType}');
                
                List itineraryList = [];
                
                if (itinerary is List) {
                  itineraryList = itinerary;
                  print('Found itinerary list with ${itineraryList.length} days');
                } else if (itinerary != null) {
                  itineraryList = [itinerary];
                  print('Found single itinerary item');
                } else {
                  print('No itinerary found in response');
                }
                
                // Parse activities
                if (itineraryList.isNotEmpty) {
                  List<Map<String, dynamic>> parsedActivities = _parseActivitiesFromAI(itineraryList);
                  
                  _safeSetState(() {
                    _allActivities = parsedActivities;
                    _days = ['All', ...List.generate(itineraryList.length, (i) => 'Day ${i + 1}')];
                    // Initialize all days as expanded
                    _expandedDays = {for (var i = 1; i <= itineraryList.length; i++) i: false};
                    _isLoading = false;
                  });
                  
                  print('Final: Parsed ${parsedActivities.length} activities across ${itineraryList.length} days');
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

  List<Map<String, dynamic>> _parseActivitiesFromAI(List itinerary) {
    List<Map<String, dynamic>> activities = [];
    
    try {
      print('Parsing itinerary with ${itinerary.length} items');
      
      for (var dayData in itinerary) {
        if (dayData is! Map) {
          print('dayData is not a Map: ${dayData.runtimeType}');
          continue;
        }
        
        final day = dayData['day'] ?? 1;
        final dayActivities = dayData['activities'];
        
        print('Processing Day $day');
        print('  activities type: ${dayActivities.runtimeType}');
        
        List activitiesList = [];
        if (dayActivities is List) {
          activitiesList = dayActivities;
          print('Found ${activitiesList.length} activities in list');
        } else if (dayActivities != null) {
          activitiesList = [dayActivities];
          print('Found single activity (converted to list)');
        } else {
          print('No activities found for day $day');
          continue;
        }
        
        for (var activity in activitiesList) {
          if (activity is! Map) {
            print('Activity is not a Map: ${activity.runtimeType}');
            continue;
          }
          
          print('  ➕ Adding activity: ${activity['title']}');
          
          activities.add({
            'day': day is int ? day : int.tryParse(day.toString()) ?? 1,
            'title': activity['title']?.toString() ?? 'Activity',
            'category': activity['category']?.toString() ?? 'General',
            'description': activity['description']?.toString() ?? '',
            'location': activity['location']?.toString() ?? widget.destination,
            'cost': activity['cost'] ?? 0,
            'duration': activity['duration'] ?? 1,
            'icon': _getCategoryIcon(activity['category']?.toString()),
            'image': 'assets/${widget.destination.toLowerCase()}.jpg',
          });
        }
      }
    } catch (e) {
      print('Error parsing activities: $e');
    }
    
    print('Total parsed activities: ${activities.length}');
    return activities;
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
                                  orElse: () => MapEntry(1, false),
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
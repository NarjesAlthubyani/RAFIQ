import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:rafiq/theme/app_colors.dart';
import 'package:rafiq/pages/home_page.dart';
import 'package:rafiq/services/trip_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _TripResultsPageState extends State<TripResultsPage>{
  int _selectedDay = 0;
  List<String> _days = ['All'];
  Map<int, bool> _expandedDays = {};

  List<Map<String, dynamic>> _allActivities = [];
  Map<String, dynamic>? _tripData;
  bool _isLoading = true;
  bool _isDisposed = false;
  bool _showAddActivityText = false;

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
    final tripData = await TripService.getTripDetails(widget.tripId);
    
    if (!_isDisposed && mounted && tripData != null) {
      _tripData = tripData;
      
      final aiResponsesList = tripData['ai_responses'];
      
      if (aiResponsesList != null && aiResponsesList is List && aiResponsesList.isNotEmpty) {
      
        final firstResponse = aiResponsesList.first as Map<String, dynamic>;
        
        final fullResponse = firstResponse['full_response'];
        
        Map<String, dynamic> responseData = {};
        
        if (fullResponse is String) {
          try {
            responseData = jsonDecode(fullResponse);
          } catch (e) {
          }
        } else if (fullResponse is Map) {
          responseData = Map<String, dynamic>.from(fullResponse);
        } else {
        }
        
        if (responseData.isNotEmpty) {
          dynamic itineraryData = responseData['itinerary'];
          
          List<dynamic> itineraryList = [];
          
          if (itineraryData is List) {
            itineraryList = itineraryData;
          } else if (itineraryData != null) {
            itineraryList = [itineraryData];
          } else {
            if (responseData.containsKey('days')) {
              itineraryList = responseData['days'] is List ? responseData['days'] : [];
            } else if (responseData.containsKey('plan')) {
              itineraryList = responseData['plan'] is List ? responseData['plan'] : [];
            }
          }
          
          if (itineraryList.isNotEmpty) {
            final parsedActivities = await _parseActivitiesFromAI(itineraryList);
            
            if (parsedActivities.isNotEmpty) {
              _safeSetState(() {
                _allActivities = parsedActivities;
                
                final uniqueDays = parsedActivities.map((a) => a['day'] as int).toSet().toList()..sort();
                
                _days = ['All', ...uniqueDays.map((day) => 'Day $day')];
                
                _expandedDays = {
                  for (var day in uniqueDays) day: false,
                };
                
                if (uniqueDays.isNotEmpty) {
                  _expandedDays[uniqueDays.first] = true;
                }
                
                _isLoading = false;
              });
            } else {
              _safeSetState(() => _isLoading = false);
            }
          } else {
            _safeSetState(() => _isLoading = false);
          }
        } else {
          _safeSetState(() => _isLoading = false);
        }
      } else {
        _safeSetState(() => _isLoading = false);
      }
    } else {
      _safeSetState(() => _isLoading = false);
    }
  } catch (e) {
    if (!_isDisposed && mounted) {
      _safeSetState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading trip: ${e.toString()}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}
  
  String _extractImageUrl(Map<String, dynamic> activity) {
    final candidateKeys = [
      'image_url',
      'imageUrl',
      'image',
      'photo_url',
      'photoUrl',
      'photo',
      'picture_url',
      'pictureUrl',
      'picture',
    ];

    for (final key in candidateKeys) {
      if (activity.containsKey(key) && activity[key] != null) {
        final String url = activity[key].toString().trim();
        if (url.isNotEmpty) {
          return url;
        }
      }
    }

    return 'assets/placeholder.jpg';
  }

  Future<String> _resolveActivityImageUrl(
    Map<String, dynamic> activity,
    String city,
  ) async {
    final extractedUrl = _extractImageUrl(activity);
    if (extractedUrl.isNotEmpty && extractedUrl.startsWith('http')) {
      return extractedUrl;
    }

    final candidateNames = <String>{
      _extractTitle(activity),
      activity['venue_name']?.toString() ?? '',
      activity['name']?.toString() ?? '',
      activity['place']?.toString() ?? '',
      activity['location']?.toString() ?? '',
    }.map((name) => name.trim()).where((name) => name.isNotEmpty).toList();

    for (final name in candidateNames) {
      final String? supabaseUrl = await TripService.getImageByName(name, city);
      if (supabaseUrl != null && supabaseUrl.isNotEmpty) {
        return supabaseUrl;
      }
    }

    return extractedUrl.isNotEmpty ? extractedUrl : 'assets/placeholder.jpg';
  }

  Future<List<Map<String, dynamic>>> _parseActivitiesFromAI(
    List<dynamic> itinerary,
  ) async {
    List<Map<String, dynamic>> activities = [];

    try {

      for (var dayData in itinerary) {
        if (dayData is! Map) {
          continue;
        }

        int day = 1;
        if (dayData.containsKey('day')) {
          day = dayData['day'] is int
              ? (dayData['day'] as int)
              : int.tryParse(dayData['day'].toString()) ?? 1;
        } else if (dayData.containsKey('day_number')) {
          day = dayData['day_number'] is int
              ? (dayData['day_number'] as int)
              : int.tryParse(dayData['day_number'].toString()) ?? 1;
        }

        dynamic dayActivities;

        if (dayData.containsKey('activities')) {
          dayActivities = dayData['activities'];
        } else if (dayData.containsKey('items')) {
          dayActivities = dayData['items'];
        } else if (dayData.containsKey('schedule')) {
          dayActivities = dayData['schedule'];
        } else if (dayData.containsKey('places')) {
          dayActivities = dayData['places'];
        } else {
          activities.add(_createActivityFromDayData(dayData, day));
          continue;
        }

        List<dynamic> activitiesList = [];
        if (dayActivities is List) {
          activitiesList = dayActivities;
        } else if (dayActivities != null) {
          activitiesList = [dayActivities];
        } else {
          activities.add(_createDefaultActivity(day));
          continue;
        }

        for (var activity in activitiesList) {
          if (activity is! Map) {
      
            continue;
          }

          Map<String, dynamic> typedActivity = Map<String, dynamic>.from(
            activity,
          );

          String title = _extractTitle(typedActivity);
          String imageUrl = await _resolveActivityImageUrl(
            typedActivity,
            widget.destination,
          );

          activities.add({
            'name': title,
            'day': day,
            'title': title,
            'location_link': typedActivity['location_link'],
            'category': _extractCategory(typedActivity),
            'description': _extractDescription(typedActivity),
            'location': _extractLocation(typedActivity, dayData),
            'cost': _extractCost(typedActivity),
            'duration': _extractDuration(typedActivity),
            'icon': _getCategoryIcon(_extractCategory(typedActivity)),
            'image_url': imageUrl,
            'lat': typedActivity['lat'],
            'lng': typedActivity['lng'],
          });
        }
      }
    } catch (e) {
    }

    if (activities.isEmpty && itinerary.isNotEmpty) {
      for (int i = 0; i < itinerary.length; i++) {
        activities.add(_createDefaultActivity(i + 1));
      }
    }

    return activities;
  }

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
    String title = _extractTitle(activity).toLowerCase();
    if (title.contains('restaurant') ||
        title.contains('cafe') ||
        title.contains('food')) {
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
    if (activity.containsKey('description') &&
        activity['description'] != null) {
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

  String _extractLocation(
    Map<String, dynamic> activity,
    Map<dynamic, dynamic> dayData,
  ) {
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

  Map<String, dynamic> _createActivityFromDayData(
    Map<dynamic, dynamic> dayData,
    int day,
  ) {
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
      'title':
          dayData['title']?.toString() ?? 'Day $day in ${widget.destination}',
      'category': dayData['category']?.toString() ?? 'General',
      'description':
          dayData['description']?.toString() ?? 'Explore ${widget.destination}',
      'location': dayData['location']?.toString() ?? widget.destination,
      'cost': cost,
      'duration': duration,
      'icon': Icons.place,
      'image_url': 'assets/placeholder.jpg',
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
      'image_url': 'assets/placeholder.jpg',
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
    String dateRange =
        '${_formatDate(widget.fromDate)} to ${_formatDate(widget.toDate)}';

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
      backgroundColor: AppColors.white,
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
                    Expanded(child: _buildActivitiesList(daysToShow)),
                  ],
                ),

                if (hasExpandedDay)
                  Positioned(
                    left: 24,
                    bottom: 40,
                    child: GestureDetector(
                      onTap: () {
                        if (!_isDisposed && mounted) {
                          _safeSetState(() {
                            _showAddActivityText = !_showAddActivityText;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              color: AppColors.white,
                              size: 24,
                            ),
                            if (_showAddActivityText) ...[
                              const SizedBox(width: 4),
                              const Text(
                                'Add activity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
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
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/${widget.destination.toLowerCase()}.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.accent.withOpacity(0.3),
                child: Center(
                  child: Icon(Icons.image, size: 64, color: AppColors.accent),
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
                  AppColors.black.withOpacity(0.2),
                  AppColors.black.withOpacity(0.6),
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
                      color: AppColors.white,
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
                                  color: AppColors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _tripData?['budget']?.toString() ??
                                      widget.budgetRange,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
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
                                  color: AppColors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateRange,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.white,
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

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                ),

                Row(
                  children: [
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
                          color: AppColors.white,
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
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _days[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

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
              icon: Icon(Icons.add, color: Colors.grey.shade600, size: 20),
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
      padding: const EdgeInsets.only(left: 22, right: 22, top: 16, bottom: 100),
      itemCount: daysToShow.length,
      itemBuilder: (context, index) {
        int dayNum = daysToShow[index];
        bool isExpanded = _expandedDays[dayNum] ?? false;
        List<Map<String, dynamic>> dayActivities = _allActivities
            .where((a) => a['day'] == dayNum)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            if (isExpanded && dayActivities.isNotEmpty) ...[
              const SizedBox(height: 14),
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

            if (index < daysToShow.length - 1)
              Container(
                height: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(vertical: 14),
              ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getTicketInfo(String activityName) async {
  try {
    return await TripService.getTicketInfo(activityName);
  } catch (e) {
    return {'hasTicket': false, 'ticketLink': null};
  }
}

Widget _buildActivityCard(Map<String, dynamic> activity) {
  final imageString =
      activity['image_url'] ?? activity['image'] ?? 'assets/placeholder.jpg';
  final ImageProvider imageProvider =
      imageString.toString().toLowerCase().startsWith('http')
      ? NetworkImage(imageString.toString())
      : AssetImage(imageString.toString());

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200, width: 1),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  image: imageProvider,
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                ),
              ),
            ),
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
                    color: AppColors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
        ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] ?? 'Activity',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          activity['icon'] ?? Icons.place,
                          color: AppColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activity['category'] ?? 'General',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getTicketInfo(activity['title']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink(); 
                        }
                        
                        if (snapshot.hasData && 
                            snapshot.data != null && 
                            snapshot.data!['hasTicket'] == true &&
                            snapshot.data!['ticketLink'] != null &&
                            (snapshot.data!['ticketLink'] as String?)?.isNotEmpty == true) {
                          final ticketLink = snapshot.data!['ticketLink'] as String;
                          return Row(
                            children: [
                              const SizedBox(width:6),
                              const Icon(
                                Icons.confirmation_number,
                                color: AppColors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  _openTicketWeb(ticketLink, activity['title']);
                                },
                                child: const Text(
                                  'Ticket',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  _viewOnMap(activity);
                },
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('View on map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  backgroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.white, width: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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

void _openTicketWeb(String ticketLink, String activityTitle) async {
  try {
    final Uri? url = Uri.tryParse(ticketLink);

    if (url == null) {
      throw 'Invalid URL';
    }

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

  } catch (e) {
    final fallback = Uri.parse(
      "https://www.google.com/search?q=${Uri.encodeComponent(activityTitle + " tickets")}"
    );
    await launchUrl(fallback);
  }
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade400),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
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
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewOnMap(Map<String, dynamic> activity) async {
  final locationLink = activity['location_link'];
  
  if (locationLink != null && locationLink.toString().isNotEmpty) {
    await _launchUrl(locationLink.toString(), activity['title']);
  } 
  else {
    final lat = activity['lat'];
    final lng = activity['lng'];
    final title = activity['title'] ?? '';
    
    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      await _openMapWithCoordinates(lat, lng, title);
    } 
    else {
      await _openMapWithQuery(title);
    }
  }
}

Future<void> _launchUrl(String url, String title) async {
  String finalUrl = url;
  
  if (url.contains('google.com/maps')) {
    if (Platform.isAndroid) {
      if (url.contains('@')) {
        final match = RegExp(r'@([-\d.]+),([-\d.]+)').firstMatch(url);
        if (match != null) {
          final lat = match.group(1);
          final lng = match.group(2);
          finalUrl = 'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(title)})';
        } else {
          finalUrl = 'geo:0,0?q=${Uri.encodeComponent(title)}';
        }
      } else {
        finalUrl = 'geo:0,0?q=${Uri.encodeComponent(title)}';
      }
    } else if (Platform.isIOS) {
      finalUrl = 'http://maps.apple.com/?q=${Uri.encodeComponent(title)}';
    } else {
      finalUrl = url;
    }
  }
  
  final Uri uri = Uri.parse(finalUrl);
  
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    _showMapErrorDialog('Cannot open map for $title');
  }
}

Future<void> _openMapWithCoordinates(double lat, double lng, String title) async {
  String url;
  
  if (Platform.isAndroid) {
    url = 'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(title)})';
  } else if (Platform.isIOS) {
    url = 'http://maps.apple.com/?q=$lat,$lng';
  } else {
    url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
  
  final Uri uri = Uri.parse(url);
  
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    _showMapErrorDialog('Cannot open map');
  }
}

Future<void> _openMapWithQuery(String query) async {
  if (query.isEmpty) {
    _showMapErrorDialog('No location information available');
    return;
  }
  
  final encodedQuery = Uri.encodeComponent(query);
  final url = 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
  final Uri uri = Uri.parse(url);
  
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showMapErrorDialog('Cannot open map for $query');
    }
  } catch (e) {
    _showMapErrorDialog('Error opening map');
  }
}

void _showMapErrorDialog(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.red,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              'Are you sure you want to delete this trip? This action cannot be undone.',
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
                            backgroundColor: AppColors.secondary,
                          ),
                        );

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HomePage(initialIndex: 3),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _confirmDeleteActivity(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    if (!_isDisposed && mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Activity'),
            content: Text(
              'Are you sure you want to delete "${activity['title']}"?',
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
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
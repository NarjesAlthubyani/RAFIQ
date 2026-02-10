import 'package:flutter/material.dart';
import 'package:rafiq/pages/home_page.dart';
import '../theme/app_colors.dart';

class TripResultsPage extends StatefulWidget {
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String budgetRange;
  final List<String> selectedInterests;

  const TripResultsPage({
    Key? key,
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
  final List<String> _days = ['All', 'Day 1', 'Day 2', 'Day 3', 'Day 4'];
  
  Map<int, bool> _expandedDays = {1: false, 2: false, 3: false, 4: false};
  
  final List<Map<String, dynamic>> _allActivities = [
    {
      'day': 1,
      'title': 'Al-balad',
      'category': 'Historic sites',
      'description': 'Historic district with traditional architecture',
      'icon': Icons.history,
      'image': 'assets/Albalad.jpg',
    },
    {
      'day': 1,
      'title': 'Jeddah Fountain',
      'category': 'Historic sites',
      'description': 'World\'s tallest fountain',
      'icon': Icons.water,
      'image': 'assets/Albalad.jpg',
    },
    {
      'day': 2,
      'title': 'Red Sea Mall',
      'category': 'Shopping',
      'description': 'Largest shopping mall in Jeddah',
      'icon': Icons.shopping_bag,
      'image': 'assets/Albalad.jpg',
    },
    {
      'day': 3,
      'title': 'King Fahd Fountain',
      'category': 'Landmarks',
      'description': 'Iconic Jeddah landmark',
      'icon': Icons.landscape,
      'image': 'assets/Albalad.jpg',
    },
    {
      'day': 4,
      'title': 'Al-Shallal Theme Park',
      'category': 'Entertainment',
      'description': 'Family amusement park',
      'icon': Icons.attractions,
      'image': 'assets/Albalad.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    String dateRange = '${_formatDate(widget.fromDate)} to ${_formatDate(widget.toDate)}';

    List<int> daysToShow = _selectedDay == 0
        ? [1, 2, 3, 4]
        : [_selectedDay];
    bool hasExpandedDay = _expandedDays.values.any((isExpanded) => isExpanded);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          Image.asset(
            'assets/Jeddah.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 42,
                    color: AppColors.white,
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
                      color: AppColors.background,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              color:AppColors.background,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.budgetRange,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.background,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateRange,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.background,
                              ),
                            ),
                          ],
                        ),
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
      GestureDetector(
        onTap: (){
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage(initialIndex: 3)),
          );
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 40),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.background,
            size: 32,
          ),
        ),
      ),
      // Three Dots Menu
      GestureDetector(
        onTap: () {
          _showHeaderMenu(context);
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 40),
          child: const Icon(
            Icons.more_horiz,
            color: AppColors.background,
            size: 32,
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
                    setState(() {
                      _selectedDay = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
          
          // Plus Button
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _expandedDays[dayNum] = !isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $dayNum',
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
                  image: AssetImage((activity['image'] ?? 'assets/Albalad.jpg') as String),
                  fit: BoxFit.cover,
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
                    _showActivityMenu(context, activity);
                  },
                  child: const Icon(
                    Icons.more_horiz,
                    color: AppColors.background,
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
                      (activity['title'] ?? 'Activity') as String,
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
                          (activity['icon'] ?? Icons.place) as IconData,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (activity['category'] ?? 'General') as String,
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
              
              OutlinedButton.icon(
                onPressed: () {
                  _viewOnMap(activity);
                },
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('View on map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:AppColors.white,
                  backgroundColor: AppColors.primary,
                  side: const BorderSide(color: Colors.white, width: 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  // Helper Methods
  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // Action Methods
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
                setState(() {
                  _days.add(newDayName);
                  _expandedDays[_days.length - 1] = false;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _viewOnMap(Map<String, dynamic> activity) {
    
    print('View ${activity['title']} on map');
  }

  void _addActivityForDay(int dayNum) {
    print('Add activity for day $dayNum');
  }

  void _showHeaderMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  Navigator.pop(context);
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
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActivityMenu(BuildContext context, Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  Navigator.pop(context);
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
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to previous page
                print('Trip deleted');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteActivity(BuildContext context, Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Are you sure you want to delete "${activity['title']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _allActivities.remove(activity);
                });
                print('Activity deleted: ${activity['title']}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
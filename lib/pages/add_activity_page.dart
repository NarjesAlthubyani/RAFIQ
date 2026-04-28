import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/nearby_activity.dart';
import '../models/activity.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; 

class AddActivityPage extends StatefulWidget {
  final String tripId;
  final int dayNumber;
  final DateTime dayDate;
  final List<Activity> existingActivities;
  final String destinationCity;
  final Function(List<NearbyActivity>) onActivitiesAdded;

  const AddActivityPage({
    Key? key,
    required this.tripId,
    required this.dayNumber,
    required this.dayDate,
    required this.existingActivities,
    required this.destinationCity,
    required this.onActivitiesAdded,
  }) : super(key: key);

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  static const String _baseUrl = 'http://10.0.2.2:8000';
  
  final Map<String, Map<String, double>> _cityCoordinates = {
    'Riyadh': {'lat': 24.7136, 'lng': 46.6753},
    'Jeddah': {'lat': 21.5433, 'lng': 39.1728},
    'AlUla': {'lat': 26.6515, 'lng': 37.9081},
  };
  
  List<NearbyActivity> _allActivities = [];
  List<NearbyActivity> _availableActivities = [];
  Set<NearbyActivity> _selectedActivities = {};
  bool _isLoading = false;
  bool _isAdding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchActivities() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final coordinates = _cityCoordinates[widget.destinationCity];
    
    if (coordinates == null) {
      throw Exception('Coordinates not found for city: ${widget.destinationCity}');
    }

    final lat = coordinates['lat']!;
    final lng = coordinates['lng']!;

    print('Fetching activities for ${widget.destinationCity} at lat: $lat, lng: $lng');

    final params = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'limit': '100',
    };

    final uri = Uri.parse('$_baseUrl/activities').replace(queryParameters: params);
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final List data = jsonDecode(res.body);
    final fetched = data.map((item) => NearbyActivity.fromJson(item)).toList();

    _allActivities = fetched;
    _filterAvailableActivities();

    print('Found ${fetched.length} activities for ${widget.destinationCity}');

    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    print('Error: $e');
    setState(() {
      _isLoading = false;
      _error = e.toString();
      _allActivities = [];
      _availableActivities = [];
    });
  }
}
  void _filterAvailableActivities() {
    final existingTitles = widget.existingActivities.map((a) => a.name).toSet();
    _availableActivities = _allActivities.where((activity) => 
      !existingTitles.contains(activity.title)
    ).toList();
    _selectedActivities.removeWhere((activity) => 
      existingTitles.contains(activity.title)
    );
  }

  Future<void> _addSelectedActivities() async {
    if (_selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one activity')),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final selectedList = _selectedActivities.toList();
      
      await widget.onActivitiesAdded(selectedList);
      
      setState(() {
        for (var activity in selectedList) {
          _availableActivities.remove(activity);
        }
        _selectedActivities.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${selectedList.length} activity(s) successfully!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isAdding = false);
    }
  }

  void _toggleSelection(NearbyActivity activity) {
    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        _selectedActivities.add(activity);
      }
    });
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'history': return Icons.history;
      case 'shopping': return Icons.shopping_bag;
      case 'food': case 'restaurant': case 'cafe': return Icons.restaurant;
      case 'nature': return Icons.nature;
      case 'adventure': return Icons.hiking;
      case 'entertainment': return Icons.attractions;
      case 'culture': return Icons.museum;
      default: return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Activity', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isAdding ? null : _addSelectedActivities,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isAdding
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Add (${_selectedActivities.length})'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Activities',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_availableActivities.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load activities\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _fetchActivities, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_availableActivities.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 64, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text('All activities added!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('No more activities to add to this day'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableActivities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final activity = _availableActivities[index];
                  final isSelected = _selectedActivities.contains(activity);
                  return _buildActivityCard(activity, isSelected);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(NearbyActivity activity, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSelection(activity),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: (activity.imageUrl != null && activity.imageUrl!.isNotEmpty)
                  ? Image.network(activity.imageUrl!, width: double.infinity, height: 160, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(height: 160, color: Colors.grey.shade300, child: const Icon(Icons.image, size: 40)))
                  : Container(height: 160, color: AppColors.accent.withOpacity(0.3), child: const Icon(Icons.image, size: 40)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(_getIconForCategory(activity.category), size: 14, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(activity.category, style: TextStyle(fontSize: 13, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
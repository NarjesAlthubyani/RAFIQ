import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/nearby_activity.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  static const String _baseUrl = 'http://10.0.2.2:8000';

  List<NearbyActivity> _activities = [];
  bool _isLoading = false;
  String? _error;
  String _selectedDuration = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

// Get user current location if permission is granted
  Future<Position?> _tryGetUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  int? _uiDurationToMinutes(String ui) {
    switch (ui.trim()) {
      case '<1 hour':
        return 60;
      case '1-2 hours':
        return 120;
      case '2-3 hours':
        return 180;
      case 'More than 3 hours':
        return 9999;
      default:
        return null;
    }
  }

  Future<void> _fetchActivities({int? availableMinutes}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pos = await _tryGetUserLocation();
      final lat = pos?.latitude ?? 21.55;
      final lng = pos?.longitude ?? 39.17;

      final params = <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
        'limit': '50',
      };
      
      // Add time filter only when selected
      if (availableMinutes != null) {
        params['available_minutes'] = availableMinutes.toString();
      }

      final uri = Uri.parse('$_baseUrl/activities').replace(queryParameters: params);
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      final List data = jsonDecode(res.body);
      final fetched = data.map((item) => NearbyActivity.fromJson(item)).toList();

      setState(() {
        _activities = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
        _activities = [];
      });
    }
  }

  List<NearbyActivity> get _visibleActivities {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _activities;
    return _activities.where((a) {
      return a.title.toLowerCase().contains(q) ||
          a.category.toLowerCase().contains(q);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

// Open duration filter and reload activities based on selection
  void _showFilters() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => FiltersBottomSheet(
        initialSelection: _selectedDuration,
      ),
    );

    if (result == null) return;

    if (result == 'CLEAR') {
      setState(() => _selectedDuration = '');
      await _fetchActivities();
      return;
    }

    setState(() => _selectedDuration = result);
    final minutes = _uiDurationToMinutes(result);
    await _fetchActivities(availableMinutes: minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: TextField(
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Discover activities',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: AppColors.accent),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilters,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.tune, color: AppColors.white),
                        if (_selectedDuration.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activities',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (_selectedDuration.isNotEmpty)
                  Text(
                    'Filter: $_selectedDuration',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load activities\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final minutes = _uiDurationToMinutes(_selectedDuration);
                        _fetchActivities(availableMinutes: minutes);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _visibleActivities.isEmpty
                  ? const Center(
                      child: Text('No activities found matching your criteria.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _visibleActivities.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final activity = _visibleActivities[index];
                        return ActivityCard(
                          title: activity.title,
                          category: activity.category,
                          duration: activity.duration,
                          imageUrl: activity.imageUrl,
                          detailsUrl: activity.detailsUrl,
                          distanceKm: activity.distanceKm,
                          ticketBooking: activity.ticketBooking,
                          ticketLink: activity.ticketLink,
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
// Card used to display activity information
class ActivityCard extends StatelessWidget {
  final String title;
  final String category;
  final String? duration;
  final String? imageUrl;
  final String? detailsUrl;
  final double? distanceKm;
  final bool ticketBooking;
  final String? ticketLink;

  const ActivityCard({
    super.key,
    required this.title,
    required this.category,
    this.duration,
    this.imageUrl,
    this.detailsUrl,
    this.distanceKm,
    required this.ticketBooking,
    this.ticketLink,
  });

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'history':
        return Icons.history;
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
      case 'restaurant':
      case 'cafe':
      case 'Food':
        return Icons.restaurant;
      case 'nature':
        return Icons.nature;
      case 'adventure':
        return Icons.hiking;
      case 'entertainment':
        return Icons.attractions;
      case 'culture':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160,
                        color: AppColors.greyLight,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      height: 160,
                      color: AppColors.greyLight,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_getIconForCategory(category),
                              color: AppColors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: const TextStyle(
                                color: AppColors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      if (distanceKm != null) ...[
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${distanceKm!.toStringAsFixed(1)} km away',
                              style: const TextStyle(
                                  color: AppColors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (duration != null && duration!.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppColors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              duration!,
                              style: const TextStyle(
                                  color: AppColors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (detailsUrl != null && detailsUrl!.isNotEmpty)
                      ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(detailsUrl!);
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'View on map',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (ticketBooking && ticketLink != null && ticketLink!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () async {
                          final uri = Uri.parse(ticketLink!);
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.confirmation_num_outlined, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Book Ticket',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// Bottom sheet used to select activity duration filter
class FiltersBottomSheet extends StatefulWidget {
  final String initialSelection;
  const FiltersBottomSheet({super.key, required this.initialSelection});

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  late String _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Filters',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Suggested duration',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFilterChip('<1 hour'),
                _buildFilterChip('1-2 hours'),
                _buildFilterChip('2-3 hours'),
                _buildFilterChip('More than 3 hours'),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'CLEAR'),
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _tempSelection),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Show results',
                      style: TextStyle(fontSize: 16),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _tempSelection == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempSelection = isSelected ? '' : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greyLight : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
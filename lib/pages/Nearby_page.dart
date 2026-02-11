import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Data Model for Activity
class Activity {
  final String title;
  final String category;
  final String? duration;
  final String imageUrl;
  final String buttonText;
  final IconData? buttonIcon;

  Activity({
    required this.title,
    required this.category,
    this.duration,
    required this.imageUrl,
    required this.buttonText,
    this.buttonIcon,
  });
}

class NearbyPage extends StatefulWidget {
  const NearbyPage({super.key});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final List<Activity> _allActivities = [
    Activity(
      title: 'Mall of Arabia',
      category: 'Shopping Malls',
      imageUrl: 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?q=80&w=1000&auto=format&fit=crop',
      buttonText: 'View on map',
      buttonIcon: Icons.location_on,
      
    ),
    Activity(
      title: 'Jeddah Beauty show',
      category: 'Event',
      duration: 'Duration More3 than 3 hours',
      imageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=1000&auto=format&fit=crop',
      buttonText: 'View Details',
    ),
    
  ];

  // State for filtering
  List<Activity> _filteredActivities = [];
  String _searchQuery = '';
  String _selectedDuration = ''; // Empty means no filter

  @override
  void initState() {
    super.initState();
    _filteredActivities = _allActivities;
  }

  void _applyFilters() {
    setState(() {
      _filteredActivities = _allActivities.where((activity) {
        final matchesSearch = activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            activity.category.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesDuration = _selectedDuration.isEmpty || 
            (activity.duration != null && activity.duration == _selectedDuration);
            
        return matchesSearch && matchesDuration;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _showFilters() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltersBottomSheet(initialSelection: _selectedDuration),
    );

    if (result != null) {
      setState(() {
        _selectedDuration = result == 'CLEAR' ? '' : result;
        _applyFilters();
      });
    }
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
          // Search Bar and Filter Button
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
                        hintText: 'Discover activates',
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search,color: AppColors.accent),
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
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Activities List
          Expanded(
            child: _filteredActivities.isEmpty
                ? const Center(child: Text('No activities found matching your criteria.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredActivities.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final activity = _filteredActivities[index];
                      return ActivityCard(
                        title: activity.title,
                        category: activity.category,
                        duration: activity.duration,
                        imageUrl: activity.imageUrl,
                        buttonText: activity.buttonText,
                        buttonIcon: activity.buttonIcon,
                      );
                    },
                  ),
          ),
        ],
      ),
      
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String title;
  final String category;
  final String? duration;
  final String imageUrl;
  final String buttonText;
  final IconData? buttonIcon;

  const ActivityCard({
    super.key,
    required this.title,
    required this.category,
    this.duration,
    required this.imageUrl,
    required this.buttonText,
    this.buttonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
         color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image sitting inside the green box
          Padding(
            padding: const EdgeInsets.all(4.0), // Padding to show green edges around image
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10), 
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 160, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: AppColors.greyLight,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          // (the part of the green box that extends below the image)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title and Category
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
                          const Icon(Icons.shopping_bag_outlined, color: AppColors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: const TextStyle(color: AppColors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      if (duration != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: AppColors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              duration!,
                              style: const TextStyle(color: AppColors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Action Button
                ElevatedButton(
  onPressed: () {
    print('$buttonText pressed');
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (buttonIcon != null) ...[
        Icon(buttonIcon, size: 14),
        const SizedBox(width: 4),
      ],
      Text(
        buttonText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),             
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Suggested duration',
              style: TextStyle(fontSize:18,fontWeight: FontWeight.w600, color: AppColors.accent),
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
                    style: TextStyle(fontSize: 16,color: AppColors.accent
                     ,decoration: TextDecoration.underline),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Show results',
                    style: TextStyle(
                   fontSize: 16 ),
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

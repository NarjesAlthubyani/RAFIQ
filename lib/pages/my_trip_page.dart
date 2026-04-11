import 'package:flutter/material.dart';
import 'package:rafiq/theme/app_colors.dart';
import 'package:rafiq/pages/trip_loading_page.dart';
import 'package:rafiq/services/trip_service.dart';

class MyTripPage extends StatefulWidget {
  final String preferenceId;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;

  const MyTripPage({
    Key? key,
    required this.preferenceId,
    required this.destination,
    required this.fromDate,
    required this.toDate,
  }) : super(key: key);

  @override
  _MyTripPageState createState() => _MyTripPageState();
}

class _MyTripPageState extends State<MyTripPage> {
  late String _preferenceId;
  late String _destination;
  late DateTime _fromDate;
  late DateTime _toDate;

  List<Interest> _interests = [];

  String? _selectedBudgetRange = '2000 - 5000';
  final List<String> _budgetOptions = [
    '500 - 1000',
    '1000 - 2000',
    '2000 - 5000',
    '5000 - 10000',
    '10000+'
  ];

  @override
  void initState() {
    super.initState();
    _preferenceId = widget.preferenceId;
    _destination = widget.destination;
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
    
    _initializeInterests();
  }

  void _initializeInterests() {
    List<Interest> baseInterests = [
      Interest(name: 'Culture', isSelected: false),
      Interest(name: 'Food', isSelected: false),
      Interest(name: 'History', isSelected: false),
      Interest(name: 'Entertainment', isSelected: false),
      Interest(name: 'Adventure', isSelected: false),
      Interest(name: 'Nature', isSelected: false),
    ];

    if (_destination != 'AlUla') {
      baseInterests.insert(3, Interest(name: 'Shopping', isSelected: false));
    }

    setState(() {
      _interests = baseInterests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(context),
              const SizedBox(height: 28),
              _buildCard(context),
              const SizedBox(height: 28),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Text(
              'Step 2/2',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.greyLight),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Budget Range',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildBudgetDropdown(),
          const SizedBox(height: 22),
          Text(
            'Select your interests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Choose as many as you'd like.",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          _interests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Loading interests...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_interests.length, (index) {
                    final interest = _interests[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _interests[index] = interest.copyWith(
                            isSelected: !interest.isSelected,
                          );
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: interest.isSelected
                              ? AppColors.accent.withOpacity(0.08)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accent,
                            width: 1.6,
                          ),
                        ),
                        child: Text(
                          interest.name,
                          style: TextStyle(
                            fontSize: 16,
                            color: interest.isSelected
                                ? AppColors.secondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),     
        ],
      ),
    );
  }

  Widget _buildBudgetDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent),
        color: AppColors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.attach_money,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBudgetRange,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBudgetRange = newValue;
                  });
                },
                items: _budgetOptions.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      'SAR $value',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final selectedCount = _interests.where((i) => i.isSelected).length;

    return Center(
      child: SizedBox(
        width: 200,
        height: 52,
        child: ElevatedButton(
          onPressed: selectedCount > 0 ? _showReviewDialog : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedCount > 0
                ? AppColors.secondary
                : AppColors.greyLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'Submit',
            style: TextStyle(
              fontSize: 18,
              color: selectedCount > 0
                  ? AppColors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final selectedInterests = _interests
        .where((i) => i.isSelected)
        .map((i) => i.name)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(30),
        title: Text(
          'Review Your Trip',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destination: $_destination',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Budget: SAR $_selectedBudgetRange',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dates: ${_formatDate(_fromDate)} - ${_formatDate(_toDate)}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Selected Interests',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedInterests
                  .map(
                    (s) => Chip(
                      label: Text(
                        s,
                        style: const TextStyle(color: AppColors.white),
                      ),
                      backgroundColor: AppColors.accent,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await TripService.saveTripDetails(
                  preferenceId: _preferenceId,
                  budgetRange: _selectedBudgetRange!,
                  selectedInterests: selectedInterests,
                );

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripLoadingPage(
                      tripId: result['trip']['trip_id'],
                      destination: _destination,
                      fromDate: _fromDate,
                      toDate: _toDate,
                      budgetRange: _selectedBudgetRange!,
                      selectedInterests: selectedInterests,
                    ),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  _showErrorDialog(e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create Trip Plan',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

class Interest {
  final String name;
  final bool isSelected;

  Interest({required this.name, this.isSelected = false});

  Interest copyWith({String? name, bool? isSelected}) {
    return Interest(
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
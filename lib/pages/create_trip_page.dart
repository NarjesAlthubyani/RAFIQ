import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'trip_loading_page.dart'; 

class MyTripPage extends StatefulWidget {
  const MyTripPage({Key? key}) : super(key: key);

  @override
  _MyTripPageState createState() => _MyTripPageState();
}

class _MyTripPageState extends State<MyTripPage> {
  final List<Interest> _interests = [
    Interest(name: 'Culture', isSelected: false),
    Interest(name: 'Food', isSelected: false),
    Interest(name: 'History', isSelected: false),
    Interest(name: 'Shopping', isSelected: false),
    Interest(name: 'Entertainment', isSelected: false),
    Interest(name: 'Adventure', isSelected: false),
    Interest(name: 'Relaxation', isSelected: false),
    Interest(name: 'Nature', isSelected: false),
  ];

  String? _selectedBudgetRange = '2000 - 5000';
  final List<String> _budgetOptions = [
    '500 - 1000',
    '1000 - 2000',
    '2000 - 5000',
    '5000 - 10000',
    '10000+'
  ];

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
              widthFactor: 0.66,
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
            color: Colors.black.withOpacity(0.04),
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_interests.length, (index) {
              final interest = _interests[index];
              return GestureDetector(
                onTap: () => setState(() => _interests[index] = interest.copyWith(isSelected: !interest.isSelected)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: interest.isSelected ? AppColors.accent.withOpacity(0.08) : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 1.6),
                  ),
                  child: Text(
                    interest.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: interest.isSelected ? AppColors.secondary : AppColors.textPrimary,
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
            child: Icon(Icons.attach_money, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBudgetRange,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                onChanged: (String? newValue) => setState(() => _selectedBudgetRange = newValue),
                items: _budgetOptions.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      '\$ $value',
                      style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
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
            backgroundColor: selectedCount > 0 ? AppColors.secondary : AppColors.greyLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            'Submit',
            style: TextStyle(fontSize: 18, color: selectedCount > 0 ? AppColors.white : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final selectedInterests = _interests.where((i) => i.isSelected).map((i) => i.name).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(30), 
        title: Text('Review Your Trip', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget: \$ $_selectedBudgetRange', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text('Selected Interests', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedInterests.map((s) => Chip(label: Text(s, style: TextStyle(color: AppColors.white)), backgroundColor: AppColors.accent)).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Back', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              _navigateToLoadingPage(selectedInterests); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Create Trip Plan', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _navigateToLoadingPage(List<String> selectedInterests) {
    final fromDate = DateTime.now().add(const Duration(days: 30));
    final toDate = fromDate.add(const Duration(days: 5));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripLoadingPage(
          destination: 'Jeddah',
          fromDate: fromDate,
          toDate: toDate,
          budgetRange: _selectedBudgetRange!,
          selectedInterests: selectedInterests,
        ),
      ),
    );
  }
}

class Interest {
  final String name;
  final bool isSelected;

  Interest({required this.name, this.isSelected = false});

  Interest copyWith({String? name, bool? isSelected}) {
    return Interest(name: name ?? this.name, isSelected: isSelected ?? this.isSelected);
  }
}
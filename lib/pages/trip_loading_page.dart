import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'trip_results_page.dart';

class TripLoadingPage extends StatefulWidget {
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String budgetRange;
  final List<String> selectedInterests;

  const TripLoadingPage({
    Key? key,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.budgetRange,
    required this.selectedInterests,
  }) : super(key: key);

  @override
  _TripLoadingPageState createState() => _TripLoadingPageState();
}

class _TripLoadingPageState extends State<TripLoadingPage> {
  @override
  void initState() {
    super.initState();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToResults();
      }
    });
  }

  void _navigateToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TripResultsPage(
          destination: widget.destination,
          fromDate: widget.fromDate,
          toDate: widget.toDate,
          budgetRange: widget.budgetRange,
          selectedInterests: widget.selectedInterests,
        ),
      ),
    );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Text(
                'Create Your Trip Plan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Three images side by side
           

              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                width: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Generating your itinerary...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFrame(String imagePath, {bool isMiddle = false}) {
    return Expanded(
      child: Container(
        height: isMiddle ? 240 : 200,
        margin: EdgeInsets.only(top: isMiddle ? 0 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.primary.withOpacity(0.1),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMiddle ? 'Main' : 'Side',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
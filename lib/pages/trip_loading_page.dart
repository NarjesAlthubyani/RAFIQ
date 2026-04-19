import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/trip_loading_controller.dart';
import '../theme/app_colors.dart';
import 'trip_results_page.dart';

class TripLoadingPage extends StatelessWidget {
  final String tripId;
  final String destination;
  final DateTime fromDate;
  final DateTime toDate;
  final String budgetRange;
  final List<String> selectedInterests;

  const TripLoadingPage({
    Key? key,
    required this.tripId,
    required this.destination,
    required this.fromDate,
    required this.toDate,
    required this.budgetRange,
    required this.selectedInterests,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripLoadingController()
        ..initialize(
          id: tripId,
          dest: destination,
          from: fromDate,
          to: toDate,
          budget: budgetRange,
          interests: selectedInterests,
        ),
      child: const _TripLoadingView(),
    );
  }
}

class _TripLoadingView extends StatelessWidget {
  const _TripLoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripLoadingController>();

    if (controller.navigateToResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripResultsPage(
              tripId: controller.tripId,
              destination: controller.destination,
              fromDate: controller.fromDate,
              toDate: controller.toDate,
              budgetRange: controller.budgetRange,
              selectedInterests: controller.selectedInterests,
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.accent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      body: controller.errorMessage != null
          ? _buildErrorState(context, controller)
          : _buildLoadingState(context, controller),
    );
  }

  Widget _buildErrorState(
      BuildContext context, TripLoadingController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: ${controller.errorMessage}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.retry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(
      BuildContext context, TripLoadingController controller) {
    return Column(
      children: [
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Create Your Trip Plan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            controller.destination,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            controller.loadingMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: Stack(
            children: [
              _buildSideImage(controller.destination, left: -124, top: 50),
              _buildCenterImage(controller.destination),
              _buildSideImage(controller.destination, right: -124, top: 50),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: _buildLoadingIndicator(controller),
        ),
      ],
    );
  }

  Widget _buildSideImage(String destination,
      {double? left, double? right, required double top}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: ClipRect(
        child: Container(
          width: 220,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/${destination.toLowerCase()}.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.accent.withOpacity(0.3),
                child: const Icon(Icons.image, color: AppColors.white, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterImage(String destination) {
    return Positioned(
      left: -20,
      right: -20,
      top: 20,
      child: Center(
        child: Container(
          width: 200,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.15),
                blurRadius: 35,
                spreadRadius: 3,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/${destination.toLowerCase()}.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withOpacity(0.3),
                child: const Icon(Icons.location_city,
                    color: AppColors.white, size: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(TripLoadingController controller) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading${'.' * controller.dotCount}',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

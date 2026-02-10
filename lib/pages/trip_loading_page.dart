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

class _TripLoadingPageState extends State<TripLoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _animateDots();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToResults();
      }
    });
  }

  void _animateDots() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _animateDots();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
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

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'This may take a few seconds',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: -124,
                  top: 50, 
                  child: ClipRect(
                    child: Container(
                      width: 220,
                      height: 320,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.background,
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/Albalad.jpg',
                          fit: BoxFit.cover,
                          width: 200,
                          height: 280,
                        ),
                      ),
                    ),
                  ),
                ),
                
                Positioned(
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
                            color: AppColors.background,
                            blurRadius: 35,
                            spreadRadius: 3,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/Albalad.jpg',
                          fit: BoxFit.cover,
                          width: 220,
                          height: 320,
                        ),
                      ),
                    ),
                  ),
                ),
                
                
                Positioned(
                  right: -124, 
                  top: 50,
                  child: ClipRect(
                    child: Container(
                      width: 220,
                      height: 320,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.background,
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/Albalad.jpg',
                          fit: BoxFit.cover,
                          width: 200,
                          height: 300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Container at BOTTOM
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: ScaleTransition(
              scale: _animation,
              child: Container(
                width: 150,
                height: 150,
                
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading Spinner
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
                 ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
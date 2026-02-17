import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'trip_results_page.dart';
import 'package:rafiq/services/trip_service.dart';
import 'package:rafiq/services/edge_function_service.dart'; // ✅ هذا صحيح

class TripLoadingPage extends StatefulWidget {
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
  _TripLoadingPageState createState() => _TripLoadingPageState();
}

class _TripLoadingPageState extends State<TripLoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _dotCount = 0;
  
  final List<String> _loadingMessages = [
    "Analyzing your preferences...",
    "Discovering hidden gems in {destination}...",
    "Finding the best restaurants...",
    "Adding local experiences...",
    "Almost there...",
  ];
  
  int _currentMessageIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

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
    _startMessageRotation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateTripWithAI();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  void _startMessageRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
      return !_isDisposed && mounted;
    });
  }

  Future<void> _generateTripWithAI() async {
    if (!_isDisposed && mounted) {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      return;
    }
    
    try {
      print('🤖 Starting AI generation for ${widget.destination}...');
      
      // ✅ تغيير هذا السطر - استخدم EdgeFunctionService بدلاً من GeminiService
      final aiResponse = await EdgeFunctionService.generateTrip(
        destination: widget.destination,
        fromDate: widget.fromDate,
        toDate: widget.toDate,
        budgetRange: widget.budgetRange,
        interests: widget.selectedInterests,
      );
      
      print('✅ AI response received successfully');
      print('📦 AI Response structure: ${aiResponse.keys}');
      
      if (!_isDisposed && mounted) {
        dynamic totalCostValue = aiResponse['total_cost'] ?? 0;
        double totalCost = 0.0;
        
        if (totalCostValue is int) {
          totalCost = totalCostValue.toDouble();
        } else if (totalCostValue is double) {
          totalCost = totalCostValue;
        } else if (totalCostValue is String) {
          totalCost = double.tryParse(totalCostValue) ?? 0.0;
        }
        
        await TripService.saveAIGeneratedTrip(
          tripId: widget.tripId,
          aiResponse: aiResponse,
          totalCost: totalCost,
          summary: aiResponse['summary'] ?? 'Trip to ${widget.destination}',
        );
        
        print('✅ Trip saved to database');
        
        _safeSetState(() {
          _isLoading = false;
        });
        
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (!_isDisposed && mounted) {
          _navigateToResults();
        }
      }
      
    } catch (e) {
      print('❌ Error: $e');
      
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    if (!_isDisposed && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Failed to generate your trip.'),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!_isDisposed && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!_isDisposed && mounted) {
                  _generateTripWithAI();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  void _animateDots() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _animateDots();
      }
    });
  }

  void _navigateToResults() {
    if (!_isDisposed && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TripResultsPage(
            tripId: widget.tripId,
            destination: widget.destination,
            fromDate: widget.fromDate,
            toDate: widget.toDate,
            budgetRange: widget.budgetRange,
            selectedInterests: widget.selectedInterests,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String loadingMessage = _loadingMessages[_currentMessageIndex]
        .replaceAll('{destination}', widget.destination);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () {
            if (!_isDisposed && mounted) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.accent),
            onPressed: () {
              if (!_isDisposed && mounted) {
                Navigator.pop(context);
              }
            },
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

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.destination,
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
                    loadingMessage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

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
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/${widget.destination.toLowerCase()}.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.accent.withOpacity(0.3),
                              child: const Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 50,
                              ),
                            );
                          },
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
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 35,
                            spreadRadius: 3,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/${widget.destination.toLowerCase()}.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primary.withOpacity(0.3),
                              child: const Icon(
                                Icons.location_city,
                                color: Colors.white,
                                size: 80,
                              ),
                            );
                          },
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
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/${widget.destination.toLowerCase()}.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.secondary.withOpacity(0.3),
                              child: const Icon(
                                Icons.landscape,
                                color: Colors.white,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                      'Loading${'.' * _dotCount}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
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
}
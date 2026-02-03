import 'package:flutter/material.dart';
import '../widgets/nav_bar.dart';
import '../theme/app_colors.dart';

class MyTripPage extends StatefulWidget {
  const MyTripPage({super.key});

  @override
  State<MyTripPage> createState() => _MyTripPageState();
}

class _MyTripPageState extends State<MyTripPage> {
  int _currentIndex = 3; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Center(
        child: Text(
          'My Trip Page',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),

      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          _navigate(index, context);
        },
      ),
    );
  }

  void _navigate(int index, BuildContext context) {
  switch (index) {
    case 0:
      Navigator.pushReplacementNamed(context, '/home');
      break;
    case 1:
      Navigator.pushReplacementNamed(context, '/nearby');
      break;
    case 2:
      Navigator.pushReplacementNamed(context, '/scan');
      break;
    case 3:
      break; // already on My Trip
    case 4:
      Navigator.pushReplacementNamed(context, '/profile');
      break;
  }
 }
}

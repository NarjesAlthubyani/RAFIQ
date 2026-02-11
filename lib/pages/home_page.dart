import 'package:flutter/material.dart';
import '../widgets/nav_bar.dart';
import '../theme/app_colors.dart';
import 'nearby_page.dart';
import 'profile_page.dart';
import 'destination_date_page.dart';
import 'my_trips_page.dart';
import 'scan_page.dart';
import 'smart_alerts_page.dart';


class HomePage extends StatefulWidget {
  final int initialIndex;
  
  const HomePage({
    super.key,
    this.initialIndex = 0, 
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. Initialize without a value here
  late int _currentIndex;

  final List<Widget> _pages = [
    const HomeContent(),
    const NearbyPage(),
    const ScanPage(),
    const MyTripsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 2. Set the current index to the one passed in (e.g., 3 for My Trips)
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.textSecondary, width: 1.5),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: AppColors.background,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Sara",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SmartAlertsPage(),
                              ),
                            );
                          },
                          child: const CircleAvatar(
                            backgroundColor: AppColors.background,
                            child: Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.accent,
                              size: 32,
                            ),
                          ),
                        ),

              ],
            ),
            const SizedBox(height: 24),

            // SEARCH BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search your destination...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // RECOMMENDED
            const Text(
              "Today's activities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/Albalad.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(0.2),
                ),
                padding: const EdgeInsets.all(15),
                alignment: Alignment.bottomLeft,
                child: const Text(
                  "Jeddah",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Recommended activities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/Albalad.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(0.2),
                ),
                padding: const EdgeInsets.all(15),
                alignment: Alignment.bottomLeft,
                child: const Text(
                  "Jeddah",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/nav_bar.dart';
import '../theme/app_colors.dart';
import 'nearby_page.dart';
import 'profile_page.dart';
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
  late int _currentIndex;
  String _userName = "User"; // Default name
  bool _isLoading = true;

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
    _currentIndex = widget.initialIndex;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user != null) {
        // Get name from user metadata
        final userName = user.userMetadata?['full_name'] ?? 
                        user.userMetadata?['name'] ?? 
                        user.email?.split('@').first ??
                        'User';
        
        setState(() {
          _userName = userName;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
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
    // Get the username from the parent widget
    final homePageState = context.findAncestorStateOfType<_HomePageState>();
    final userName = homePageState?._userName ?? "User";

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER with dynamic user name
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
                    Text(
                      userName, // Dynamic user name!
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold
                      ),
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

            // TODAY'S ACTIVITIES
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

            // RECOMMENDED ACTIVITIES
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
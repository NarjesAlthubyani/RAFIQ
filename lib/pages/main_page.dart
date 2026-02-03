import 'package:flutter/material.dart';
import '../widgets/nav_bar.dart'; 
import '../theme/app_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     border: Border.all(color: AppColors.textSecondary, width: 1.5), 
                   ),
                   child: CircleAvatar(
                   backgroundColor: AppColors.background,
                   child: const Icon(size: 32,
                     Icons.person,
                     color: AppColors.textSecondary,
                   ),
                  ),
                 ),
                 const SizedBox(width: 10), 
                 const Text(
                  "Sara",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                 ),
                ],
          ),
    
           CircleAvatar(
            backgroundColor: AppColors.background,
            child: const Icon(size: 32,
             Icons.notifications_active_outlined,
             color: AppColors.accent,
            ),
           ),
          ],
        ),
         const SizedBox(height: 24),

              // --- SEARCH BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
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

              // --- RECOMMENDED SECTION ---
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
                    color: const Color.fromRGBO(0, 0, 0, 1).withOpacity(0.2),
                  ),
                  padding: const EdgeInsets.all(15),
                  alignment: Alignment.bottomLeft,
                  child: const Text(
                    "Jeddah",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
               const SizedBox(height:16),

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
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 3. The Bottom Nav Bar
      bottomNavigationBar: CustomNavBar(
       currentIndex: _currentIndex,
       onTap: (index) {
       if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
          _navigate(index);
       },
      ),
    );
  }
  void _navigate(int index) {
  switch (index) {
    case 0:
      break; // already Home
    case 1:
      Navigator.pushReplacementNamed(context, '/nearby');
      break;
    case 2:
      Navigator.pushReplacementNamed(context, '/scan');
      break;
    case 3:
      Navigator.pushReplacementNamed(context, '/mytrip');
      break;
    case 4:
      Navigator.pushReplacementNamed(context, '/profile');
      break;
  }
}
}
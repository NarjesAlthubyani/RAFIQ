import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import '../services/weather_service.dart';
import '../adapters/weather_adapter.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

// SmartAlertsPage is responsible for displaying real-time smart alerts
// to the user based on weather conditions and stored alert data. 

class SmartAlertsPage extends StatefulWidget {
  const SmartAlertsPage({super.key});

  @override
  State<SmartAlertsPage> createState() => _SmartAlertsPageState();
}
class _SmartAlertsPageState extends State<SmartAlertsPage> {
  // List of alerts retrieved from the database
  List<AlertModel> alerts = [];

  @override
  void initState() {
    super.initState();
    loadAlerts();
    checkWeather();
  }

    // Fetches all alerts for the current user from Supabase
    Future<void> loadAlerts() async {
    final user = AuthService.currentUser;

    if (user == null) return;

    final response = await supabase
        .from('alerts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    // Convert raw JSON data into AlertModel objects
    setState(() {
      alerts = (response as List)
          .map((json) => AlertModel.fromJson(json))
          .toList();
    });
  }

  // Retrieves the user's selected city from the database.
  Future<String> getUserCity() async {
  final user = AuthService.currentUser;

  if (user == null) return "Jeddah";

  final response = await supabase
      .from('users')
      .select('location')
      .eq('user_id', user.id)
      .maybeSingle();

  return response?['location'] ?? "Jeddah";
}

// Checks current weather conditions for the user's city
// and generates a weather alert if conditions are severe.
Future<void> checkWeather() async {
  final weatherService = WeatherService();

  final currentCity = await getUserCity(); // update link city according user's city from DB
  // Fetch weather condition from external service "OpenWeather APIs"
  final condition = await weatherService.getWeatherCondition(currentCity);
  // Convert weather condition into an alert object if needed
  final alert = WeatherAdapter.convertToAlert(condition, currentCity);

  // Store alert in database and refresh UI if alert is generated
  if (alert != null) {
    await supabase.from('alerts').insert(alert.toJson());
    await loadAlerts();
  }
}

  


  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      backgroundColor: AppColors.greyLight,
      // Page header
      appBar: AppBar(
            backgroundColor: AppColors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
      
      // Main content area displaying alerts list
     body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                "Smart Alerts",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                "Stay informed about your trip",
                style: TextStyle(fontSize: 16, color:AppColors.greyLight,),
              ),
              const SizedBox(height: 30),

              if (alerts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Text("No alerts available"),
                  ),
                )
              else
              // Builds and displays a list of alert cards from the alerts data
                ...alerts.map((alert) => AlertCard(alert: alert)).toList(),
            ],
          ),
        ),

    );
  }
}

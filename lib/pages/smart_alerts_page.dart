import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import '../services/weather_service.dart';
import '../adapters/weather_adapter.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';

class SmartAlertsPage extends StatefulWidget {
  const SmartAlertsPage({super.key});

  @override
  State<SmartAlertsPage> createState() => _SmartAlertsPageState();
}
class _SmartAlertsPageState extends State<SmartAlertsPage> {
  List<AlertModel> alerts = [];

  @override
  void initState() {
    super.initState();
    loadAlerts();
    checkWeather();
  }

    Future<void> loadAlerts() async {
    final user = AuthService.currentUser;

    if (user == null) return;

    final response = await supabase
        .from('alerts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      alerts = (response as List)
          .map((json) => AlertModel.fromJson(json))
          .toList();
    });
  }

    Future<void> checkWeather() async {
    final weatherService = WeatherService();

    String currentCity = "Jeddah"; // our scope

    final condition = await weatherService.getWeatherCondition(currentCity);

    final alert = WeatherAdapter.convertToAlert(condition, currentCity);

    if (alert != null) {
      await supabase.from('alerts').insert(alert.toJson());
      await loadAlerts(); 
    }
  }

  


  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

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
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                ...alerts.map((alert) => AlertCard(alert: alert)).toList(),
            ],
          ),
        ),

    );
  }
}

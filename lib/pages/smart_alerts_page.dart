import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import '../data/alert_repository.dart';


class SmartAlertsPage extends StatelessWidget {
   SmartAlertsPage({super.key});

  


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
          child: FutureBuilder<List<AlertModel>>(
            future: AlertRepository.getUserAlerts(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Error loading alerts"));
              }

              final alerts = snapshot.data ?? [];

              return ListView(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Smart Alerts",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Stay informed about your trip",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (alerts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Text(
                          "No alerts available",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...alerts.map((alert) => AlertCard(alert: alert)).toList(),
                ],
              );
            },
          ),
        ),

    );
  }
}

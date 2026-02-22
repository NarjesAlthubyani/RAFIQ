import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AlertRepository {
  static List<AlertModel> getAlerts() {
    return [
      AlertModel(
        title: "Heavy Rain Expected",
        description:
            "Moderate to heavy rainfall is forecasted for this afternoon.",
        time: "Today, 2:00 PM - 6:00 PM",
        icon: Icons.cloud,
      ),
      AlertModel(
        title: "Traffic Jam on King Road",
        description:
            "Heavy traffic reported on King Road heading north. Expect delays of 20-30 minutes.",
        time: "Today, 2:00 PM - 6:00 PM",
        icon: Icons.traffic,
      ),
      AlertModel(
        title: "Jeddah Beauty Show Cancelled",
        description:
            "The show has been cancelled and postponed until tomorrow.",
        time: "Today, 2:00 PM - 6:00 PM",
        icon: Icons.event_busy,
      ),
    ];
  }
}

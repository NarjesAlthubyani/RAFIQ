import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;

  const AlertCard({super.key, required this.alert});

  IconData getIcon(String type) {
      switch (type) {
        case 'weather':
          return Icons.cloud;
        case 'traffic':
          return Icons.traffic;
        case 'event':
          return Icons.event;
        default:
          return Icons.notifications;
      }
    }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            getIcon(alert.type),
            color: AppColors.accent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(alert.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
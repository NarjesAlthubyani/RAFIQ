import 'package:flutter/material.dart';

class AlertModel {
  final String title;
  final String description;
  final String time;
  final IconData icon;

  AlertModel({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
  });
}
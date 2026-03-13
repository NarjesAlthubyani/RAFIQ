import 'package:flutter/material.dart';

class AlertModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'type': type,
      'is_read': isRead,
    };
  }
}
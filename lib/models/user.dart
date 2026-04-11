class AppUser {
  final String userId;
  final String name;
  final String email;
  final String password;
  final bool alertsEnabled;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    this.alertsEnabled = false,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'email': email,
    'password': password,
    'alerts_enabled': alertsEnabled,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    userId: json['user_id'],
    name: json['name'],
    email: json['email'],
    password: json['password'],
    alertsEnabled: json['alerts_enabled'] ?? false,
  );
}
class User {
  final int id;
  final String email;
  final String? name;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    email: json['email'] as String,
    name: json['name'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'created_at': createdAt.toIso8601String(),
  };
}

class UserProfile {
  final int id;
  final int userId;
  final int? age;
  final String? occupation;
  final double sleepTargetHours;
  final bool hasPartTimeJob;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.age,
    this.occupation,
    required this.sleepTargetHours,
    required this.hasPartTimeJob,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    age: json['age'] as int?,
    occupation: json['occupation'] as String?,
    sleepTargetHours: double.parse(json['sleep_target_hours'].toString()),
    hasPartTimeJob: json['has_part_time_job'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  final String? school;
  final String? grade;
  final String? avatarColor;

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.school,
    this.grade,
    this.avatarColor,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'student',
      school: json['school']?.toString(),
      grade: json['grade']?.toString(),
      avatarColor: json['avatar_color'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        'school': school,
        'grade': grade,
        'avatar_color': avatarColor,
      };
}

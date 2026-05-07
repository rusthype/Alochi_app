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
    String firstName = json['first_name'] ?? '';
    String lastName = json['last_name'] ?? '';

    if (firstName.isEmpty && lastName.isEmpty && json['name'] != null) {
      final nameParts = (json['name'] as String).split(' ');
      firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      firstName: firstName,
      lastName: lastName,
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

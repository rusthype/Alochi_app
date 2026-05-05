class TeacherProfileModel {
  final String id;
  final String name;
  final String username;
  final String phone;

  const TeacherProfileModel({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
  });

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) {
    return TeacherProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

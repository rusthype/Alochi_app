class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String? school;
  final int xp;
  final String? avatarColor;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.school,
    required this.xp,
    this.avatarColor,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json,
      {bool isCurrentUser = false}) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? '',
      school: json['school'],
      xp: json['xp'] ?? json['total_xp'] ?? 0,
      avatarColor: json['avatar_color'],
      isCurrentUser: isCurrentUser,
    );
  }
}

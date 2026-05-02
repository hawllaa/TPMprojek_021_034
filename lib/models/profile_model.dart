class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final int totalCollected;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.totalCollected = 0,
  });

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    int? totalCollected,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalCollected: totalCollected ?? this.totalCollected,
    );
  }
}

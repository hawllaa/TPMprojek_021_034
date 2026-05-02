class AuthModel {
  final String? userId;
  final bool isLoggedIn;

  AuthModel({
    this.userId,
    this.isLoggedIn = false,
  });

  AuthModel copyWith({
    String? userId,
    bool? isLoggedIn,
  }) {
    return AuthModel(
      userId: userId ?? this.userId,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

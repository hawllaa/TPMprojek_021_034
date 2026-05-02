class ChatMessageModel {
  final String id;
  final String userId;
  final String message;
  final bool isUser;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.isUser,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      message: map['message'] ?? '',
      isUser: map['is_user'] as bool,
      createdAt: map['created_at'].toString(),
    );
  }
}

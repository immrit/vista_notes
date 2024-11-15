import 'dart:convert';

// تعریف مدل کامنت
class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String username;
  final String avatarUrl;
  bool isVerified; // فیلد isVerified

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.username,
    this.avatarUrl = '', // مقدار پیش‌فرض برای avatarUrl
    this.isVerified = false, // مقدار پیش‌فرض برای isVerified
  });

  // متد سازنده از Map
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      // بررسی وجود کلید users
      username: map['profiles']?['username'] as String ?? 'کاربر',
      avatarUrl: map['profiles']?['avatar_url'] as String ?? '',

      isVerified: map['profiles'] != null
          ? (map['profiles']['is_verified'] ?? false)
          : false,
    );
  }

  // متد تبدیل به Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'profiles': {
        'username': username,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
      },
    };
  }

  // متد تبدیل به JSON
  String toJson() => json.encode(toMap());

  // متد سازنده از JSON
  factory CommentModel.fromJson(String source) =>
      CommentModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'CommentModel(id: $id, postId: $postId, userId: $userId, content: $content, createdAt: $createdAt, username: $username, avatarUrl: $avatarUrl, isVerified: $isVerified)';
}

import 'dart:convert';

class PublicPost {
  final String id; // شناسه پست
  final String userId; // شناسه کاربر
  final String content; // محتوای پست
  final DateTime createdAt; // تاریخ ایجاد پست
  final String username; // نام کاربری
  final String avatarUrl; // URL عکس پروفایل

  PublicPost({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.username,
    required this.avatarUrl,
  });

  factory PublicPost.fromMap(Map<String, dynamic> map) {
    return PublicPost(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      username: map['profiles']['username'] as String, // گرفتن نام کاربری
      avatarUrl:
          map['profiles']['avatar_url'] as String, // گرفتن URL عکس پروفایل
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'profiles': {
        'username': username,
        'avatar_url': avatarUrl,
      },
    };
  }

  String toJson() => json.encode(toMap());

  factory PublicPost.fromJson(String source) =>
      PublicPost.fromMap(json.decode(source));

  @override
  String toString() =>
      'PublicPost(id: $id, userId: $userId, content: $content, createdAt: $createdAt, username: $username, avatarUrl: $avatarUrl)';
}

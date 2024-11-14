import 'dart:convert';

import 'package:vistaNote/util/const.dart';

// تعریف مدل پست عمومی
class PublicPostModel {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String username;
  final String avatarUrl;
  int likeCount; // تعداد لایک‌ها
  bool isLiked; // آیا کاربر فعلی لایک کرده است؟
  bool isVerified; // اضافه کردن فیلد isVerified

  PublicPostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.username,
    this.avatarUrl = '', // مقدار پیش‌فرض برای avatarUrl
    this.likeCount = 0,
    this.isLiked = false,
    this.isVerified = false, // مقدار پیش‌فرض برای isVerified
  });

  // متد سازنده از Map
  factory PublicPostModel.fromMap(Map<String, dynamic> map) {
    return PublicPostModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      username: map['profiles']['username'] as String,
      avatarUrl:
          map['profiles']['avatar_url'] as String? ?? '', // بررسی مقدار null
      likeCount: map['like_count'] as int? ?? 0,
      isLiked: map['is_liked'] as bool? ?? false,
      isVerified:
          map['profiles']['is_verified'] ?? false, // اضافه کردن isVerified
    );
  }

  // متد تبدیل به Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'profiles': {
        'username': username,
        'avatar_url': avatarUrl,
        'is_verified': isVerified, // اضافه کردن isVerified به Map
      },
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }

  // متد تبدیل به JSON
  String toJson() => json.encode(toMap());

  // متد سازنده از JSON
  factory PublicPostModel.fromJson(String source) =>
      PublicPostModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'PublicPost(id: $id, userId: $userId, content: $content, createdAt: $createdAt, username: $username, avatarUrl: $avatarUrl, likeCount: $likeCount, isLiked: $isLiked, isVerified: $isVerified)';
}

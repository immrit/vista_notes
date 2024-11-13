import 'dart:convert';

import 'package:vistaNote/util/const.dart';

class PublicPostModel {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String username;
  final String avatarUrl;
  int likeCount; // تعداد لایک‌ها
  bool isLiked; // آیا کاربر فعلی لایک کرده است؟

  PublicPostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.username,
    this.avatarUrl = '', // مقدار پیش‌فرض برای avatarUrl
    this.likeCount = 0,
    this.isLiked = false,
  });

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
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }

  String toJson() => json.encode(toMap());

  factory PublicPostModel.fromJson(String source) =>
      PublicPostModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'PublicPost(id: $id, userId: $userId, content: $content, createdAt: $createdAt, username: $username, avatarUrl: $avatarUrl, likeCount: $likeCount, isLiked: $isLiked)';
}

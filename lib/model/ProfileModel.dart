import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'publicPostModel.dart';

enum VerificationType { none, blueTick, official }

@immutable
class ProfileModel extends Equatable {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? email;
  final String? bio; // فیلد bio برای توضیحات پروفایل
  final int followersCount; // تعداد دنبال‌کنندگان
  final DateTime? createdAt;
  final bool isVerified;
  final VerificationType verificationType;
  final bool isFollowed;
  final List<PublicPostModel> posts;

  const ProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.email,
    this.bio,
    this.followersCount = 0, // مقدار پیش‌فرض
    this.createdAt,
    this.isVerified = false,
    this.verificationType = VerificationType.none,
    this.isFollowed = false,
    this.posts = const [],
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: (map['user_id'] ?? map['id'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      avatarUrl: map['avatar_url']?.toString(),
      email: map['email']?.toString(),
      bio: map['bio']?.toString(), // مقداردهی فیلد bio
      followersCount: map['followers_count'] ?? 0, // مقداردهی دنبال‌کنندگان
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      isVerified: map['is_verified'] ?? false,
      verificationType: map['verification_type'] != null
          ? VerificationType.values.firstWhere(
              (type) => type.name == map['verification_type'],
              orElse: () => VerificationType.none,
            )
          : VerificationType.none,
      isFollowed: map['is_followed'] ?? false,
      posts: (map['posts'] as List<dynamic>?)
              ?.map((post) => PublicPostModel.fromMap(post))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'email': email,
        'bio': bio, // تبدیل به Map
        'followers_count': followersCount, // تبدیل به Map
        'created_at': createdAt?.toIso8601String(),
        'is_verified': isVerified,
        'verification_type': verificationType.name,
        'is_followed': isFollowed,
        'posts': posts.map((post) => post.toMap()).toList(),
      };

  String toJson() => json.encode(toMap());

  ProfileModel copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? email,
    String? bio,
    int? followersCount,
    DateTime? createdAt,
    bool? isVerified,
    VerificationType? verificationType,
    bool? isFollowed,
    List<PublicPostModel>? posts,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      verificationType: verificationType ?? this.verificationType,
      isFollowed: isFollowed ?? this.isFollowed,
      posts: posts ?? this.posts,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        avatarUrl,
        email,
        bio, // اضافه شدن bio به props
        followersCount, // اضافه شدن followersCount به props
        isVerified,
        verificationType,
        isFollowed,
        posts,
      ];
}

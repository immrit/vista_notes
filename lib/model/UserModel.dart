import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileModel extends Equatable {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? email;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.email,
    this.createdAt,
  });

  // سازنده از JSON
  factory ProfileModel.fromJson(String source) =>
      ProfileModel.fromMap(json.decode(source));

  // سازنده از Map با هندلینگ پیشرفته
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: (map['user_id'] ?? map['id'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      avatarUrl: map['avatar_url']?.toString(),
      email: map['email']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  // تبدیل به Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'email': email,
        'created_at': createdAt?.toIso8601String(),
      };

  // تبدیل به JSON
  String toJson() => json.encode(toMap());

  // متد copyWith برای تغییرات ایمن
  ProfileModel copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? email,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // متد toString برای لاگ و دیباگ
  @override
  String toString() => '''
    Profile(
      id: $id, 
      username: $username, 
      email: $email
    )''';

  // Equatable برای مقایسه‌های دقیق
  @override
  List<Object?> get props => [id, username, avatarUrl, email];

  // متدهای اضافی برای بررسی وضعیت
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
}

// Provider مدیریت پروفایل
class ProfileNotifier extends StateNotifier<ProfileModel?> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(null);

  Future<void> fetchProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        state = ProfileModel.fromMap(
            {'id': user.id, 'email': user.email, ...userData});
      }
    } catch (e) {
      state = null;
      print('خطا در دریافت پروفایل: $e');
    }
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update(updatedProfile.toMap())
          .eq('id', updatedProfile.id);

      state = updatedProfile;
    } catch (e) {
      print('خطا در بروزرسانی پروفایل: $e');
    }
  }

  void clearProfile() {
    state = null;
  }
}

// Provider نهایی
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileModel?>((ref) {
  return ProfileNotifier(ref);
});

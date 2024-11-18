import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// Enum برای نوع تایید
enum VerificationType { none, blueTick, official }

@immutable
class UserModel extends Equatable {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? email;
  final DateTime? createdAt;
  final bool isVerified;
  final VerificationType verificationType; // اضافه کردن verificationType

  const UserModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.email,
    this.createdAt,
    this.isVerified = false,
    this.verificationType = VerificationType.none, // مقدار پیش‌فرض none
  });

  // سازنده از JSON
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // سازنده از Map با هندلینگ پیشرفته
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['user_id'] ?? map['id'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      avatarUrl: map['avatar_url']?.toString(),
      email: map['email']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      isVerified: map['is_verified'] ?? false,
      verificationType: map['verification_type'] != null
          ? VerificationType.values.firstWhere(
              (type) => type.name == map['verification_type'],
              orElse: () => VerificationType.none,
            )
          : VerificationType.none, // پارسینگ verification_type
    );
  }

  // تبدیل به Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'email': email,
        'created_at': createdAt?.toIso8601String(),
        'is_verified': isVerified,
        'verification_type':
            verificationType.name, // اضافه کردن verification_type
      };

  // تبدیل به JSON
  String toJson() => json.encode(toMap());

  // متد copyWith برای تغییرات ایمن
  UserModel copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? email,
    DateTime? createdAt,
    bool? isVerified,
    VerificationType? verificationType, // اضافه کردن verificationType
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      verificationType: verificationType ??
          this.verificationType, // پیاده‌سازی verificationType
    );
  }

  // متد toString برای لاگ و دیباگ
  @override
  String toString() => '''
    Profile(
      id: $id, 
      username: $username, 
      email: $email,
      isVerified: $isVerified,
      verificationType: $verificationType
    )''';

  // Equatable برای مقایسه‌های دقیق
  @override
  List<Object?> get props =>
      [id, username, avatarUrl, email, isVerified, verificationType];

  // متدهای اضافی برای بررسی وضعیت
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
}
  




// Provider مدیریت پروفایل
// class ProfileNotifier extends StateNotifier<ProfileModel?> {
//   final Ref ref;

//   ProfileNotifier(this.ref) : super(null);

//   Future<void> fetchProfile() async {
//     try {
//       final user = Supabase.instance.client.auth.currentUser;
//       if (user != null) {
//         final userData = await Supabase.instance.client
//             .from('profiles')
//             .select()
//             .eq('id', user.id)
//             .single();

//         state = ProfileModel.fromMap(
//             {'id': user.id, 'email': user.email, ...userData});
//       }
//     } catch (e) {
//       state = null;
//       print('خطا در دریافت پروفایل: $e');
//     }
//   }

//   Future<void> updateProfile(ProfileModel updatedProfile) async {
//     try {
//       await Supabase.instance.client
//           .from('profiles')
//           .update(updatedProfile.toMap())
//           .eq('id', updatedProfile.id);

//       state = updatedProfile;
//     } catch (e) {
//       print('خطا در بروزرسانی پروفایل: $e');
//     }
//   }

//   void clearProfile() {
//     state = null;
//   }
// }

// // Provider نهایی
// final profileProvider =
//     StateNotifierProvider<ProfileNotifier, ProfileModel?>((ref) {
//   return ProfileNotifier(ref);
// });

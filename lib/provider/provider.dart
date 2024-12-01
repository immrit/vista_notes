import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/model/ProfileModel.dart';
import 'package:vistaNote/model/notificationModel.dart';
import 'package:vistaNote/model/publicPostModel.dart';
import '../main.dart';
import '../model/CommentModel.dart';
import '../model/NotesModel.dart';
import '../model/UserModel.dart';
import '../util/themes.dart';

//check user state
final authStateProvider = StreamProvider<User?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

final authProvider = Provider<User?>((ref) {
  final auth = Supabase.instance.client.auth;
  return auth.currentUser;
});

//fetch user profile
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authStateProvider).when(
        data: (user) => user,
        loading: () => null,
        error: (err, stack) => null,
      );

  if (user == null) {
    throw Exception('User is not logged in');
  }

  final response =
      await supabase.from('profiles').select().eq('id', user.id).maybeSingle();

  if (response == null) {
    throw Exception('Profile not found');
  }

  return response;
});

//Edite Profile

final profileUpdateProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, updatedData) async {
  final user = ref.watch(authStateProvider).when(
        data: (user) => user,
        loading: () => null,
        error: (err, stack) => null,
      );
  if (user == null) {
    throw Exception('User is not logged in');
  }

  final response =
      await supabase.from('profiles').update(updatedData).eq('id', user.id);

  if (response != null) {
    throw Exception('Failed to update profile');
  }
});

//fetch notes
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final userId = supabase.auth.currentSession!.user.id;
  final response = await supabase.from('Notes').select().eq('user_id', userId);

  final data = response as List<dynamic>;
  return data.map((e) => Note.fromMap(e as Map<String, dynamic>)).toList();
});

//update pass

final changePasswordProvider =
    FutureProvider.family<void, String>((ref, newPassword) async {
  final response = await Supabase.instance.client.auth.updateUser(
    UserAttributes(password: newPassword),
  );

  throw Exception(response);
});

//delete notes

final deleteNoteProvider =
    FutureProvider.family<void, dynamic>((ref, noteId) async {
  final response = await supabase.from('Notes').delete().eq('id', noteId);

  if (response != null) {
    throw Exception('Error deleting note: ${response!}');
  }
});

final themeProvider = StateProvider<ThemeData>((ref) {
  // بررسی حالت پلتفرم و انتخاب تم متناسب
  final platformBrightness = PlatformDispatcher.instance.platformBrightness;

  return platformBrightness == Brightness.dark
      ? darkTheme // اگر گوشی در حالت تیره است
      : lightTheme; // اگر گوشی در حالت روشن است
});

final isLoadingProvider = StateProvider<bool>((ref) => false);
final isRedirectingProvider = StateProvider<bool>((ref) => false);

// واکشی پست‌ها
final fetchPublicPosts = FutureProvider<List<PublicPostModel>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;

  try {
    final response = await supabase
        .from('public_posts')
        .select(
            '*, profiles(username, avatar_url, is_verified), post_likes(user_id)')
        .order('created_at', ascending: false);

    final postsData = response as List<dynamic>; // از فیلد data استفاده کنید

    return postsData.map((e) {
      // اطمینان از نوع صحیح فیلدها با استفاده از عملگرهای اختیاری و مقادیر پیش‌فرض
      final profile = e['profiles'] as Map<String, dynamic>? ?? {};
      final avatarUrl = profile['avatar_url'] as String? ?? '';
      final username = profile['username'] as String? ?? 'Unknown';
      final isVerified =
          profile['is_verified'] as bool? ?? false; // بررسی وضعیت تایید

      final likes = e['post_likes'] as List<dynamic>? ?? [];
      final likeCount = likes.length;
      final isLiked = likes.any((like) => like['user_id'] == userId);

      return PublicPostModel.fromMap({
        ...e,
        'like_count': likeCount,
        'is_liked': isLiked,
        'username': username,
        'avatar_url': avatarUrl,
        'is_verified': isVerified, // اضافه کردن isVerified به Map
      });
    }).toList();
  } catch (e) {
    print("Exception in fetching public posts: $e");
    throw Exception("Exception in fetching public posts: $e");
  }
});
final postsProvider = StateProvider<List<PublicPostModel>>((ref) => []);

// سرویس Supabase برای مدیریت لایک‌ها
class SupabaseService {
  final SupabaseClient supabase;

  SupabaseService(this.supabase);

  Future<void> toggleLike({
    required String postId,
    required String ownerId,
    required WidgetRef ref,
  }) async {
    try {
      // بررسی اعتبار شناسه‌ها
      if (postId.isEmpty) {
        throw ArgumentError('شناسه پست نمی‌تواند خالی باشد');
      }

      if (ownerId.isEmpty) {
        throw ArgumentError('شناسه مالک پست نمی‌تواند خالی باشد');
      }

      final userId = _validateUser();

      // بررسی اینکه آیا شناسه‌ها UUID معتبر هستند
      _validateUUID(postId);
      _validateUUID(ownerId);
      _validateUUID(userId);

      // بررسی لایک موجود با استفاده از باکچ سیف
      final existingLike = await _checkExistingLike(postId, userId);

      if (existingLike == null) {
        await _addLike(postId, userId, ownerId);
      } else {
        await _removeLike(postId, userId, ownerId);
      }

      // بروزرسانی استیت
      ref.invalidate(fetchPublicPosts);
    } on AuthException catch (e) {
      print('خطای احراز هویت: ${e.message}');
      rethrow;
    } on ArgumentError catch (e) {
      print('خطای اعتبارسنجی: ${e.message}');
      rethrow;
    } catch (e) {
      print('خطا در toggleLike: $e');
      rethrow;
    }
  }

// متد اعتبارسنجی UUID
  void _validateUUID(String uuid) {
    final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false);

    if (uuid.isEmpty || !uuidRegex.hasMatch(uuid)) {
      throw ArgumentError('شناسه نامعتبر: $uuid');
    }
  }

  String _validateUser() {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('کاربر احراز هویت نشده است');
    }
    return user.id;
  }

  Future<Map<String, dynamic>?> _checkExistingLike(
      String postId, String userId) async {
    try {
      return await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
    } catch (e) {
      print('خطا در بررسی لایک موجود: $e');
      return null;
    }
  }

  Future<void> _addLike(String postId, String userId, String ownerId) async {
    try {
      await supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });

      await _updateLikeCount(postId, increase: true);

      if (userId != ownerId) {
        await _createLikeNotification(postId, userId, ownerId);
      }
    } catch (e) {
      print('خطا در افزودن لایک: $e');
      rethrow;
    }
  }

  Future<void> _removeLike(String postId, String userId, String ownerId) async {
    try {
      await supabase.from('post_likes').delete().match({
        'post_id': postId,
        'user_id': userId,
      });

      await _updateLikeCount(postId, increase: false);
      await _removeLikeNotification(postId, userId, ownerId);
    } catch (e) {
      print('خطا در حذف لایک: $e');
      rethrow;
    }
  }

  Future<void> _createLikeNotification(
      String postId, String senderId, String recipientId) async {
    try {
      final existingNotification = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', recipientId)
          .eq('sender_id', senderId)
          .eq('post_id', postId)
          .eq('type', 'like')
          .maybeSingle();

      if (existingNotification == null) {
        await supabase.from('notifications').insert({
          'recipient_id': recipientId,
          'sender_id': senderId,
          'post_id': postId,
          'type': 'like',
          'content': '⭐',
          'is_read': false
        });
      }
    } catch (e) {
      print('خطا در ایجاد نوتیفیکیشن: $e');
      rethrow;
    }
  }

  Future<void> _removeLikeNotification(
      String postId, String senderId, String recipientId) async {
    try {
      await supabase.from('notifications').delete().match({
        'recipient_id': recipientId,
        'sender_id': senderId,
        'post_id': postId,
        'type': 'like'
      });
    } catch (e) {
      print('خطا در حذف نوتیفیکیشن: $e');
      rethrow;
    }
  }

  Future<void> _updateLikeCount(String postId, {required bool increase}) async {
    try {
      await supabase.rpc('update_like_count',
          params: {'post_id_input': postId, 'increment': increase ? 1 : -1});
    } catch (e) {
      print('خطا در بروزرسانی تعداد لایک‌ها: $e');
      rethrow;
    }
  }

  Future<void> insertReport({
    required String postId,
    required String reportedUserId,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      // بررسی اعتبار شناسه‌ها
      if (postId.isEmpty || reportedUserId.isEmpty) {
        throw ArgumentError('شناسه‌ها نمی‌توانند خالی باشند');
      }

      _validateUUID(postId);
      _validateUUID(reportedUserId);

      final userId = _validateUser();
      _validateUUID(userId);

      await supabase.from('reports').insert({
        'post_id': postId,
        'reported_user_id': reportedUserId,
        'reporter_id': userId,
        'reason': reason,
        'additional_details': additionalDetails,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending'
      });
    } catch (e) {
      print('خطا در ثبت گزارش: $e');
      rethrow;
    }
  }

  Future<void> deletePost(WidgetRef ref, String postId) async {
    try {
      // بررسی اعتبار شناسه
      if (postId.isEmpty) {
        throw ArgumentError('شناسه پست نمی‌تواند خالی باشد');
      }

      _validateUUID(postId);

      final userId = _validateUser();

      // حذف لایک‌ها
      await supabase.from('post_likes').delete().eq('post_id', postId);

      // حذف نوتیفیکیشن‌ها
      await supabase.from('notifications').delete().eq('post_id', postId);

      // حذف پست
      await supabase.from('public_posts').delete().eq('id', postId);

      ref.invalidate(fetchPublicPosts);

      print('پست و وابستگی‌های آن با موفقیت حذف شدند.');
    } catch (e) {
      print('خطا در حذف پست: $e');
      rethrow;
    }
  }

  Future<List<ProfileModel>> fetchFollowers(String userId) async {
    final response = await supabase.from('follows').select('''
      profiles!follows_follower_id_fkey (
        id, username, full_name, avatar_url, email, bio, 
        followers_count, created_at, 
        is_verified, verification_type
      )
    ''').eq('following_id', userId);

    if (response == null) {
      throw Exception('Error fetching followers: response is null');
    }

    try {
      return (response as List<dynamic>).map((item) {
        final profileMap = item['profiles'];
        if (profileMap == null) {
          throw Exception('Profile data is missing in the response');
        }
        return ProfileModel.fromMap(profileMap);
      }).toList();
    } catch (e) {
      print('Error parsing response: $e');
      throw Exception('Error converting profiles');
    }
  }

  Future<List<ProfileModel>> fetchFollowing(String userId) async {
    final response = await supabase
        .from('follows') // جدول دنبال‌شده‌ها
        .select('''
        profiles!follows_following_id_fkey (
          id, username, full_name, avatar_url, email, bio, 
          followers_count, created_at, 
          is_verified, verification_type
        )
      ''').eq('follower_id', userId); // دریافت دنبال‌شده‌ها

    if (response == null) {
      throw Exception('Error fetching following');
    }

    // تبدیل داده به مدل پروفایل
    final List data = response ?? [];
    return data.map((item) {
      final profileMap = item['profiles']; // بررسی وجود داده‌های پروفایل
      if (profileMap == null) {
        throw Exception('Missing profile data');
      }
      return ProfileModel.fromMap(profileMap);
    }).toList();
  }
}

// Provider برای سرویس Supabase

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final supabase = Supabase.instance.client;
  return SupabaseService(supabase);
});

//Provider برای سرویس و Notifier

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationsNotifier() : super([]);

  // متد حذف تمامی اعلان‌ها
  Future<void> deleteAllNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception("User not logged in");
      }

      // حذف تمامی اعلان‌های کاربر فعلی
      await supabase.from('notifications').delete().eq('recipient_id', userId);

      // بروزرسانی وضعیت (حذف همه اعلان‌ها از لیست)
      state = [];
    } catch (e) {
      print("Error deleting notifications: $e");
      throw Exception("Failed to delete notifications");
    }
  }

  Future<void> fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id; // گرفتن شناسه کاربر فعلی

    if (userId == null) {
      throw Exception("User not logged in");
    }

    final response = await supabase
        .from('notifications')
        .select(
            '*, sender:profiles!notifications_sender_id_fkey(username, avatar_url , is_verified)')
        .eq('recipient_id', userId) // استفاده از شناسه کاربر فعلی
        .order('created_at', ascending: false);

    final notifications =
        response.map((item) => NotificationModel.fromMap(item)).toList();
    state = notifications;
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        (ref) {
  return NotificationsNotifier()..fetchNotifications();
});

// سرویس Supabase برای گزارش پست‌ها

// تعریف پازنده برای SupabaseClient
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// تعریف پرووایدر سرویس گزارش
final reportServiceProvider = Provider<ReportService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReportService(client);
});

class ReportService {
  final SupabaseClient client;

  ReportService(this.client);

  Future<void> reportPost({
    required String postId,
    required String userId,
    required String reportReason,
  }) async {
    final response = await client.from('reports').insert({
      'post_id': postId,
      'user_id': userId,
      'reason': reportReason,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (response.error != null) {
      throw Exception('Error reporting post: ${response.error!.message}');
    }
  }
}

// provider for profiles

class ProfileService {
  final _supabase = Supabase.instance.client;

  // دریافت پروفایل کاربر فعلی
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles') // نام جدول پروفایل
          .select('*')
          .eq('id', user.id)
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      print('Error fetching current user profile: $e');
      return null;
    }
  }

  // دریافت پروفایل با شناسه
  Future<UserModel?> getProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }
}

// Provider برای سرویس پروفایل
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

// Provider برای پروفایل کاربر فعلی
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getCurrentUserProfile();
});

// Provider برای پروفایل با شناسه خاص
final profileByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfileById(userId);
});

// مثال استفاده در ویجت
class ProfileWidget extends ConsumerWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // دریافت پروفایل کاربر فعلی
    final currentProfileAsync = ref.watch(currentUserProfileProvider);

    return currentProfileAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const Text('خطا در بارگذاری پروفایل'),
      data: (profile) {
        if (profile == null) {
          return const Text('کاربر وارد نشده است');
        }
        return Column(
          children: [
            Text(profile.username),
            if (profile.isVerified)
              const Icon(Icons.verified, color: Colors.blue)
          ],
        );
      },
    );
  }
}

// مثال دریافت پروفایل با شناسه خاص
class OtherProfileWidget extends ConsumerWidget {
  final String userId;

  const OtherProfileWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));

    return profileAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const Text('خطا در بارگذاری پروفایل'),
      data: (profile) {
        if (profile == null) {
          return const Text('پروفایل یافت نشد');
        }
        return Column(
          children: [
            Text(profile.username),
            if (profile.isVerified)
              const Icon(Icons.verified, color: Colors.blue)
          ],
        );
      },
    );
  }
}

//fetch comments
//Comment StateNotifier

class CommentService {
  final SupabaseClient _supabase;

  CommentService(this._supabase);

  Future<CommentModel> addComment({
    required String postId,
    required String content,
    required String postOwnerId,
    String? parentCommentId, // اضافه کردن پارامتر جدید
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('کاربر وارد سیستم نشده است');
      }

      if (content.trim().isEmpty) {
        throw Exception('محتوای کامنت نمی‌تواند خالی باشد');
      }

      final response = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': currentUser.id,
            'content': content,
            'post_owner_id': postOwnerId,
            'parent_comment_id': parentCommentId, // اضافه کردن فیلد جدید
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, user:profiles(username, avatar_url, is_verified)')
          .single();

      return CommentModel.fromMap(response);
    } catch (e) {
      print('خطا در ارسال کامنت: $e');
      rethrow;
    }
  }

// تغییر متد fetchComments برای دریافت کامنت‌های فرزند
  Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles(username, avatar_url, is_verified)')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      // دریافت لیست کامنت‌ها
      List<CommentModel> comments =
          (response as List).map((item) => CommentModel.fromMap(item)).toList();

      // مرتب‌سازی کامنت‌ها بر اساس والد
      _organizeComments(comments);

      return comments;
    } catch (e) {
      print('خطا در واکشی کامنت‌ها: $e');
      return [];
    }
  }

// متد کمکی برای مرتب‌سازی کامنت‌ها
  void _organizeComments(List<CommentModel> comments) {
    final Map<String, CommentModel> commentMap = {};

    // ایجاد نقشه از کامنت‌ها بر اساس شناسه
    for (var comment in comments) {
      commentMap[comment.id] = comment;
      comment.replies = []; // مقداردهی اولیه برای replies
    }

    // اضافه کردن کامنت‌های فرزند به والدین و حذف آنها از لیست اصلی
    comments.removeWhere((comment) {
      if (comment.parentCommentId != null) {
        final parentComment = commentMap[comment.parentCommentId];
        if (parentComment != null) {
          parentComment.replies ??= [];
          parentComment.replies!.add(comment);
          return true; // حذف ریپلای از لیست اصلی
        }
      }
      return false; // کامنت اصلی حذف نمی‌شود
    });
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final currentUserId = _supabase.auth.currentUser!.id;

      // Optional: You might want to add a check to ensure only the comment owner can delete
      final response = await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', currentUserId);

      return response;
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> searchMentionableUsers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,name.ilike.%$query%')
          .limit(10);

      return (response as List)
          .map((userData) => UserModel.fromJson(userData))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  Future<void> addMentionToComment({
    required String commentId,
    required List<String> mentionedUserIds,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('کاربر وارد سیستم نشده است');
      }

      // درج منشن‌ها در جدول comment_mentions
      final mentions = mentionedUserIds
          .map((userId) => {
                'comment_id': commentId,
                'user_id': userId,
                'created_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabase.from('comment_mentions').insert(mentions);
    } catch (e) {
      print('خطا در اضافه کردن منشن به کامنت: $e');
      rethrow;
    }
  }
}

// Provider برای جستجوی کاربران
final mentionableUsersProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) {
  final commentService = ref.watch(commentServiceProvider);
  return commentService.searchMentionableUsers(query);
});

// comment_providers.dart
final commentServiceProvider = Provider<CommentService>((ref) {
  final supabase = Supabase.instance.client;
  return CommentService(supabase);
});

final commentsProvider =
    FutureProvider.family<List<CommentModel>, String>((ref, postId) {
  final commentService = ref.read(commentServiceProvider);
  return commentService.fetchComments(postId);
});

// comment_notifier.dart
class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  final CommentService _commentService;
  final TextEditingController contentController = TextEditingController();

  // اضافه کردن یک فلگ برای جلوگیری از ارسال مکرر
  bool _isSubmitting = false;

  CommentNotifier(this._commentService) : super(const AsyncValue.data(null));

  Future<void> addComment(
      {required String postId,
      required String content,
      required String postOwnerId,
      String? parentCommentId,
      List<String> mentionedUserIds = const [],
      required WidgetRef ref}) async {
    // جلوگیری از ارسال مکرر
    if (_isSubmitting) return;

    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) return;

    // تنظیم فلگ ارسال
    _isSubmitting = true;
    state = const AsyncValue.loading();

    try {
      // افزودن کامنت با مشخصات کامل
      final comment = await _commentService.addComment(
        postId: postId,
        content: trimmedContent,
        postOwnerId: postOwnerId,
        parentCommentId: parentCommentId,
      );

      // اگر منشن‌هایی وجود دارد، آنها را اضافه کنید
      if (mentionedUserIds.isNotEmpty) {
        await _commentService.addMentionToComment(
          commentId: comment.id,
          mentionedUserIds: mentionedUserIds,
        );
      }

      // پاک کردن کنترلر
      contentController.clear();

      // بروزرسانی استیت کامنت‌ها
      await _updateCommentsState(postId, comment, parentCommentId, ref);

      state = const AsyncValue.data(null);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    } finally {
      // بازنشانی فلگ ارسال
      _isSubmitting = false;
    }
  }

  // متد جدید برای بروزرسانی استیت کامنت‌ها
  Future<void> _updateCommentsState(
    String postId,
    CommentModel newComment,
    String? parentCommentId,
    WidgetRef ref,
  ) async {
    // دریافت پروایدر کامنت‌ها برای پست مورد نظر
    final commentsProvider =
        StateNotifierProvider<CommentsNotifier, List<CommentModel>>((ref) {
      return CommentsNotifier(_commentService);
    });

    // بروزرسانی استیت کامنت‌ها
    ref.read(commentsProvider.notifier).addComment(
          postId: postId,
          comment: newComment,
          parentCommentId: parentCommentId,
        );
  }

  Future<String> getPostOwnerId(String postId) async {
    final response = await supabase
        .from('public_posts')
        .select('user_id')
        .eq('id', postId)
        .single();

    return response['user_id'] as String;
  }

  Future<void> deleteComment(String commentId, WidgetRef ref) async {
    state = const AsyncValue.loading();

    try {
      await _commentService.deleteComment(commentId);
      state = const AsyncValue.data(null);

      // بروزرسانی استیت کامنت‌ها برای پست مشخص
      ref.read(commentsProvider(commentId));
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}

// نوتیفایر جدید برای مدیریت کامنت‌ها
class CommentsNotifier extends StateNotifier<List<CommentModel>> {
  final CommentService _commentService;

  CommentsNotifier(this._commentService) : super([]);

  void addComment({
    required String postId,
    required CommentModel comment,
    String? parentCommentId,
  }) {
    if (parentCommentId != null) {
      // پیدا کردن کامنت والد و اضافه کردن ریپلای
      state = state.map((existingComment) {
        if (existingComment.id == parentCommentId) {
          final updatedReplies = [...(existingComment.replies ?? []), comment];
          return existingComment.copyWith(
            replies: updatedReplies?.cast<CommentModel>(),
          );
        }
        return existingComment;
      }).toList();
    } else {
      // اگر کامنت اصلی است، به لیست اضافه می‌شود
      // جلوگیری از تکرار
      if (!state.any((existingComment) => existingComment.id == comment.id)) {
        state = [...state, comment];
      }
    }
  }

  void removeComment(String commentId) {
    state = state.where((comment) {
      // حذف کامنت اصلی
      if (comment.id == commentId) return false;

      // حذف ریپلای‌های مربوط به کامنت
      if (comment.replies != null) {
        comment.replies =
            comment.replies!.where((reply) => reply.id != commentId).toList();
      }

      return true;
    }).toList();
  }
}

// پروایدر جدید برای کامنت‌ها
// final commentsProvider = StateNotifierProvider<CommentsNotifier, List<CommentModel>>((ref) {
//   final commentService = ref.read(commentServiceProvider);
//   return CommentsNotifier(commentService);
// });

final commentNotifierProvider =
    StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
  final commentService = ref.read(commentServiceProvider);
  return CommentNotifier(commentService);
});

class ProfileNotifier extends StateNotifier<ProfileModel?> {
  final Ref ref;

  ProfileNotifier(this.ref) : super(null);

  Future<void> fetchProfile(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      // دریافت اطلاعات پروفایل
      final profileResponse = await supabase.from('profiles').select('''
            id,
            username,
            full_name,
            avatar_url,
            email,
            bio,
            created_at,
            is_verified
          ''').eq('id', userId).single();

      // محاسبه تعداد دنبال‌کنندگان
// محاسبه تعداد دنبال‌کنندگان
      final followersResponse = await supabase
          .from('follows')
          .select('id')
          .eq('following_id', userId);

      final followersCount = followersResponse.length;

// محاسبه تعداد دنبال‌شونده‌ها
      final followingResponse =
          await supabase.from('follows').select('id').eq('follower_id', userId);

      final followingCount = followingResponse.length;

      // دریافت پست‌ها
      // دریافت پست‌ها
      final postsResponse = await supabase.from('public_posts').select('''
    id, 
    content, 
    created_at, 
    user_id,
    profiles(username, avatar_url, is_verified),
    post_likes(user_id)
''').eq('user_id', userId).order('created_at', ascending: false);

// ساخت مدل پروفایل
      final profile = ProfileModel.fromMap(profileResponse);
      final posts = postsResponse.map((post) {
        final postLikes = post['post_likes'] as List? ?? [];
        final likeCount = postLikes.length;
        final isLiked =
            postLikes.any((like) => like['user_id'] == currentUserId);

        return PublicPostModel.fromMap({
          ...post,
          'like_count': likeCount,
          'is_liked': isLiked,
          'username': post['profiles']?['username'] ?? 'Unknown',
          'avatar_url': post['profiles']?['avatar_url'] ?? '',
          'is_verified': post['profiles']?['is_verified'] ?? false,
        });
      }).toList();

      // بررسی وضعیت فالو
      final followStatusResponse = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', supabase.auth.currentUser!.id)
          .eq('following_id', userId)
          .maybeSingle();

      // ساخت مدل پروفایل
      postsResponse.map((post) {
        final postLikes = post['post_likes'] as List;
        return PublicPostModel.fromMap({
          ...post,
          'is_liked': postLikes.any((like) => like['user_id'] == currentUserId),
          'profiles': post['profiles'],
        });
      }).toList();

      // به‌روزرسانی استیت
      state = profile.copyWith(
        posts: posts,
        followersCount: followersCount,
        followingCount: followingCount,
        isFollowed: followStatusResponse != null,
      );
    } catch (e) {
      print('خطا در دریافت پروفایل: $e');
      state = null;
    }
  }

  Future<void> toggleFollow(String userId) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (state == null || currentUserId == null) return;

    try {
      if (state!.isFollowed) {
        // حذف فالو
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', userId);

        // حذف اعلان فالو
        await supabase.from('notifications').delete().match({
          'recipient_id': userId,
          'sender_id': currentUserId,
          'type': 'follow',
        });

        // کاهش تعداد فالوورها
        state = state!.copyWith(
          isFollowed: false,
          followersCount: state!.followersCount - 1,
        );
      } else {
        // اضافه کردن فالو
        await supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
        });

        // ایجاد اعلان فالو
        // await supabase.from('notifications').insert({
        //   'recipient_id': userId,
        //   'sender_id': currentUserId,
        //   'type': 'follow',
        //   'content': 'کاربر شما را دنبال کرد'
        // });

        // افزایش تعداد فالوورها
        state = state!.copyWith(
          isFollowed: true,
          followersCount: state!.followersCount + 1,
        );
      }
    } catch (e) {
      print('خطا در تغییر وضعیت فالو: $e');
    }
  }

  void updatePost(PublicPostModel updatedPost) {
    if (state == null) return;

    final updatedPosts = state!.posts.map((post) {
      if (post.id == updatedPost.id) {
        return updatedPost;
      }
      return post;
    }).toList();

    state = state!.copyWith(posts: updatedPosts);
  }

  void addNewPost(PublicPostModel newPost) {
    if (state == null) return;

    // افزودن پست جدید به ابتدای لیست
    final updatedPosts = [newPost, ...state!.posts];

    // به‌روزرسانی استیت با پست‌های جدید
    state = state!.copyWith(posts: updatedPosts);
  }
}

final userProfileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileModel?, String>(
  (ref, userId) => ProfileNotifier(ref)..fetchProfile(userId),
);

final postProvider =
    FutureProvider.family<PublicPostModel, String>((ref, postId) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('public_posts')
      .select(
          '*, profiles(username, avatar_url, is_verified), post_likes(user_id)')
      .eq('id', postId)
      .maybeSingle();

  if (response == null) {
    throw Exception('پستی با این شناسه یافت نشد.');
  }

  final likes = response['post_likes'] as List<dynamic>? ?? [];
  final likeCount = likes.length;
  final isLiked =
      likes.any((like) => like['user_id'] == supabase.auth.currentUser?.id);
  print('Response from Supabase: $response');

  return PublicPostModel.fromMap({
    ...response,
    'like_count': likeCount,
    'is_liked': isLiked,
    'username': response['profiles']?['username'] ?? 'Unknown',
    'avatar_url': response['profiles']?['avatar_url'] ?? '',
    'is_verified': response['profiles']?['is_verified'] ?? false,
  });
});

class ReportCommentService {
  final SupabaseClient supabase;

  ReportCommentService(this.supabase);

  Future<void> reportComment({
    required String commentId,
    required String reporterId,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      // ارسال گزارش به جدول comment_reports
      await supabase.from('comment_reports').insert({
        'comment_id': commentId,
        'reporter_id': reporterId,
        'reason': reason, // دلیل گزارش
        'additional_details': additionalDetails, // توضیحات اضافی
        'reported_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to report comment: $e');
    }
  }
}

// ارائه‌دهنده سرویس گزارش کامنت‌ها
final reportCommentServiceProvider = Provider<ReportCommentService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ReportCommentService(supabase);
});

//profile report

class ReportProfileService {
  final SupabaseClient supabase;

  ReportProfileService(this.supabase);

  Future<void> reportProfile({
    required String userId,
    required String reporterId,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      // ارسال گزارش به جدول profile_reports
      await supabase.from('profile_reports').insert({
        'profile_id': userId,
        'reporter_id': reporterId,
        'reason': reason, // دلیل گزارش
        'additional_details': additionalDetails, // توضیحات اضافی
        'reported_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to report profile: $e');
    }
  }
}

// ارائه‌دهنده سرویس گزارش پروفایل‌ها
final reportProfileServiceProvider = Provider<ReportProfileService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ReportProfileService(supabase);
});

//mention user profile
// mention_providers.dart
final mentionUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  try {
    final supabase = Supabase.instance.client;

    // واکشی کاربران با اطلاعات کامل
    final response = await supabase
        .from('profiles')
        .select('id, username, avatar_url, is_verified, verification_type')
        .order('username');

    return (response as List)
        .map((userData) => UserModel.fromMap(userData))
        .toList();
  } catch (e) {
    print('خطا در دریافت کاربران برای منشن: $e');
    return [];
  }
});

// mention_service.dart
class MentionService {
  final SupabaseClient _supabase;

  MentionService(this._supabase);

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, avatar_url, is_verified, verification_type')
          .or('username.ilike.%$query%, email.ilike.%$query%')
          .limit(10);

      return (response as List)
          .map((userData) => UserModel.fromMap(userData))
          .toList();
    } catch (e) {
      print('خطا در جستجوی کاربران: $e');
      return [];
    }
  }

  // متد اضافه کردن منشن به کامنت
  Future<void> addMentionToComment({
    required String commentId,
    required List<String> mentionedUserIds,
  }) async {
    try {
      await _supabase.from('comment_mentions').insert(mentionedUserIds
          .map((userId) => {
                'comment_id': commentId,
                'user_id': userId,
              })
          .toList());
    } catch (e) {
      print('خطا در ثبت منشن‌ها: $e');
      rethrow;
    }
  }
}

// mention_notifier.dart
class MentionNotifier extends StateNotifier<List<UserModel>> {
  final MentionService _mentionService;

  MentionNotifier(this._mentionService) : super([]);

  Future<void> searchMentionableUsers(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }

    try {
      final users = await _mentionService.searchUsers(query);
      state = users;
    } catch (e) {
      state = [];
      print('خطا در جستجوی کاربران: $e');
    }
  }

  void clearMentions() {
    state = [];
  }
}

// mention_providers_final.dart
final mentionServiceProvider = Provider<MentionService>((ref) {
  final supabase = Supabase.instance.client;
  return MentionService(supabase);
});

final mentionNotifierProvider =
    StateNotifierProvider<MentionNotifier, List<UserModel>>((ref) {
  final mentionService = ref.read(mentionServiceProvider);
  return MentionNotifier(mentionService);
});

final userFollowersProvider =
    FutureProvider.family<List<ProfileModel>, String>((ref, userId) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  return await supabaseService.fetchFollowers(userId);
});

final userFollowingProvider =
    FutureProvider.family<List<ProfileModel>, String>((ref, userId) async {
  final supabaseService = ref.read(supabaseServiceProvider);

  return await supabaseService.fetchFollowing(userId);
});

final fetchFollowingPostsProvider =
    FutureProvider<List<PublicPostModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;

  // دریافت لیست افرادی که کاربر فعلی دنبال می‌کند
  final followingResponse = await supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', currentUserId.toString());

  final followingIds = followingResponse.map((e) => e['following_id']).toList();

  // دریافت پست‌های افراد دنبال شده
  final response = await supabase
      .from('public_posts')
      .select('''
        id, 
        content, 
        created_at, 
        user_id,
        profiles(username, avatar_url, is_verified),
        post_likes(user_id)
      ''')
      .or(followingIds.map((id) => 'user_id.eq.$id').join(','))
      .order('created_at', ascending: false);

  return response.map((post) {
    final postLikes = post['post_likes'] as List? ?? [];

    // چک کردن لایک توسط کاربر فعلی
    final isLikedByCurrentUser =
        postLikes.any((like) => like['user_id'] == currentUserId);

    return PublicPostModel.fromMap({
      ...post,
      'like_count': postLikes.length,
      'is_liked': isLikedByCurrentUser,
      'username': post['profiles']?['username'] ?? 'Unknown',
      'avatar_url': post['profiles']?['avatar_url'] ?? '',
      'is_verified': post['profiles']?['is_verified'] ?? false,
    });
  }).toList();
});

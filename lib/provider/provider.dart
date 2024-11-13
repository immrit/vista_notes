import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vistaNote/model/notificationModel.dart';
import 'package:vistaNote/model/publicPostModel.dart';
import '../main.dart';
import '../model/NotesModel.dart';
import '../util/themes.dart';

//check user state
final authStateProvider = StreamProvider<User?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
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

// حالت مدیریت تم
final themeProvider = StateProvider<ThemeData>((ref) {
  return lightTheme; // به صورت پیش‌فرض تم روشن
});

final isLoadingProvider = StateProvider<bool>((ref) => false);
final isRedirectingProvider = StateProvider<bool>((ref) => false);

// واکشی پست‌ها
final fetchPublicPosts = FutureProvider<List<PublicPostModel>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;

  try {
    final response = await supabase
        .from('public_posts')
        .select('*, profiles(username, avatar_url), post_likes(user_id)')
        .order('created_at', ascending: false);

    final postsData = response as List<dynamic>;

    return postsData.map((e) {
      // اطمینان از نوع صحیح فیلدها با استفاده از عملگرهای اختیاری و مقادیر پیش‌فرض
      final profile = e['profiles'] as Map<String, dynamic>? ?? {};
      final avatarUrl =
          profile['avatar_url'] as String? ?? ''; // استفاده از یک رشته پیش‌فرض
      final username =
          profile['username'] as String? ?? 'Unknown'; // بررسی وجود نام کاربری

      final likes = e['post_likes'] as List<dynamic>? ?? [];
      final likeCount = likes.length;
      final isLiked = likes.any((like) => like['user_id'] == userId);

      return PublicPostModel.fromMap({
        ...e,
        'like_count': likeCount,
        'is_liked': isLiked,
        'username': username,
        'avatar_url': avatarUrl,
      });
    }).toList();
  } catch (e) {
    print("Exception in fetching public posts: $e");
    throw Exception("Exception in fetching public posts: $e");
  }
});

// سرویس Supabase برای مدیریت لایک‌ها
class SupabaseService {
  final SupabaseClient supabase;

  SupabaseService(this.supabase);

  Future<void> toggleLike(
      {required String postId,
      required String ownerId,
      required WidgetRef ref}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // بررسی لایک موجود
      final existingLike = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike == null) {
        // ثبت لایک جدید
        await _addLike(postId, userId, ownerId);
      } else {
        // حذف لایک
        await _removeLike(postId, userId, ownerId);
      }
    } catch (e) {
      print('Error in toggleLike: $e');
      rethrow;
    }
  }

  Future<void> _addLike(String postId, String userId, String ownerId) async {
    // ثبت لایک
    await supabase.from('post_likes').insert({
      'post_id': postId,
      'user_id': userId,
    });

    // به‌روزرسانی تعداد لایک‌ها
    await _updateLikeCount(postId, increase: true);

    // ایجاد نوتیفیکیشن فقط اگر لایک کننده صاحب پست نباشد
    if (userId != ownerId) {
      await _createLikeNotification(postId, userId, ownerId);
    }
  }

  Future<void> _removeLike(String postId, String userId, String ownerId) async {
    // حذف لایک
    await supabase.from('post_likes').delete().match({
      'post_id': postId,
      'user_id': userId,
    });

    // به‌روزرسانی تعداد لایک‌ها
    await _updateLikeCount(postId, increase: false);

    // حذف نوتیفیکیشن
    await _removeLikeNotification(postId, userId, ownerId);
  }

  Future<void> _createLikeNotification(
      String postId, String senderId, String recipientId) async {
    // دریافت اطلاعات پروفایل فرستنده
    final senderProfile = await supabase
        .from('profiles')
        .select('username, avatar_url')
        .eq('id', senderId)
        .single();

    // بررسی عدم وجود اعلان تکراری
    final existingNotification = await supabase
        .from('notifications')
        .select()
        .eq('recipient_id', recipientId)
        .eq('sender_id', senderId)
        .eq('post_id', postId)
        .eq('type', 'like')
        .maybeSingle();

    if (existingNotification == null) {
      // ثبت نوتیفیکیشن
      await supabase.from('notifications').insert({
        'recipient_id': recipientId,
        'sender_id': senderId,
        'post_id': postId,
        'type': 'like',
        'content': '⭐', // ایموجی لایک به عنوان مقدار content
        'is_read': false
      });
    }
  }

  Future<void> _removeLikeNotification(
      String postId, String senderId, String recipientId) async {
    // حذف نوتیفیکیشن لایک
    await supabase.from('notifications').delete().match({
      'recipient_id': recipientId,
      'sender_id': senderId,
      'post_id': postId,
      'type': 'like'
    });
  }

  Future<void> _updateLikeCount(String postId, {required bool increase}) async {
    try {
      await supabase.rpc('update_like_count',
          params: {'post_id_input': postId, 'increment': increase ? 1 : -1});
    } catch (e) {
      print('Error updating like count: $e');
      rethrow;
    }
  }

  Future<void> insertReport(
      {required String postId,
      required String reportedUserId,
      required String reason,
      String? additionalDetails}) async {
    try {
      // بررسی اینکه کاربر لاگین کرده باشد
      if (supabase.auth.currentUser == null) {
        throw Exception('کاربر لاگین نشده است');
      }

      await supabase.from('reports').insert({
        'post_id': postId,
        'reported_user_id': reportedUserId,
        'reporter_id': supabase.auth.currentUser!.id,
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
}
// تعریف پروایدر Supabase

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final supabase = Supabase.instance.client;
  return SupabaseService(supabase);
});

//Provider برای سرویس و Notifier

class NotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationsNotifier() : super([]);

  Future<void> fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id; // گرفتن شناسه کاربر فعلی

    if (userId == null) {
      throw Exception("User not logged in");
    }

    final response = await supabase
        .from('notifications')
        .select(
            '*, sender:profiles!notifications_sender_id_fkey(username, avatar_url)')
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

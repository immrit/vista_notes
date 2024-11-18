import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        'content':
            'کاربر ${senderProfile['username']} پست شما رو پسندید: $postContent',
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

//delete posts
  Future<void> deletePost(WidgetRef ref, String postId) async {
    try {
      final likesResponse =
          await supabase.from('post_likes').delete().eq('post_id', postId);
      if (likesResponse == null) {
        print(
            'likesResponse is null but continuing assuming the operation was successful.');
      } else if (likesResponse.error != null) {
        throw Exception('خطا در حذف لایک‌ها: ${likesResponse.error!.message}');
      }

      final notificationsResponse =
          await supabase.from('notifications').delete().eq('post_id', postId);
      if (notificationsResponse == null) {
        print(
            'notificationsResponse is null but continuing assuming the operation was successful.');
      } else if (notificationsResponse.error != null) {
        throw Exception(
            'خطا در حذف اعلان‌ها: ${notificationsResponse.error!.message}');
      }

      final response =
          await supabase.from('public_posts').delete().eq('id', postId);
      if (response == null) {
        print(
            'response is null but continuing assuming the operation was successful.');
      } else if (response.error != null) {
        throw Exception('خطا در حذف پست: ${response.error!.message}');
      }
      ref.invalidate(fetchPublicPosts);

      print('پست و وابستگی‌های آن با موفقیت حذف شدند.');
    } catch (e) {
      print('خطا در حذف پست: $e');
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

// provider for profiles

class ProfileService {
  final _supabase = Supabase.instance.client;

  // دریافت پروفایل کاربر فعلی
  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles') // نام جدول پروفایل
          .select('*')
          .eq('id', user.id)
          .single();

      return ProfileModel.fromMap(response);
    } catch (e) {
      print('Error fetching current user profile: $e');
      return null;
    }
  }

  // دریافت پروفایل با شناسه
  Future<ProfileModel?> getProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return ProfileModel.fromMap(response);
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
final currentUserProfileProvider = FutureProvider<ProfileModel?>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getCurrentUserProfile();
});

// Provider برای پروفایل با شناسه خاص
final profileByIdProvider =
    FutureProvider.family<ProfileModel?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfileById(userId);
});

// مثال استفاده در ویجت
class ProfileWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // دریافت پروفایل کاربر فعلی
    final currentProfileAsync = ref.watch(currentUserProfileProvider);

    return currentProfileAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('خطا در بارگذاری پروفایل'),
      data: (profile) {
        if (profile == null) {
          return Text('کاربر وارد نشده است');
        }
        return Column(
          children: [
            Text(profile.username),
            if (profile.isVerified) Icon(Icons.verified, color: Colors.blue)
          ],
        );
      },
    );
  }
}

// مثال دریافت پروفایل با شناسه خاص
class OtherProfileWidget extends ConsumerWidget {
  final String userId;

  OtherProfileWidget({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));

    return profileAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('خطا در بارگذاری پروفایل'),
      data: (profile) {
        if (profile == null) {
          return Text('پروفایل یافت نشد');
        }
        return Column(
          children: [
            Text(profile.username),
            if (profile.isVerified) Icon(Icons.verified, color: Colors.blue)
          ],
        );
      },
    );
  }
}

//fetch comments
//Comment StateNotifier

class CommentService {
  final supabase = Supabase.instance.client;

  Future<CommentModel> addComment(
      {required String postId,
      required String userId,
      required String content}) async {
    try {
      if (content.trim().isEmpty) {
        throw Exception('محتوای کامنت نمی‌تواند خالی باشد');
      }

      final response = await supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, profiles(username, avatar_url, is_verified)')
          .single();

      return CommentModel.fromMap(response);
    } catch (e) {
      print('خطا در ارسال کامنت: $e');
      rethrow;
    }
  }

  Future<List<CommentModel>> fetchComments(String postId) async {
    try {
      final response = await supabase
          .from('comments')
          .select('*, profiles(username, avatar_url, is_verified)')
          .eq('post_id', postId)
          .order('created_at');

      return (response as List)
          .map((item) => CommentModel.fromMap(item))
          .toList();
    } catch (e) {
      print('خطا در واکشی کامنت‌ها: $e');
      return [];
    }
  }
}

// Provider برای واکشی کامنت‌ها از دیتابیس
final commentServiceProvider = Provider((ref) => CommentService());

final commentsProvider =
    FutureProvider.family<List<CommentModel>, String>((ref, postId) {
  final commentService = ref.read(commentServiceProvider);
  return commentService.fetchComments(postId);
});

// comment_notifier.dart
class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  final CommentService _commentService;
  final TextEditingController contentController = TextEditingController();

  CommentNotifier(this._commentService) : super(AsyncValue.data(null));

  Future<void> addComment(
      {required String postId, required String userId}) async {
    if (contentController.text.trim().isEmpty) return;

    state = AsyncValue.loading();
    try {
      await _commentService.addComment(
          postId: postId,
          userId: userId,
          content: contentController.text.trim());

      contentController.clear();
      state = AsyncValue.data(null);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}

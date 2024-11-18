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
      throw AuthException('کاربر احراز هویت نشده است');
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
}

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
      final response = await _supabase
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

  CommentNotifier(this._commentService) : super(const AsyncValue.data(null));

  Future<void> addComment({required String postId}) async {
    final content = contentController.text.trim();
    if (content.isEmpty) return;

    state = const AsyncValue.loading();

    try {
      await _commentService.addComment(
        postId: postId,
        content: content,
      );

      contentController.clear();
      state = const AsyncValue.data(null);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
}

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
      final profileData = await supabase.from('profiles').select('''
      id,
      username,
      avatar_url,
      email,
      bio,
      followers_count,
      created_at,
      is_verified,
      verification_type
    ''').eq('id', userId).single();

      // دریافت پست‌های عمومی با اطلاعات اضافی
      final postsData = await supabase.from('public_posts').select('''
        id, 
        content, 
        created_at, 
        user_id,
        like_count,
        profiles(username, avatar_url, is_verified),
        post_likes!inner(user_id)
      ''').eq('user_id', userId).order('created_at', ascending: false);

      // بررسی وضعیت فالو
      final followStatus = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', supabase.auth.currentUser!.id)
          .eq('following_id', userId)
          .maybeSingle();

      // به‌روزرسانی وضعیت پروفایل و پست‌ها
      final profile = ProfileModel.fromMap(profileData);

      final posts = postsData.map((post) {
        // محاسبه وضعیت لایک برای هر پست
        final likeCount = post['like_count'] ?? 0;
        final postLikes = post['post_likes'] as List;

        return PublicPostModel.fromMap({
          ...post,
          'like_count': likeCount,
          'is_liked': postLikes.any((like) => like['user_id'] == currentUserId),
          'profiles': post['profiles'],
        });
      }).toList();

      state = profile.copyWith(posts: posts, isFollowed: followStatus != null);
    } catch (e) {
      print('خطا در دریافت پروفایل: $e');
      state = null;
    }
  }

  Future<void> toggleFollow(String userId) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (state == null || currentUserId == null) return;
    final isFollowed = state!.isFollowed;

    try {
      if (isFollowed) {
        // حذف دنبال کردن
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', userId);
      } else {
        // اضافه کردن دنبال کردن
        await supabase.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
        });
      }

      // به‌روزرسانی وضعیت فالو در استیت
      state = state!.copyWith(
          isFollowed: !isFollowed,
          followersCount: isFollowed
              ? state!.followersCount - 1
              : state!.followersCount + 1);
    } catch (e) {
      print('خطا در تغییر وضعیت فالو: $e');
    }
  }

  // متد جدید برای به‌روزرسانی پست
  void updatePost(PublicPostModel updatedPost) {
    // اگر استیت خالی باشد، کاری انجام نده
    if (state == null) return;

    // ایجاد لیست جدید از پست‌ها با جایگزینی پست به‌روزرسانی شده
    final updatedPosts = state!.posts.map((post) {
      return post.id == updatedPost.id ? updatedPost : post;
    }).toList();

    // ایجاد نسخه جدید از پروفایل با پست‌های به‌روزرسانی شده
    state = state!.copyWith(posts: updatedPosts);
  }

  // به‌روزرسانی وضعیت فالو
  //     state = state!.copyWith(
  //         isFollowed: !isFollowed,
  //         followersCount: isFollowed
  //             ? (state!.followersCount - 1)
  //             : (state!.followersCount + 1));

  //     // تازه‌سازی پروایدر
  //     ref.invalidate(userProfileProvider(userId));
  //   } catch (e) {
  //     print('خطا در تغییر وضعیت دنبال کردن: $e');
  //   }
  // }

  // متد جدید برای لایک کردن پست
  Future<void> toggleLike(String postId) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (state == null || currentUserId == null) return;

    try {
      // بررسی وضعیت لایک فعلی
      final existingLike = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (existingLike != null) {
        // حذف لایک
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUserId);
      } else {
        // اضافه کردن لایک
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': currentUserId,
        });
      }

      // به‌روزرسانی لیست پست‌ها
      final updatedPosts = state!.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
              likeCount: existingLike != null
                  ? post.likeCount - 1
                  : post.likeCount + 1,
              isLiked: existingLike == null);
        }
        return post;
      }).toList();

      state = state!.copyWith(posts: updatedPosts);

      // تازه‌سازی پروایدر
      ref.invalidate(userProfileProvider(state!.id));
    } catch (e) {
      print('خطا در تغییر وضعیت لایک: $e');
    }
  }
}

final userProfileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileModel?, String>(
  (ref, userId) => ProfileNotifier(ref)..fetchProfile(userId),
);

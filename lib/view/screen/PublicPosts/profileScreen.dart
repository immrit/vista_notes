import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../model/ProfileModel.dart';
import '../../../model/publicPostModel.dart';
import '../../../provider/provider.dart';
import '../../../util/widgets.dart';
// در فایل ProfileScreen:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // واکشی اطلاعات پروفایل در اینجا
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileProvider(widget.userId).notifier);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider(widget.userId));
    final currentUser = ref.watch(authProvider);
    final getprofile = ref.watch(profileProvider);
    final currentcolor = ref.watch(themeProvider);

    return Scaffold(
      endDrawer: CustomDrawer(getprofile, currentcolor, context),
      body: profileState == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(profileState),
                _buildPostsList(profileState),
              ],
            ),
    );
  }

  SliverAppBar _buildSliverAppBar(ProfileModel profile) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      title: _buildAppBarTitle(profile),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildProfileHeader(profile),
      ),
    );
  }

  Row _buildAppBarTitle(ProfileModel profile) {
    return Row(
      children: [
        Text(profile.username),
        const SizedBox(width: 5),
        if (profile.isVerified)
          const Icon(Icons.verified, color: Colors.blue, size: 16),
      ],
    );
  }

  Widget _buildProfileHeader(ProfileModel profile) {
    final bool isCurrentUserProfile = profile.id == ref.read(authProvider)?.id;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          _buildProfileInfo(profile, isCurrentUserProfile),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(ProfileModel profile, bool isCurrentUserProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildProfileAvatar(profile),
            const Spacer(),
            _buildProfileActionButton(profile, isCurrentUserProfile),
          ],
        ),
        const SizedBox(height: 16),
        _buildProfileDetails(profile),
      ],
    );
  }

  Widget _buildProfileAvatar(ProfileModel profile) {
    return CircleAvatar(
      radius: 40,
      backgroundImage:
          profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
      child:
          profile.avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
    );
  }

  Widget _buildProfileActionButton(
      ProfileModel profile, bool isCurrentUserProfile) {
    return isCurrentUserProfile
        ? ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/editProfile'),
            child: const Text('Edit Profile'),
          )
        : ElevatedButton(
            onPressed: () => _toggleFollow(profile.id),
            child: Text(profile.isFollowed ? 'Following' : 'Follow'),
          );
  }

  Widget _buildProfileDetails(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.username,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (profile.bio != null) ...[
          const SizedBox(height: 10),
          Text(profile.bio!),
        ],
        const SizedBox(height: 16),
        Text('${profile.followersCount} followers'),
      ],
    );
  }

  SliverList _buildPostsList(ProfileModel profile) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (profile.posts.isEmpty) {
            return const Center(
              child: Text('هنوز پستی وجود ندارد'),
            );
          }
          return _buildPostItem(profile, profile.posts[index]);
        },
        childCount: profile.posts.isEmpty ? 1 : profile.posts.length,
      ),
    );
  }

  Widget _buildPostItem(ProfileModel profile, PublicPostModel post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(profile, post),
            const SizedBox(height: 12),
            Text(post.content),
            const SizedBox(height: 16),
            _buildPostActions(post),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(ProfileModel profile, PublicPostModel post) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: profile.avatarUrl != null
              ? NetworkImage(profile.avatarUrl!)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  profile.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 5),
                if (profile.isVerified)
                  const Icon(Icons.verified, color: Colors.blue, size: 16),
              ],
            ),
            Text(
              _formatDate(post.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostActions(PublicPostModel post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildLikeButton(post),
            _buildCommentButton(post),
            _buildShareButton(post),
          ],
        ),
      ],
    );
  }

  Widget _buildLikeButton(PublicPostModel post) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            post.isLiked ? Icons.favorite : Icons.favorite_border,
            color: post.isLiked ? Colors.red : null,
          ),
          onPressed: () => _toggleLike(post),
        ),
        Text('${post.likeCount}'),
      ],
    );
  }

  Widget _buildCommentButton(PublicPostModel post) {
    return IconButton(
      icon: const Icon(Icons.comment),
      onPressed: () => _showComments(post),
    );
  }

  Widget _buildShareButton(PublicPostModel post) {
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () => _sharePost(post),
    );
  }

  void _toggleLike(PublicPostModel post) async {
    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    await ref.read(supabaseServiceProvider).toggleLike(
          postId: post.id,
          ownerId: post.userId,
          ref: ref,
        );

    ref
        .read(userProfileProvider(widget.userId).notifier)
        .updatePost(updatedPost);
  }

  void _toggleFollow(String userId) {
    ref.read(userProfileProvider(widget.userId).notifier).toggleFollow(userId);
  }

  void _showComments(PublicPostModel post) {
    showCommentsBottomSheet(context, ref, post.id, post.userId);
  }

  void _sharePost(PublicPostModel post) {
    String shareText =
        'کاربر ${post.username} به شما ارسال کرد: \n\n${post.content}';
    Share.share(shareText);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

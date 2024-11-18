import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/ProfileModel.dart';
import '../../../provider/provider.dart';
import '../../../util/widgets.dart';
// در فایل ProfileScreen:

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider(userId));
    final getprofile = ref.watch(profileProvider);
    final currentcolor = ref.watch(themeProvider);
    final currentUser = ref.watch(authProvider); // کاربر جاری را بازیابی کنید.

    return Scaffold(
      body: profileState == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  floating: false,
                  pinned: true,
                  title: Text(profileState.username),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        CustomDrawer(getprofile, currentcolor, context);
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildProfileHeader(
                        context, profileState, currentUser?.id ?? ''),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildPostsList(profileState);
                    },
                    childCount: 1,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, ProfileModel profile, String currentUserId) {
    final bool isCurrentUserProfile = currentUserId == profile.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const Spacer(),
                  isCurrentUserProfile
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/editeProfile');
                          },
                          child: const Text('Edit Profile'),
                        )
                      : Consumer(
                          builder: (context, ref, _) => ElevatedButton(
                            onPressed: () => ref
                                .read(userProfileProvider(userId).notifier)
                                .toggleFollow(userId),
                            child: Text(
                                profile.isFollowed ? 'Following' : 'Follow'),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 16),
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
              Row(
                children: [
                  Text('${profile.followersCount} followers'),
                  const SizedBox(width: 16),
                  if (profile.isVerified)
                    Row(
                      children: const [
                        Icon(Icons.verified, color: Colors.blue, size: 16),
                        SizedBox(width: 4),
                        Text('Verified'),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList(ProfileModel profile) {
    if (profile.posts.isEmpty) {
      return const Center(
        child: Text('هنوز پستی وجود ندارد'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: profile.posts.length,
      itemBuilder: (context, index) {
        final post = profile.posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        Text(
                          profile.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                ),
                const SizedBox(height: 12),
                Text(post.content),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                      icon: Icons.favorite_border,
                      count: post.likeCount,
                      onPressed: () {},
                    ),
                    _buildActionButton(
                      icon: Icons.comment_outlined,
                      count: 0,
                      onPressed: () {},
                    ),
                    _buildActionButton(
                      icon: Icons.repeat,
                      count: 0,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        if (count > 0) Text(count.toString()),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

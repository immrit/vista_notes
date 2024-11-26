import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vistaNote/util/widgets.dart';
import 'package:vistaNote/view/screen/PublicPosts/profileScreen.dart';
import '../../../provider/provider.dart';
import '../../../util/const.dart';
import 'PostDetailPage.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final getprofile = ref.watch(profileProvider);
    final currentcolor = ref.watch(themeProvider);
    return Scaffold(
      endDrawer: CustomDrawer(getprofile, currentcolor, context),
      appBar: AppBar(
        title: const Text('اعلان ها'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
        },
        child: notifications.isEmpty
            ? const Center(child: Text('اعلان جدیدی وجود نداره'))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: notification.avatarUrl.isEmpty
                              ? const AssetImage(defaultAvatarUrl)
                              : NetworkImage(notification.avatarUrl),
                        ),
                        title: Row(
                          children: [
                            Text(notification.username),
                            const SizedBox(width: 5),
                            if (notification.userIsVerified)
                              const Icon(Icons.verified,
                                  color: Colors.blue, size: 16),
                          ],
                        ),
                        subtitle: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(notification.content,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        trailing: Icon(
                          notification.isRead
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: notification.isRead
                              ? Colors.green
                              : const Color.fromARGB(255, 137, 127, 127),
                        ),
                        onTap: () {
                          if (notification.type == 'follow') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userId: notification.senderId,
                                  username: notification.username,
                                ),
                              ),
                            );
                          } else if (notification.type == 'like' ||
                              notification.type == 'comment' ||
                              notification.type == 'mention') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailsPage(
                                    postId: notification.PostId),
                              ),
                            );
                          }
                        },
                      ),
                      Divider(
                        endIndent: 20,
                        indent: 20,
                        color: Colors.grey[200],
                      )
                    ],
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () async {
            ref.refresh(notificationsProvider);
          }),
    );
  }
}

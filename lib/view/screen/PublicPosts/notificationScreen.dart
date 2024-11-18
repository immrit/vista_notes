import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/provider.dart';
import '../../../util/const.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
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
                        title: Text(notification.username),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/provider.dart';
import '../../../util/const.dart';

class NotificationsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('اعلان ها'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
        },
        child: notifications.isEmpty
            ? Center(child: Text('اعلان جدیدی وجود نداره'))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: notification.avatarUrl.isEmpty
                          ? AssetImage(defaultAvatarUrl)
                          : NetworkImage(notification.avatarUrl),
                    ),
                    title: Text(notification.username),
                    subtitle: Text(notification.content),
                    trailing: Icon(
                      notification.isRead
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: notification.isRead
                          ? Colors.green
                          : const Color.fromARGB(255, 137, 127, 127),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

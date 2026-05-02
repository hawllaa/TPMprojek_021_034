import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';
import 'widgets/notification_bottom_nav.dart';

const Color colorPinkDark = Color(0xFFCF7486);

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});

  @override
  State<UserNotificationScreen> createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  final NotificationController _controller = NotificationController();

  @override
  void initState() {
    super.initState();
    _controller.loadUserNotifications().then((_) {
      if (mounted) setState(() {});
    });
    _controller.subscribeUserNotifications();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF4F6),
      appBar: AppBar(
        title: const Text("Notifikasi",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: colorPinkDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: colorPinkDark))
          : _controller.userNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text("Belum ada notifikasi baru.",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.userNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = _controller.userNotifications[index];
                    return GestureDetector(
                      onTap: () => _controller.markAsRead(notif.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notif.isRead
                              ? Colors.white
                              : const Color(0xFFFFE6ED),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: notif.isRead
                                ? Colors.transparent
                                : colorPinkDark.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  colorPinkDark.withOpacity(0.2),
                              child: const Icon(
                                  Icons.notifications_active,
                                  color: colorPinkDark),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${notif.createdAt.hour}:${notif.createdAt.minute.toString().padLeft(2, '0')} WIB",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: colorPinkDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: const NotificationBottomNav(),
    );
  }
}

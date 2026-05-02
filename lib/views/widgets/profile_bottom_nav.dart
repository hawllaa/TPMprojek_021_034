import 'package:flutter/material.dart';
import 'package:photocard/main.dart' as main;
import 'package:photocard/views/collection_screen.dart';
import 'package:photocard/views/home_screen.dart';
import 'package:photocard/views/chat_screen.dart';
import 'package:photocard/views/user_notification_screen.dart';


class ProfileBottomNav extends StatelessWidget {
  const ProfileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: const Border(
            top: BorderSide(color: Color(0xFFF3E3E8), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const CollectPhotocardPage())),
              child: const Icon(Icons.image_search,
                  color: Color(0xFFFDD4DD), size: 30),
            ),

            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatiePage())),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFFFDD4DD), size: 30),
            ),

            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HomePage())),
              child: const Icon(Icons.home,
                  color: Color(0xFFFDD4DD), size: 30),
            ),

            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserNotificationScreen())),
              child: const Icon(Icons.notifications_none, color: Color(0xFFFDD4DD), size: 33),
            ),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: main.colorPinkDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

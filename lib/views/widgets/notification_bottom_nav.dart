import 'package:flutter/material.dart';
import 'package:photocard/main.dart' as main;
import 'package:photocard/views/collection_screen.dart';
import 'package:photocard/views/profile_screen.dart';
import '../chat_screen.dart';

class NotificationBottomNav extends StatelessWidget {
  const NotificationBottomNav({super.key});

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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CollectPhotocardPage()),
              ),
              child: const Icon(Icons.image_search,
                  color: Color(0xFFFDD4DD), size: 30),
            ),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatiePage()),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFFFDD4DD), size: 30),
            ),

            GestureDetector(
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Icon(Icons.home_outlined, 
                  color: Color(0xFFFDD4DD), size: 33), 
            ),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: main.colorPinkDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications, color: Colors.white, size: 30),
            ),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
              child: const Icon(Icons.person_outline, color: Color(0xFFFDD4DD), size: 33),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../views/widgets/auth_form_area.dart';

const colorPinkDark = Color(0xFFCF7486);

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(child: _buildOnboardingImage()),
                const Expanded(child: AuthFormArea()),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: constraints.maxHeight * 0.35,
                    width: double.infinity,
                    child: _buildOnboardingImage(),
                  ),
                  const AuthFormArea(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOnboardingImage() {
    return Container(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/on_boarding.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: colorPinkDark.withOpacity(0.3),
              child: const Icon(
                Icons.image,
                size: 50,
                color: Color.fromARGB(255, 255, 165, 208),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

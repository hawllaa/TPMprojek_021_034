import 'package:flutter/material.dart';
import '../../../../controllers/auth_controller.dart';

const colorPinkDark = Color(0xFFCF7486);

class LoginForm extends StatefulWidget {
  final AuthController controller;
  final Future<void> Function(String role) onSuccess; 

  const LoginForm({
    super.key,
    required this.controller,
    required this.onSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final result = await widget.controller.login(
      _emailCtrl.text,
      _passCtrl.text,
    );

    if (!mounted) return;

    if (result != "error") {
      await widget.onSuccess(result); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Gagal! Periksa Email/Password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                hintText: "Enter your email",
                prefixIcon: Icon(Icons.email_outlined, color: colorPinkDark),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: "Enter your password",
                prefixIcon: const Icon(Icons.lock_outline, color: colorPinkDark),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: colorPinkDark,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
            ),
            const SizedBox(height: 20),
            widget.controller.isLoading
                ? const CircularProgressIndicator(color: colorPinkDark)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPinkDark,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Sign In"),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../controllers/auth_controller.dart';

const colorPinkDark = Color(0xFFCF7486);

class RegisterForm extends StatefulWidget {
  final AuthController controller;
  final VoidCallback onSuccess;

  const RegisterForm({
    super.key,
    required this.controller,
    required this.onSuccess,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final success = await widget.controller.register(
      _nameCtrl.text,
      _emailCtrl.text,
      _passCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daftar Gagal!")),
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
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: "Full Name",
                prefixIcon: Icon(Icons.person_outline, color: colorPinkDark),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                hintText: "Email",
                prefixIcon: Icon(Icons.email_outlined, color: colorPinkDark),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Password",
                prefixIcon: Icon(Icons.lock_outline, color: colorPinkDark),
              ),
            ),
            const SizedBox(height: 20),
            widget.controller.isLoading
                ? const CircularProgressIndicator(color: colorPinkDark)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPinkDark,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Sign Up"),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

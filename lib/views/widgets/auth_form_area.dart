import 'package:flutter/material.dart';
import 'package:photocard/views/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/auth_controller.dart';
import 'login_form.dart';
import 'register_form.dart';

const colorPinkDark = Color(0xFFCF7486);
const colorPinkLigh = Color(0xFFFFE6ED);

class AuthFormArea extends StatefulWidget {
  const AuthFormArea({super.key});

  @override
  State<AuthFormArea> createState() => _AuthFormAreaState();
}

class _AuthFormAreaState extends State<AuthFormArea>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _controller = AuthController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndBiometric();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAndBiometric() async {
    final isLoggedIn = await _controller.checkLoginStatus();
    if (isLoggedIn && mounted) {
      _runBiometric();
    }
  }

  Future<void> _runBiometric() async {
  final authenticated = await _controller.authenticateBiometric();
  if (authenticated && mounted) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    if (data != null && data['is_admin'] == true) {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }
}

  Future<void> _onLoginSuccess(String role) async {
    await _controller.saveLoginState();
    if (!mounted) return;

    if (role == "admin") {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else {
      _runBiometric();
    }
  }

  Future<void> _onAuthSuccess() async {
    await _controller.saveLoginState();
    if (mounted) _runBiometric();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorPinkLigh,
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: colorPinkDark,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: colorPinkDark,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Sign In'),
                Tab(text: 'Sign Up'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Hello Again!",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorPinkDark),
          ),
          const SizedBox(height: 4),
          const Text(
            "Sign in to your account",
            style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 189, 178, 183)),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 350,
            child: TabBarView(
              controller: _tabController,
              children: [
                LoginForm(
                  controller: _controller,
                  onSuccess: _onLoginSuccess, 
                ),
                RegisterForm(
                  controller: _controller,
                  onSuccess: _onAuthSuccess, 
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
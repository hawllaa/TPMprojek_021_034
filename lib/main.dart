import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'views/auth_screen.dart';
import 'views/admin_dashboard.dart';
import 'views/admin_upload_screen.dart';
import 'views/home_screen.dart';

const colorPinkLigh = Color(0xFFFFE6ED);
const colorPinkDark = Color(0xFFCF7486);
const colorTextDark = Color(0xFF4A4A4A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  await Supabase.initialize(
    url: 'https://thctnkrlugdurcsmlkxl.supabase.co',
    anonKey: 'sb_publishable_mkKOOZlvA1FAqX7S3yhgSw_9mqnLNr3',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koleksi PC K-Pop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: colorPinkLigh,
        primaryColor: colorPinkDark,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/admin_upload': (context) => const AdminUploadScreen(),
      },
    );
  }
}
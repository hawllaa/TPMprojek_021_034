import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_model.dart';

class AuthController extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthModel _authModel = AuthModel();
  AuthModel get authModel => _authModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _authModel = _authModel.copyWith(isLoggedIn: isLoggedIn);
    notifyListeners();
    return isLoggedIn;
  }

  Future<void> saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    _authModel = _authModel.copyWith(isLoggedIn: true);
    notifyListeners();
  }

  Future<bool> authenticateBiometric() async {
    try {
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      if (!isDeviceSupported || !canCheckBiometrics) {
        debugPrint("Biometric tidak tersedia");
        return false;
      }

      final List<BiometricType> available = await _localAuth.getAvailableBiometrics();

      if (available.isEmpty) {
        debugPrint("Tidak ada fingerprint/face id terdaftar");
        return false;
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan sidik jari untuk masuk',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return authenticated;
    } catch (e) {
      debugPrint("Biometric Error: $e");
      return false;
    }
  }

  Future<String> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return "error";

    _setLoading(true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('is_admin')
            .eq('id', response.user!.id)
            .maybeSingle();

        _authModel = _authModel.copyWith(
          userId: response.user!.id,
          isLoggedIn: true,
        );
        notifyListeners();

        if (data != null && data['is_admin'] == true) {
          return "admin";
        } else {
          return "user";
        }
      }
      return "error";
    } catch (e) {
      debugPrint("Login Error: $e");
      return "error";
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) return false;

    _setLoading(true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name},
      );

      if (response.user != null) {
        try {
          await Supabase.instance.client.from('profiles').insert({
            'id': response.user!.id,
            'is_admin': false, 
          });
        } catch (insertError) {
          debugPrint("Insert Profile Error: $insertError");
        }

        _authModel = _authModel.copyWith(
          userId: response.user!.id,
          isLoggedIn: true,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Register Error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
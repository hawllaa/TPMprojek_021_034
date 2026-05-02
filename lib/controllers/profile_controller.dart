import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileController extends ChangeNotifier {
  ProfileModel? profile;
  bool isLoading = true;
  bool isSaving = false;

  final _client = Supabase.instance.client;

  Future<void> loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final collections = await _client
          .from('collections')
          .select('id')
          .eq('user_id', user.id);

      final totalCollected = (collections as List).length;

      String? avatarUrl;
      try {
        final profileData = await _client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (profileData != null) {
          avatarUrl = profileData['avatar_url'];
        }
      } catch (_) {}

      profile = ProfileModel(
        id: user.id,
        fullName: user.userMetadata?['full_name'] ?? 'Kpopper',
        email: user.email ?? '',
        avatarUrl: avatarUrl,
        totalCollected: totalCollected,
      );
    } catch (e) {
      debugPrint("ERROR LOAD PROFILE: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<String?> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (picked == null) return null;

    isSaving = true;
    notifyListeners();

    try {
      debugPrint("MULAI UPLOAD...");
      final user = _client.auth.currentUser;
      debugPrint("USER: ${user?.id}");
      if (user == null) return null;

      final file = File(picked.path);
      debugPrint("FILE PATH: ${picked.path}");
      final ext = picked.path.split('.').last;
      debugPrint("EXT: $ext");
      final path = "${user.id}/avatar.$ext";
      debugPrint("STORAGE PATH: $path");

      await _client.storage.from('avatars').upload(
            path,
            file,
            fileOptions:
                FileOptions(upsert: true, contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
          );

      final url = _client.storage.from('avatars').getPublicUrl(path);
      final urlWithBust = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      await _client.from('profiles').upsert({
        'id': user.id,
        'avatar_url': urlWithBust, 
      });
      profile = profile?.copyWith(avatarUrl: urlWithBust);
      notifyListeners();
      return "Foto profil berhasil diperbarui 💗";
    } catch (e) {
      debugPrint("ERROR UPLOAD AVATAR: $e");
      return "Gagal mengupload foto.";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> updateName(String newName) async {
    if (newName.trim().isEmpty) return "Nama tidak boleh kosong.";

    isSaving = true;
    notifyListeners();

    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': newName.trim()}),
      );

      profile = profile?.copyWith(fullName: newName.trim());
      notifyListeners();
      return "Nama berhasil diperbarui 💗";
    } catch (e) {
      debugPrint("ERROR UPDATE NAME: $e");
      return "Gagal memperbarui nama.";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    if (newPassword.length < 6) {
      return "Password minimal 6 karakter.";
    }

    isSaving = true;
    notifyListeners();

    try {
      final email = profile?.email ?? '';
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return "Password berhasil diubah 💗";
    } on AuthException catch (e) {
      debugPrint("AUTH ERROR: $e");
      if (e.message.toLowerCase().contains('invalid')) {
        return "Password lama salah.";
      }
      return "Gagal mengubah password.";
    } catch (e) {
      debugPrint("ERROR CHANGE PASSWORD: $e");
      return "Gagal mengubah password.";
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

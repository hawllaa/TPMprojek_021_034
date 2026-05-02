import 'package:flutter/material.dart';
import 'package:photocard/main.dart' as main;

import '../../controllers/profile_controller.dart';
import 'widgets/profile_bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = ProfileController();
  final _nameController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _controller.loadProfile().then((_) {
      if (mounted) {
        _nameController.text = _controller.profile?.fullName ?? '';
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handlePickAvatar() async {
    final msg = await _controller.pickAndUploadAvatar();
    if (msg != null && mounted) {
      _showSnack(msg);
      setState(() {});
    }
  }

  Future<void> _handleUpdateName() async {
    final msg = await _controller.updateName(_nameController.text);
    if (msg != null && mounted) {
      _showSnack(msg);
      setState(() {});
    }
  }

  Future<void> _handleChangePassword() async {
    final msg = await _controller.changePassword(
      _oldPassController.text,
      _newPassController.text,
    );
    if (msg != null && mounted) {
      _showSnack(msg);
      if (msg.contains('berhasil')) {
        _oldPassController.clear();
        _newPassController.clear();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE6ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: main.colorPinkDark),
        title: const Text(
          "Profil Saya",
          style: TextStyle(
            color: main.colorPinkDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: main.colorPinkDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 28),

                  _buildStatsCard(),
                  const SizedBox(height: 20),

                  _buildCard(
                    title: "Nama",
                    child: Column(
                      children: [
                        _inputField(
                          controller: _nameController,
                          hint: "Nama lengkap",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _pinkButton(
                          label: "Simpan Nama",
                          onTap: _controller.isSaving
                              ? null
                              : _handleUpdateName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCard(
                    title: "Ganti Password",
                    child: Column(
                      children: [
                        _inputField(
                          controller: _oldPassController,
                          hint: "Password lama",
                          icon: Icons.lock_outline,
                          obscure: _obscureOld,
                          toggleObscure: () =>
                              setState(() => _obscureOld = !_obscureOld),
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          controller: _newPassController,
                          hint: "Password baru (min. 6 karakter)",
                          icon: Icons.lock_reset,
                          obscure: _obscureNew,
                          toggleObscure: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        const SizedBox(height: 12),
                        _pinkButton(
                          label: "Ubah Password",
                          onTap: _controller.isSaving
                              ? null
                              : _handleChangePassword,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: const ProfileBottomNav(),
    );
  }

  Widget _buildAvatarSection() {
    final avatarUrl = _controller.profile?.avatarUrl;
    return Column(
      children: [
        GestureDetector(
          onTap: _handlePickAvatar,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: main.colorPinkDark, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: main.colorPinkDark.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: const Color(0xFFFFD6DF),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person,
                          size: 56, color: main.colorPinkDark)
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: main.colorPinkDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _controller.profile?.fullName ?? '',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: main.colorPinkDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _controller.profile?.email ?? '',
          style: const TextStyle(
            fontSize: 13,
            color: Color.fromARGB(255, 189, 178, 183),
          ),
        ),
        if (_controller.isSaving) ...[
          const SizedBox(height: 10),
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: main.colorPinkDark),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: main.colorPinkDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: main.colorPinkDark.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_album_outlined,
              color: Colors.white70, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_controller.profile?.totalCollected ?? 0}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "Photocard di-collect",
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: main.colorPinkDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: main.colorPinkDark),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: main.colorPinkDark,
                  size: 20,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFFF5F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _pinkButton(
      {required String label, required VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: main.colorPinkDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: main.colorPinkDark.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}

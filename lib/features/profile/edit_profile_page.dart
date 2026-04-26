import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;

  // change password
  final _oldPw = TextEditingController();
  final _newPw = TextEditingController();
  bool _changingPw = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthService>().currentUser;
    _name = TextEditingController(text: u?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _oldPw.dispose();
    _newPw.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context
          .read<AuthService>()
          .updateProfile(displayName: _name.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePw() async {
    if (_oldPw.text.isEmpty || _newPw.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới tối thiểu 6 ký tự')),
      );
      return;
    }
    setState(() => _changingPw = true);
    try {
      await context.read<AuthService>().changePassword(
            oldPassword: _oldPw.text,
            newPassword: _newPw.text,
          );
      if (!mounted) return;
      _oldPw.clear();
      _newPw.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đổi mật khẩu')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppPalette.of(context).backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _form,
                  child: AppTextField(
                    label: 'Tên hiển thị',
                    icon: Icons.person_outline,
                    controller: _name,
                    validator: (v) =>
                        validateNotEmpty(v, label: 'Tên hiển thị'),
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Lưu thay đổi',
                  icon: Icons.save_rounded,
                  loading: _saving,
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Mật khẩu hiện tại',
                  icon: Icons.lock_outline,
                  controller: _oldPw,
                  obscure: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Mật khẩu mới',
                  icon: Icons.lock_outline,
                  controller: _newPw,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Đổi mật khẩu',
                  icon: Icons.lock_reset_rounded,
                  loading: _changingPw,
                  onPressed: _changePw,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

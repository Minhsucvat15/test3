import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/animated_logo.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/auth_service.dart';
import '../home/home_shell.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register';
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu nhập lại không khớp')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final user = await auth.register(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _name.text.trim(),
      );
      await context.read<LibraryRepository>().bind(user.id);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          settings: const RouteSettings(name: HomeShell.routeName),
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, a, __) =>
              FadeTransition(opacity: a, child: const HomeShell()),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AnimatedLogo(size: 80)),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Tạo tài khoản',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Tên hiển thị',
                    icon: Icons.person_outline,
                    controller: _name,
                    validator: (v) =>
                        validateNotEmpty(v, label: 'Tên hiển thị'),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline,
                    controller: _password,
                    obscure: true,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Nhập lại mật khẩu',
                    icon: Icons.lock_outline,
                    controller: _confirm,
                    obscure: true,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Đăng ký',
                    icon: Icons.person_add_alt_1_rounded,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

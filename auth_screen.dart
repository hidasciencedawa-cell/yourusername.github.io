import 'package:flutter/material.dart';

import '../app_repository.dart';
import '../models/app_models.dart';
import '../widgets/shared_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.repository});
  final AppRepository repository;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool busy = false;
  UserRole role = UserRole.customer;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final secretCodeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    secretCodeController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => busy = true);
    String? error;
    if (isLogin) {
      error = await widget.repository.login(email: emailController.text, password: passwordController.text, role: role, secretCode: secretCodeController.text);
    } else {
      error = await widget.repository.register(name: nameController.text, phone: phoneController.text, email: emailController.text, password: passwordController.text, confirmPassword: confirmPasswordController.text, role: role, secretCode: secretCodeController.text);
    }
    if (!mounted) return;
    setState(() => busy = false);
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
      return;
    }
    showAppSnackBar(context, isLogin ? 'Login successful.' : 'Registration successful. Please login.');
    if (!isLogin) {
      setState(() {
        isLogin = true;
        passwordController.clear();
        confirmPasswordController.clear();
        secretCodeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF7F3EA), Color(0xFFEAF6FB), Color(0xFFFFFCF5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 880;
                      return Flex(
                        direction: compact ? Axis.vertical : Axis.horizontal,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF134E4A), Color(0xFF0F766E), Color(0xFF0EA5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _HeroTag(),
                                SizedBox(height: 24),
                                Text('Mount Print Zone', style: TextStyle(fontSize: 38, height: 1.1, color: Colors.white, fontWeight: FontWeight.w800)),
                                SizedBox(height: 16),
                                Text('One dashboard for registration, ordering, customer tracking, services, reports, and payment totals.', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                                SizedBox(height: 28),
                                AuthPoint(title: 'Customer flow', body: 'Browse services, place orders, and monitor order history and notifications.'),
                                AuthPoint(title: 'Admin flow', body: 'Manage services, accept or cancel requests, complete orders, and filter reports by date.'),
                                AuthPoint(title: 'Security basics', body: 'Passwords are hashed before storage and admin actions require the secret code.'),
                              ]),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                SegmentedButton<bool>(segments: const [ButtonSegment<bool>(value: true, label: Text('Login')), ButtonSegment<bool>(value: false, label: Text('Register'))], selected: {isLogin}, onSelectionChanged: (value) => setState(() => isLogin = value.first)),
                                const SizedBox(height: 20),
                                Text(isLogin ? 'Login to your account' : 'Create your printer shop account', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Text(isLogin ? 'Use your email, password, and role to continue.' : 'Register as a customer or admin. Admin accounts require the shop secret code.', style: const TextStyle(color: Color(0xFF5B6B7F))),
                                const SizedBox(height: 24),
                                if (!isLogin) ...[
                                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                                  const SizedBox(height: 14),
                                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
                                  const SizedBox(height: 14),
                                ],
                                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
                                const SizedBox(height: 14),
                                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                                const SizedBox(height: 14),
                                if (!isLogin) ...[
                                  TextField(controller: confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
                                  const SizedBox(height: 14),
                                ],
                                DropdownButtonFormField<UserRole>(value: role, items: UserRole.values.map((item) => DropdownMenuItem(value: item, child: Text(userRoleLabel(item)))).toList(), onChanged: (value) => setState(() => role = value ?? UserRole.customer), decoration: const InputDecoration(labelText: 'Role')),
                                if (role == UserRole.admin) ...[
                                  const SizedBox(height: 14),
                                  TextField(controller: secretCodeController, obscureText: true, decoration: const InputDecoration(labelText: 'Admin Secret Code')),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: const Color(0xFF0F766E)), onPressed: busy ? null : submit, child: Text(busy ? 'Please wait...' : isLogin ? 'Login' : 'Register'))),
                                const SizedBox(height: 14),
                                const Text('Admin login requires a valid secret code.', style: TextStyle(color: Color(0xFF5B6B7F), fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: const Text('Printer Shop Management System', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

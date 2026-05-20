import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@bapenda.go.id');
  final _passwordController = TextEditingController(text: 'integratax');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 56),
            Text(
              'INTEGRATAX.',
              style: GoogleFonts.barlow(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masuk sebagai Administrator IT Bapenda untuk membuka dashboard monitoring.',
              style: AppTypography.bodyMedium(context),
            ),
            const SizedBox(height: 34),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppDecorations.cardElevated(
                accentColor: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LoginField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _LoginField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_rounded,
                    obscureText: true,
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      auth.errorMessage!,
                      style: AppTypography.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.statusError),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Masuk Dashboard'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Mode demo: aplikasi menggunakan lingkungan simulasi untuk kebutuhan evaluasi.',
              style: AppTypography.dataSmall(context),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    ref
        .read(authProvider.notifier)
        .login(_emailController.text, _passwordController.text);
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTypography.bodyLarge(context),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderNormal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderNormal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.role});

  final String role;

  bool get isAdmin => role == 'admin';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (widget.isAdmin) {
        await auth.loginAdmin(_controller.text.trim());
        await ref.read(syncDataProvider.notifier).refresh();
        if (mounted) context.go('/admin');
      } else {
        final phone = _controller.text.replaceAll(RegExp(r'\D'), '');
        if (phone.length < 10) {
          throw Exception('Enter a valid 10-digit phone number');
        }
        await auth.loginParent(phone);
        await ref.read(syncDataProvider.notifier).refresh();
        if (mounted) context.go('/parent');
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Login' : 'Parent Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/role-select'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const AppLogo(size: 90),
            const SizedBox(height: 16),
            Text(AppConstants.schoolName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            if (widget.isAdmin)
              TextField(
                controller: _controller,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              )
            else
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Father or Mother Phone Number',
                  counterText: '',
                  prefixText: '+91 ',
                ),
                onSubmitted: (_) => _submit(),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isAdmin ? 'Admin Login' : 'Parent Login'),
            ),
            const SizedBox(height: 24),
            Text(
              'Need help? Call ${AppConstants.schoolPhone}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

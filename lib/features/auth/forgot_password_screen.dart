import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/constants/colors.dart';
import '../../core/api/auth_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthApi().forgotPassword(_ctrl.text.trim());
      setState(() => _sent = true);
    } catch (_) {
      setState(() =>
          _error = "Xatolik yuz berdi. Qayta urinib ko'ring.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgMain,
      appBar: AppBar(
        title: const Text('Parolni tiklash'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent
                ? Column(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: kGreen, size: 64),
                      const SizedBox(height: 16),
                      const Text('Yuborildi!',
                          style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text(
                          "Parolni tiklash uchun ko'rsatmalar yuborildi.",
                          style: TextStyle(color: kTextSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Kirish sahifasiga qaytish'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.lock_reset_rounded,
                          color: kOrange, size: 64),
                      const SizedBox(height: 16),
                      const Text('Parolni tiklash',
                          style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('Foydalanuvchi nomingizni kiriting',
                          style: TextStyle(color: kTextSecondary)),
                      const SizedBox(height: 32),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: kRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!,
                              style: const TextStyle(color: kRed)),
                        ),
                      TextField(
                        controller: _ctrl,
                        decoration: const InputDecoration(
                          labelText: 'Foydalanuvchi nomi',
                          prefixIcon:
                              Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                              : const Text('Yuborish'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

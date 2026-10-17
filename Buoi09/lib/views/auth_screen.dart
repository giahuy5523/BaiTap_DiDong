import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../utils/ui_helpers.dart';
import '../utils/validation.dart';

class AuthScreen extends StatefulWidget {
  final bool isRegister;

  const AuthScreen({
    super.key,
    this.isRegister = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final controller = AuthController();

      if (widget.isRegister) {
        await controller.register(
          _email.text,
          _password.text,
        );

        if (mounted) {
          Navigator.pop(context, _email.text.trim());
        }
      } else {
        final success = await controller.login(
          _email.text,
          _password.text,
        );

        if (!mounted) return;

        if (success) {
          _password.clear();

          await showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Đăng nhập thành công'),
                content: Text(_email.text.trim()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            },
          );
        } else {
          setState(() {
            _error = 'Email hoặc mật khẩu không đúng.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRegister() async {
    final registeredEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(isRegister: true),
      ),
    );

    if (registeredEmail != null && mounted) {
      _email.text = registeredEmail;
      _password.clear();

      showMessage(
        context,
        'Đăng ký thành công. Hãy đăng nhập.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isRegister ? 'Đăng ký tài khoản' : 'Đăng nhập',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Colors.grey.shade200,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        validator: emailError,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscurePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Nhập mật khẩu.';
                          }

                          if (widget.isRegister && value.length < 6) {
                            return 'Mật khẩu cần ít nhất 6 ký tự.';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      if (widget.isRegister) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPassword,
                          enabled: !_busy,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nhập lại mật khẩu',
                          ),
                          validator: (value) {
                            if (value != _password.text) {
                              return 'Mật khẩu nhập lại không khớp.';
                            }

                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _busy ? null : _submit,
                            child: Text(
                              widget.isRegister
                                  ? 'Đăng ký'
                                  : 'Sign in',
                            ),
                          ),
                          if (!widget.isRegister)
                            ElevatedButton(
                              onPressed: _busy ? null : _openRegister,
                              child: const Text('Register'),
                            ),
                        ],
                      ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
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
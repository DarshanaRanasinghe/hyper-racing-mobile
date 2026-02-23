import 'package:flutter/material.dart';
import '../widgets/input_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _auth = AuthService();
  final _users = UserService();

  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _friendlyAuthError(Object e) {
    final msg = e.toString();
    if (msg.contains('email-already-in-use')) return 'Email already in use.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    return 'Registration failed. Try again.';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cred = await _auth.registerWithEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );

      // ✅ Create user profile in Firestore with presence fields
      await _users.createUserProfile(
        uid: cred.user!.uid,
        username: _usernameCtrl.text,
        email: _emailCtrl.text,
        photoUrl: "", // you can add a real URL later
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful. Please login.')),
      );

      Navigator.pop(context); // back to login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyAuthError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                InputField(
                  hint: 'Username',
                  controller: _usernameCtrl,
                  prefix: const Icon(Icons.person),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                ),
                const SizedBox(height: 12),
                InputField(
                  hint: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(Icons.email),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InputField(
                  hint: 'Password',
                  controller: _passwordCtrl,
                  obscure: true,
                  prefix: const Icon(Icons.lock),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InputField(
                  hint: 'Confirm Password',
                  controller: _confirmCtrl,
                  obscure: true,
                  prefix: const Icon(Icons.lock_outline),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm password';
                    if (v != _passwordCtrl.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Create Account',
                    loading: _loading,
                    onPressed: _register,
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

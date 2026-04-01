import 'package:flutter/material.dart';

import '../main.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.onAccountCreated});

  final ValueChanged<UserProfileData> onAccountCreated;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onAccountCreated(
      UserProfileData(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E7), Color(0xFFF5FFF1)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SignInHero(),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E3527),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FieldBlock(
                          controller: _nameController,
                          label: 'Name',
                          hintText: 'Enter your full name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _FieldBlock(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hintText: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _FieldBlock(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: 'Create your password',
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            if (value.trim().length < 4) {
                              return 'Use at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1F9448),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _SignInHero extends StatelessWidget {
  const _SignInHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFA8C1E), Color(0xFFF4B340)],
        ),
      ),
      child: Row(
        children: [
          const _AnimatedLogoBadge(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FreshCart Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Save your name, phone number and password for your account.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLogoBadge extends StatefulWidget {
  const _AnimatedLogoBadge();

  @override
  State<_AnimatedLogoBadge> createState() => _AnimatedLogoBadgeState();
}

class _AnimatedLogoBadgeState extends State<_AnimatedLogoBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final lift = -4 * _controller.value;
        final scale = 1 + (0.05 * _controller.value);
        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: Color(0xFF22B455),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF36523F),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFFAFBF7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF1E9348),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFC94A4A)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFC94A4A)),
            ),
          ),
        ),
      ],
    );
  }
}

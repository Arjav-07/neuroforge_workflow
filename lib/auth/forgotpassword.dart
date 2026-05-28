import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset Link Transmitted Successfully!")));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error sending link")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left, color: ForgeTheme.brandBlue, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/forgotpassword.png", height: 240, errorBuilder: (c, e, s) => const SizedBox(height: 10)),
                  const SizedBox(height: 28),
                  const Text("Forgot Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 8),
                  const Text(
                    "No worries! Enter your email address and we'll send you link to reset your password.",
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 13, color: ForgeTheme.textMuted, height: 1.4)
                  ),
                  const SizedBox(height: 24),
                  buildCustomInputField(hintText: "Email", icon: Icons.mail_outline, controller: emailController),
                  const SizedBox(height: 20),
                  _isLoading 
                      ? const CircularProgressIndicator(color: ForgeTheme.brandBlue)
                      : buildMainActionButton(label: "Send Link", onTap: _handleReset),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text.rich(
                      TextSpan(
                        text: "Remember your password? ",
                        style: TextStyle(color: ForgeTheme.textMuted, fontSize: 13),
                        children: [TextSpan(text: "Sign In", style: TextStyle(color: ForgeTheme.brandBlue, fontWeight: FontWeight.bold))]
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
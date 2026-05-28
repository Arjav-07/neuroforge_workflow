import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool agree = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              icon: const Icon(Icons.chevron_left, color: brandBlue, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/signup.png", height: 220),
                const SizedBox(height: 28),
                const Text(
                  "Create account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Let's get you started with your account",
                  style: TextStyle(fontSize: 13, color: ForgeTheme.textMuted),
                ),
                const SizedBox(height: 24),

                buildCustomInputField(
                  hintText: "Username",
                  icon: Icons.person_outline,
                  controller: _usernameController,
                ),
                buildCustomInputField(
                  hintText: "Email",
                  icon: Icons.mail_outline,
                  controller: _emailController,
                ),
                buildCustomInputField(
                  hintText: "Password",
                  icon: Icons.lock_outline,
                  isObscure: true,
                  controller: _passwordController,
                ),

                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: agree,
                        onChanged: (v) {
                          setState(() {
                            agree = v!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "I agree to the Term & Service and Privacy Policy",
                        style: TextStyle(
                          fontSize: 12,
                          color: ForgeTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                buildMainActionButton(
                  label: "Sign Up",
                  onTap: () async {
                    // 1. Basic structural validation checking
                    if (_emailController.text.trim().isEmpty ||
                        _passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill in your credentials."),
                        ),
                      );
                      return;
                    }

                    try {
                      // 2. Dispatch network registration task
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );

                      if (!context.mounted) return;
                      Navigator.pushNamed(context, '/signin');
                    } on FirebaseAuthException catch (e) {
                      // 3. Catch custom Firebase errors cleanly instead of crashing
                      String message = "Registration failed. Please try again.";

                      if (e.code == 'email-already-in-use') {
                        message =
                            "This email is already registered. Try logging in instead!";
                      } else if (e.code == 'weak-password') {
                        message = "The password provided is too weak.";
                      } else if (e.code == 'invalid-email') {
                        message = "The email address is badly formatted.";
                      }

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: ForgeTheme.brandBlue,
                        ),
                      );
                    } catch (e) {
                      // Catch-all for basic system/network connection failures
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("An unexpected error occurred: $e"),
                          backgroundColor: ForgeTheme.brandBlue,
                        ),
                      );
                    }
                  },
                ),

                // const Padding(
                //   padding: EdgeInsets.symmetric(vertical: 18.0),
                //   child: Text("OR", style: TextStyle(color: kMutedTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                // ),

                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     buildSocialIconCircle("🌐"),
                //     const SizedBox(width: 20),
                //     buildSocialIconCircle("🐱"),
                //   ],
                // ),
                const SizedBox(height: 28),

                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signin'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Already have account? ",
                      style: TextStyle(
                        color: ForgeTheme.textMuted,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.bold,
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

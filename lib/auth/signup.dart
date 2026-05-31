import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool agree = false;
  bool _isLoading = false;

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final username =
        _usernameController.text.trim();

    final email =
        _emailController.text.trim();

    final password =
        _passwordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all fields",
          ),
        ),
      );
      return;
    }

    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please accept Terms & Conditions",
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      UserCredential credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User user = credential.user!;

      await user.updateDisplayName(username);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "username": username,
        "email": email,

        "companyId": "",

        "role": "",

        "onboardingStatus":
            "pending_invite",

        "createdAt":
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Account created successfully"),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/signin',
      );
    } on FirebaseAuthException catch (e) {
      String message =
          "Something went wrong";

      switch (e.code) {
        case "email-already-in-use":
          message =
              "Email already registered";
          break;

        case "weak-password":
          message =
              "Password should be at least 6 characters";
          break;

        case "invalid-email":
          message =
              "Invalid email address";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Error: ${e.toString()}"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeTheme.background,
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: brandBlue,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Image.asset(
                  "assets/images/signup.png",
                  height: 220,
                ),

                const SizedBox(height: 28),

                const Text(
                  "Create account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Let's get you started with your account",
                  style: TextStyle(
                    fontSize: 13,
                    color: ForgeTheme.textMuted,
                  ),
                ),

                const SizedBox(height: 24),

                buildCustomInputField(
                  controller:
                      _usernameController,
                  hintText: "Username",
                  icon:
                      Icons.person_outline,
                ),

                buildCustomInputField(
                  controller:
                      _emailController,
                  hintText: "Email",
                  icon:
                      Icons.mail_outline,
                ),

                buildCustomInputField(
                  controller:
                      _passwordController,
                  hintText: "Password",
                  icon:
                      Icons.lock_outline,
                  isObscure: true,
                ),

                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: agree,
                        onChanged: (value) {
                          setState(() {
                            agree =
                                value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "I agree to the Terms & Service and Privacy Policy",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              ForgeTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _isLoading
                    ? const CircularProgressIndicator(
                        color: brandBlue,
                      )
                    : buildMainActionButton(
                        label: "Sign Up",
                        onTap: _signUp,
                      ),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/signin',
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text:
                          "Already have account? ",
                      style: TextStyle(
                        color:
                            ForgeTheme.textMuted,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: brandBlue,
                            fontWeight:
                                FontWeight.bold,
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
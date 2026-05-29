import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/utils/Landing_gatekeeper.dart';
import 'package:neuroforge_workflow/screen/onboarding_Screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Encapsulated inside state lifecycle to avoid memory leaks and global bleeding
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    // Correctly release controller resources when screen is unmounted
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all layout credentials.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate user credentials with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (!mounted) return;

      // 2. Instantly inspect Firestore to see if this profile is already linked to a workspace
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final String companyId = userData?['companyId'] ?? '';
        final String onboardingStatus = userData?['onboardingStatus'] ?? '';

        // If company tracking token is found and onboarding is finalized, bypass joining setup!
        if (companyId.isNotEmpty && onboardingStatus == 'completed') {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          return;
        }
      }
      
      // Default fallback: Direct to the Join / Create company flow
      Navigator.pushNamedAndRemoveUntil(context, '/join-company', (route) => false);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Authentication failed.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Invalid email or password credentials.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is badly formatted.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen())),
            ),
            // Disabled default native back arrows completely
            automaticallyImplyLeading: false,
            // Right-aligned action deck containing our sign-out control routine
            actions: [],
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
                Image.asset(
                  "assets/images/login.png", 
                  height: 220,
                  errorBuilder: (c, e, s) => const SizedBox(height: 10),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Welcome back!", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Login to continue to workspace", 
                  style: TextStyle(fontSize: 14, color: ForgeTheme.textMuted),
                ),
                const SizedBox(height: 24),

                buildCustomInputField(
                  controller: _emailController, 
                  hintText: "Email", 
                  icon: Icons.mail_outline,
                ),
                buildCustomInputField(
                  controller: _passwordController, 
                  hintText: "Password", 
                  icon: Icons.lock_outline, 
                  isObscure: _isPasswordObscured,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: ForgeTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text(
                        "Forgot Password?", 
                        style: TextStyle(
                          color: brandBlue, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w600, 
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),

                _isLoading
                    ? const CircularProgressIndicator(color: brandBlue)
                    : buildMainActionButton(
                        label: "Sign In",
                        onTap: _handleSignIn,
                      ),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have account? ",
                      style: TextStyle(color: ForgeTheme.textMuted, fontSize: 13),
                      children: [
                        TextSpan(
                          text: "Sign Up", 
                          style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
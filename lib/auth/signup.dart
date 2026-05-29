import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool agree = false;
  bool _isLoading = false; // Added to manage global UI loading state
  
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
              onPressed: () => _isLoading ? null : Navigator.pop(context), // Disable back action when loading
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
                        onChanged: _isLoading 
                          ? null // Disable interaction during network stream
                          : (v) {
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

                // Conditional block toggles between the button and a loading spinner
                _isLoading
                    ? const CircularProgressIndicator(color: brandBlue)
                    : buildMainActionButton(
                        label: "Sign Up",
                        onTap: () async {
                          final username = _usernameController.text.trim();
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          // 1. Basic structural validation
                          if (username.isEmpty || email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill in all fields.")),
                            );
                            return;
                          }

                          if (!agree) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("You must agree to the terms.")),
                            );
                            return;
                          }

                          // Trigger spinner and freeze inputs
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            // 2. Dispatch network registration task
                            UserCredential userCredential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                            // 3. Ensure the user was created successfully
                            if (userCredential.user != null) {
                              final String uid = userCredential.user!.uid;

                              // Update Auth Profile Display Name
                              await userCredential.user!.updateDisplayName(username);
                              await userCredential.user!.reload();

                              // 4. Record user data into Firestore with flow mapping states
                              await FirebaseFirestore.instance.collection('users').doc(uid).set({
                                'uid': uid,
                                'username': username,
                                'email': email,
                                'companyId': '', // Initialized empty
                                'role': '', // Initialized empty until chosen
                                'onboardingStatus': 'pending_invite', // Onboarding milestone tracker
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                            }

                            if (!context.mounted) return;
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Account created successfully!")),
                            );
                            
                            Navigator.pushNamed(context, '/signin');
                          } on FirebaseAuthException catch (e) {
                            final message = e.message ?? 'Authentication error';
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("An error occurred: ${e.toString()}")),
                            );
                          } finally {
                            // Re-enable interactive states if operation terminates or fails
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                      ),

                const SizedBox(height: 28),

                GestureDetector(
                  onTap: () => _isLoading ? null : Navigator.pushNamed(context, '/signin'),
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
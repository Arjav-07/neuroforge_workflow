import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neuroforge_workflow/screen/onboarding_screen.dart';
import 'package:neuroforge_workflow/auth/signin.dart';
import 'package:neuroforge_workflow/auth/joincompany.dart';
import 'package:neuroforge_workflow/screen/home_screen.dart';

class LandingGatekeeper extends StatelessWidget {
  const LandingGatekeeper({super.key});

  /// Evaluates whether this specific app instance requires onboarding views
  Future<bool> _needsOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if the device has never saved the flag or if a user logged out
    return prefs.getBool('show_onboarding_flow') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _needsOnboarding(),
      builder: (context, onboardingSnapshot) {
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 1. Condition Alpha: User is brand new or just logged out -> Load Onboarding first
        if (onboardingSnapshot.data == true) {
          return const OnboardingScreen();
        }

        // 2. Condition Beta: Regular app cold-start -> Verify active background authentication session
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // No user active session found -> Direct to credentials form loop
            if (!authSnapshot.hasData || authSnapshot.data == null) {
              return const SignInScreen();
            }

            // 3. Condition Gamma: User token matches, verify database company mapping parameters
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authSnapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SignInScreen();
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final String companyId = userData?['companyId'] ?? '';
                final String onboardingStatus = userData?['onboardingStatus'] ?? '';

                // Already bound to workspace cleanly -> Direct route to Home, bypassing Onboarding and Joining pages
                if (companyId.isNotEmpty && onboardingStatus == 'completed') {
                  return const HomeScreen();
                }

                // Authenticated account has no active company context assigned yet -> Route to Join Setup
                return const JoinCompanyScreen();
              },
            );
          },
        );
      },
    );
  }

  /// Pipeline invoked when onboarding finishes. Sets device preferences and redirects.
  static void completeOnboardingFlow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Toggle tracking key to false so ordinary app restarts bypass onboarding slides
    await prefs.setBool('show_onboarding_flow', false);

    final user = FirebaseAuth.instance.currentUser;

    if (!context.mounted) return;

    // Route evaluation path directly following onboarding completion
    if (user == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
      return;
    }

    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!context.mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final String companyId = userData?['companyId'] ?? '';
        final String onboardingStatus = userData?['onboardingStatus'] ?? '';

        if (companyId.isNotEmpty && onboardingStatus == 'completed') {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          return;
        }
      }

      Navigator.pushNamedAndRemoveUntil(context, '/join-company', (route) => false);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    }
  }
}
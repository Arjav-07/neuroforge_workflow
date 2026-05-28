import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neuroforge_workflow/auth/createcompany.dart';
import 'package:neuroforge_workflow/auth/forgotpassword.dart';
import 'package:neuroforge_workflow/auth/joincompany.dart';
import 'package:neuroforge_workflow/auth/signin.dart';
import 'package:neuroforge_workflow/auth/signup.dart';
import 'package:neuroforge_workflow/firebase_options.dart';
import 'package:neuroforge_workflow/screen/onboarding_Screen.dart';

Future<void>main() async {
  // Guard baseline engine interaction bindings
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Correctly initialize Firebase configurations across native hosts
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Core Engine configuration initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroForge Workflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF304CB1),
        ),
      ),
      // Clean mapping hierarchy using static base references
      initialRoute: '/signup',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/join-company': (context) => const JoinCompanyScreen(),
        '/create-company': (context) => const CreateCompanyScreen(),
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neuroforge_workflow/auth/createcompany.dart';
import 'package:neuroforge_workflow/auth/forgotpassword.dart';
import 'package:neuroforge_workflow/auth/joincompany.dart';
import 'package:neuroforge_workflow/auth/signin.dart';
import 'package:neuroforge_workflow/auth/signup.dart';
import 'package:neuroforge_workflow/core/utils/Landing_gatekeeper.dart';
import 'package:neuroforge_workflow/firebase_options.dart';
import 'package:neuroforge_workflow/screen/choose_role_screen.dart';
import 'package:neuroforge_workflow/screen/home_screen.dart';
import 'package:neuroforge_workflow/screen/invitation_screen.dart';
import 'package:neuroforge_workflow/screen/invite_link_screen.dart';
import 'package:neuroforge_workflow/screen/invitepeoplescreen.dart';

Future<void> main() async {
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
      initialRoute: '/',
      routes: {
        // Core Entrance Traffic Guard
        '/': (context) => const LandingGatekeeper(),

        // Authentication Route Layers
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // Workspace Setup Onboarding Layers
        '/join-company': (context) => const JoinCompanyScreen(),
        '/create-company': (context) => const CreateCompanyScreen(),

        // Standardized Dynamic Navigation Targets
        '/choose-role': (context) => const ChooseRoleScreen(),
        '/invitation-screen': (context) => const InvitationScreen(),
        '/invite-link': (context) => const InviteLinkScreen(),
        '/invite-people': (context) => const InviteMembersScreen(),

        // Core App Space Target
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
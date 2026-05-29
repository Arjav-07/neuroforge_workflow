import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the current user's unique UID from Firebase Auth
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? uid = currentUser?.uid;

    return Scaffold(
      backgroundColor: ForgeTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "NeuroForge Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: brandBlue),
            onPressed: () async {
              // Sign out clears the Auth token, triggering your Auth Gate to kick back to login
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: uid == null
            ? const Center(child: Text("No authenticated user found."))
            : FutureBuilder<DocumentSnapshot>(
                // 2. Fetch the document that matches the authenticated UID
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, snapshot) {
                  // State A: Network request is executing
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: brandBlue),
                    );
                  }

                  // State B: An error occurred (e.g., internet dropped, rules violation)
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading profile: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  // State C: Document doesn't exist in Firestore yet
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text("Profile data not found."),
                    );
                  }

                  // State D: Data successfully fetched!
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final String username = userData['username'] ?? 'User';
                  final String email = userData['email'] ?? 'No email associated';

                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            fontSize: 16,
                            color: ForgeTheme.textMuted,
                          ),
                        ),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: ForgeTheme.textMuted,
                          ),
                        ),
                        const Divider(height: 40, thickness: 1),
                        
                        // Placeholder workspace body
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Your workflows will appear here.",
                              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
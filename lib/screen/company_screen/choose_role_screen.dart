import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String _selectedRole = "Project Manager"; // Track active index selection dynamically
  bool _isLoading = false;

  void _handleRoleFinalization() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication session lost. Please login again.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Permanently update the user profile metadata inside Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': _selectedRole,
        'onboardingStatus': 'completed', // Flags onboarding as finalized for the Gatekeeper
      }, SetOptions(merge: true));

      if (!mounted) return;

      // 2. Clear history stack completely and route straight into your main dashboard shell
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to finalize role setup: $e"), backgroundColor: Colors.redAccent),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: brandBlue, size: 30),
          onPressed: () => _isLoading ? null : Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Image.asset("assets/images/signup.png", height: 160, errorBuilder: (c, e, s) => const SizedBox(height: 10)),
              const SizedBox(height: 16),
              const Text("Choose your role", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 6),
              const Text("Select the role that describes you", style: TextStyle(fontSize: 13, color: ForgeTheme.textMuted)),
              const SizedBox(height: 24),
              
              // Interactive Radio Selection Engine Blocks
              _buildRoleSelectableCard("Project Manager", "Plan, coordinate, and deliver projects successfully", Icons.assignment_outlined),
              _buildRoleSelectableCard("Team Member", "Collaborate and contribute to team tasks", Icons.people_outline),
              _buildRoleSelectableCard("Admin", "Manage team, settings, and company resources", Icons.shield_outlined),
              
              const Spacer(),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: brandBlue))
                  : buildMainActionButton(
                      label: "Get Started",
                      onTap: _handleRoleFinalization,
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectableCard(String title, String subtitle, IconData placeholderIcon) {
    final bool isSelected = _selectedRole == title;

    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _selectedRole = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ForgeTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? brandBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFD6D9E6),
              child: Icon(placeholderIcon, color: brandBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: ForgeTheme.textMuted, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Custom Radio Checkmark Circle representation matching screenshot designs
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? brandBlue : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMainActionButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandBlue,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
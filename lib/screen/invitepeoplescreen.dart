import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class InviteMembersScreen extends StatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isActionProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Sends a functional invitation record payload to the cloud database
  void _sendEmailInvitation(String email, String companyId, String companyName) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;

    // Basic email format verification regex
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a valid email format structural definition.")),
      );
      return;
    }

    setState(() => _isActionProcessing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Log a transactional membership invite token record into the backend
      await FirebaseFirestore.instance.collection('invitations').add({
        'companyId': companyId,
        'companyName': companyName,
        'invitedEmail': cleanEmail,
        'senderUid': currentUser?.uid ?? '',
        'status': 'pending',
        'sentAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invitation securely dispatched to $cleanEmail!")),
      );
      _emailController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to process transaction: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically retrieve organizational arguments safely from the modal route map
    final Map<String, dynamic> companyArgs = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    final String companyId = companyArgs['companyId'] ?? '';
    final String companyName = companyArgs['companyName'] ?? 'Your Company';
    final String inviteCode = companyArgs['inviteCode'] ?? '';
    final String inviteUrl = companyArgs['inviteUrl'] ?? '';

    return Scaffold(
      backgroundColor: ForgeTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: brandBlue, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Invite Members",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                "Add people to $companyName",
                style: const TextStyle(fontSize: 13, color: ForgeTheme.textMuted),
              ),
              const SizedBox(height: 24),
              
              // Search/Input Field with Action Add Button
              buildCustomInputField(
                controller: _emailController,
                hintText: "Enter email address",
                icon: Icons.mail_outline,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(color: brandBlue, shape: BoxShape.circle),
                    child: _isActionProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add, color: Colors.white, size: 16),
                            onPressed: () => _sendEmailInvitation(_emailController.text, companyId, companyName),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Suggested",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              
              // Suggested Members List Configuration Block
              Expanded(
                child: ListView(
                  children: [
                    _buildSuggestedMemberTile("Riya Patel", "Product Designer", companyId, companyName),
                    _buildSuggestedMemberTile("Neel Sachapara", "Software Developer", companyId, companyName),
                  ],
                ),
              ),
              
              buildMainActionButton(
                label: "Continue to Links",
                onTap: () {
                  // Keep structural navigation trace intact passing parameters to share deck screen view
                  Navigator.pushNamed(
                    context, 
                    '/invite-link',
                    arguments: {
                      'companyId': companyId,
                      'companyName': companyName,
                      'inviteCode': inviteCode,
                      'inviteUrl': inviteUrl,
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedMemberTile(String name, String role, String companyId, String companyName) {
    bool isTileInvited = false;

    return StatefulBuilder(
      builder: (context, setTileState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ForgeTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF0F2FA),
                child: Text(name[0], style: const TextStyle(color: brandBlue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text(role, style: const TextStyle(fontSize: 12, color: ForgeTheme.textMuted)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTileInvited ? const Color(0xFFE2E6F5) : const Color(0xFFD6D9E6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: isTileInvited 
                  ? null 
                  : () {
                      setTileState(() => isTileInvited = true);
                      // Generates mock email address based on target string structures
                      final mockEmail = "${name.replaceAll(' ', '').toLowerCase()}@neuroforge.com";
                      _sendEmailInvitation(mockEmail, companyId, companyName);
                    },
                child: Text(
                  isTileInvited ? "Sent" : "Invite", 
                  style: const TextStyle(color: brandBlue, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget buildCustomInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: [
          Icon(icon, color: ForgeTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: ForgeTheme.textMuted, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }

  Widget buildMainActionButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ForgeTheme.brandBlue,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
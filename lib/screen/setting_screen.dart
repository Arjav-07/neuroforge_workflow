import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoadingContext = true;
  String _userRole = "TEAM MEMBER";
  String _companyName = "Loading Workspace...";

  @override
  void initState() {
    super.initState();
    _loadUserSessionDetails();
  }

  Future<void> _loadUserSessionDetails() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Fetch current profile configuration node
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        _userRole = (userData['role'] ?? 'Team Member').toString().toUpperCase();
        final String companyId = userData['companyId'] ?? '';

        // 2. Resolve corporate brand string match parameters
        if (companyId.isNotEmpty) {
          final companyDoc = await FirebaseFirestore.instance.collection('companies').doc(companyId).get();
          if (companyDoc.exists && companyDoc.data() != null) {
            _companyName = companyDoc.data()!['name'] ?? 'Your Workspace';
          }
        } else {
          _companyName = "No Linked Workspace";
        }
      }
    } catch (e) {
      debugPrint("Settings initialization pipeline tracer blocked: $e");
      _companyName = "Error Loading Details";
    } finally {
      if (mounted) {
        setState(() => _isLoadingContext = false);
      }
    }
  }

  void _handleLogoutTransaction() async {
    // Structural modal prompt layout ensuring zero unintentional session rejections
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ForgeTheme.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            "Confirm Logout",
            style: TextStyle(fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
          ),
          content: const Text(
            "Are you sure you want to disconnect from your technical workspace session layer?",
            style: TextStyle(color: ForgeTheme.textMuted, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // Highlight destructive actions
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                Navigator.pop(context); // Dismiss the confirm alert modal trace
                await FirebaseAuth.instance.signOut();
                
                if (!mounted) return;
                // Terminate session architecture stacks safely back into security portals
                Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String initialPlaceholderToken = (currentUser?.displayName ?? "U").substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED),
      body: SafeArea(
        child: _isLoadingContext
            ? const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      "Settings",
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 24),

                    // --- 1. USER PROFILE IDENTITY PLACARD CARD ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: ForgeTheme.brandBlue,
                            child: Text(
                              initialPlaceholderToken,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (currentUser?.displayName ?? "Workspace User").toUpperCase(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userRole,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ForgeTheme.brandBlue, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- 2. WORKSPACE MANAGEMENT ANCHORS ---
                    _buildPlacardHeaderLabel("WORKSPACE SYSTEM"),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          _buildSettingsActionRow(Icons.business_center_rounded, "Current Organization", _companyName, isStaticView: true),
                          _buildDividerLine(),
                          _buildSettingsActionRow(Icons.vpn_key_rounded, "Access Code Credentials", "View URL Link tokens", onTap: () {
                            // Wire connection branch hooks mapping your invite screen arguments route here if needed
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- 3. SECURITY & PREFERENCES DECK ---
                    _buildPlacardHeaderLabel("PREFERENCES"),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          _buildSettingsActionRow(Icons.shield_outlined, "Security & Verification", "Password management reset links"),
                          _buildDividerLine(),
                          _buildSettingsActionRow(Icons.notifications_none_rounded, "Push Notification Rules", "Alert rules configurations"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- 4. SECURE DESTRUCTIVE ANCHOR TRIGGER ---
                    GestureDetector(
                      onTap: _handleLogoutTransaction,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                            SizedBox(width: 10),
                            Text(
                              "Disconnect Session",
                              style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlacardHeaderLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 14.0, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildDividerLine() {
    return Divider(color: Colors.black.withOpacity(0.04), thickness: 1, height: 1, indent: 60, endIndent: 16);
  }

  Widget _buildSettingsActionRow(IconData icon, String title, String valSubtitle, {VoidCallback? onTap, bool isStaticView = false}) {
    return InkWell(
      onTap: isStaticView ? null : (onTap ?? () {}),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 18, backgroundColor: const Color(0xFFF2F1ED), child: Icon(icon, color: ForgeTheme.brandBlue, size: 18)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(valSubtitle, style: TextStyle(fontSize: 11, color: ForgeTheme.textMuted.withOpacity(0.8), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (!isStaticView)
              Icon(Icons.chevron_right_rounded, color: ForgeTheme.textMuted.withOpacity(0.4), size: 22),
          ],
        ),
      ),
    );
  }
}
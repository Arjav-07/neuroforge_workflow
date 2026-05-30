import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:neuroforge_workflow/core/constant/theme.dart';

class InviteLinkScreen extends StatelessWidget {
  const InviteLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract routing configuration bundles pushed from workspace setup
    final Map<String, dynamic> companyArgs = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    // Fallback defaults to prevent layout render blocks
    final String inviteCode = companyArgs['inviteCode'] ?? "000000";
    final String inviteUrl = companyArgs['inviteUrl'] ?? "https://neuroforge-workflow.web.app/invite/error";
    final String companyName = companyArgs['companyName'] ?? "Your Workspace";

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
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text("Workspace Credentials", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                const Text("Share access tokens with your team crew", style: TextStyle(fontSize: 13, color: ForgeTheme.textMuted)),
                const SizedBox(height: 32),
                
                // --- 1. EXCLUSIVE COMPANY CODE PANEL BLOCK ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Company Joining Code", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: ForgeTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: brandBlue.withOpacity(0.15), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        inviteCode.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 34, 
                          fontWeight: FontWeight.w900, 
                          color: brandBlue,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 140,
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6D9E6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: inviteCode.toUpperCase()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Joining code copied to clipboard!")),
                            );
                          },
                          icon: const Icon(Icons.copy, color: brandBlue, size: 14),
                          label: const Text("Copy Code", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // --- 2. DYNAMIC VISUAL LINK PANEL BLOCK ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Invite Link Alternative", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ForgeTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.link, color: brandBlue, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              inviteUrl,
                              style: const TextStyle(fontSize: 13, color: brandBlue, fontWeight: FontWeight.w600, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 140,
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6D9E6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: inviteUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invite link copied to clipboard!")),
                            );
                          },
                          icon: const Icon(Icons.link_rounded, color: brandBlue, size: 16),
                          label: const Text("Copy Link", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Secondary Share Action Sheet Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6D9E6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    ),
                    onPressed: () {
                      Share.share(
                        "Join my team workspace '$companyName' on NeuroForge Workflow!\n\nSecure Code: ${inviteCode.toUpperCase()}\nRegistration Link: $inviteUrl",
                        subject: "NeuroForge Workspace Access Keys",
                      );
                    },
                    icon: const Icon(Icons.share_outlined, color: brandBlue, size: 20),
                    label: const Text("Share Credentials", style: TextStyle(color: brandBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),

                // Pipeline Route Target Button — Closes onboarding flow and enters workspace directly
                buildMainActionButton(
                  label: "Enter Workspace",
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:share_plus/share_plus.dart'; // Handles platform-native share intent cards

class InviteLinkScreen extends StatelessWidget {
  const InviteLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Safely extract routing bundle arguments generated during organizational setup
    final Map<String, dynamic> companyArgs = 
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    // Fallback defaults to prevent unexpected null layout render blocks
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text("Invite Link", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              const Text("Anyone with this link can join", style: TextStyle(fontSize: 13, color: ForgeTheme.textMuted)),
              const SizedBox(height: 40),
              
              // Visual Link Container Block
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: ForgeTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.link, color: brandBlue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            inviteUrl,
                            style: const TextStyle(fontSize: 14, color: brandBlue, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 140,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD6D9E6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Link copied to clipboard!")),
                          );
                        },
                        child: const Text("Copy Link", style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Secondary Share Action Button
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
                    // Invokes system drawer popups overlaying contextual info text
                    Share.share(
                      "Join my workspace '$companyName' on NeuroForge Workflow using this registration access token link: $inviteUrl",
                      subject: "NeuroForge Workflow Team Invitation",
                    );
                  },
                  icon: const Icon(Icons.share_outlined, color: brandBlue, size: 20),
                  label: const Text("Share Link", style: TextStyle(color: brandBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // Finalize Workspace Navigation Target Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ForgeTheme.brandBlue,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                child: const Text(
                  "Enter Workspace", 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
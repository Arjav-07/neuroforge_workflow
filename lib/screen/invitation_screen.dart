import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class InvitationScreen extends StatelessWidget {
  const InvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: brandBlue, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Mascot Character Placeholder Image Box
              Image.asset("assets/images/signup.png", height: 180, errorBuilder: (c, e, s) => const Icon(Icons.mail_outline, size: 100, color: brandBlue)),
              const SizedBox(height: 20),
              const Text("You're Invited!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 6),
              const Text("You have been invited by a company", style: TextStyle(fontSize: 13, color: ForgeTheme.textMuted)),
              const SizedBox(height: 28),
              
              // Company Summary Metadata Panel Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ForgeTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    _buildMetaRow("Company", "Apex Solution", isBrandItem: true, prefixLetter: "A"),
                    const Divider(height: 24, thickness: 0.5),
                    _buildMetaRow("Role", "Project Manager"),
                    const Divider(height: 24, thickness: 0.5),
                    _buildMetaRow("Invited by", "Ajay B.", prefixLetter: "A"),
                    const Divider(height: 24, thickness: 0.5),
                    _buildMetaRow("Member", "24"),
                  ],
                ),
              ),
              const Spacer(),
              
              buildMainActionButton(
                label: "Accept Invitation",
                onTap: () => Navigator.pushNamed(context, '/choose-role'),
              ),
              const SizedBox(height: 12),
              
              // Decline Outlined Secondary Action
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: brandBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Decline", style: TextStyle(color: brandBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {bool isBrandItem = false, String? prefixLetter}) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 13, color: ForgeTheme.textMuted, fontWeight: FontWeight.w500))),
        if (prefixLetter != null) ...[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: isBrandItem ? brandBlue : const Color(0xFFD6D9E6), shape: BoxShape.circle),
            child: Text(prefixLetter, style: TextStyle(fontSize: 11, color: isBrandItem ? Colors.white : brandBlue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isBrandItem ? brandBlue : ForgeTheme.textDark),
          ),
        ),
      ],
    );
  }
}
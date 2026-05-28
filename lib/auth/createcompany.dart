import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class CreateCompanyScreen extends StatelessWidget {
  const CreateCompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: ForgeTheme.brandBlue, size: 28), 
          onPressed: () => Navigator.pop(context)
        )
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text("Create a Company", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black))),
              const Center(child: Padding(
                padding: EdgeInsets.only(top: 4.0, bottom: 24.0),
                child: Text("Tell us about your company", style: TextStyle(fontSize: 13, color: ForgeTheme.textMuted)),
              )),

              const Text("Company name", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              buildCustomInputField(hintText: "Enter company name", icon: Icons.business, controller: TextEditingController()),

              const Text("Company slug(optional)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              buildCustomInputField(hintText: "Enter company slug", icon: Icons.link, controller: TextEditingController()),

              const Text("Industry", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              _buildThemeDropdownField(hintText: "Select Industry", icon: Icons.check_circle),

              const Text("Company size", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              _buildThemeDropdownField(hintText: "Select size", icon: Icons.people_outline),
              
              const Text("Add Logo", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  CircleAvatar(
                    radius: 24, 
                    backgroundColor: ForgeTheme.brandBlue, 
                    child: const Text("A", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: kIconCircleBg, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: brandBlue, size: 24),
                  )
                ],
              ),
              const SizedBox(height: 36),

              buildMainActionButton(label: "Create Company", onTap: () {},),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/join-company'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Want to join an existing company? ",
                      style: TextStyle(
                        color: ForgeTheme.textMuted,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: "Join here",
                          style: TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeDropdownField({required String hintText, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: kInputFieldBg, borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(color: kIconCircleBg, shape: BoxShape.circle),
            child: Icon(icon, color: brandBlue, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(hintText, style: const TextStyle(color: kMutedTextColor, fontSize: 14)),
                icon: const Icon(Icons.keyboard_arrow_down, color: kMutedTextColor),
                items: const [],
                onChanged: (val) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
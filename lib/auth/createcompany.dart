import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:neuroforge_workflow/core/utils/invite_engine.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  String? _selectedIndustry;
  String? _selectedSize;
  bool _isLoading = false;

  final List<String> _industries = ['Technology', 'Finance', 'Healthcare', 'Education', 'Other'];
  final List<String> _companySizes = ['1-10 employees', '11-50 employees', '51-200 employees', '201+ employees'];

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  // Visual Custom Layout Dropdown Template 
  Widget _buildThemeDropdownField({required String hintText, required IconData icon, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: kInputFieldBg, borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: const BoxDecoration(color: kIconCircleBg, shape: BoxShape.circle), child: Icon(icon, color: brandBlue, size: 16)),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value, isExpanded: true,
                hint: Text(hintText, style: ForgeTheme.bodyText),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreateCompany() async {
    final companyName = _nameController.text.trim();
    var companySlug = _slugController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (companyName.isEmpty || _selectedIndustry == null || _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all required fields.")));
      return;
    }
    if (user == null) return;

    setState(() => _isLoading = true);
    if (companySlug.isEmpty) companySlug = companyName.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');

    try {
      final String generatedCode = InviteEngine.generateInviteCode();
      final String inviteUrl = "https://neuroforge-workflow.web.app/invite/$generatedCode";

      final companyRef = FirebaseFirestore.instance.collection('companies').doc();
      await companyRef.set({
        'companyId': companyRef.id, 'name': companyName, 'slug': companySlug,
        'industry': _selectedIndustry, 'size': _selectedSize, 'ownerUid': user.uid,
        'inviteCode': generatedCode, 'inviteUrl': inviteUrl, 'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'companyId': companyRef.id, 'role': 'Owner', 'onboardingStatus': 'completed', 
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/invite-link', (route) => false, arguments: {
        'inviteCode': generatedCode, 'inviteUrl': inviteUrl, 'companyName': companyName, 'companyId': companyRef.id,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ForgeTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('show_onboarding_flow', true);
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text("Logout", style: ForgeTheme.bodyText.copyWith(color: brandBlue, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(child: Text("Create a Company", style: ForgeTheme.displayHeader.copyWith(fontSize: 24))),
                const SizedBox(height: 4),
                Center(child: Text("Tell us about your company", style: ForgeTheme.bodyText)),
                const SizedBox(height: 24),
                buildCustomInputField(hintText: "Enter company name", icon: Icons.business, controller: _nameController),
                buildCustomInputField(hintText: "Enter company slug (optional)", icon: Icons.link, controller: _slugController),
                _buildThemeDropdownField(hintText: "Select Industry", icon: Icons.check_circle_outline, value: _selectedIndustry, items: _industries, onChanged: (v) => setState(() => _selectedIndustry = v)),
                _buildThemeDropdownField(hintText: "Select size", icon: Icons.people_outline, value: _selectedSize, items: _companySizes, onChanged: (v) => setState(() => _selectedSize = v)),
                const SizedBox(height: 24),
                _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: brandBlue))
                    : buildMainActionButton(label: "Create Company", onTap: _handleCreateCompany),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
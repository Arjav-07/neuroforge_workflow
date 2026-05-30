import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinCompanyScreen extends StatefulWidget {
  const JoinCompanyScreen({super.key});

  @override
  State<JoinCompanyScreen> createState() => _JoinCompanyScreenState();
}

class _JoinCompanyScreenState extends State<JoinCompanyScreen> {
  // Array matrix managing split input nodes and dynamic focus shifts
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleJoinCompany() async {
    // Combine the 6 split string values into a standardized uppercase alphanumeric slug token
    final String completeCode = _controllers.map((c) => c.text.trim()).join().toUpperCase();
    final user = FirebaseAuth.instance.currentUser;

    if (completeCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete the full 6-digit invite token layout.")),
      );
      return;
    }

    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Scan the backend database collection to locate a matching invitation code mapping
      final companyQuery = await FirebaseFirestore.instance
          .collection('companies')
          .where('inviteCode', isEqualTo: completeCode)
          .limit(1)
          .get();

      if (!mounted) return;

      if (companyQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("The invite code entered is invalid. Please verify and try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Extract matching target meta parameters
      final companyDoc = companyQuery.docs.first;
      final String companyId = companyDoc.id;

      // 2. Safely merge corporate binding references into the active user data manifest
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'companyId': companyId,
        'role': '', // Keeps role unassigned until selected on the subsequent screen view
        'onboardingStatus': 'selecting_role', // Directs routing rules to prompt the role view next
      }, SetOptions(merge: true));

      if (!mounted) return;

      // 3. Clear stack and progress into the upcoming role layout screen block
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/choose-role',
        (route) => false,
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Infrastructure handshake dropped: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents any accidental pop requests via system navigation gestures
      child: Scaffold(
        backgroundColor: ForgeTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          automaticallyImplyLeading: false, 
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('show_onboarding_flow', true);

                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/signin', 
                    (route) => false,
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: brandBlue, 
                    fontSize: 15, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset("assets/images/forgotpassword.png", height: 220, errorBuilder: (c, e, s) => const SizedBox(height: 10)),
                  const SizedBox(height: 28),
                  const Text("Join a Company", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 6),
                  const Text("Enter an invite code to join your company", style: TextStyle(fontSize: 13, color: kMutedTextColor)),
                  const SizedBox(height: 32),
    
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSegmentCodeInput(0),
                      _buildSegmentCodeInput(1),
                      _buildSegmentCodeInput(2),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text("-", style: TextStyle(fontSize: 28, color: brandBlue, fontWeight: FontWeight.bold)),
                      ),
                      _buildSegmentCodeInput(3),
                      _buildSegmentCodeInput(4),
                      _buildSegmentCodeInput(5),
                    ],
                  ),
                  const SizedBox(height: 36),
    
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: brandBlue))
                      : buildMainActionButton(label: "Join Company", onTap: _handleJoinCompany),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text("OR", style: TextStyle(color: kMutedTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
    
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: brandBlue, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/create-company'),
                      child: const Text("Create a New Company", style: TextStyle(color: brandBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentCodeInput(int index) {
    return Container(
      width: 42,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: kInputFieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brandBlue, width: 1.5),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        maxLength: 1,
        textCapitalization: TextCapitalization.characters,
        keyboardType: TextInputType.text, // Allowing generic text characters for custom invite formats
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBlue),
        decoration: const InputDecoration(counterText: "", border: InputBorder.none),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
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
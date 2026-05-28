import 'package:flutter/material.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class JoinCompanyScreen extends StatelessWidget {
  const JoinCompanyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: brandBlue, size: 30), 
          onPressed: () => Navigator.pop(context)
        )
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/forgotpassword.png", height: 220),
                const SizedBox(height: 28),
              const Text("Join a Company", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 6),
              const Text("Enter an invite code to join your company", style: TextStyle(fontSize: 13, color: kMutedTextColor)),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSegmentCodeInput(),
                  _buildSegmentCodeInput(),
                  _buildSegmentCodeInput(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text("-", style: TextStyle(fontSize: 28, color: brandBlue, fontWeight: FontWeight.bold)),
                  ),
                  _buildSegmentCodeInput(),
                  _buildSegmentCodeInput(),
                  _buildSegmentCodeInput(),
                ],
              ),
              const SizedBox(height: 36),

              buildMainActionButton(label: "Join Company", onTap: () {},),
              
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
                  onPressed: () => Navigator.pushNamed(context, '/create-company'),
                  child: const Text("Create a New Company", style: TextStyle(color: brandBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentCodeInput() {
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
      child: const TextField(
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBlue),
        decoration: InputDecoration(counterText: "", border: InputBorder.none),
      ),
    );
  }
}
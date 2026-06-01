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
  String _myCompanyId = "";
  String _currentUsername = "";
  
  // Localized Notification Toggle States
  bool _pushNotificationsEnabled = true;
  bool _emailDigestsEnabled = false;
  bool _taskDeadlinesAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadUserSessionDetails();
  }

  Future<void> _loadUserSessionDetails() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        _userRole = (userData['role'] ?? 'Team Member').toString().toUpperCase().trim();
        _currentUsername = userData['username'] ?? user.displayName ?? "Workspace User";
        _myCompanyId = userData['companyId'] ?? '';

        if (_myCompanyId.isNotEmpty) {
          final companyDoc = await FirebaseFirestore.instance.collection('companies').doc(_myCompanyId).get();
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

  void _showModalSettingsPanel({required String title, required Widget child}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F1ED),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // --- PRIVILEGE GATED ADMIN DASHBOARD ROUTE ---
  void _navigateToAdminDashboardPortal() {
    final bool hasAdminAccess = _userRole == "OWNER" || _userRole == "ADMIN" || _userRole == "PROJECT MANAGER";
    
    if (hasAdminAccess) {
      Navigator.pushNamed(context, '/admin-panel'); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Security Intercept: Administrative permissions strictly required.")),
      );
    }
  }

  void _openChangeRolePanel() {
    final bool isPrivileged = _userRole == "OWNER" || _userRole == "ADMIN" || _userRole == "PROJECT MANAGER";
    
    if (!isPrivileged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Access Denied: Role management is restricted to Owners and Managers.")),
      );
      return;
    }

    String tempSelectedRole = "TEAM MEMBER";
    List<Map<String, dynamic>> contextTeamMembers = [];
    String? selectedMemberUid;

    _showModalSettingsPanel(
      title: "Adjust Team Roles",
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where('companyId', isEqualTo: _myCompanyId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
              }
              
              if (snapshot.hasData && contextTeamMembers.isEmpty) {
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                contextTeamMembers = snapshot.data!.docs
                    .where((doc) => doc.id != currentUid)
                    .map((doc) => {
                          "uid": doc.id, 
                          "name": (doc.data() as Map<String, dynamic>)['username'] ?? 'Anonymous Member', 
                          "role": (doc.data() as Map<String, dynamic>)['role'] ?? 'TEAM MEMBER'
                        })
                    .toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("1. Select Workspace Colleague", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMemberUid,
                        hint: const Text("Choose a teammate"),
                        isExpanded: true,
                        items: contextTeamMembers.map((member) {
                          return DropdownMenuItem<String>(
                            value: member['uid'],
                            child: Text("${member['name']} (${member['role']})"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedMemberUid = val;
                            final currentMember = contextTeamMembers.firstWhere((m) => m['uid'] == val);
                            tempSelectedRole = currentMember['role'].toString().toUpperCase();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("2. Assign Target Privilege Level", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ["OWNER", "ADMIN", "PROJECT MANAGER", "TEAM MEMBER"].contains(tempSelectedRole) ? tempSelectedRole : "TEAM MEMBER",
                        isExpanded: true,
                        items: ["OWNER", "ADMIN", "PROJECT MANAGER", "TEAM MEMBER"].map((role) {
                          return DropdownMenuItem<String>(value: role, child: Text(role));
                        }).toList(),
                        onChanged: selectedMemberUid == null ? null : (val) {
                          setModalState(() => tempSelectedRole = val!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: selectedMemberUid == null ? null : () async {
                      await FirebaseFirestore.instance.collection('users').doc(selectedMemberUid).update({
                        'role': tempSelectedRole,
                      });
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: ForgeTheme.brandBlue, content: Text("Teammate access level successfully updated to $tempSelectedRole")),
                      );
                    },
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: selectedMemberUid == null ? Colors.grey.shade400 : ForgeTheme.brandBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text("Apply Authority Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }

  void _openDeleteOrganizationPanel() {
    if (_userRole != "OWNER") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text("Access Gated: Only the Primary Workspace Owner can delete this organization.")),
      );
      return;
    }

    final TextEditingController confirmController = TextEditingController();

    _showModalSettingsPanel(
      title: "Delete Organization",
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "CRITICAL WARNING: This action will permanently remove '$_companyName' and unlink all standard profiles.",
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "To confirm deletion processing, please type the complete organization string variable exact match: '$_companyName'",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ForgeTheme.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.08))),
              child: TextField(
                controller: confirmController,
                onChanged: (val) => setModalState(() {}),
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Type organization name exact string copy"),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: confirmController.text.trim() != _companyName ? null : () async {
                await FirebaseFirestore.instance.collection('companies').doc(_myCompanyId).delete();
                
                final linkedUsers = await FirebaseFirestore.instance.collection('users').where('companyId', isEqualTo: _myCompanyId).get();
                for (var doc in linkedUsers.docs) {
                  await doc.reference.update({'companyId': '', 'role': 'TEAM MEMBER'});
                }

                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _companyName = "No Linked Workspace";
                  _userRole = "TEAM MEMBER";
                  _myCompanyId = "";
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: Colors.black, content: Text("Organization destroyed. Your environment profile shifted back to sandbox")),
                );
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: confirmController.text.trim() == _companyName ? const Color(0xFFEF4444) : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text("PERMANENTLY PURGE ORGANIZATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSecurityPanel() {
    final User? user = FirebaseAuth.instance.currentUser;
    final TextEditingController usernameController = TextEditingController(text: _currentUsername);
    final TextEditingController emailResetController = TextEditingController(text: user?.email);

    _showModalSettingsPanel(
      title: "Security & Profile Details",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Modify Profile Username", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: usernameController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
              decoration: const InputDecoration(
                border: InputBorder.none, 
                hintText: "Enter new username",
                icon: Icon(Icons.person_outline_rounded, size: 18, color: ForgeTheme.brandBlue)
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final String newName = usernameController.text.trim();
              if (newName.isNotEmpty && user != null) {
                await user.updateDisplayName(newName);
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                  'username': newName,
                });
                
                setState(() {
                  _currentUsername = newName;
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: ForgeTheme.brandBlue, content: Text("Profile username synchronized successfully.")),
                );
              }
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: ForgeTheme.brandBlue, width: 1.5), borderRadius: BorderRadius.circular(20)),
              child: const Center(
                child: Text("Apply Username Changes", style: TextStyle(color: ForgeTheme.brandBlue, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.black.withOpacity(0.08)),
          const SizedBox(height: 12),
          const Text("Account Security Verification Link", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
          const SizedBox(height: 6),
          Text("Trigger a secure pass-key recovery verification token to your registered account below.", style: TextStyle(fontSize: 12, color: ForgeTheme.textMuted.withOpacity(0.8), height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: emailResetController,
              readOnly: true,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.5)),
              decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.alternate_email_rounded, size: 18, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final String email = emailResetController.text.trim();
              if (email.isNotEmpty) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: ForgeTheme.brandBlue, content: Text("Secure password update link dispatched to your inbox.")),
                );
              }
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(color: ForgeTheme.brandBlue, borderRadius: BorderRadius.circular(24)),
              child: const Center(child: Text("Dispatch Password Reset Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
            ),
          ),
        ],
      ),
    );
  }

  void _openNotificationsPanel() {
    _showModalSettingsPanel(
      title: "Push Notification Rules",
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text("Push Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ForgeTheme.textDark)),
              subtitle: const Text("Receive instant mobile status alerts", style: TextStyle(fontSize: 11)),
              activeColor: ForgeTheme.brandBlue,
              value: _pushNotificationsEnabled,
              onChanged: (val) => setModalState(() => setState(() => _pushNotificationsEnabled = val)),
            ),
            Divider(color: Colors.black.withOpacity(0.04)),
            SwitchListTile.adaptive(
              title: const Text("Task Deadlines", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ForgeTheme.textDark)),
              subtitle: const Text("Alert parameters 24 hours prior to end flags", style: TextStyle(fontSize: 11)),
              activeColor: ForgeTheme.brandBlue,
              value: _taskDeadlinesAlerts,
              onChanged: (val) => setModalState(() => setState(() => _taskDeadlinesAlerts = val)),
            ),
            Divider(color: Colors.black.withOpacity(0.04)),
            SwitchListTile.adaptive(
              title: const Text("Email Digests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ForgeTheme.textDark)),
              subtitle: const Text("Weekly structural performance recaps", style: TextStyle(fontSize: 11)),
              activeColor: ForgeTheme.brandBlue,
              value: _emailDigestsEnabled,
              onChanged: (val) => setModalState(() => setState(() => _emailDigestsEnabled = val)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAccessCredentialsPanel() {
    _showModalSettingsPanel(
      title: "Access Code Credentials",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Corporate Token Workspace Identifier", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, color: ForgeTheme.brandBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _myCompanyId.isNotEmpty ? _myCompanyId : "STANDALONE_SANDBOX_MODE",
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text("Give this authorization key to project collaborators to bridge accounts into this administrative segment layout.", style: TextStyle(fontSize: 12, color: ForgeTheme.textMuted.withOpacity(0.7), height: 1.4)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _handleLogoutTransaction() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ForgeTheme.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Confirm Logout", style: TextStyle(fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
          content: const Text("Are you sure you want to disconnect from your technical workspace session layer?", style: TextStyle(color: ForgeTheme.textMuted, fontSize: 14, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
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
    final String initialPlaceholderToken = _currentUsername.isNotEmpty
        ? _currentUsername.substring(0, 1).toUpperCase()
        : "U";

    // Access evaluation for displaying structural panels
    final bool isManagementPrivileged = _userRole == "OWNER" || _userRole == "ADMIN" || _userRole == "PROJECT MANAGER";

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
                    const Text("Settings", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, letterSpacing: -0.5)),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(28),
                        border:Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: ForgeTheme.brandBlue,
                            child: Text(initialPlaceholderToken, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_currentUsername.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                                const SizedBox(height: 4),
                                Text(_userRole, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ForgeTheme.brandBlue, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildPlacardHeaderLabel("Workspace System"),
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 3)),
                      child: Column(
                        children: [
                          _buildSettingsActionRow(Icons.business_center_rounded, "Current Organization", _companyName, isStaticView: true),
                          _buildDividerLine(),
                          _buildSettingsActionRow(Icons.vpn_key_rounded, "Access Code Credentials", "View system workspace token identifier links", onTap: _openAccessCredentialsPanel),
                          
                          if (isManagementPrivileged) ...[
                            _buildDividerLine(),
                            _buildSettingsActionRow(
                              Icons.admin_panel_settings_rounded, 
                              "Admin Console Dashboard", 
                              "Access system analytical logs and dynamic metrics panel", 
                              onTap: _navigateToAdminDashboardPortal,
                              customIconColor: ForgeTheme.brandBlue,
                            ),
                            _buildDividerLine(),
                            _buildSettingsActionRow(
                              Icons.manage_accounts_rounded, 
                              "Manage Team Roles", 
                              "Modify authority parameters for internal members", 
                              onTap: _openChangeRolePanel
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildPlacardHeaderLabel("Preferences & Security"),
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 3)),
                      child: Column(
                        children: [
                          _buildSettingsActionRow(Icons.shield_outlined, "Security & Profile Details", "Update system username credentials and request secure verification links", onTap: _openSecurityPanel),
                          _buildDividerLine(),
                          _buildSettingsActionRow(Icons.notifications_none_rounded, "Push Notification Rules", "Toggle mobile distribution channels and deadline tracking alerts", onTap: _openNotificationsPanel),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_userRole == "OWNER") ...[
                      _buildPlacardHeaderLabel("ADMINISTRATIVE DANGER ZONE"),
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 3)),
                        child: _buildSettingsActionRow(
                          Icons.delete_forever_rounded, 
                          "Purge Organization Data", 
                          "Permanently delete entire organization registry maps from Firestore", 
                          onTap: _openDeleteOrganizationPanel,
                          customIconColor: const Color(0xFFEF4444)
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    const SizedBox(height: 20),
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
                            Text("Disconnect Session", style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.1)),
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
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8)),
    );
  }

  Widget _buildDividerLine() {
    return Divider(color: Colors.black.withOpacity(0.04), thickness: 1, height: 1, indent: 60, endIndent: 16);
  }

  Widget _buildSettingsActionRow(IconData icon, String title, String valSubtitle, {VoidCallback? onTap, bool isStaticView = false, Color? customIconColor}) {
    return InkWell(
      onTap: isStaticView ? null : (onTap ?? () {}),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18, 
              backgroundColor: customIconColor != null ? customIconColor.withOpacity(0.1) : ForgeTheme.background, 
              child: Icon(icon, color: customIconColor ?? ForgeTheme.brandBlue, size: 18)
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: customIconColor ?? ForgeTheme.textDark)),
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
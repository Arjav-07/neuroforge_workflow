import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _todoChecklistItemController = TextEditingController();
  
  bool _isGroupEventMode = false; 
  String _selectedCategory = "Work";
  
  String _userRole = "TEAM MEMBER"; 
  String _myCompanyId = "";
  bool _isLoadingRole = true;

  List<Map<String, dynamic>> _coworkersList = [];
  final List<String> _selectedAssigneeIds = [];
  final List<String> _localTodoSubtasks = [];

  // LIVE DATETIME STATE PARAMETERS
  DateTime _pickedDate = DateTime(2026, 5, 30);
  TimeOfDay _pickedTime = const TimeOfDay(hour: 11, minute: 0);

  @override
  void initState() {
    super.initState();
    _initializeCorporateData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _todoChecklistItemController.dispose();
    super.dispose();
  }

  Future<void> _initializeCorporateData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        final String rawRole = data['role'] ?? 'Team Member';
        _userRole = rawRole.trim(); 
        _myCompanyId = (data['companyId'] ?? '').toString();

        final bool isPrivileged = _userRole == "OWNER" || 
                                  _userRole == "ADMIN" || 
                                  _userRole == "PROJECT MANAGER" || 
                                  _userRole == "Project Manager";
        if (isPrivileged) {
          _isGroupEventMode = true;
        }

        if (_myCompanyId.isNotEmpty) {
          final coworkersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('companyId', isEqualTo: _myCompanyId)
              .get();

          _coworkersList = coworkersSnapshot.docs
              .where((d) => d.id != user.uid) 
              .map((d) => {
                    "uid": d.id,
                    "username": d.data()['username'] ?? 'Team Member',
                    "role": d.data()['role'] ?? 'Employee',
                  })
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error loading profile context: $e");
    }
    setState(() => _isLoadingRole = false);
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2036, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF304CB1),
              onPrimary: Colors.white,
              onSurface: ForgeTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickedDate) {
      setState(() {
        _pickedDate = picked;
      });
    }
  }

  Future<void> _selectTargetTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF304CB1),
              onPrimary: Colors.white,
              onSurface: ForgeTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickedTime) {
      setState(() {
        _pickedTime = picked;
      });
    }
  }

  void _handleSubmitTask() async {
    final String enteredTitle = _titleController.text.trim();
    if (enteredTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title.")),
      );
      return;
    }

    final String normalizedRole = _userRole.toUpperCase();
    final bool isPrivilegedRole = normalizedRole == "OWNER" || 
                                  normalizedRole == "ADMIN" || 
                                  normalizedRole == "PROJECT MANAGER";
    
    if (_isGroupEventMode && !isPrivilegedRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          content: Text("Access Denied: Your role ($_userRole) cannot create workspace cards."),
        ),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String dateKey = "${_pickedDate.year}-${_pickedDate.month.toString().padLeft(2, '0')}-${_pickedDate.day.toString().padLeft(2, '0')}";
    String timeKey = _pickedTime.format(context);

    try {
      if (_isGroupEventMode) {
        // Shared Workspace Team Task Document Generation
        final newGlobalEventRef = FirebaseFirestore.instance.collection('tasks').doc();
        await newGlobalEventRef.set({
          "title": _titleController.text.trim(),
          "location": _locationController.text.trim(),
          "description": _descriptionController.text.trim(),
          "category": _selectedCategory,
          "time": timeKey,
          "priority": "High",
          "createdBy": user.uid,
          "companyId": _myCompanyId,
          "assignedTo": _selectedAssigneeIds,
          "date": dateKey,
          "createdAt": FieldValue.serverTimestamp(),
        });
      } else {
        // Localized Private Personal To-Do Subcollection Document Generation
        final newPersonalTodoRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('personal_todos')
            .doc();
            
        await newPersonalTodoRef.set({
          "title": _titleController.text.trim(),
          "isDone": false,
          "date": dateKey,
          "time": timeKey,
          "companyId": _myCompanyId, // Matches tenant system schemas seamlessly
          "subtasks": _localTodoSubtasks.map((t) => {"title": t, "isDone": false}).toList(),
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF304CB1), 
            content: Text(_isGroupEventMode ? "Workspace Group Task Broadcasted!" : "Personal To-Do Recorded!")
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("FIRESTORE REJECTION CATCH: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent, 
            content: Text("Database Error: ${e.toString()}")
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String normalizedRole = _userRole.toUpperCase();
    final bool canCreateGroupTasks = normalizedRole == "OWNER" || 
                                     normalizedRole == "ADMIN" || 
                                     normalizedRole == "PROJECT MANAGER";

    String formattedDateText = "${_pickedDate.day} ${_getMonthNameShort(_pickedDate.month)} ${_pickedDate.year}";
    String formattedTimeText = _pickedTime.format(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED),
      body: SafeArea(
        child: _isLoadingRole 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF304CB1)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ForgeTheme.surfaceWhite, width: 2)),
                          child: const CircleAvatar(radius: 24, backgroundColor: ForgeTheme.surfaceWhite, backgroundImage: AssetImage("assets/images/profile_avatar.png")),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text((currentUser?.displayName ?? "User").toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(_userRole.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF304CB1), letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                      _buildHeaderIconButton("assets/icons/chat.png", Icons.chat_bubble_outline_rounded),
                      const SizedBox(width: 12),
                      _buildHeaderIconButton("assets/icons/notification.png", Icons.notifications_none_rounded),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text("Create New", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 0.9)),
                  Text(_isGroupEventMode ? "Group Task" : "Personal To-Do", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF304CB1))),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFE2E1DD), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (canCreateGroupTasks) {
                                setState(() => _isGroupEventMode = true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Standard team accounts are restricted to creating personal to-dos.")),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isGroupEventMode ? const Color(0xFF304CB1) : Colors.transparent, 
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  "Workspace Task", 
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800, 
                                    fontSize: 13, 
                                    color: _isGroupEventMode 
                                        ? Colors.white 
                                        : (canCreateGroupTasks ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.15)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isGroupEventMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: !_isGroupEventMode ? const Color(0xFF304CB1) : Colors.transparent, borderRadius: BorderRadius.circular(24)),
                              child: Center(child: Text("Personal To-Do", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: !_isGroupEventMode ? Colors.white : Colors.black.withOpacity(0.4)))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFE2E1DD), borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputFieldLabel(_isGroupEventMode ? "Task Title" : "To-Do Name"),
                        _buildStyledTextField(_titleController, _isGroupEventMode ? "Enter task title" : "What needs to be done?", Icons.add_box_rounded),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputFieldLabel("Target Date"),
                                  _buildPickerTile(Icons.calendar_today_rounded, formattedDateText, () => _selectTargetDate(context)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputFieldLabel("Alert Time"),
                                  _buildPickerTile(Icons.access_time_filled_rounded, formattedTimeText, () => _selectTargetTime(context)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isGroupEventMode 
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  _buildInputFieldLabel("Task Workspace Scope"),
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        _buildCategoryChip("Work"),
                                        _buildCategoryChip("Meeting"),
                                        _buildCategoryChip("Others"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInputFieldLabel("Target Location"),
                                  _buildStyledTextField(_locationController, "Enter workspace branch/URL", Icons.location_on_rounded),
                                  const SizedBox(height: 16),
                                  _buildInputFieldLabel("Context Description"),
                                  _buildStyledTextField(_descriptionController, "Add technical specs or rules", Icons.text_fields_rounded),
                                  const SizedBox(height: 16),
                                  _buildInputFieldLabel("Assign Project Participants"),
                                  _buildCorporateParticipantDropdown(),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  _buildInputFieldLabel("Breakdown Checklist Items (Sub-Tasks)"),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(radius: 20, backgroundColor: Color(0xFF304CB1), child: Icon(Icons.playlist_add_rounded, color: Colors.white, size: 18)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _todoChecklistItemController,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ForgeTheme.textDark),
                                            decoration: InputDecoration(hintText: "Add sub-task...", hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A).withOpacity(0.3)), border: InputBorder.none),
                                            onSubmitted: (value) {
                                              if (value.trim().isNotEmpty) {
                                                setState(() {
                                                  _localTodoSubtasks.add(value.trim());
                                                  _todoChecklistItemController.clear();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF304CB1), size: 26),
                                          onPressed: () {
                                            if (_todoChecklistItemController.text.trim().isNotEmpty) {
                                              setState(() {
                                                _localTodoSubtasks.add(_todoChecklistItemController.text.trim());
                                                _todoChecklistItemController.clear();
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_localTodoSubtasks.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(16)),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _localTodoSubtasks.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.radio_button_off_rounded, size: 16, color: Color(0xFF304CB1)),
                                                const SizedBox(width: 10),
                                                Expanded(child: Text(_localTodoSubtasks[index], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ForgeTheme.textDark))),
                                                GestureDetector(
                                                  onTap: () => setState(() => _localTodoSubtasks.removeAt(index)),
                                                  child: Icon(Icons.close_rounded, size: 16, color: Colors.redAccent.withOpacity(0.6)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                                  child: const Center(child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 15))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _handleSubmitTask,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(color: const Color(0xFF304CB1), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF304CB1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                                  child: Center(child: Text(_isGroupEventMode ? "Deploy Card" : "Save Item", style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15))),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildInputFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: 0.2)),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String hint, IconData leadingIcon) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: const Color(0xFF304CB1), child: Icon(leadingIcon, color: Colors.white, size: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ForgeTheme.textDark),
              decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A).withOpacity(0.3)), border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String valueText, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: const Color(0xFF304CB1), child: Icon(icon, color: Colors.white, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(valueText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)))),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF304CB1) : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
      ),
    );
  }

  Widget _buildCorporateParticipantDropdown() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 55),
      constraints: const BoxConstraints(maxHeight: 280, maxWidth: 300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            const CircleAvatar(radius: 20, backgroundColor: const Color(0xFF304CB1), child: Icon(Icons.people_alt_rounded, color: Colors.white, size: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedAssigneeIds.isEmpty 
                    ? "Select Coworkers (${_coworkersList.length} available)"
                    : "${_selectedAssigneeIds.length} Selected",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A).withOpacity(_selectedAssigneeIds.isEmpty ? 0.3 : 0.8)),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF0F172A).withOpacity(0.4)),
            const SizedBox(width: 12),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        if (_coworkersList.isEmpty) {
          return [const PopupMenuItem(enabled: false, child: Text("No colleagues found in this company."))];
        }
        return _coworkersList.map((employee) {
          final bool isChecked = _selectedAssigneeIds.contains(employee['uid']);
          return PopupMenuItem<String>(
            value: employee['uid'],
            child: StatefulBuilder(
              builder: (context, setPopupState) {
                return CheckboxListTile(
                  title: Text(employee['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ForgeTheme.textDark)),
                  subtitle: Text(employee['role'].toString().toUpperCase(), style: const TextStyle(fontSize: 11, color: Color(0xFF304CB1), fontWeight: FontWeight.w600)),
                  value: isChecked,
                  activeColor: const Color(0xFF304CB1),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedAssigneeIds.add(employee['uid']);
                      } else {
                        _selectedAssigneeIds.remove(employee['uid']);
                      }
                    });
                    setPopupState(() {});
                  },
                );
              },
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildHeaderIconButton(String assetPath, IconData fallbackIcon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: ForgeTheme.surfaceWhite.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: ForgeTheme.surfaceWhite, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Transform.scale(
        scale: 0.45,
        child: Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: const Color(0xFF0F172A), size: 20)),
      ),
    );
  }

  String _getMonthNameShort(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}
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
  String _selectedPriority = "Medium";

  String _userRole = "TEAM MEMBER";
  String _myCompanyId = "";
  bool _isLoadingRole = true;
  bool _isParticipantDropdownOpen = false;

  List<Map<String, dynamic>> _coworkersList = [];
  final List<String> _selectedAssigneeIds = [];
  final List<String> _localTodoSubtasks = [];

  DateTime _pickedDate = DateTime.now();
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

  void _clearWholeFormFields() {
    setState(() {
      _titleController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _todoChecklistItemController.clear();

      _selectedAssigneeIds.clear();
      _localTodoSubtasks.clear();

      _isParticipantDropdownOpen = false;
      _selectedCategory = "Work";
      _selectedPriority = "Medium";

      _pickedDate = DateTime.now();
      _pickedTime = const TimeOfDay(hour: 11, minute: 0);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Form cleared successfully."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _initializeCorporateData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final String rawRole = data['role'] ?? 'Team Member';
        _userRole = rawRole.trim();
        _myCompanyId = (data['companyId'] ?? '').toString();

        final bool isPrivileged =
            _userRole == "OWNER" ||
            _userRole == "ADMIN" ||
            _userRole == "PROJECT MANAGER" ||
            _userRole == "Project Manager";
        if (isPrivileged) {
          setState(() => _isGroupEventMode = true);
        }

        if (_myCompanyId.isNotEmpty) {
          final coworkersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('companyId', isEqualTo: _myCompanyId)
              .get();
          setState(() {
            _coworkersList = coworkersSnapshot.docs
                .where((d) => d.id != user.uid)
                .map((d) {
                  final employeeData = d.data();
                  String displayName = employeeData['username'] ?? '';
                  if (displayName.isEmpty && employeeData['email'] != null) {
                    displayName = employeeData['email'].toString().split('@')[0];
                  }
                  if (displayName.isEmpty) displayName = 'Team Member';
                  return {
                    "uid": d.id,
                    "username": displayName,
                    "role": employeeData['role'] ?? 'Team Member',
                  };
                })
                .toList();
          });
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
              primary: ForgeTheme.brandBlue,
              onPrimary: Colors.white,
              onSurface: ForgeTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickedDate) {
      setState(() => _pickedDate = picked);
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
              primary: ForgeTheme.brandBlue,
              onPrimary: Colors.white,
              onSurface: ForgeTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickedTime) {
      setState(() => _pickedTime = picked);
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

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String dateKey = "${_pickedDate.year}-${_pickedDate.month.toString().padLeft(2, '0')}-${_pickedDate.day.toString().padLeft(2, '0')}";
    String timeKey = _pickedTime.format(context);

    final subtaskListMap = _localTodoSubtasks.map((t) => {"title": t, "isDone": false}).toList();

    try {
      if (_isGroupEventMode) {
        final newGlobalEventRef = FirebaseFirestore.instance.collection('tasks').doc();
        final String taskId = newGlobalEventRef.id;
        final String taskNumber = "NF-${DateTime.now().millisecondsSinceEpoch}";

        await newGlobalEventRef.set({
          "taskId": taskId,
          "taskNumber": taskNumber,
          "title": enteredTitle,
          "location": _locationController.text.trim(),
          "description": _descriptionController.text.trim(),
          "priority": _selectedPriority,
          "category": _selectedCategory,
          "dueDate": dateKey,
          "dueTime": timeKey,
          "deadline": Timestamp.fromDate(
            DateTime(
              _pickedDate.year,
              _pickedDate.month,
              _pickedDate.day,
              _pickedTime.hour,
              _pickedTime.minute,
            ),
          ),
          "status": "pending",
          "isCompleted": false,
          "isOverdue": false,
          "createdBy": user.uid,
          "companyId": _myCompanyId,
          "assignedTo": _selectedAssigneeIds,
          "subtasks": subtaskListMap,
          "createdAt": FieldValue.serverTimestamp(),
          "completedAt": null,
        });
      } else {
        final newPersonalTodoRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('personal_todos')
            .doc();
        final String todoId = newPersonalTodoRef.id;

        await newPersonalTodoRef.set({
          "todoId": todoId,
          "title": enteredTitle,
          "description": _descriptionController.text.trim(),
          "date": dateKey,
          "time": timeKey,
          "category": "Personal",
          "isDone": false,
          "status": "pending",
          "priority": "Medium",
          "companyId": _myCompanyId,
          "subtasks": subtaskListMap,
          "createdAt": FieldValue.serverTimestamp(),
          "completedAt": null,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ForgeTheme.brandBlue,
            content: Text(
              _isGroupEventMode
                  ? "Workspace Group Task Broadcasted!"
                  : "Personal To-Do Recorded!",
            ),
          ),
        );
        _clearWholeFormFields();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            content: Text("Database Error: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    String formattedDateText = "${_pickedDate.day} ${_getMonthNameShort(_pickedDate.month)} ${_pickedDate.year}";
    String formattedTimeText = _pickedTime.format(context);

    return Scaffold(
      backgroundColor: ForgeTheme.background,
      body: SafeArea(
        child: _isLoadingRole
            ? const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue))
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
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
                              Text(
                                (currentUser?.displayName ?? "User").toUpperCase(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userRole.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ForgeTheme.brandBlue, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderIconButton("assets/icons/chat.png", Icons.chat_bubble_outline_rounded),
                        const SizedBox(width: 12),
                        _buildHeaderIconButton("assets/icons/notification.png", Icons.notifications_none_rounded),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text("Create", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ForgeTheme.textDark, height: 0.9)),
                    Text(
                      _isGroupEventMode ? "Group Task" : "Personal To-Do",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ForgeTheme.textDark.withOpacity(0.35)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ForgeTheme.surfaceWhite.withOpacity(0.5),
                        border: Border.all(color: ForgeTheme.surfaceWhite, width: 2),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_userRole.toUpperCase() == "OWNER" || _userRole.toUpperCase() == "ADMIN" || _userRole.toUpperCase() == "PROJECT MANAGER") {
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
                                  color: _isGroupEventMode ? ForgeTheme.brandBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Text(
                                    "Workspace Task",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _isGroupEventMode ? Colors.white : Colors.black.withOpacity(0.4),
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
                                decoration: BoxDecoration(
                                  color: !_isGroupEventMode ? ForgeTheme.brandBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: !_isGroupEventMode ? Colors.white : Colors.transparent, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    "Personal To-Do",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: !_isGroupEventMode ? Colors.white : Colors.black.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:  Colors.white.withOpacity(0.5),
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputFieldLabel(_isGroupEventMode ? "Task Title" : "To-Do Name"),
                          _buildStyledTextField(
                            _titleController,
                            _isGroupEventMode ? "Enter task title" : "What needs to be done?",
                            "assets/icons/event_active.png", // Image Asset Path
                            isMultiLine: false,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputFieldLabel("Target Date"),
                                    _buildPickerTile(
                                      "assets/icons/cal_active.png", // Image Asset Path
                                      formattedDateText,
                                      () => _selectTargetDate(context),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputFieldLabel("Alert Time"),
                                    _buildPickerTile(
                                      "assets/icons/clock.png", // Image Asset Path
                                      formattedTimeText,
                                      () => _selectTargetTime(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          if (_isGroupEventMode) ...[
                            const SizedBox(height: 16),
                            _buildInputFieldLabel("Priority"),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildPriorityChip("Low", _selectedPriority, () => setState(() => _selectedPriority = "Low")),
                                  _buildPriorityChip("Medium", _selectedPriority, () => setState(() => _selectedPriority = "Medium")),
                                  _buildPriorityChip("High", _selectedPriority, () => setState(() => _selectedPriority = "High")),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInputFieldLabel("Task Type / Category"),
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
                            _buildStyledTextField(_locationController, "Enter location/URL", "assets/icons/location.png", isMultiLine: false),
                            const SizedBox(height: 16),
                            _buildInputFieldLabel("Context Description"),
                            _buildStyledTextField(_descriptionController, "Add technical specs or rules", "assets/icons/text.png", isMultiLine: true),
                            const SizedBox(height: 16),
                            _buildInputFieldLabel("Assign Project Participants"),
                            _buildCorporateParticipantDropdown(),
                          ] else ...[
                            const SizedBox(height: 16),
                            _buildInputFieldLabel("Context Description"),
                            _buildStyledTextField(_descriptionController, "Add important personal notes", "assets/icons/text.png", isMultiLine: true),
                          ],

                          const SizedBox(height: 16),
                          _buildInputFieldLabel("Breakdown Checklist Items (Sub-Tasks)"),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(color: ForgeTheme.background, borderRadius: BorderRadius.circular(26)),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: ForgeTheme.brandBlue,
                                  child: Transform.scale(
                                    scale: 0.5,
                                    child: Image.asset("assets/icons/add.png", color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _todoChecklistItemController,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ForgeTheme.textDark),
                                    decoration: InputDecoration(
                                      hintText: "Add sub-task...",
                                      hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A).withOpacity(0.3)),
                                      border: InputBorder.none,
                                    ),
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
                                  icon: Transform.scale(
                                    scale: 0.6,
                                    child: Image.asset("assets/icons/add.png", color: ForgeTheme.brandBlue),
                                  ),
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
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _localTodoSubtasks.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                    child: Row(
                                      children: [
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Image.asset("assets/icons/radio_off.png", color: ForgeTheme.brandBlue),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _localTodoSubtasks[index],
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ForgeTheme.textDark),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() => _localTodoSubtasks.removeAt(index)),
                                          child: Transform.scale(
                                            scale: 0.8,
                                            child: Image.asset("assets/icons/close.png", color: Colors.redAccent.withOpacity(0.6)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _clearWholeFormFields,
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                                    child: const Center(
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B), fontSize: 15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _handleSubmitTask,
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: ForgeTheme.brandBlue,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [BoxShadow(color: ForgeTheme.brandBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    child: Center(
                                      child: Text(
                                        _isGroupEventMode ? "Deploy Card" : "Save Item",
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: 0.2),
      ),
    );
  }

  // Refactored helper to support Image Asset strings cleanly
  Widget _buildStyledTextField(TextEditingController controller, String hint, String assetPath, {required bool isMultiLine}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: ForgeTheme.background, borderRadius: BorderRadius.circular(26)),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isMultiLine ? 4.0 : 0.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: ForgeTheme.brandBlue,
              child: Transform.scale(
                scale: 0.5,
                child: Image.asset(assetPath, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: isMultiLine ? null : 1,
              keyboardType: isMultiLine ? TextInputType.multiline : TextInputType.text,
              textInputAction: isMultiLine ? TextInputAction.newline : TextInputAction.done,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ForgeTheme.textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A).withOpacity(0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Refactored helper to support Image Asset strings cleanly
  Widget _buildPickerTile(String assetPath, String valueText, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(color: ForgeTheme.background, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: ForgeTheme.brandBlue,
              child: Transform.scale(
                scale: 0.5,
                child: Image.asset(assetPath, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                valueText,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
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
        decoration: BoxDecoration(
          color: isSelected ? ForgeTheme.brandBlue : ForgeTheme.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildCorporateParticipantDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isParticipantDropdownOpen = !_isParticipantDropdownOpen),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: ForgeTheme.background,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _isParticipantDropdownOpen ? ForgeTheme.brandBlue : Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ForgeTheme.brandBlue,
                  child: Transform.scale(
                    scale: 0.5,
                    child: Image.asset("assets/icons/person.png", color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedAssigneeIds.isEmpty
                        ? "Select Coworkers (${_coworkersList.length} available)"
                        : "${_selectedAssigneeIds.length} Selected",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A).withOpacity(_selectedAssigneeIds.isEmpty ? 0.3 : 0.8),
                    ),
                  ),
                ),
                Icon(
                  _isParticipantDropdownOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF0F172A).withOpacity(0.4),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _isParticipantDropdownOpen
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: ForgeTheme.background,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: _coworkersList.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No colleagues found in this company.", style: TextStyle(color: ForgeTheme.textMuted, fontSize: 13)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _coworkersList.length,
                          itemBuilder: (context, index) {
                            final employee = _coworkersList[index];
                            final bool isChecked = _selectedAssigneeIds.contains(employee['uid']);
                            return Theme(
                              data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                              child: CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: ForgeTheme.brandBlue,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                value: isChecked,
                                title: Text(
                                  employee['username'] ?? 'Unknown Roster Name',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ForgeTheme.textDark),
                                ),
                                subtitle: Text(
                                  (employee['role'] ?? 'Team Member').toString().toUpperCase(),
                                  style: const TextStyle(fontSize: 11, color: ForgeTheme.brandBlue, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                ),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!_selectedAssigneeIds.contains(employee['uid'])) {
                                        _selectedAssigneeIds.add(employee['uid']);
                                      }
                                    } else {
                                      _selectedAssigneeIds.remove(employee['uid']);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton(String assetPath, IconData fallbackIcon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: ForgeTheme.surfaceWhite.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: ForgeTheme.surfaceWhite, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Transform.scale(
        scale: 0.45,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: const Color(0xFF0F172A), size: 20),
        ),
      ),
    );
  }

  String _getMonthNameShort(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}

Widget _buildPriorityChip(String label, String selectedPriority, VoidCallback onTap) {
  final bool isSelected = selectedPriority == label;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? ForgeTheme.brandBlue : ForgeTheme.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  List<Map<String, dynamic>> _checklistItems = [];
  bool _isPersonalTodo = false;
  String? _documentId;

  @override
  void initState() {
    super.initState();
    _parseIncomingTaskData();
  }

  void _parseIncomingTaskData() {
    _isPersonalTodo = widget.task['isPersonal'] == true || widget.task.containsKey('subtasks') || !widget.task.containsKey('companyId');
    _documentId = widget.task['docId'] ?? widget.task['id'];

    if (widget.task['subtasks'] != null && widget.task['subtasks'] is List) {
      final List<dynamic> rawSubtasks = widget.task['subtasks'];
      _checklistItems = rawSubtasks.map((item) {
        if (item is Map) {
          return {
            "title": item['title'] ?? 'Sub-task Item',
            "isDone": item['isDone'] == true || item['isDone'] == 'true',
          };
        }
        return {"title": item.toString(), "isDone": false};
      }).toList();
    } else {
      _checklistItems = [
        {"title": "Review Wiring Architecture & Logs", "isDone": true},
        {"title": "Optimize Firestore Data Rules Pipeline", "isDone": false},
        {"title": "Render Reactive Flutter Graph Matrix", "isDone": false},
        {"title": "Execute End-to-End Sandbox Tests", "isDone": false},
      ];
    }
  }

  void _toggleChecklistItem(int index) async {
    setState(() {
      _checklistItems[index]['isDone'] = !_checklistItems[index]['isDone'];
    });

    if (_isPersonalTodo && _documentId != null) {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('personal_todos')
            .doc(_documentId)
            .update({'subtasks': _checklistItems});
      } catch (e) {
        debugPrint("Failed to sync subtask item update status: $e");
      }
    }
  }

  void _handleCompleteMainTask() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _documentId == null) {
      Navigator.pop(context);
      return;
    }

    try {
      if (_isPersonalTodo) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('personal_todos')
            .doc(_documentId)
            .update({'isCompleted': true});
      } else {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(_documentId)
            .update({'isCompleted': true});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: ForgeTheme.brandBlue,
            content: Text("Task successfully marked as completed!"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (dbError) {
      debugPrint("Error writing complete transaction node: $dbError");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text("Update Blocked: $dbError")),
        );
      }
    }
  }

  // --- FIXED: PARSES STRINGS SAFE AND EXTRACTS ONLY HH:mm GRID VALUES ---
  String _formatAssignmentTime(dynamic createdAtValue) {
    if (createdAtValue == null || createdAtValue.toString().trim().isEmpty) {
      return "--:--";
    }

    try {
      final String rawStr = createdAtValue.toString().trim();
      
      // 1. Check if the string matches ISO format or standard date format
      DateTime? parsedDate = DateTime.tryParse(rawStr);
      
      // 2. Fallback regex extraction if it contains an explicit timestamp pattern
      if (parsedDate == null) {
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(rawStr);
        if (match != null) {
          String hour = match.group(1)!.padLeft(2, '0');
          String minute = match.group(2)!;
          return "$hour:$minute";
        }
        return "Recent";
      }

      String hours = parsedDate.hour.toString().padLeft(2, '0');
      String minutes = parsedDate.minute.toString().padLeft(2, '0');
      return "$hours:$minutes"; // Returns strictly HH:mm layout framework

    } catch (_) {
      return "--:--";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String originalTitle = (widget.task['title'] ?? 'Task Details').toString();
    final String title = originalTitle.replaceAll('\n', ' ');
    final String priority = widget.task['priority'] ?? 'High';
    final String time = widget.task['dueTime'] ?? widget.task['time'] ?? '02:00 AM';
    final String date = widget.task['dueDate'] ?? widget.task['date'] ?? '14 May 2026';
    
    final String description = widget.task['description'] != null && widget.task['description'].toString().trim().isNotEmpty
        ? widget.task['description'].toString()
        : "Architect and deploy the complete system workspace analytics board data framework loop.";

    final String workspaceLocation = widget.task['location'] != null && widget.task['location'].toString().trim().isNotEmpty
        ? widget.task['location'].toString()
        : "UI/UX Analytics Platform Workspace";

    int completedCount = _checklistItems.where((item) => item['isDone']).length;
    double completionProgressFraction = _checklistItems.isEmpty ? 0.0 : completedCount / _checklistItems.length;

    return Scaffold(
      backgroundColor: ForgeTheme.background, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ForgeTheme.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz_rounded, color: ForgeTheme.textDark, size: 22),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildOverlappingTeamAvatars(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.15), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                priority.toUpperCase(),
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, letterSpacing: -0.8, height: 1.15),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: ForgeTheme.brandBlue, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isPersonalTodo ? "Personal Tasks Desk Space" : workspaceLocation, 
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ForgeTheme.textMuted, letterSpacing: -0.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- ASYNC DYNAMIC CREATOR PROFILE VIEW CARD ---
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.task['createdBy'].toString())
                          .get(),
                      builder: (context, userSnapshot) {
                        String finalName = "Workspace Creator";
                        String finalRole = (widget.task['category'] ?? "Management").toUpperCase();

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          finalName = userData?['username'] ?? userData?['name'] ?? "Workspace Creator";
                          finalRole = (userData?['role'] ?? finalRole).toUpperCase();
                        }

                        // If the database already stored a pre-formatted direct string, bypass lookup constraints
                        if (widget.task['createdBy'] != null && widget.task['createdBy'].toString().length > 20 == false) {
                          finalName = widget.task['createdBy'].toString();
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: ForgeTheme.brandBlue.withOpacity(0.1),
                                child: const Icon(Icons.assignment_ind_rounded, color: ForgeTheme.brandBlue, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: finalName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
                                        children: [
                                          TextSpan(
                                            text: " ($finalRole)",
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ForgeTheme.brandBlue),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Assigned at ${_formatAssignmentTime(widget.task['createdAt'])}", // Formatted cleanly to HH:mm
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ForgeTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(child: _buildParamMetricColumn(Icons.calendar_today_rounded, "DUE DATE", date)),
                            VerticalDivider(color: Colors.black.withOpacity(0.06), thickness: 1, indent: 4, endIndent: 4),
                            Expanded(child: _buildParamMetricColumn(Icons.access_time_filled_rounded, "TIME FRAME", time)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text("Description", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, letterSpacing: -0.2)),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ForgeTheme.textDark.withOpacity(0.55), height: 1.45),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Checklist Matrix", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, letterSpacing: -0.2)),
                        Text("$completedCount/${_checklistItems.length} Done", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ForgeTheme.brandBlue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: completionProgressFraction, minHeight: 6, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation<Color>(ForgeTheme.brandBlue)),
                    ),
                    const SizedBox(height: 16),
                    
                    _checklistItems.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              "No subtasks broken down for this item.",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ForgeTheme.textDark.withOpacity(0.35)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _checklistItems.length,
                            itemBuilder: (context, index) {
                              final item = _checklistItems[index];
                              final bool isDone = item['isDone'];
                              return GestureDetector(
                                onTap: () => _toggleChecklistItem(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDone ? Colors.white.withOpacity(0.4) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDone ? Colors.transparent : Colors.white, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: isDone ? ForgeTheme.brandBlue : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isDone ? ForgeTheme.brandBlue : ForgeTheme.brandBlue.withOpacity(0.4), width: 2),
                                        ),
                                        child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          item['title'],
                                          style: TextStyle(
                                              fontSize: 14, 
                                              fontWeight: FontWeight.w700, 
                                              color: isDone ? ForgeTheme.textDark.withOpacity(0.35) : ForgeTheme.textDark, 
                                              decoration: isDone ? TextDecoration.lineThrough : null),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(color: ForgeTheme.background, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, -10))]),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.black.withOpacity(0.03))),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: ForgeTheme.textDark.withOpacity(0.3), size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(hintText: "Add comment...", hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ForgeTheme.textDark.withOpacity(0.3)), border: InputBorder.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: _handleCompleteMainTask,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(color: ForgeTheme.brandBlue, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: ForgeTheme.brandBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text("Complete Task", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamMetricColumn(IconData icon, String headerText, String infoValue) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: ForgeTheme.background.withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: ForgeTheme.brandBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(headerText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ForgeTheme.textDark.withOpacity(0.3), letterSpacing: 0.6)),
              const SizedBox(height: 2),
              Text(infoValue, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ForgeTheme.textDark, letterSpacing: -0.1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlappingTeamAvatars() {
    return SizedBox(
      width: 82,
      height: 36,
      child: Stack(
        children: [
          _buildAvatarPosition(0, "assets/images/task_avatar1.png"),
          _buildAvatarPosition(20, "assets/images/task_avatar2.png"),
          _buildAvatarPosition(40, "assets/images/profile_avatar.png"),
        ],
      ),
    );
  }

  Widget _buildAvatarPosition(double leftOffset, String assetPath) {
    return Positioned(
      left: leftOffset,
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(radius: 16, backgroundColor: ForgeTheme.surfaceWhite, backgroundImage: AssetImage(assetPath)),
      ),
    );
  }
}
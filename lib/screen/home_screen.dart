import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:neuroforge_workflow/screen/task_detailed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = "Today's Task";
  late PageController _pageController;
  double _scrollOffset = 0.0;

  // --- COMPLETE COMPREHENSIVE DATA MATRIX TRACKING ALL FILTERS ---
  final List<Map<String, dynamic>> _allWorkspaceTasks = [
    // Today's Tasks
    {
      "title": "Wiring Dashboard\nAnalytics",
      "time": "02:00 AM",
      "priority": "High",
      "category": "Today's Task",
    },
    {
      "title": "Syncing Firestore\nSecurity Rules",
      "time": "04:30 PM",
      "priority": "Medium",
      "category": "Today's Task",
    },

    // Weekly Tasks
    {
      "title": "Designing Neo-Brutal\nUI Components",
      "time": "11:00 AM",
      "priority": "High",
      "category": "Weekly tasks",
    },
    {
      "title": "Reviewing Sprint\nArchitecture",
      "time": "09:00 AM",
      "priority": "Low",
      "category": "Weekly tasks",
    },
    {
      "title": "Deploying Webhook\nCloud Functions",
      "time": "06:15 PM",
      "priority": "High",
      "category": "Weekly tasks",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initPageController();
  }

  // Initializes and resets scroll offset loops cleanly
  void _initPageController() {
    const int initialLoopOffsetPage = 1000;
    _pageController =
        PageController(
          viewportFraction: 0.86,
          initialPage: initialLoopOffsetPage,
        )..addListener(() {
          setState(() {
            _scrollOffset = _pageController.page ?? 0.0;
          });
        });
    _scrollOffset = initialLoopOffsetPage.toDouble();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Dynamically parses task data tracking configurations matching your top pill layout selection
  List<Map<String, dynamic>> _getFilteredTasks() {
    if (_selectedFilter == "All") {
      return _allWorkspaceTasks;
    }
    return _allWorkspaceTasks
        .where((task) => task['category'] == _selectedFilter)
        .toList();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "PM";
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    String initials = "";
    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty)
      initials += nameParts[0][0];
    if (nameParts.length > 1 && nameParts[nameParts.length - 1].isNotEmpty)
      initials += nameParts[nameParts.length - 1][0];
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final List<Map<String, dynamic>> displayedTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: ForgeTheme.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid ?? '')
              .snapshots(),
          builder: (context, snapshot) {
            String rawUsername = (currentUser?.displayName ?? "User")
                .toUpperCase();
            String displayRole = "USER ROLE"; // Default placeholder role

            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              rawUsername = userData?['username'] ?? rawUsername;
              final String rawRole = userData?['role'] ?? '';
              if (rawRole.isNotEmpty) displayRole = rawRole.toUpperCase();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // --- 1. HEADER BRANDING SECTION ---
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ForgeTheme.surfaceWhite,
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundColor: kIconCircleBg,
                            backgroundImage: AssetImage(
                              "assets/images/profile_avatar.png",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rawUsername.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ForgeTheme.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayRole,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ForgeTheme.brandBlue,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildHeaderIconButton(
                        "assets/icons/chat.png",
                        Icons.chat_bubble_outline_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderIconButton(
                        "assets/icons/notification.png",
                        Icons.notifications_none_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- 2. SALUTATION ---
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text.rich(
                      TextSpan(
                        text: "HI ${_getInitials(rawUsername)}, ",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: ForgeTheme.textDark,
                          letterSpacing: -0.8,
                        ),
                        children: [
                          TextSpan(
                            text: "nice to\nsee you",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: ForgeTheme.textDark.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 3. INTERACTIVE FILTER CHIP TRACK (FIXED SCROLL WRAPPER TO PREVENT OVERFLOW) ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _buildFilterChip("All"),
                        const SizedBox(width: 12),
                        _buildFilterChip("Today's Task"),
                        const SizedBox(width: 12),
                        _buildFilterChip("Weekly tasks"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 4. FLUID INTERACTIVE CIRCULAR PAGE DECK (FIXED UPWARD-RIGHT FANNING ARRANGEMENT) ---
                  Expanded(
                    child: displayedTasks.isEmpty
                        ? _buildEmptyStateView()
                        : PageView.builder(
                            key: ValueKey(_selectedFilter),
                            controller: _pageController,
                            clipBehavior: Clip.none,
                            itemBuilder: (context, index) {
                              final int circularDataIndex =
                                  index % displayedTasks.length;
                              double indexPositionDelta = index - _scrollOffset;

                              // --- MOCKUP ARRANGEMENT TRANSFORMATIONS MATRIX ---
                              double rotationAngle =
                                  indexPositionDelta *
                                  -0.06; // Tilted rotation factor
                              double horizontalShift =
                                  indexPositionDelta *
                                  28.0; // Pushes cards out to right side background
                              double verticalStackOffset =
                                  indexPositionDelta *
                                  14.0; // Lifts background layers upward

                              // Downscales tracking layers behind foreground card frame
                              double activeScaleFactor = math.max(
                                0.82,
                                1.0 - (indexPositionDelta.abs() * 0.05),
                              );

                              // Normalization constraint boundary layout when card leaves viewport left side
                              if (indexPositionDelta < 0) {
                                rotationAngle = indexPositionDelta * -0.02;
                                horizontalShift = indexPositionDelta * 32.0;
                                verticalStackOffset = 0.0;
                              }

                              return AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, child) {
                                  return Transform(
                                    transform: Matrix4.identity()
                                      ..setEntry(
                                        3,
                                        2,
                                        0.001,
                                      ) // Deep depth perception
                                      ..translate(
                                        horizontalShift,
                                        verticalStackOffset,
                                      )
                                      ..scale(
                                        activeScaleFactor,
                                        activeScaleFactor,
                                      )
                                      ..rotateZ(rotationAngle),
                                    alignment: Alignment.center,
                                    child: child,
                                  );
                                },
                                child: _buildTaskCard(
                                  displayedTasks[circularDataIndex],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Handles empty card array views safely
  Widget _buildEmptyStateView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            color: const Color(0xFF0F172A).withOpacity(0.2),
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            "All Tasks Completed!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(task: task),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ForgeTheme.brandBlue,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ForgeTheme.surfaceWhite, width: 3),
          boxShadow: [
            BoxShadow(
              color: ForgeTheme.brandBlue.withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildOverlappingTeamAvatars(),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task['time'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ForgeTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: Colors.redAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task['priority'],
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              task['title'],
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 21,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.check,
                            color: ForgeTheme.brandBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          "To Complete",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: ForgeTheme.surfaceWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Transform.scale(
                    scale: 0.40,
                    child: Image.asset(
                      "assets/icons/edit.png",
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.edit_outlined,
                        color: ForgeTheme.textDark,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Transform.scale(
        scale: 0.45,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(fallbackIcon, color: const Color(0xFF0F172A), size: 20),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _initPageController();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? ForgeTheme.brandBlue
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? ForgeTheme.brandBlue : Colors.white,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ForgeTheme.brandBlue.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ForgeTheme.textDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingTeamAvatars() {
    return SizedBox(
      width: 64,
      height: 38,
      child: Stack(
        children: [
          const CircleAvatar(
                radius: 19,
                backgroundColor: ForgeTheme.surfaceWhite,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: kIconCircleBg,
                backgroundImage: AssetImage("assets/images/task_avatar2.png"),
              ),
              ),
          Positioned(
            left: 20,
              child: const CircleAvatar(
                radius: 19,
                backgroundColor: ForgeTheme.surfaceWhite,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: kIconCircleBg,
                backgroundImage: AssetImage("assets/images/task_avatar2.png"),
              ),
              )
          ),
        ],
      ),
    );
  }
}

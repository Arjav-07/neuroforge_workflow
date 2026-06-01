import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:neuroforge_workflow/screen/task_detailed_screen.dart';

const Color kIconCircleBg = Colors.grey;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _selectedFilter = "All";
  late PageController _pageController;
  double _scrollOffset = 0.0;
  String _myCompanyId = "";
  bool _isLoadingContext = true;
  late DateTime _currentTrackingDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTrackingDate();
    _initPageController();
    _fetchUserCompanyContext();
  }

  void _refreshTrackingDate() {
    final now = DateTime.now();
    _currentTrackingDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      
      if (_currentTrackingDay.isBefore(todayMidnight)) {
        setState(() {
          _refreshTrackingDate();
          _initPageController();
        });
      }
    }
  }

  void _initPageController() {
    _pageController = PageController(
      viewportFraction: 0.86,
      initialPage: 0,
    )..addListener(() {
        if (!_pageController.hasClients) return;
        setState(() {
          _scrollOffset = _pageController.page ?? _pageController.initialPage.toDouble();
        });
      });
    _scrollOffset = 0.0;
  }

  Future<void> _fetchUserCompanyContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _myCompanyId = (doc.data()?['companyId'] ?? '').toString();
        _isLoadingContext = false;
      });
    } else {
      setState(() {
        _isLoadingContext = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredTasks(List<Map<String, dynamic>> tasks) {
    if (_selectedFilter == "All") {
      return tasks;
    }

    final todayKey =
        "${_currentTrackingDay.year}-${_currentTrackingDay.month.toString().padLeft(2, '0')}-${_currentTrackingDay.day.toString().padLeft(2, '0')}";

    if (_selectedFilter == "Today's Task") {
      return tasks.where((task) {
        final itemDate = task['dueDate'] ?? task['date'];
        return itemDate == todayKey;
      }).toList();
    }

    if (_selectedFilter == "Weekly tasks") {
      final weekEnd = _currentTrackingDay.add(const Duration(days: 7));

      return tasks.where((task) {
        final itemDateStr = task['dueDate'] ?? task['date'];
        if (itemDateStr != null) {
          try {
            final parsedDate = DateTime.parse(itemDateStr.toString());
            return (parsedDate.isAfter(_currentTrackingDay) || parsedDate.isAtSameMomentAs(_currentTrackingDay)) && 
                   parsedDate.isBefore(weekEnd);
          } catch (_) {}
        }

        if (task['deadline'] == null) {
          return false;
        }
        final deadline = (task['deadline'] as Timestamp).toDate();
        return (deadline.isAfter(_currentTrackingDay) || deadline.isAtSameMomentAs(_currentTrackingDay)) && 
               deadline.isBefore(weekEnd);
      }).toList();
    }

    return tasks;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "PM";
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    String initials = "";
    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials += nameParts[0][0];
    }
    if (nameParts.length > 1 && nameParts[nameParts.length - 1].isNotEmpty) {
      initials += nameParts[nameParts.length - 1][0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (_isLoadingContext) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: ForgeTheme.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid ?? '')
              .snapshots(),
          builder: (context, snapshot) {
            String rawUsername = (currentUser?.displayName ?? "User").toUpperCase();
            String displayRole = "USER ROLE";

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
                            backgroundImage: AssetImage("assets/images/profile_avatar.png"),
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
                        assetPath: "assets/icons/chat.png",
                        fallbackIcon: Icons.chat_bubble_outline_rounded,
                        onTap: () {
                          Navigator.pushNamed(context, '/chat');
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderIconButton(
                        assetPath: "assets/icons/notification.png",
                        fallbackIcon: Icons.notifications_none_rounded,
                        onTap: () {},
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

                  // --- 3. INTERACTIVE FILTER CHIP TRACK ---
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
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 4. FLUID INTERACTIVE CIRCULAR PAGE DECK ---
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tasks')
                          .where('companyId', isEqualTo: _myCompanyId)
                          .where('isCompleted', isEqualTo: false)
                          .snapshots(),
                      builder: (context, taskSnapshot) {
                        if (taskSnapshot.hasError) {
                          return Center(child: Text(taskSnapshot.error.toString()));
                        }

                        if (!taskSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        List<Map<String, dynamic>> rawCompanyTasks = taskSnapshot.data!.docs
                            .map((doc) => {
                                  ...doc.data() as Map<String, dynamic>,
                                  "docId": doc.id,
                                  "isPersonal": false,
                                })
                            .toList();

                        final uid = FirebaseAuth.instance.currentUser!.uid;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('personal_todos')
                              .where('isCompleted', isEqualTo: false)
                              .snapshots(),
                          builder: (context, todoSnapshot) {
                            if (!todoSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            List<Map<String, dynamic>> personalTodos = todoSnapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return {
                                ...data,
                                "isPersonal": true,
                                "docId": doc.id,
                                "priority": data["priority"] ?? "Medium",
                              };
                            }).toList();

                            List<Map<String, dynamic>> unifiedTasks = List.from(rawCompanyTasks)..addAll(personalTodos);
                            final List<Map<String, dynamic>> combinedTasks = _getFilteredTasks(unifiedTasks);

                            if (combinedTasks.isEmpty) {
                              return _buildEmptyStateView();
                            }

                            return PageView.builder(
                              itemCount: combinedTasks.length,
                              key: ValueKey(_selectedFilter + _currentTrackingDay.toIso8601String()),
                              controller: _pageController,
                              clipBehavior: Clip.none,
                              itemBuilder: (context, index) {
                                double indexPositionDelta = index - _scrollOffset;

                                double rotationAngle = indexPositionDelta * -0.06;
                                double horizontalShift = indexPositionDelta * 28.0;
                                double verticalStackOffset = indexPositionDelta * 14.0;

                                double activeScaleFactor = math.max(
                                  0.82,
                                  1.0 - (indexPositionDelta.abs() * 0.05),
                                );

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
                                        ..setEntry(3, 2, 0.001)
                                        ..translate(horizontalShift, verticalStackOffset)
                                        ..scale(activeScaleFactor, activeScaleFactor)
                                        ..rotateZ(rotationAngle),
                                      alignment: Alignment.center,
                                      child: child,
                                    );
                                  },
                                  child: _buildTaskCard(combinedTasks[index]),
                                );
                              },
                            );
                          },
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
    final bool isPersonal = task['isPersonal'] == true;
    final String originalTitle = (task['title'] ?? 'Untitled Task').toString();

    // 28 character validation check loop
    String truncatedTitle = originalTitle;
    if (originalTitle.length > 28) {
      truncatedTitle = "${originalTitle.substring(0, 28)}... ";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        task['dueTime'] ?? task['time'] ?? '--',
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ForgeTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        (task['priority'] ?? 'Medium').toString(),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPersonal) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "PERSONAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 18),
            
            // --- FIXED: REDUCED FONT SIZE BY 2 (FROM 34 TO 32) ---
            Expanded(
              child: Text(
                truncatedTitle,
                maxLines: 3, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30, 
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.12, 
                  letterSpacing: -0.6,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SwipeToCompleteBar(task: task),
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

  Widget _buildHeaderIconButton({
    required String assetPath, 
    required IconData fallbackIcon, 
    required VoidCallback onTap, 
  }) {
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
      child: InkWell(
        onTap: onTap, 
        customBorder: const CircleBorder(), 
        splashColor: ForgeTheme.brandBlue.withOpacity(0.1), 
        child: Transform.scale(
          scale: 0.45,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Icon(fallbackIcon, color: const Color(0xFF0F172A), size: 20),
          ),
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
          color: isSelected ? ForgeTheme.brandBlue : Colors.white.withOpacity(0.5),
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
            fontWeight: FontWeight.w600,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeToCompleteBar extends StatefulWidget {
  final Map<String, dynamic> task;

  const _SwipeToCompleteBar({required this.task});

  @override
  State<_SwipeToCompleteBar> createState() => _SwipeToCompleteBarState();
}

class _SwipeToCompleteBarState extends State<_SwipeToCompleteBar> {
  double _dragOffset = 0.0;
  bool _isCompletedActionTriggered = false;

  void _executeCompletion() async {
    setState(() {
      _isCompletedActionTriggered = true;
    });

    final bool isPersonal = widget.task['isPersonal'] == true;
    final String docId = widget.task['docId'] ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      if (isPersonal) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('personal_todos')
            .doc(docId)
            .update({'isCompleted': true});
      } else {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(docId)
            .update({'isCompleted': true});
      }
    } catch (e) {
      debugPrint("Error writing completion milestone: $e");
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
          _isCompletedActionTriggered = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54, 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxSliderWidth = constraints.maxWidth;
          const double handleButtonRadius = 42.0; 
          final double maxDragDistance = maxSliderWidth - handleButtonRadius - 12.0;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned.fill(
                child: Align(
                  child: Opacity(
                    opacity: math.max(0.0, 1.0 - (_dragOffset / (maxDragDistance / 1.4))),
                    
                    child: const Text(
                      "  To Complete",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 14,
                child: Opacity(
                  opacity: math.max(0.0, 1.0 - (_dragOffset / maxDragDistance)),
                  child: Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: _isCompletedActionTriggered ? const Duration(milliseconds: 150) : Duration.zero,
                curve: Curves.easeOut,
                left: _dragOffset + 6, 
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompletedActionTriggered) return;
                    setState(() {
                      _dragOffset += details.primaryDelta!;
                      if (_dragOffset < 0.0) _dragOffset = 0.0;
                      if (_dragOffset > maxDragDistance) _dragOffset = maxDragDistance;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompletedActionTriggered) return;
                    
                    if (_dragOffset >= maxDragDistance * 0.85) {
                      setState(() => _dragOffset = maxDragDistance);
                      _executeCompletion();
                    } else {
                      setState(() => _dragOffset = 0.0);
                    }
                  },
                  child: Container(
                    width: handleButtonRadius,
                    height: handleButtonRadius,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _isCompletedActionTriggered
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: ForgeTheme.brandBlue,
                              ),
                            )
                          : const Icon(
                              Icons.check,
                              color: ForgeTheme.brandBlue, 
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
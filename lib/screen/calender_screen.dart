import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';
import 'package:neuroforge_workflow/screen/task_detailed_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  double _scrollOffset = 0.0;
  
  late DateTime _selectedDate;
  late List<DateTime> _currentWeekDays;

  Stream<QuerySnapshot>? _tasksStream;
  String _myCompanyId = "";
  bool _isLoadingContext = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshToCurrentDate();
    _initPageController();
    _fetchUserCompanyContext();
  }

  void _refreshToCurrentDate() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _generateWeekDays(_selectedDate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      
      if (_selectedDate.isBefore(todayMidnight)) {
        setState(() {
          _refreshToCurrentDate();
          _initPageController();
        });
      }
    }
  }

  void _generateWeekDays(DateTime anchorDate) {
    int currentUtcOffset = anchorDate.weekday - 1; 
    DateTime monday = anchorDate.subtract(Duration(days: currentUtcOffset));
    _currentWeekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  void _initPageController() {
    _pageController = PageController(viewportFraction: 0.86, initialPage: 0)
      ..addListener(() {
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
        
        // Filter out completed corporate workflows instantly
        _tasksStream = FirebaseFirestore.instance
            .collection('tasks')
            .where('companyId', isEqualTo: _myCompanyId)
            .where('isCompleted', isEqualTo: false)
            .snapshots();
            
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

  List<Map<String, dynamic>> _filterTasksBySelectedDate(List<Map<String, dynamic>> mixedTasks) {
    String targetedDateKey = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    
    return mixedTasks.where((task) {
      final taskDate = task['date'] ?? task['dueDate'];
      return taskDate == targetedDateKey;
    }).toList();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "PM";
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    String initials = "";
    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) initials += nameParts[0][0];
    if (nameParts.length > 1 && nameParts[nameParts.length - 1].isNotEmpty) initials += nameParts[nameParts.length - 1][0];
    return initials.toUpperCase();
  }

  String _getWeekLabel(int weekday) {
    switch (weekday) {
      case 1: return "MON";
      case 2: return "TUE";
      case 3: return "WED";
      case 4: return "THU";
      case 5: return "FRI";
      case 6: return "SAT";
      default: return "SUN";
    }
  }

  String _getMonthName(int month) {
    const months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"];
    return months[month - 1];
  }

  void _openFullCalendarView(List<DocumentSnapshot> rawCompanyDocs, List<DocumentSnapshot> rawPersonalDocs) {
    final DateTime startLimit = DateTime(2026, 1, 1);
    final DateTime endLimit = DateTime(2036, 12, 31);
    final int totalMonths = ((endLimit.year - startLimit.year) * 12) + endLimit.month - startLimit.month + 1;
    
    int initialPageOffset = ((_selectedDate.year - startLimit.year) * 12) + _selectedDate.month - startLimit.month;
    final PageController modalPageController = PageController(initialPage: initialPageOffset);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF2F1ED),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, 
                    height: 5, 
                    decoration: BoxDecoration(
                      color: ForgeTheme.textDark.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(10)
                    )
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: PageView.builder(
                      controller: modalPageController,
                      itemCount: totalMonths,
                      itemBuilder: (context, pageIndex) {
                        final int computedMonthVal = ((startLimit.month - 1 + pageIndex) % 12) + 1;
                        final int computedYearVal = startLimit.year + ((startLimit.month - 1 + pageIndex) ~/ 12);
                        
                        final DateTime activeMonthData = DateTime(computedYearVal, computedMonthVal, 1);
                        final int totalDaysInMonth = DateTime(computedYearVal, computedMonthVal + 1, 0).day;
                        int leadingOffsetCount = activeMonthData.weekday - 1;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getMonthName(computedMonthVal),
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, letterSpacing: -0.5),
                                    ),
                                    const SizedBox(width: 10),
                                    
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        splashColor: Colors.transparent,
                                      ),
                                      child: PopupMenuButton<int>(
                                        offset: const Offset(0, 50),
                                        elevation: 12,
                                        color: ForgeTheme.background,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        initialValue: computedYearVal,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: ForgeTheme.surfaceWhite,
                                            borderRadius: BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "$computedYearVal",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ForgeTheme.textDark),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.keyboard_arrow_down_rounded, color: ForgeTheme.textDark.withOpacity(0.5), size: 20),
                                            ],
                                          ),
                                        ),
                                        onSelected: (int selectedYear) {
                                          final int targetPageOffset = ((selectedYear - startLimit.year) * 12) + computedMonthVal - startLimit.month;
                                          modalPageController.animateToPage(
                                            targetPageOffset, 
                                            duration: const Duration(milliseconds: 500), 
                                            curve: Curves.easeOutExpo
                                          );
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return List.generate(11, (i) => 2026 + i).map((int yearItem) {
                                            bool isActive = yearItem == computedYearVal;
                                            return PopupMenuItem<int>(
                                              value: yearItem,
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  
                                                  color: isActive ? ForgeTheme.brandBlue.withOpacity(0.1) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "$yearItem",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                                                      color: isActive ? ForgeTheme.brandBlue : ForgeTheme.textDark,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left, color: ForgeTheme.brandBlue),
                                      onPressed: pageIndex > 0 ? () => modalPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right, color: ForgeTheme.brandBlue),
                                      onPressed: pageIndex < totalMonths - 1 ? () => modalPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ["M", "T", "W", "T", "F", "S", "S"].map((day) => Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4), fontSize: 13))).toList(),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7, 
                                  mainAxisSpacing: 10, 
                                  crossAxisSpacing: 10
                                ),
                                itemCount: totalDaysInMonth + leadingOffsetCount, 
                                itemBuilder: (context, gridIndex) {
                                  if (gridIndex < leadingOffsetCount) return const SizedBox.shrink();
                                  
                                  int dayNum = gridIndex - leadingOffsetCount + 1;
                                  DateTime targetGridDay = DateTime(computedYearVal, computedMonthVal, dayNum);
                                  bool isSameDayActive = _selectedDate.day == dayNum && _selectedDate.month == computedMonthVal && _selectedDate.year == computedYearVal;

                                  String cellDateStr = "${targetGridDay.year}-${targetGridDay.month.toString().padLeft(2, '0')}-${targetGridDay.day.toString().padLeft(2, '0')}";
                                  
                                  bool hasCompanyTask = rawCompanyDocs.any((doc) {
                                    final data = doc.data() as Map<String, dynamic>?;
                                    return (data?['date'] ?? data?['dueDate']) == cellDateStr;
                                  });
                                  bool hasPersonalTask = rawPersonalDocs.any((doc) {
                                    final data = doc.data() as Map<String, dynamic>?;
                                    return (data?['date'] ?? data?['dueDate']) == cellDateStr;
                                  });

                                  bool hasTaskOnThisDay = hasCompanyTask || hasPersonalTask;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDate = targetGridDay;
                                        _generateWeekDays(targetGridDay); 
                                        _initPageController();
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSameDayActive ? ForgeTheme.brandBlue : Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: isSameDayActive ? ForgeTheme.brandBlue : Colors.white, width: 1.5),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            "$dayNum", 
                                            style: TextStyle(
                                              fontSize: 14, 
                                              fontWeight: FontWeight.bold, 
                                              color: isSameDayActive ? Colors.white : ForgeTheme.textDark
                                            )
                                          ),
                                          if (hasTaskOnThisDay)
                                            Positioned(
                                              bottom: 4,
                                              child: Container(
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSameDayActive ? Colors.white : ForgeTheme.brandBlue,
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? '';

    if (_isLoadingContext) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnapshot) {
            String rawUsername = (currentUser?.displayName ?? "User").toUpperCase();
            String displayRole = "USER ROLE";

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
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
                            Text(rawUsername.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(displayRole, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ForgeTheme.brandBlue, letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                      _buildHeaderIconButton("assets/icons/chat.png", Icons.chat_bubble_outline_rounded),
                      const SizedBox(width: 12),
                      _buildHeaderIconButton("assets/icons/notification.png", Icons.notifications_none_rounded),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Wrap stream builders to fetch accurate task count markers on top header triggers
                  StreamBuilder<QuerySnapshot>(
                    stream: _tasksStream,
                    builder: (context, companySnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('personal_todos').where('isCompleted', isEqualTo: false).snapshots(),
                        builder: (context, personalSnapshot) {
                          final companyDocs = companySnapshot.hasData ? companySnapshot.data!.docs : <DocumentSnapshot>[];
                          final personalDocs = personalSnapshot.hasData ? personalSnapshot.data!.docs : <DocumentSnapshot>[];
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text.rich(
                                  TextSpan(
                                    text: "HI ${_getInitials(rawUsername)}, ",
                                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ForgeTheme.textDark, letterSpacing: -0.8),
                                    children: [TextSpan(text: "nice to\nsee you", style: TextStyle(fontWeight: FontWeight.w800, color: ForgeTheme.textDark.withOpacity(0.35)))],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _openFullCalendarView(companyDocs, personalDocs),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                                  ),
                                  child: const Text("View full calendar", style: TextStyle(color: ForgeTheme.brandBlue, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: -0.1)),
                                ),
                              ),
                            ],
                          );
                        }
                      );
                    },
                  ),
                        
                  const SizedBox(height: 30),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    child: Row(
                      children: List.generate(_currentWeekDays.length, (index) {
                        DateTime stripDay = _currentWeekDays[index];
                        final bool isSelected = _selectedDate.day == stripDay.day && _selectedDate.month == stripDay.month && _selectedDate.year == stripDay.year;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = stripDay;
                              _initPageController();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.fastOutSlowIn,
                            width: 62,
                            height: 82,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? ForgeTheme.brandBlue : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: isSelected ? ForgeTheme.brandBlue : Colors.white, width: 2),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: ForgeTheme.brandBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
                                  : [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_getWeekLabel(stripDay.weekday), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white.withOpacity(0.7) : ForgeTheme.textDark.withOpacity(0.4))),
                                const SizedBox(height: 6),
                                Text("${stripDay.day}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : ForgeTheme.textDark)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _tasksStream,
                      builder: (context, companySnapshot) {
                        if (companySnapshot.hasError) {
                          return Center(child: Text("Error: ${companySnapshot.error}"));
                        }
                        if (!companySnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        List<Map<String, dynamic>> companyTasks = companySnapshot.data!.docs.map((doc) {
                          return {
                            ...doc.data() as Map<String, dynamic>,
                            "docId": doc.id,
                            "isPersonal": false,
                          };
                        }).toList();

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('personal_todos').where('isCompleted', isEqualTo: false).snapshots(),
                          builder: (context, personalSnapshot) {
                            if (!personalSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            List<Map<String, dynamic>> personalTasks = personalSnapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return {
                                ...data,
                                "docId": doc.id,
                                "isPersonal": true,
                                "priority": data["priority"] ?? "Medium",
                              };
                            }).toList();

                            List<Map<String, dynamic>> unifiedTasks = List.from(companyTasks)..addAll(personalTasks);
                            final List<Map<String, dynamic>> displayedTasks = _filterTasksBySelectedDate(unifiedTasks);

                            if (displayedTasks.isEmpty) {
                              return _buildEmptyStateView();
                            }

                            return PageView.builder(
                              key: ValueKey(_selectedDate),
                              controller: _pageController,
                              clipBehavior: Clip.none,
                              itemCount: displayedTasks.length, 
                              itemBuilder: (context, index) {
                                double indexPositionDelta = index - _scrollOffset;
                                double rotationAngle = indexPositionDelta * -0.06;
                                double horizontalShift = indexPositionDelta * 18.0;
                                double verticalStackOffset = indexPositionDelta * 14.0;
                                double activeScaleFactor = math.max(0.82, 1.0 - (indexPositionDelta.abs() * 0.05));
                                
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
                                  child: _buildTaskCard(displayedTasks[index]), 
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
          Icon(Icons.event_available_outlined, color: const Color(0xFF0F172A).withOpacity(0.2), size: 54),
          const SizedBox(height: 12),
          Text("No Schedules for this Day", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A).withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final bool isPersonal = task['isPersonal'] == true;
    final String originalTitle = (task['title'] ?? 'Untitled Task').toString();

    // Enforce 28 letter strict truncation limits safely
    String truncatedTitle = originalTitle;
    if (originalTitle.length > 28) {
      truncatedTitle = "${originalTitle.substring(0, 28)}...";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ForgeTheme.brandBlue,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ForgeTheme.surfaceWhite, width: 3),
          boxShadow: [BoxShadow(color: ForgeTheme.brandBlue.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 10))],
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(task['time'] ?? task['dueTime'] ?? '--:--', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
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
                  decoration: BoxDecoration(color: ForgeTheme.surfaceWhite, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(task['priority'] ?? 'Medium', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
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
            
            // --- MATCHED DESIGN TYPOGRAPHY ---
            Expanded(
              child: Text(
                truncatedTitle, 
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w700, 
                  color: Colors.white, 
                  height: 1.12, 
                  letterSpacing: -0.6
                )
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                // Injected the styled horizontal swiper gesture tracking widget class
                Expanded(
                  child: _SwipeToCompleteBar(task: task),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: ForgeTheme.surfaceWhite, shape: BoxShape.circle),
                  child: Transform.scale(
                    scale: 0.40,
                    child: Image.asset("assets/icons/edit.png", errorBuilder: (context, error, stackTrace) => const Icon(Icons.edit_outlined, color: ForgeTheme.textDark, size: 22)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Transform.scale(
        scale: 0.45,
        child: Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: const Color(0xFF0F172A), size: 20)),
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
            child: CircleAvatar(radius: 17, backgroundColor: ForgeTheme.surfaceWhite, backgroundImage: AssetImage("assets/images/task_avatar1.png")),
          ),
          Positioned(
            left: 20,
            child: const CircleAvatar(
              radius: 19,
              backgroundColor: ForgeTheme.surfaceWhite,
              child: CircleAvatar(radius: 17, backgroundColor: ForgeTheme.surfaceWhite, backgroundImage: AssetImage("assets/images/task_avatar2.png")),
            ),
          ),
        ],
      ),
    );
  }
}

// --- FULLY SYNCHRONIZED COMPLETED GESTURE SLIDER (SCREENSHOT 2026-06-01 AT 5.22.35 PM FIXES) ---
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
      debugPrint("Error completing task on swipe: $e");
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
      height: 60, 
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
              Center(
                    child: Opacity(
                      opacity: math.max(0.0, 1.0 - (_dragOffset / (maxDragDistance / 1.3))),
                      child: const Text(
                        "   To Complete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      )
                    ),
                  ),

              Positioned(
                right: 14,
                child: Opacity(
                  opacity: math.max(0.0, 1.0 - (_dragOffset / maxDragDistance)),
                  child: Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    color: Colors.white.withOpacity(0.7),
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
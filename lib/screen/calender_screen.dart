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

class _CalendarScreenState extends State<CalendarScreen> {
  late PageController _pageController;
  double _scrollOffset = 0.0;
  
  late DateTime _selectedDate;
  late List<DateTime> _currentWeekDays;

  final List<Map<String, dynamic>> _allTasksDatabase = [
    {"title": "Wiring Dashboard\nAnalytics", "time": "02:00 AM", "priority": "High", "date": "2026-05-30"},
    {"title": "Syncing Firestore\nSecurity Rules", "time": "04:30 PM", "priority": "Medium", "date": "2026-05-30"},
    {"title": "Reviewing Sprint\nArchitecture", "time": "09:00 AM", "priority": "Low", "date": "2026-05-28"},
    {"title": "Designing Neo-Brutal\nUI Components", "time": "11:00 AM", "priority": "High", "date": "2026-05-29"},
    {"title": "Deploying Webhook\nCloud Functions", "time": "06:15 PM", "priority": "High", "date": "2026-06-01"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(2026, 5, 30);
    _generateWeekDays(_selectedDate);
    _initPageController();
  }

  void _generateWeekDays(DateTime anchorDate) {
    int currentUtcOffset = anchorDate.weekday - 1; 
    DateTime monday = anchorDate.subtract(Duration(days: currentUtcOffset));
    _currentWeekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  void _initPageController() {
    const int initialLoopOffsetPage = 1000;
    _pageController = PageController(viewportFraction: 0.86, initialPage: initialLoopOffsetPage)
      ..addListener(() {
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

  List<Map<String, dynamic>> _getFilteredTasksForSelectedDate() {
    String targetedDateKey = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    return _allTasksDatabase.where((task) => task['date'] == targetedDateKey).toList();
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

  void _openFullCalendarView() {
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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: ForgeTheme.textDark.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
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
                        final int leadingOffsetCount = activeMonthData.weekday - 1;

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
                                        splashColor: Colors.transparent,
                                      ),
                                      child: PopupMenuButton<int>(
                                        offset: const Offset(0, 45),
                                        elevation: 12,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        initialValue: computedYearVal,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
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
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 10),
                                itemCount: totalDaysInMonth + leadingOffsetCount, 
                                itemBuilder: (context, gridIndex) {
                                  if (gridIndex < leadingOffsetCount) return const SizedBox.shrink();
                                  
                                  int dayNum = gridIndex - leadingOffsetCount + 1;
                                  DateTime targetGridDay = DateTime(computedYearVal, computedMonthVal, dayNum);
                                  bool isSameDayActive = _selectedDate.day == dayNum && _selectedDate.month == computedMonthVal && _selectedDate.year == computedYearVal;

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
                                      child: Center(
                                        child: Text("$dayNum", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSameDayActive ? Colors.white : ForgeTheme.textDark)),
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
    final List<Map<String, dynamic>> displayedTasks = _getFilteredTasksForSelectedDate();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid ?? '').snapshots(),
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
                  Row(
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
                        onTap: _openFullCalendarView,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
                          ),
                          child: const Text("View full calendar", style: TextStyle(color: ForgeTheme.brandBlue, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: -0.1)),
                        ),
                      ),
                    ],
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
                    child: displayedTasks.isEmpty
                        ? _buildEmptyStateView()
                        : PageView.builder(
                            key: ValueKey(_selectedDate),
                            controller: _pageController,
                            clipBehavior: Clip.none,
                            itemBuilder: (context, index) {
                              final int circularDataIndex = index % displayedTasks.length;
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
                                child: _buildTaskCard(displayedTasks[circularDataIndex]),
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
                      Text(task['time'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: ForgeTheme.surfaceWhite, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(task['priority'], style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(task['title'], style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, height: 1.15, letterSpacing: -0.5)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 21, backgroundColor: Colors.white, child: Icon(Icons.check, color: ForgeTheme.brandBlue, size: 18)),
                        const SizedBox(width: 14),
                        const Text("To Complete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.2)),
                        const Spacer(),
                        Icon(Icons.keyboard_double_arrow_right_rounded, color: Colors.white.withOpacity(0.7), size: 20),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
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
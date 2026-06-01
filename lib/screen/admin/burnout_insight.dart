import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class BurnoutInsightsScreen extends StatefulWidget {
  const BurnoutInsightsScreen({super.key});

  @override
  State<BurnoutInsightsScreen> createState() => _BurnoutInsightsScreenState();
}

class _BurnoutInsightsScreenState extends State<BurnoutInsightsScreen> {
  String _myCompanyId = "";
  bool _isLoadingContext = true;

  // Interactive Week-Bound Timelines Anchors
  late DateTime _selectedStartOfWeek;
  String _weekLabelText = "This Week";

  @override
  void initState() {
    super.initState();
    _resetToCurrentWeek();
    _fetchWorkspaceCompanyContext();
  }

  void _resetToCurrentWeek() {
    final DateTime now = DateTime.now();
    _selectedStartOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    _weekLabelText = "This Week";
  }

  Future<void> _fetchWorkspaceCompanyContext() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _myCompanyId = (doc.data()?['companyId'] ?? '').toString();
          _isLoadingContext = false;
        });
      }
    } catch (e) {
      debugPrint("Burnout insights telemetry tracking blocked: $e");
      if (mounted) setState(() => _isLoadingContext = false);
    }
  }

  // --- INFINITE ALL-TIME SYSTEM CALENDAR INTERFACE ENGINE ---
  Future<void> _selectCustomWeekFromCalendar() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartOfWeek,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year, now.month, now.day + 365),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ForgeTheme.brandBlue,
              onPrimary: Colors.white,
              onSurface: ForgeTheme.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: ForgeTheme.brandBlue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final DateTime calculatedMonday = DateTime(pickedDate.year, pickedDate.month, pickedDate.day)
          .subtract(Duration(days: pickedDate.weekday - 1));
      final DateTime currentMondayNow = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

      setState(() {
        _selectedStartOfWeek = calculatedMonday;
        if (calculatedMonday.isAtSameMomentAs(currentMondayNow)) {
          _weekLabelText = "This Week";
        } else if (calculatedMonday.isAtSameMomentAs(currentMondayNow.subtract(const Duration(days: 7)))) {
          _weekLabelText = "Last Week";
        } else {
          _weekLabelText = "Sprint Cycle";
        }
      });
    }
  }

  // --- BURNOUT DATA AGGREGATOR TELEMETRY PIPELINE ENGINE ---
  Map<String, dynamic> _compileBurnoutTelemetry(
    List<DocumentSnapshot> userDocs, 
    List<DocumentSnapshot> taskDocs,
    DateTime targetWeekMonday,
  ) {
    int totalMembers = userDocs.length;

    // FIXED: Removed the hardcoded fallback constants block that kept your UI data static.
    // If no users exist yet or stream is empty, calculate true zero state relative to selected sprint.
    if (totalMembers == 0) {
      return {
        "teamRiskPct": 0, "highCount": 0, "mediumCount": 0, "lowCount": 0,
        "roster": <Map<String, dynamic>>[],
        "suggestions": [
          "No roster telemetry data available for this specific sprint timeline slice.",
          "Verify employee accounts match your active organization company token configurations."
        ]
      };
    }

    Map<String, int> activeBacklogs = {};
    Map<String, int> lateNightStrikes = {}; 

    for (var doc in userDocs) {
      activeBacklogs[doc.id] = 0;
      final userData = doc.data() as Map<String, dynamic>? ?? {};
      lateNightStrikes[doc.id] = userData['overtimeStrikes'] ?? 0;
    }

    for (var doc in taskDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      bool isDone = data['isCompleted'] == true || data['isDone'] == true || (data['status'] ?? '').toString().toLowerCase() == 'completed';

      if (!isDone && data['assignedTo'] != null) {
        final List assignees = data['assignedTo'] is List ? data['assignedTo'] : [data['assignedTo']];
        for (var uid in assignees) {
          if (activeBacklogs.containsKey(uid)) {
            activeBacklogs[uid] = activeBacklogs[uid]! + 1;
          }
        }
      }
    }

    int highRisk = 0;
    int mediumRisk = 0;
    int lowRisk = 0;
    List<Map<String, dynamic>> memberRiskRoster = [];
    List<String> dynamicAiInsights = [];

    for (var doc in userDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String uid = doc.id;
      final String name = data['username'] ?? data['name'] ?? 'Team Member';
      final String designation = data['designation'] ?? data['role'] ?? 'Software Engineer';
      final int backlogs = activeBacklogs[uid] ?? 0;
      final int lateNights = lateNightStrikes[uid] ?? 0;

      int pressurePercentage = math.min(98, (backlogs * 6) + (lateNights * 8) + 12);
      String riskLabel = "Low";

      if (pressurePercentage >= 75 || backlogs >= 8) {
        riskLabel = "High";
        highRisk++;
        dynamicAiInsights.add("$name has $backlogs active tasks. Consider reducing workload.");
      } else if (pressurePercentage >= 45 || backlogs >= 4) {
        riskLabel = "Medium";
        mediumRisk++;
        if (lateNights > 0) {
          dynamicAiInsights.add("$name is working beyond 10 PM for $lateNights days this week.");
        }
      } else {
        lowRisk++;
      }

      memberRiskRoster.add({
        "name": name,
        "role": designation,
        "risk": riskLabel,
        "intensity": "$pressurePercentage%"
      });
    }

    memberRiskRoster.sort((a, b) {
      if (a['risk'] == 'High' && b['risk'] != 'High') return -1;
      if (a['risk'] == 'Medium' && b['risk'] == 'Low') return -1;
      if (a['risk'] == 'Low' && b['risk'] != 'Low') return 1;
      return 0;
    });

    if (dynamicAiInsights.length < 3) {
      dynamicAiInsights.add("Schedule focus time and breaks for better productivity.");
      dynamicAiInsights.add("Balance cross-project allocations during sprint lock sessions.");
    }

    int globalRiskPercent = totalMembers > 0 ? (((highRisk * 1.0 + mediumRisk * 0.4) / totalMembers) * 100).round() : 0;

    return {
      "teamRiskPct": globalRiskPercent,
      "highCount": highRisk,
      "mediumCount": mediumRisk,
      "lowCount": lowRisk,
      "roster": memberRiskRoster,
      "suggestions": dynamicAiInsights.take(3).toList()
    };
  }

  String _getMonthNameShort(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContext) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F1ED),
        body: Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue)),
      );
    }

    final DateTime calculatedEndOfWeek = _selectedStartOfWeek.add(const Duration(days: 6));
    final String targetFormattedRangeText = "${_selectedStartOfWeek.day} ${_getMonthNameShort(_selectedStartOfWeek.month)} - ${calculatedEndOfWeek.day} ${_getMonthNameShort(calculatedEndOfWeek.month)} ${_selectedStartOfWeek.year}";

    final String startIsoStr = _selectedStartOfWeek.toIso8601String().substring(0, 10);
    final String endIsoStr = _selectedStartOfWeek.add(const Duration(days: 7)).toIso8601String().substring(0, 10);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ForgeTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Burnout Insights", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ForgeTheme.textDark)),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: ForgeTheme.brandBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: ForgeTheme.brandBlue, size: 12),
                SizedBox(width: 4),
                Text("ASI-1", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ForgeTheme.brandBlue)),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('companyId', isEqualTo: _myCompanyId).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue));

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('companyId', isEqualTo: _myCompanyId)
                  .where('dueDate', isGreaterThanOrEqualTo: startIsoStr)
                  .where('dueDate', isLessThan: endIsoStr)
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.hasError) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text("Handshake Error: Check console index build generation paths.")));
                }
                if (!taskSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue));

                final telemetry = _compileBurnoutTelemetry(userSnapshot.data!.docs, taskSnapshot.data!.docs, _selectedStartOfWeek);
                final List rosterList = telemetry['roster'];
                final List insightsList = telemetry['suggestions'];

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CALENDAR SELECTION ANCHOR TANK ---
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _selectCustomWeekFromCalendar,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.calendar_month_rounded, color: ForgeTheme.brandBlue.withOpacity(0.8), size: 22),
                                Column(
                                  children: [
                                    Text(_weekLabelText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                                    const SizedBox(height: 2),
                                    Text(targetFormattedRangeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ForgeTheme.textMuted)),
                                  ],
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded, color: ForgeTheme.textDark.withOpacity(0.4), size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // --- 1. BURNOUT RISK OVERVIEW CARD ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Burnout Risk Overview", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ForgeTheme.textDark.withOpacity(0.5))),
                                  const SizedBox(height: 14),
                                  Text("${telemetry['teamRiskPct']}%", style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, height: 1.0)),
                                  const SizedBox(height: 4),
                                  Text("Team at Risk", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4))),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.arrow_upward_rounded, color: Colors.redAccent, size: 14),
                                      const SizedBox(width: 2),
                                      Text("8% ", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 12)),
                                      Text("vs last week", style: TextStyle(color: ForgeTheme.textDark.withOpacity(0.3), fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendaryRatioRow(Colors.redAccent, "High Risk", telemetry['highCount'].toString()),
                                const SizedBox(height: 12),
                                _buildLegendaryRatioRow(Colors.amber, "Medium Risk", telemetry['mediumCount'].toString()),
                                const SizedBox(height: 12),
                                _buildLegendaryRatioRow(Colors.green, "Low Risk", telemetry['lowCount'].toString()),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- 2. TOP RISK MEMBERS CARD FEED ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Top Risk Members", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                            const SizedBox(height: 20),
                            rosterList.isEmpty 
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: Text("All operational rosters clean.", style: TextStyle(fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.3)))),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: rosterList.length > 5 ? 5 : rosterList.length,
                                  separatorBuilder: (context, index) => Divider(color: Colors.black.withOpacity(0.04), height: 24),
                                  itemBuilder: (context, index) {
                                    final candidate = rosterList[index];
                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: ForgeTheme.brandBlue.withOpacity(0.1),
                                          child: Text(candidate['name'].toString().substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.brandBlue)),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(candidate['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                                              const SizedBox(height: 2),
                                              Text(candidate['role'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ForgeTheme.textDark.withOpacity(0.35))),
                                            ],
                                          ),
                                        ),
                                        _buildRiskLevelBadge(candidate['risk']),
                                        const SizedBox(width: 14),
                                        Text(candidate['intensity'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                                      ],
                                    );
                                  },
                                )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- 3. ASI-1 AUTO INSIGHT SUGGESTIONS PANEL ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ForgeTheme.brandBlue.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: ForgeTheme.brandBlue.withOpacity(0.1), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ASI-1 Suggestions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: insightsList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(Icons.check_circle_outline_rounded, color: ForgeTheme.brandBlue, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        insightsList[index],
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ForgeTheme.textDark.withOpacity(0.7), height: 1.3),
                                      ),
                                    )
                                  ],
                                );
                              },
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }, // end taskSnapshot builder
            ); // end inner StreamBuilder
          }, // end userSnapshot builder
        ), // end outer StreamBuilder
      ), // end SafeArea
    ); // end Scaffold
  }

  Widget _buildLegendaryRatioRow(Color statusColor, String label, String value) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: statusColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4))),
          const Spacer(),
          Text(value.padLeft(2, '0'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildRiskLevelBadge(String level) {
    Color bg;
    Color txt;
    if (level == "High") {
      bg = const Color(0xFFEF4444).withOpacity(0.08);
      txt = const Color(0xFFEF4444);
    } else if (level == "Medium") {
      bg = const Color(0xFFF59E0B).withOpacity(0.08);
      txt = const Color(0xFFF59E0B);
    } else {
      bg = const Color(0xFF10B981).withOpacity(0.08);
      txt = const Color(0xFF10B981);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(level, style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
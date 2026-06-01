import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class TeamOverviewScreen extends StatefulWidget {
  const TeamOverviewScreen({super.key});

  @override
  State<TeamOverviewScreen> createState() => _TeamOverviewScreenState();
}

class _TeamOverviewScreenState extends State<TeamOverviewScreen> {
  String _myCompanyId = "";
  bool _isLoadingContext = true;

  @override
  void initState() {
    super.initState();
    _fetchTeamCompanyContext();
  }

  Future<void> _fetchTeamCompanyContext() async {
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
      debugPrint("Team Overview initialization pipeline blocked: $e");
      if (mounted) setState(() => _isLoadingContext = false);
    }
  }

  // --- ANALYTICS PROCESSING CALCULATOR ENGINE ---
  Map<String, dynamic> _processTeamAnalytics(List<DocumentSnapshot> userDocs, List<DocumentSnapshot> taskDocs) {
    int totalMembers = userDocs.length;
    
    // Fallback defaults matching mock setups if database roster is empty
    if (totalMembers == 0) {
      return {
        "total": 32, "active": 28, "onLeave": 4,
        "highCount": 6, "mediumCount": 14, "lowCount": 12,
        "highPct": 19, "mediumPct": 44, "lowPct": 37,
        "roster": _getFallbackRoster(),
      };
    }

    int onLeaveCount = 0;
    List<Map<String, dynamic>> compiledRoster = [];

    // Map member UIDs to track active task backlogs
    Map<String, int> userTaskCounts = {};
    for (var doc in userDocs) {
      userTaskCounts[doc.id] = 0;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['status'] == 'on_leave' || data['status'] == 'leave') {
        onLeaveCount++;
      }
    }

    // Tally active pending backlogs per engineer
    for (var doc in taskDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      bool isDone = data['isCompleted'] == true || data['isDone'] == true || (data['status'] ?? '').toString().toLowerCase() == 'completed';
      
      if (!isDone && data['assignedTo'] != null) {
        final List assignees = data['assignedTo'] is List ? data['assignedTo'] : [data['assignedTo']];
        for (var uid in assignees) {
          if (userTaskCounts.containsKey(uid)) {
            userTaskCounts[uid] = userTaskCounts[uid]! + 1;
          }
        }
      }
    }

    int highWorkload = 0;
    int mediumWorkload = 0;
    int lowWorkload = 0;

    for (var doc in userDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String uid = doc.id;
      final int activeTasks = userTaskCounts[uid] ?? 0;

      String risk = "Low";
      if (activeTasks >= 5) {
        risk = "High";
        highWorkload++;
      } else if (activeTasks >= 2) {
        risk = "Medium";
        mediumWorkload++;
      } else {
        lowWorkload++;
      }

      compiledRoster.add({
        "name": data['username'] ?? 'Anonymous Teammate',
        "role": data['designation'] ?? data['role'] ?? 'Software Developer',
        "risk": risk,
      });
    }

    int highPct = totalMembers > 0 ? ((highWorkload / totalMembers) * 100).round() : 0;
    int mediumPct = totalMembers > 0 ? ((mediumWorkload / totalMembers) * 100).round() : 0;
    int lowPct = totalMembers > 0 ? ((lowWorkload / totalMembers) * 100).round() : 0;

    return {
      "total": totalMembers,
      "active": totalMembers - onLeaveCount,
      "onLeave": onLeaveCount,
      "highCount": highWorkload,
      "mediumCount": mediumWorkload,
      "lowCount": lowWorkload,
      "highPct": highPct,
      "mediumPct": mediumPct,
      "lowPct": lowPct,
      "roster": compiledRoster,
    };
  }

  List<Map<String, dynamic>> _getFallbackRoster() {
    return [
      {"name": "Ajay Bhisara", "role": "UI/UX Designer", "risk": "High"},
      {"name": "Riya Patel", "role": "Frontend Developer", "risk": "Medium"},
      {"name": "Dhruv Joshi", "role": "Backend Developer", "risk": "Low"},
      {"name": "Meet Shah", "role": "QA Engineer", "risk": "Low"},
      {"name": "Tina Desai", "role": "Product Designer", "risk": "Medium"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContext) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F1ED),
        body: Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ForgeTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Team Overview",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ForgeTheme.textDark),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: ForgeTheme.textDark, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('companyId', isEqualTo: _myCompanyId).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue));

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').where('companyId', isEqualTo: _myCompanyId).snapshots(),
              builder: (context, taskSnapshot) {
                if (!taskSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue));

                final analytics = _processTeamAnalytics(userSnapshot.data!.docs, taskSnapshot.data!.docs);
                final List rosterList = analytics['roster'];

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. HORIZONTAL COUNT METRICS CARDS ---
                      Row(
                        children: [
                          _buildTopSummaryTile("Total Members", analytics['total'].toString(), const Color(0xFF3B82F6)),
                          const SizedBox(width: 10),
                          _buildTopSummaryTile("Active", analytics['active'].toString(), const Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          _buildTopSummaryTile("On Leave", analytics['onLeave'].toString(), const Color(0xFFEF4444)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- 2. WORKLOAD DISTRIBUTION DONUT METRIC BLOCK ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Workload Distribution", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                SizedBox(
                                  width: 130,
                                  height: 130,
                                  child: CustomPaint(
                                    painter: DonutChartPainter(
                                      high: analytics['highCount'],
                                      medium: analytics['mediumCount'],
                                      low: analytics['lowCount'],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildLegendRow(Colors.redAccent, "High", "${analytics['highCount']} (${analytics['highPct']}%)"),
                                      const SizedBox(height: 12),
                                      _buildLegendRow(Colors.amber, "Medium", "${analytics['mediumCount']} (${analytics['mediumPct']}%)"),
                                      const SizedBox(height: 12),
                                      _buildLegendRow(Colors.green, "Low", "${analytics['lowCount']} (${analytics['lowPct']}%)"),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- 3. BURNOUT RISK ROSTER LIST ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Burnout Risk", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rosterList.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.black.withOpacity(0.04), height: 24),
                              itemBuilder: (context, index) {
                                final member = rosterList[index];
                                return _buildRosterItemRow(member['name'], member['role'], member['risk']);
                              },
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSummaryTile(String label, String value, Color highlightColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4))),
            const SizedBox(height: 6),
            Text(value.padLeft(2, '0'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: highlightColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, String value) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ForgeTheme.textDark.withOpacity(0.4))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
      ],
    );
  }

  Widget _buildRosterItemRow(String name, String role, String riskLevel) {
    Color badgeBgColor;
    Color badgeTextColor;

    if (riskLevel == "High") {
      badgeBgColor = const Color(0xFFEF4444).withOpacity(0.08);
      badgeTextColor = const Color(0xFFEF4444);
    } else if (riskLevel == "Medium") {
      badgeBgColor = const Color(0xFFF59E0B).withOpacity(0.08);
      badgeTextColor = const Color(0xFFF59E0B);
    } else {
      badgeBgColor = const Color(0xFF10B981).withOpacity(0.08);
      badgeTextColor = const Color(0xFF10B981);
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: ForgeTheme.brandBlue.withOpacity(0.1),
          child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.brandBlue)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
              const SizedBox(height: 1),
              Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ForgeTheme.textDark.withOpacity(0.35))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(12)),
          child: Text(
            riskLevel,
            style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}

// --- VECTOR PATH WORKLOAD DONUT PAINTER ---
class DonutChartPainter extends CustomPainter {
  final int high;
  final int medium;
  final int low;

  DonutChartPainter({required this.high, required this.medium, required this.low});

  @override
  void paint(Canvas canvas, Size size) {
    int total = high + medium + low;
    if (total == 0) total = 1;

    final double sweepHigh = (high / total) * 2 * math.pi;
    final double sweepMedium = (medium / total) * 2 * math.pi;
    final double sweepLow = (low / total) * 2 * math.pi;

    final Rect boundingRectangle = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint slicePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;

    double startingAngle = -math.pi / 2;

    // 1. High Arc
    if (high > 0) {
      slicePaint.color = const Color(0xFFEF4444);
      canvas.drawArc(boundingRectangle, startingAngle, sweepHigh, false, slicePaint);
      startingAngle += sweepHigh;
    }

    // 2. Medium Arc
    if (medium > 0) {
      slicePaint.color = const Color(0xFFF59E0B);
      canvas.drawArc(boundingRectangle, startingAngle, sweepMedium, false, slicePaint);
      startingAngle += sweepMedium;
    }

    // 3. Low Arc
    if (low > 0) {
      slicePaint.color = const Color(0xFF10B981);
      canvas.drawArc(boundingRectangle, startingAngle, sweepLow, false, slicePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
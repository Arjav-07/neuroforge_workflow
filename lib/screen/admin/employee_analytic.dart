import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class EmployeeAnalyticsScreen extends StatefulWidget {
  const EmployeeAnalyticsScreen({super.key});

  @override
  State<EmployeeAnalyticsScreen> createState() => _EmployeeAnalyticsScreenState();
}

class _EmployeeAnalyticsScreenState extends State<EmployeeAnalyticsScreen> {
  String _myCompanyId = "";
  bool _isLoadingContext = true;
  String _selectedTimeframe = "This Week";

  // State trackers holding the selected teammate details
  String? _activeTargetUid;
  String? _activeTargetName;
  String? _activeTargetRole;

  @override
  void initState() {
    super.initState();
    _fetchAdminCompanyContext();
  }

  Future<void> _fetchAdminCompanyContext() async {
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
      debugPrint("Handshake tracing error: $e");
      if (mounted) setState(() => _isLoadingContext = false);
    }
  }

  // --- COMPUTES DYNAMIC METRICS FOR THE SELECTED INDIVIDUAL ---
  Map<String, dynamic> _calculateTargetEmployeeStats(List<DocumentSnapshot> taskDocs, String targetUid) {
    int completed = 0;
    int inProgress = 0;
    int overdue = 0;

    final DateTime midnightToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (var doc in taskDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final List assignees = data['assignedTo'] is List ? data['assignedTo'] : [data['assignedTo'] ?? ''];

      if (assignees.contains(targetUid)) {
        bool isDone = data['isCompleted'] == true || data['isDone'] == true || (data['status'] ?? '').toString().toLowerCase() == 'completed';

        if (isDone) {
          completed++;
        } else {
          inProgress++;
          
          final String? rawDateStr = data['dueDate'] ?? data['date'];
          DateTime? taskDueDate;
          if (rawDateStr != null) {
            try {
              taskDueDate = DateTime.parse(rawDateStr);
            } catch (_) {}
          }

          if (taskDueDate != null && taskDueDate.isBefore(midnightToday)) {
            overdue++;
          } else if (data['isOverdue'] == true) {
            overdue++;
          }
        }
      }
    }

    int totalAssigned = completed + inProgress + overdue;
    int productivityRate = totalAssigned > 0 ? ((completed / totalAssigned) * 100).round() : 0;

    double workloadRatio = totalAssigned > 0 ? (totalAssigned / 12).clamp(0.1, 1.0) : 0.1;
    String workloadStatus = "Optimal";
    Color workloadColor = const Color(0xFF10B981);

    if (workloadRatio > 0.8) {
      workloadStatus = "Overloaded";
      workloadColor = const Color(0xFFEF4444);
    } else if (workloadRatio > 0.5) {
      workloadStatus = "Moderate";
      workloadColor = const Color(0xFFF59E0B);
    }

    String riskLabel = "Low";
    Color riskColor = const Color(0xFF10B981);
    if (overdue > 3 || inProgress > 8) {
      riskLabel = "High";
      riskColor = const Color(0xFFEF4444);
    } else if (overdue > 1 || inProgress > 4) {
      riskLabel = "Medium";
      riskColor = const Color(0xFFF59E0B);
    }

    return {
      "completed": completed,
      "total": totalAssigned,
      "inProgress": inProgress,
      "overdue": overdue,
      "rate": productivityRate,
      "workloadRatio": workloadRatio,
      "workloadStatus": workloadStatus,
      "workloadColor": workloadColor,
      "riskLabel": riskLabel,
      "riskColor": riskColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContext) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F1ED),
        body: Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue)),
      );
    }

    // --- RENDER SCREEN VIEW BASED ON CURRENT SELECTION STATE ---
    if (_activeTargetUid == null) {
      return _buildEmployeeListDirectory();
    }

    return _buildAnalyticsDashboardView();
  }

  // --- VIEW 1: INTERACTIVE TEAM ROSTER DIRECTORY GRID ---
  Widget _buildEmployeeListDirectory() {
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
          "Select Teammate",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ForgeTheme.textDark),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('companyId', isEqualTo: _myCompanyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue));
          }

          final userDocs = snapshot.data!.docs;

          if (userDocs.isEmpty) {
            return Center(
              child: Text(
                "No team members registered yet.",
                style: TextStyle(fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            physics: const BouncingScrollPhysics(),
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final data = userDocs[index].data() as Map<String, dynamic>? ?? {};
              final String uid = userDocs[index].id;
              final String username = data['username'] ?? 'Anonymous Member';
              final String designation = data['designation'] ?? data['role'] ?? 'Software Developer';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      _activeTargetUid = uid;
                      _activeTargetName = username;
                      _activeTargetRole = designation;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: ForgeTheme.brandBlue.withOpacity(0.12),
                          child: Text(
                            username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: ForgeTheme.brandBlue, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                              const SizedBox(height: 2),
                              Text(designation, style: TextStyle(fontSize: 11, color: ForgeTheme.textDark.withOpacity(0.4), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: ForgeTheme.textDark.withOpacity(0.2), size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- VIEW 2: THE DETAILED PERFORMANCE ANALYTICS VIEW ---
  Widget _buildAnalyticsDashboardView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ForgeTheme.textDark, size: 20),
          onPressed: () {
            setState(() {
              _activeTargetUid = null; // Clears the profile selection state stack to safely pop back to directory view
            });
          },
        ),
        title: const Text(
          "Employee Analytics",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ForgeTheme.textDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
          builder: (context, snapshot) {
            final bool hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
            final Map<String, dynamic> metrics = hasData 
                ? _calculateTargetEmployeeStats(snapshot.data!.docs, _activeTargetUid!)
                : {
                    "completed": 18, "total": 30, "inProgress": 10, "overdue": 2, "rate": 88,
                    "workloadRatio": 0.70, "workloadStatus": "Optimal", "workloadColor": const Color(0xFF10B981),
                    "riskLabel": "Low", "riskColor": const Color(0xFF10B981)
                  };

            int total = metrics['total'] > 0 ? metrics['total'] : 1;
            double completedPct = (metrics['completed'] / total) * 100;
            double progressPct = (metrics['inProgress'] / total) * 100;
            double overduePct = (metrics['overdue'] / total) * 100;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE IDENTITY CARD ---
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: ForgeTheme.brandBlue.withOpacity(0.12),
                        child: Text(
                          _activeTargetName!.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ForgeTheme.brandBlue),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_activeTargetName!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                            const SizedBox(height: 1),
                            Text(_activeTargetRole!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ForgeTheme.textDark.withOpacity(0.4))),
                          ],
                        ),
                      ),
                      _buildTimeframeDropdown(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- STAT TILES COMPONENT ---
                  Row(
                    children: [
                      _buildSummaryCard("Tasks Completed", metrics['completed'].toString(), "+ 20%", Colors.green),
                      const SizedBox(width: 10),
                      _buildSummaryCard("Productivity", "${metrics['rate']}%", "+ 14%", Colors.green),
                      const SizedBox(width: 10),
                      _buildSummaryCard("Avg Response", "2h 15m", "Optimal", ForgeTheme.brandBlue),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- WORKLOAD CONTAINER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Workload", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: metrics['workloadRatio'],
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF2F1ED),
                            valueColor: AlwaysStoppedAnimation<Color>(ForgeTheme.brandBlue),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${(metrics['workloadRatio'] * 100).round()}%", 
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
                            ),
                            Text(
                              metrics['workloadStatus'], 
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: metrics['workloadColor']),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- DETAILED PROGRESS LAYER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tasks by Status", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                        const SizedBox(height: 20),
                        _buildStatusRowItem("Completed", metrics['completed'], completedPct.round(), const Color(0xFF3B82F6)),
                        const SizedBox(height: 16),
                        _buildStatusRowItem("In Progress", metrics['inProgress'], progressPct.round(), const Color(0xFF8B5CF6)),
                        const SizedBox(height: 16),
                        _buildStatusRowItem("Overdue", metrics['overdue'], overduePct.round(), const Color(0xFFF97316)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- BURNOUT INSIGHTS CHART GAUGE ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Burnout Risk", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metrics['riskLabel'], 
                                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: metrics['riskColor'], height: 1.1),
                                ),
                                const SizedBox(height: 2),
                                Text.rich(
                                  TextSpan(
                                    text: "Last week: ",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.35)),
                                    children: const [
                                      TextSpan(text: "Medium", style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: SizedBox(
                                height: 55,
                                child: CustomPaint(
                                  painter: MiniWaveSparklinePainter(riskColor: metrics['riskColor']),
                                ),
                              ),
                            )
                          ],
                        )
                      ],
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

  Widget _buildSummaryCard(String title, String count, String deltaLabel, Color trackColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, height: 1.0)),
            const SizedBox(height: 6),
            Text(deltaLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trackColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRowItem(String label, int value, int percentage, Color barColor) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ForgeTheme.textDark.withOpacity(0.5))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF2F1ED),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 50,
          child: Text(
            "$value ($percentage%)", 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
            textAlign: TextAlign.right,
          ),
        )
      ],
    );
  }

  Widget _buildTimeframeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeframe,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: ForgeTheme.textDark.withOpacity(0.6)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
          items: ["This Week", "Last Week", "This Month"].map((String val) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedTimeframe = val);
          },
        ),
      ),
    );
  }
}

class MiniWaveSparklinePainter extends CustomPainter {
  final Color riskColor;
  MiniWaveSparklinePainter({required this.riskColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path wavePath = Path();
    final List<Offset> trackNodes = [
      Offset(0, size.height * 0.80),
      Offset(size.width * 0.16, size.height * 0.72),
      Offset(size.width * 0.32, size.height * 0.50),
      Offset(size.width * 0.48, size.height * 0.65),
      Offset(size.width * 0.64, size.height * 0.45),
      Offset(size.width * 0.80, size.height * 0.25),
      Offset(size.width * 0.96, size.height * 0.15),
    ];

    wavePath.moveTo(trackNodes[0].dx, trackNodes[0].dy);
    for (int i = 1; i < trackNodes.length; i++) {
      wavePath.lineTo(trackNodes[i].dx, trackNodes[i].dy);
    }

    final Paint fillGradientAreaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [riskColor.withOpacity(0.12), riskColor.withOpacity(0.00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path closedAreaPath = Path.from(wavePath);
    closedAreaPath.lineTo(trackNodes.last.dx, size.height);
    closedAreaPath.lineTo(trackNodes.first.dx, size.height);
    closedAreaPath.close();
    canvas.drawPath(closedAreaPath, fillGradientAreaPaint);

    final Paint lineStrokePaint = Paint()
      ..color = riskColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(wavePath, lineStrokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
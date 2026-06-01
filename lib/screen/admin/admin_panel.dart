import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _myCompanyId = "";
  bool _isLoadingContext = true;

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
      debugPrint("Admin panel security handshake blocked: $e");
      if (mounted) setState(() => _isLoadingContext = false);
    }
  }

  // --- REAL-TIME DATA COMPUTATION CORE ENGINE ---
  Map<String, dynamic> _calculateGlobalMetrics(List<DocumentSnapshot> taskDocs) {
    int totalTasks = taskDocs.length;
    int completedCount = 0;
    int inProgressCount = 0;
    int overdueCount = 0;
    
    final Set<String> uniqueProjectScopes = {};
    final DateTime currentTrackingMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (var doc in taskDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      
      String category = data['category'] ?? 'General';
      uniqueProjectScopes.add(category);

      bool isDone = data['isCompleted'] == true || data['isDone'] == true || (data['status'] ?? '').toString().toLowerCase() == 'completed';
      
      if (isDone) {
        completedCount++;
      } else {
        inProgressCount++;
        
        final String? rawDateStr = data['dueDate'] ?? data['date'];
        DateTime? taskDueDate;
        if (rawDateStr != null) {
          try {
            taskDueDate = DateTime.parse(rawDateStr);
          } catch (_) {}
        }
        
        if (taskDueDate != null && taskDueDate.isBefore(currentTrackingMidnight)) {
          overdueCount++;
        } else if (data['isOverdue'] == true) {
          overdueCount++;
        }
      }
    }

    int productivityRate = totalTasks > 0 ? ((completedCount / totalTasks) * 100).round() : 0;

    int highBurnoutCount = 0;
    if (inProgressCount > 0) {
      highBurnoutCount = (inProgressCount / 3).floor() + (overdueCount > 0 ? 1 : 0);
    }
    int burnoutRiskPercentage = totalTasks > 0 ? ((inProgressCount / totalTasks) * 45).round() : 0;
    burnoutRiskPercentage = math.min(100, burnoutRiskPercentage + (overdueCount * 2));

    return {
      "projects": uniqueProjectScopes.isNotEmpty ? uniqueProjectScopes.length : 0,
      "totalTasks": totalTasks,
      "completed": completedCount,
      "overdue": overdueCount,
      "inProgress": inProgressCount,
      "productivityRate": productivityRate,
      "burnoutRate": math.max(5, burnoutRiskPercentage),
      "highRiskCount": highBurnoutCount > 0 ? highBurnoutCount : 0,
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
          "Admin Workspace Center",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ForgeTheme.textDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('companyId', isEqualTo: _myCompanyId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Data Stream Connection Interrupted: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue));
            }

            final Map<String, dynamic> stats = _calculateGlobalMetrics(snapshot.data!.docs);
            final int liveRate = stats['productivityRate'];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. TWO-BY-TWO GRID STATS MATRIX ---
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.85,
                    children: [
                      _buildAdminMetricTile(
                        count: stats['projects'].toString(),
                        label: "Projects",
                        assetPath: "assets/icons/projects.png",
                        themeColor: const Color(0xFF3B82F6),
                        fallbackIcon: Icons.folder_copy_rounded,
                      ),
                      _buildAdminMetricTile(
                        count: stats['totalTasks'].toString(),
                        label: "Tasks",
                        assetPath: "assets/icons/tasks.png",
                        themeColor: const Color(0xFFF59E0B),
                        fallbackIcon: Icons.assignment_rounded,
                      ),
                      _buildAdminMetricTile(
                        count: stats['completed'].toString(),
                        label: "Completed",
                        assetPath: "assets/icons/completed.png",
                        themeColor: const Color(0xFF10B981),
                        fallbackIcon: Icons.check_circle_rounded,
                      ),
                      _buildAdminMetricTile(
                        count: stats['overdue'].toString(),
                        label: "Overdue",
                        assetPath: "assets/icons/overdue.png",
                        themeColor: const Color(0xFFEF4444),
                        fallbackIcon: Icons.error_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- NEW INTERACTIVE MANAGEMENT CONTROL HUB ---
                  _buildPlacardHeaderLabel("WORKSPACE CONTROLS"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _buildHubActionRow(
                          icon: Icons.groups_rounded,
                          title: "Team Overview",
                          subtitle: "Track project member allocations and workspace roles",
                          routePath: "/team-overview",
                        ),
                        _buildDividerLine(),
                        _buildHubActionRow(
                          icon: Icons.analytics_outlined,
                          title: "Employee Analytics",
                          subtitle: "Evaluate specific team member sprint velocity indicators",
                          routePath: "/emp-anlytics",
                        ),
                        _buildDividerLine(),
                        _buildHubActionRow(
                          icon: Icons.stacked_bar_chart_rounded,
                          title: "Overall Analytics",
                          subtitle: "Review combined cross-project systemic execution charts",
                          routePath: "/overall-analytics",
                        ),
                        _buildDividerLine(),
                        _buildHubActionRow(
                          icon: Icons.psychology_rounded,
                          title: "Burnout Insights",
                          subtitle: "Monitor backlog pressures to balance operational health parameters",
                          routePath: "/burnout-insights",
                          customIconColor: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 2. TEAM PRODUCTIVITY SCALED TREND PLOT CHART ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Team Productivity",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ForgeTheme.textDark.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$liveRate%",
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, height: 1.0),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              liveRate >= 50 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                              color: liveRate >= 50 ? const Color(0xFF10B981) : Colors.orange, 
                              size: 16
                            ),
                            const SizedBox(width: 4),
                            Text(
                              liveRate >= 50 ? "Stable Velocity " : "Action Required ",
                              style: TextStyle(
                                color: liveRate >= 50 ? const Color(0xFF10B981) : Colors.orange, 
                                fontWeight: FontWeight.w800, 
                                fontSize: 13
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "across sprints",
                                style: TextStyle(color: ForgeTheme.textDark.withOpacity(0.35), fontWeight: FontWeight.w700, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: LineGraphVectorPainter(liveRate: liveRate),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 3. BURNOUT RISK AND IN-PROGRESS DUO PANEL ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Burnout Risk", 
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ForgeTheme.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${stats['burnoutRate']}%", 
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ForgeTheme.textDark),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "High: ${stats['highRiskCount']}", 
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
                                      child: const Icon(Icons.bolt_rounded, color: Color(0xFFEF4444), size: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tasks in Progress", 
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ForgeTheme.textDark.withOpacity(0.8)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                stats['inProgress'].toString().padLeft(2, '0'),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, height: 1.0),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Across active scopes",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.35)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- 4. INTELLIGENT AI ASSISTANT CONSOLE BAR (ASI-1) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ForgeTheme.brandBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: ForgeTheme.brandBlue.withOpacity(0.12), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: ForgeTheme.brandBlue,
                          backgroundImage: AssetImage("assets/images/ai_avatar.png"),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI Assistant (ASI-1)",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "I have generated strategic velocity insights for your roster today.",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ForgeTheme.textDark.withOpacity(0.5), height: 1.3),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/ai_chat');
                                },
                                child: Container(
                                  height: 40,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: ForgeTheme.brandBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Open ASI-1 Console Chat",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close_rounded, size: 18, color: ForgeTheme.textDark.withOpacity(0.3)),
                          onPressed: () {},
                        ),
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

  Widget _buildAdminMetricTile({
    required String count,
    required String label,
    required String assetPath,
    required Color themeColor,
    required IconData fallbackIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: themeColor.withOpacity(0.12),
            child: Transform.scale(
              scale: 0.45,
              child: Image.asset(
                assetPath,
                color: themeColor,
                errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: themeColor, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count.padLeft(2, '0'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ForgeTheme.textDark, height: 1.1),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.35)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-COMPONENT RENDERING HELPERS ---
  Widget _buildPlacardHeaderLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 14.0, bottom: 8),
      child: Text(
        text, 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.8)
      ),
    );
  }

  Widget _buildDividerLine() {
    return Divider(color: Colors.black.withOpacity(0.04), thickness: 1, height: 1, indent: 56, endIndent: 16);
  }

  Widget _buildHubActionRow({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required String routePath,
    Color? customIconColor,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routePath),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18, 
              backgroundColor: customIconColor != null ? customIconColor.withOpacity(0.1) : const Color(0xFFF2F1ED), 
              child: Icon(icon, color: customIconColor ?? ForgeTheme.brandBlue, size: 18)
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: ForgeTheme.textMuted.withOpacity(0.8), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: ForgeTheme.textMuted.withOpacity(0.4), size: 22),
          ],
        ),
      ),
    );
  }
}

class LineGraphVectorPainter extends CustomPainter {
  final int liveRate;
  LineGraphVectorPainter({required this.liveRate});

  @override
  void paint(Canvas canvas, Size size) {
    final Path trendLinePath = Path();
    final Path gradientAreaPath = Path();

    double targetPeakY = size.height * (1.0 - (liveRate / 100).clamp(0.1, 0.9));

    final List<Offset> points = [
      Offset(0, size.height * 0.90),
      Offset(size.width * 0.14, size.height * 0.75),
      Offset(size.width * 0.28, size.height * 0.78),
      Offset(size.width * 0.42, size.height * 0.65),
      Offset(size.width * 0.56, math.min(size.height * 0.6, targetPeakY * 1.3)),
      Offset(size.width * 0.70, math.min(size.height * 0.5, targetPeakY * 1.1)),
      Offset(size.width * 0.84, math.min(size.height * 0.55, targetPeakY * 1.15)),
      Offset(size.width * 0.98, targetPeakY),
    ];

    trendLinePath.moveTo(points[0].dx, points[0].dy);
    gradientAreaPath.moveTo(points[0].dx, size.height);
    gradientAreaPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      trendLinePath.lineTo(points[i].dx, points[i].dy);
      gradientAreaPath.lineTo(points[i].dx, points[i].dy);
    }

    gradientAreaPath.lineTo(points.last.dx, size.height);
    gradientAreaPath.close();

    final Paint fillGradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ForgeTheme.brandBlue.withOpacity(0.18),
          ForgeTheme.brandBlue.withOpacity(0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(gradientAreaPath, fillGradientPaint);

    final Paint lineStrokePaint = Paint()
      ..color = ForgeTheme.brandBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(trendLinePath, lineStrokePaint);

    final Paint nodePaint = Paint()
      ..color = ForgeTheme.brandBlue
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 3.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineGraphVectorPainter oldDelegate) => oldDelegate.liveRate != liveRate;
}
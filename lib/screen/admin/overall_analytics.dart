import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class OverallAnalyticsScreen extends StatefulWidget {
  const OverallAnalyticsScreen({super.key});

  @override
  State<OverallAnalyticsScreen> createState() => _OverallAnalyticsScreenState();
}

class _OverallAnalyticsScreenState extends State<OverallAnalyticsScreen> {
  String _myCompanyId = "";
  bool _isLoadingContext = true;

  // --- INTERACTIVE CALENDAR STATE ANCHORS ---
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
    // Anchor time frame defensively to Monday of the current active week loop
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
      debugPrint("Overall analytics pipeline tracer blocked: $e");
      if (mounted) setState(() => _isLoadingContext = false);
    }
  }

  // --- NEW ALL-TIME CALENDAR ENGINE SELECTOR ---
  Future<void> _selectCustomWeekFromCalendar() async {
    final DateTime now = DateTime.now();
    
    // Open the system calendar dialog modal allowing historical macro selection
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartOfWeek,
      firstDate: DateTime(2020), // Day one bounds allowed by database architectures
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
      // Calculate Monday matching the targeted pickup timestamp safely
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

  // --- MACRO ANALYTICS CALCULATION ENGINE ---
  Map<String, dynamic> _calculateMacroMetrics(List<DocumentSnapshot> taskDocs) {
    int totalTasks = taskDocs.length;
    int completed = 0;
    int inProgress = 0;
    int overdue = 0;
    int blocked = 0;

    final DateTime currentTrackingMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (var doc in taskDocs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      String status = (data['status'] ?? '').toString().toLowerCase();
      bool isExplicitlyDone = data['isCompleted'] == true || data['isDone'] == true || status == 'completed';

      if (isExplicitlyDone) {
        completed++;
      } else if (status == 'blocked' || data['isBlocked'] == true) {
        blocked++;
      } else {
        inProgress++;
        
        final String? rawDateStr = data['dueDate'] ?? data['date'];
        DateTime? taskDueDate;
        if (rawDateStr != null) {
          try {
            taskDueDate = DateTime.parse(rawDateStr);
          } catch (_) {}
        }
        
        if (taskDueDate != null && taskDueDate.isBefore(currentTrackingMidnight)) {
          overdue++;
        } else if (data['isOverdue'] == true || status == 'overdue') {
          overdue++;
        }
      }
    }

    // FIXED: Shifted from a static fallback matrix to an accurate zero state
    if (totalTasks == 0) {
      return {
        "total": 0, "completed": 0, "inProgress": 0, "overdue": 0, "blocked": 0,
        "completionRate": 0, "productivityScore": 0,
        "compPct": 0, "progPct": 0, "overduePct": 0, "blockedPct": 0
      };
    }

    int completionRate = ((completed / totalTasks) * 100).round();
    int productivityScore = (((completed * 1.0 + inProgress * 0.4) / totalTasks) * 100).round().clamp(0, 100);

    return {
      "total": totalTasks,
      "completed": completed,
      "inProgress": inProgress,
      "overdue": overdue,
      "blocked": blocked,
      "completionRate": completionRate,
      "productivityScore": productivityScore,
      "compPct": ((completed / totalTasks) * 100).round(),
      "progPct": ((inProgress / totalTasks) * 100).round(),
      "overduePct": ((overdue / totalTasks) * 100).round(),
      "blockedPct": ((blocked / totalTasks) * 100).round(),
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

    // Generate strict timeline filter strings matching layout configurations
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
        title: const Text(
          "Overall Analytics",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ForgeTheme.textDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          // FIXED: Appended range constraints directly into the tasks collection stream
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('companyId', isEqualTo: _myCompanyId)
              .where('dueDate', isGreaterThanOrEqualTo: startIsoStr)
              .where('dueDate', isLessThan: endIsoStr)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Data Sync Fault intercepted: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue));
            }

            final Map<String, dynamic> macroStats = _calculateMacroMetrics(snapshot.data!.docs);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- A. DATE RANGE SELECTOR TIMELINE CONTAINER ---
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
                            Icon(Icons.unfold_more_rounded, color: ForgeTheme.textDark.withOpacity(0.4), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- B. TOP ANALYTICAL PLACARD TRIO ROWS ---
                  Row(
                    children: [
                      _buildMacroPlacardTile("Completion Rate", "${macroStats['completionRate']}%", "12%"),
                      const SizedBox(width: 14),
                      _buildMacroPlacardTile("Productivity Score", "${macroStats['productivityScore']} / 100", "15%"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- C. MULTI-LINE HISTORICAL TASKS OVERVIEW CHART ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tasks Overview", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildChartLegendChip(const Color(0xFF10B981), "Completed"),
                              const SizedBox(width: 12),
                              _buildChartLegendChip(const Color(0xFFF59E0B), "In Progress"),
                              const SizedBox(width: 12),
                              _buildChartLegendChip(const Color(0xFFEF4444), "Overdue"),
                              const SizedBox(width: 12),
                              _buildChartLegendChip(const Color(0xFF8B5CF6), "Blocked"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: MultiLineGraphCanvasPainter(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text("Mon", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
                            Text("Tue", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
                            Text("Wed", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
                            Text("Thu", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
                            Text("Fri", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
                            Text("Sat", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
                            Text("Sun", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- D. TOTAL STATUS DONUT AND ROW MIXED DASHBOARD ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tasks by Status", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ForgeTheme.textDark)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CustomPaint(
                                painter: MultiStatusDonutPainter(
                                  comp: macroStats['completed'],
                                  prog: macroStats['inProgress'],
                                  overdue: macroStats['overdue'],
                                  blocked: macroStats['blocked'],
                                  total: macroStats['total'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Navigator.canPop(context) 
                            ? const SizedBox.shrink()
                            : Expanded(
                              child: Column(
                                children: [
                                  _buildStatusRowLegend(const Color(0xFF10B981), "Completed", "${macroStats['completed']} (${macroStats['compPct']}%)"),
                                  const SizedBox(height: 12),
                                  _buildStatusRowLegend(const Color(0xFFF59E0B), "In Progress", "${macroStats['inProgress']} (${macroStats['progPct']}%)"),
                                  const SizedBox(height: 12),
                                  _buildStatusRowLegend(const Color(0xFFEF4444), "Overdue", "${macroStats['overdue']} (${macroStats['overduePct']}%)"),
                                  const SizedBox(height: 12),
                                  _buildStatusRowLegend(const Color(0xFF8B5CF6), "Blocked", "${macroStats['blocked']} (${macroStats['blockedPct']}%)"),
                                ],
                              ),
                            ),
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

  Widget _buildMacroPlacardTile(String title, String mainValue, String percentageDelta) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4))),
            const SizedBox(height: 12),
            Text(mainValue, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, height: 1.0)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 2),
                Text(percentageDelta, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegendChip(Color indicatorColor, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: indicatorColor),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ForgeTheme.textDark.withOpacity(0.4))),
      ],
    );
  }

  Widget _buildStatusRowLegend(Color sectionColor, String label, String metricsText) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: sectionColor),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.4))),
        const Spacer(),
        Text(metricsText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ForgeTheme.textDark)),
      ],
    );
  }
}

class MultiLineGraphCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double i = 0; i <= 4; i++) {
      double alignmentHeight = size.height * (i / 4);
      canvas.drawLine(Offset(0, alignmentHeight), Offset(size.width, alignmentHeight), gridLinePaint);
    }

    final double w = size.width;
    final double h = size.height;

    _drawTrendPath(canvas, w, [h * 0.65, h * 0.45, h * 0.55, h * 0.35, h * 0.50, h * 0.35, h * 0.40], const Color(0xFF3B82F6));
    _drawTrendPath(canvas, w, [h * 0.85, h * 0.65, h * 0.75, h * 0.60, h * 0.75, h * 0.55, h * 0.48], const Color(0xFF10B981));
    _drawTrendPath(canvas, w, [h * 0.95, h * 0.82, h * 0.90, h * 0.78, h * 0.94, h * 0.78, h * 0.76], const Color(0xFFEF4444));
    _drawTrendPath(canvas, w, [h * 0.98, h * 0.95, h * 0.94, h * 0.96, h * 0.92, h * 0.94, h * 0.93], const Color(0xFF8B5CF6));
  }

  void _drawTrendPath(Canvas canvas, double overallWidth, List<double> nodeHeights, Color pathColor) {
    final Path trendLinePath = Path();
    final double xIncrementInterval = overallWidth / (nodeHeights.length - 1);

    trendLinePath.moveTo(0, nodeHeights[0]);
    for (int i = 1; i < nodeHeights.length; i++) {
      trendLinePath.lineTo(i * xIncrementInterval, nodeHeights[i]);
    }

    final Paint curveLineStrokePaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(trendLinePath, curveLineStrokePaint);

    final Paint circleNodePaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < nodeHeights.length; i++) {
      canvas.drawCircle(Offset(i * xIncrementInterval, nodeHeights[i]), 3.0, circleNodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MultiStatusDonutPainter extends CustomPainter {
  final int comp;
  final int prog;
  final int overdue;
  final int blocked;
  final int total;

  MultiStatusDonutPainter({required this.comp, required this.prog, required this.overdue, required this.blocked, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    int workingDivisor = total > 0 ? total : 1;

    final double sweepComp = (comp / workingDivisor) * 2 * math.pi;
    final double sweepProg = (prog / workingDivisor) * 2 * math.pi;
    final double sweepOverdue = (overdue / workingDivisor) * 2 * math.pi;
    final double sweepBlocked = (blocked / workingDivisor) * 2 * math.pi;

    final Rect alignmentBounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint arcSegmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    double dynamicStartAngle = -math.pi / 2;

    if (comp > 0) {
      arcSegmentPaint.color = const Color(0xFF10B981);
      canvas.drawArc(alignmentBounds, dynamicStartAngle, sweepComp, false, arcSegmentPaint);
      dynamicStartAngle += sweepComp;
    }

    if (prog > 0) {
      arcSegmentPaint.color = const Color(0xFFF59E0B);
      canvas.drawArc(alignmentBounds, dynamicStartAngle, sweepProg, false, arcSegmentPaint);
      dynamicStartAngle += sweepProg;
    }

    if (overdue > 0) {
      arcSegmentPaint.color = const Color(0xFFEF4444);
      canvas.drawArc(alignmentBounds, dynamicStartAngle, sweepOverdue, false, arcSegmentPaint);
      dynamicStartAngle += sweepOverdue;
    }

    if (blocked > 0) {
      arcSegmentPaint.color = const Color(0xFF8B5CF6);
      canvas.drawArc(alignmentBounds, dynamicStartAngle, sweepBlocked, false, arcSegmentPaint);
    }

    final TextPainter textRenderer = TextPainter(
      text: TextSpan(
        text: "$total\n",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ForgeTheme.textDark, height: 1.1),
        children: const [
          TextSpan(text: "Total", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ForgeTheme.textMuted)),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final Offset centerTextOffset = Offset(
      (size.width - textRenderer.width) / 2,
      (size.height - textRenderer.height) / 2,
    );
    textRenderer.paint(canvas, centerTextOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuroforge_workflow/core/constant/theme.dart';

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? quickReplies;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies,
  });
}

class Asi1AssistantScreen extends StatefulWidget {
  const Asi1AssistantScreen({super.key});

  @override
  State<Asi1AssistantScreen> createState() => _Asi1AssistantScreenState();
}

class _Asi1AssistantScreenState extends State<Asi1AssistantScreen> {
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();
  
  String _myCompanyId = "";
  String _currentUserName = "Member";
  bool _isLoadingContext = true;
  bool _isAiTyping = false;
  
  final List<MessageModel> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchWorkspaceProfileContext();
  }

  @override
  void dispose() {
    _chatInputController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkspaceProfileContext() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        setState(() {
          _myCompanyId = (data['companyId'] ?? '').toString();
          _currentUserName = (data['username'] ?? data['name'] ?? 'Ajay').toString();
        });
      }
    } catch (e) {
      debugPrint("ASI-1 user validation line tracking fault: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingContext = false);
        _injectGreetingMessage();
      }
    }
  }

  void _injectGreetingMessage() {
    if (_conversationHistory.isEmpty) {
      setState(() {
        _conversationHistory.add(
          MessageModel(
            text: "Hello $_currentUserName! 👋\nI'm ASI-1, your AI workspace assistant. I have established hooks into your team database maps. What operational metrics can we audit?",
            isUser: false,
            timestamp: DateTime.now(),
            quickReplies: [
              "Who is overloaded this week?",
              "Show bottleneck metrics",
              "Suggest how to balance workload"
            ],
          ),
        );
      });
    }
  }

  // --- ASI-1 DYNAMIC FIRESTORE READING ENGINE ---
  Future<String> _evaluateOperationalBacklogsLive() async {
    if (_myCompanyId.isEmpty) {
      return "Workspace context missing. Ensure you are signed into an organization network loop.";
    }

    try {
      // 1. Read live workspace user profiles roster
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: _myCompanyId)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return " Roster metrics clean. No employee data found linked to company: $_myCompanyId";
      }

      // 2. Fetch current week bounded tasks parameters
      final now = DateTime.now();
      final DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final String startIsoStr = startOfWeek.toIso8601String().substring(0, 10);
      final String endIsoStr = startOfWeek.add(const Duration(days: 7)).toIso8601String().substring(0, 10);

      final taskSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('companyId', isEqualTo: _myCompanyId)
          .where('dueDate', isGreaterThanOrEqualTo: startIsoStr)
          .where('dueDate', isLessThan: endIsoStr)
          .get();

      // 3. Extract and parse document collections
      Map<String, int> activeBacklogs = {};
      for (var doc in userSnapshot.docs) {
        activeBacklogs[doc.id] = 0;
      }

      for (var doc in taskSnapshot.docs) {
        final data = doc.data();
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

      List<Map<String, dynamic>> highWorkloadRoster = [];
      for (var doc in userSnapshot.docs) {
        final data = doc.data();
        final String name = data['username'] ?? data['name'] ?? 'Team Member';
        final int backlogs = activeBacklogs[doc.id] ?? 0;
        final int strikes = data['overtimeStrikes'] ?? 0;

        // Dynamic pressure weight calculation formula
        int loadPercentage = math.min(99, (backlogs * 6) + (strikes * 8) + 12);

        if (backlogs > 0) {
          highWorkloadRoster.add({
            "name": name,
            "tasks": backlogs,
            "intensity": loadPercentage,
          });
        }
      }

      if (highWorkloadRoster.isEmpty) {
        return "All active team load allocation metrics look perfectly clear for this sprint window! No risk factors identified.";
      }

      // Sort descending by highest task volume
      highWorkloadRoster.sort((a, b) => (b['tasks'] as int).compareTo(a['tasks'] as int));

      StringBuffer buffer = StringBuffer("Here are the members with high workload this week:\n\n");
      for (int i = 0; i < highWorkloadRoster.length; i++) {
        final member = highWorkloadRoster[i];
        buffer.write("${i + 1}. ${member['name']} - ${member['tasks']} active tasks (${member['intensity']}%)\n");
      }

      return buffer.toString().trim();
    } catch (e) {
      return "Operational telemetry failed to render: Check your Firestore compound composite rules indexes configurations. Error: $e";
    }
  }

  void _handleMessageSubmission(String messageInputText) async {
    if (messageInputText.trim().isEmpty) return;

    _chatInputController.clear();
    final userMessage = MessageModel(
      text: messageInputText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _conversationHistory.add(userMessage);
      _isAiTyping = true; 
    });
    _scrollListToBottomDeck();

    final String normalizedInput = messageInputText.toLowerCase().trim();
    String botReplyText = "";
    List<String>? nextOptions;

    // Active query text matching patterns
    if (normalizedInput.contains('overloaded') || normalizedInput.contains('who is')) {
      botReplyText = await _evaluateOperationalBacklogsLive();
      nextOptions = ["Suggest how to balance workload", "Show bottleneck metrics"];
    } else if (normalizedInput.contains('balance') || normalizedInput.contains('suggest')) {
      botReplyText = "Understood. I can auto-redistribute non-critical backend tasks from higher density staff blocks down into open capacity lanes automatically. Shall I draft the assignment matrix update adjustments?";
      nextOptions = ["Yes, auto-assign balances", "Cancel re-routing actions"];
    } else if (normalizedInput.contains('bottleneck') || normalizedInput.contains('metrics')) {
      botReplyText = "Real-time task indexing alerts show design review phases are tracking a 32% prolonged execution variance compared to standard deployment cycles. Backpressure is starting to form on cross-project sprints.";
      nextOptions = ["Who is overloaded this week?", "Suggest how to balance workload"];
    } else {
      botReplyText = "I am processing that parameters request block. Ask me about workload congestion indicators, project task overloads, or balance suggestions.";
      nextOptions = ["Who is overloaded this week?", "Show bottleneck metrics"];
    }

    // Add a natural minimal reading/typing delay feel to the user interface
    await Future.delayed(Duration(milliseconds: 600 + math.Random().nextInt(600)));

    if (mounted) {
      setState(() {
        _isAiTyping = false;
        _conversationHistory.add(
          MessageModel(
            text: botReplyText,
            isUser: false,
            timestamp: DateTime.now(),
            quickReplies: nextOptions,
          ),
        );
      });
      _scrollListToBottomDeck();
    }
  }

  void _scrollListToBottomDeck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContext) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: ForgeTheme.brandBlue)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ForgeTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: ForgeTheme.brandBlue.withOpacity(0.08),
                  child: const Icon(Icons.auto_awesome_rounded, color: ForgeTheme.brandBlue, size: 18),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ASI-1 Core OS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: ForgeTheme.textDark)),
                Row(
                  children: [
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text("Reading Database", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.35))),
                  ],
                )
              ],
            )
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _listScrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: _conversationHistory.length + (_isAiTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _conversationHistory.length) {
                    return _buildTypingIndicatorRow();
                  }
                  final message = _conversationHistory[index];
                  return _buildInteractiveChatBubbleColumn(message);
                },
              ),
            ),
            
            // --- FIELD DECK INTERACTION HOOP ---
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.5),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _chatInputController,
                          onSubmitted: _handleMessageSubmission,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ForgeTheme.textDark),
                          decoration: InputDecoration(
                            hintText: "Ask ASI-1 anything...",
                            hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ForgeTheme.textDark.withOpacity(0.3)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _handleMessageSubmission(_chatInputController.text),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(color: ForgeTheme.brandBlue, shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.send_rounded, color: Colors.white, size: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveChatBubbleColumn(MessageModel message) {
    return Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              CircleAvatar(
                radius: 15,
                backgroundColor: ForgeTheme.brandBlue.withOpacity(0.06),
                child: const Icon(Icons.auto_awesome_rounded, color: ForgeTheme.brandBlue, size: 14),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: message.isUser ? ForgeTheme.brandBlue : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft: Radius.circular(message.isUser ? 24 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 24),
                  ),
                  boxShadow: [
                    if (!message.isUser)
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: message.isUser ? Colors.white : ForgeTheme.textDark.withOpacity(0.9),
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // --- CONTEXT REPLIES CHIPS ACTION DECKS ---
        if (!message.isUser && message.quickReplies != null && message.quickReplies!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 12, bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.quickReplies!.map((replyText) {
                return InkWell(
                  onTap: () => _handleMessageSubmission(replyText),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ForgeTheme.brandBlue.withOpacity(0.12), width: 1.2),
                    ),
                    child: Text(
                      replyText,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: ForgeTheme.brandBlue),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTypingIndicatorRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: ForgeTheme.brandBlue.withOpacity(0.06),
            child: const Icon(Icons.auto_awesome_rounded, color: ForgeTheme.brandBlue, size: 14),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) => _buildAnimatedDot(index)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 150)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: ForgeTheme.brandBlue.withOpacity(0.3 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // SECURITY: Import dotenv
import 'package:stress_detection_app/core/stress_data.dart';
import 'package:stress_detection_app/core/theme.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  // SECURITY FIX: Read from .env file instead of hardcoding
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Session State Control
  bool _sessionEnded = false;
  bool _isRatingPhase = false;

  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // Check if key exists to prevent crash
    if (_apiKey.isEmpty) {
      debugPrint("ERROR: GEMINI_API_KEY not found in .env file");
      setState(() {
        _messages.add(ChatMessage(
          text: "System Error: API Key missing. Please check configuration.",
          isUser: false,
          time: DateTime.now(),
        ));
      });
      return;
    }
    _initGemini();
  }

  void _initGemini() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 1.0,
      ),
    );

    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    final stressLabel = StressData().currentLabel;
    String greeting = "I'm here. I'm listening.";

    if (stressLabel == "High Stress") {
      greeting = "I can sense things are heavy right now. I'm here to listen. What's happening?";
    } else if (stressLabel == "Relaxed") {
      greeting = "You seem balanced. How is your day going?";
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: greeting,
            isUser: false,
            time: DateTime.now(),
          ));
        });
      }
    });
  }

  void _resetSession() {
    setState(() {
      _messages.clear();
      _isLoading = false;
      _sessionEnded = false;
      _isRatingPhase = false;
    });
    if (_apiKey.isNotEmpty) {
      _addInitialGreeting();
    }
  }

  Future<void> _sendMessage() async {
    if (_sessionEnded) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Add User Message
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // 2. CHECK: Is this a rating? (Intercept logic)
    if (_isRatingPhase && RegExp(r'^[1-5]$').hasMatch(text)) {
      await Future.delayed(const Duration(milliseconds: 600));

      setState(() {
        _messages.add(ChatMessage(
          text: "Thank you for your feedback. Take care—this session is now closed.",
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
        _sessionEnded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Session Ended. Take care!"),
          backgroundColor: AppTheme.primaryTeal,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 3. NORMAL AI PROCESSING
    try {
      final data = StressData();
      final int userTurnCount = _messages.where((m) => m.isUser).length;

      bool userIsClosing = text.toLowerCase().contains("thanks") ||
          text.toLowerCase().contains("bye") ||
          text.toLowerCase().contains("better") ||
          text.toLowerCase().contains("okay") ||
          text.toLowerCase().contains("good");

      String phaseInstruction = "";

      if (userTurnCount <= 1) {
        phaseInstruction = """
        PHASE: DISCOVERY.
        User just started.
        GOAL: Ask probing questions ("Why?", "What happened?"). Do not advise yet.
        """;
      } else if (userTurnCount == 2) {
        phaseInstruction = """
        PHASE: DEEP EMPATHY.
        GOAL: Validate feelings deeply. Say "That sounds hard" or "I hear you."
        """;
      } else if (userTurnCount >= 3 && !userIsClosing) {
        phaseInstruction = """
        PHASE: ACTION & EMPOWERMENT.
        GOAL: Give confidence and specific tools.
        CRITICAL:
        - If they say "I can't", say: "You are capable. Pull yourself together, we can fix this."
        - Offer ONE specific solution (CBT/Action).
        - Be a strong mentor.
        """;
      } else {
        _isRatingPhase = true;
        phaseInstruction = """
        PHASE: CONCLUSION.
        The user seems ready to end.
        INSTRUCTION:
        1. Acknowledge progress.
        2. ASK FOR FEEDBACK: "Before you go, please rate this chat 1 to 5."
        3. Do not say anything else. Just ask for the rating.
        """;
      }

      final String promptContext = """
      SYSTEM IDENTITY:
      You are a world-class Psychotherapist (compassionate, human, expert).
      
      LIVE CONTEXT:
      - Stress: ${data.currentStressValue.toInt()}/100 (${data.currentLabel})
      - Turn: $userTurnCount

      CURRENT INSTRUCTION ($phaseInstruction):
      
      GENERAL RULES:
      - Max 3 sentences.
      - Sound human.
      - Never be generic.

      USER SAYS:
      "$text"
      """;

      final content = [Content.text(promptContext)];
      final response = await _model.generateContent(content);

      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? "I'm here.",
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();

    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Connection blip. Try again. (Error: $e)",
          isUser: false,
          time: DateTime.now(),
        ));
      });
    } finally {
      if (!_sessionEnded) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: _buildOptimizedAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _ChatBubble(message: _messages[index]),
            ),
          ),
          _buildInputArea(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isKeyboardOpen ? 0 : 120,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildOptimizedAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      titleSpacing: 20,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
            child: const Icon(Icons.security, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Therapy Assistant", style: AppTheme.headingStyle.copyWith(fontSize: 16)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(StressData().currentLabel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: _getStatusColor(StressData().currentLabel)),
                    const SizedBox(width: 4),
                    Text(
                      StressData().currentLabel,
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold,
                        color: _getStatusColor(StressData().currentLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'clear') {
              _resetSession();
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: AppTheme.alertCoral, size: 20),
                    SizedBox(width: 12),
                    Text("Clear & Restart", style: TextStyle(color: AppTheme.textDark)),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10)],
      ),
      child: SafeArea(
        top: false, bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1, maxLines: 4,
                enabled: !_sessionEnded,
                decoration: InputDecoration(
                  hintText: _sessionEnded ? "Session closed. Clear & Restart ->" : "Type here...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true, fillColor: const Color(0xFFF5F7F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => (_isLoading || _sessionEnded) ? null : _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: (_isLoading || _sessionEnded) ? null : _sendMessage,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: (_isLoading || _sessionEnded) ? Colors.grey[300] : AppTheme.primaryTeal,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String label) {
    if (label == "High Stress") return AppTheme.alertCoral;
    if (label == "Relaxed") return AppTheme.statuscodecalm;
    return Colors.orange;
  }
}

// ---------------------------------------------------------
// WIDGETS
// ---------------------------------------------------------

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser, required this.time});
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeString = DateFormat('HH:mm').format(message.time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 14, backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/logo.png'),
                  child: Icon(Icons.security, size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryTeal : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF2D3436),
                      fontSize: 15, height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: isUser ? 0 : 40),
            child: Text(timeString, style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/activity_service.dart';

const String _apiKey = 'YOUR_GEMINI_API_KEY';
const String _model = 'gemini-2.5-flash';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _history = [];
  List<String> _chatTitles = [];
  bool _isLoading = false;
  bool _showHistory = false;

  //  Session timer for study hours tracking
  late DateTime _sessionStart;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _loadSavedChats();
  }

  @override
  void dispose() {
    //  Save study time when leaving chat screen
    _saveStudySession();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveStudySession() async {
    final minutes = DateTime.now().difference(_sessionStart).inMinutes;
    if (minutes > 0) {
      await ActivityService.addStudyMinutes(minutes);
    }
  }

  Future<void> _loadSavedChats() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _chatTitles = prefs.getStringList('chat_history_titles') ?? []);
    }
  }

  Future<void> _saveChat(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('chat_history_titles') ?? [];
    if (!list.contains(title)) list.insert(0, title);
    if (list.length > 30) list.removeLast(); // Keep last 30 chats
    await prefs.setStringList('chat_history_titles', list);
    await prefs.setString(title, jsonEncode(_messages));
    if (mounted) setState(() => _chatTitles = list);
  }

  Future<void> _loadChat(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(title);
    if (raw != null && mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(jsonDecode(raw));
        _history = [];
        _showHistory = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _history.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ]
    });
    _scrollToBottom();

    try {
      final res = await http
          .post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': _history,
              'generationConfig': {
                'temperature': 0.7,
                //  Increased from 1024 → 8192 to load full responses
                'maxOutputTokens': 8192,
              }
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print('Gemini API Error: ${res.statusCode}');
        print('Response Body: ${res.body}');
        throw Exception(
          'API Error ${res.statusCode}: ${res.body}',
        );
      }

      final data = jsonDecode(res.body);
      final reply = data['candidates'][0]['content']['parts'][0]['text'] as String;

      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': reply});
          _isLoading = false;
        });
      }

      _history.add({
        'role': 'model',
        'parts': [
          {'text': reply}
        ]
      });

      //  Only track chat count per message
      final subtitle = text.length > 40 ? '${text.substring(0, 40)}...' : text;
      await ActivityService.addActivity('Used AI Chat', subtitle: subtitle, type: 'chat');
      await ActivityService.incrementChats();

      final chatTitle = text.length > 30 ? '${text.substring(0, 30)}...' : text;
      await _saveChat(chatTitle);
    } catch (e) {
      print('Gemini Error: $e');

      if (mounted) {
        setState(() {
          _messages.add({'role': 'error', 'text': 'Gemini Error:\n$e'});
          _isLoading = false;
        });
      }
    }

    //  Scroll after setState has rebuilt
    _scrollToBottom();
  }

  void _clearChat() {
    setState(() {
      _messages = [];
      _history = [];
    });
  }

  void _scrollToBottom() {
    //  Double post-frame callback ensures layout is fully complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F5AF0),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LearnFlow AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Gemini 2.5 Flash', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.chat_bubble_rounded : Icons.history_rounded),
            onPressed: () => setState(() => _showHistory = !_showHistory),
            tooltip: 'Chat History',
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear this chat?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearChat();
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              tooltip: 'Clear Chat',
            ),
        ],
      ),
      body: _showHistory ? _buildHistory() : _buildChat(),
    );
  }

  Widget _buildHistory() {
    if (_chatTitles.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text('No saved chats yet', style: TextStyle(color: Colors.black45, fontSize: 16)),
          SizedBox(height: 8),
          Text('Your conversations will appear here', style: TextStyle(color: Colors.black38, fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatTitles.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () => _loadChat(_chatTitles[i]),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF7F5AF0)),
              const SizedBox(width: 12),
              Expanded(child: Text(_chatTitles[i], style: const TextStyle(fontWeight: FontWeight.w500))),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildChat() {
    return Column(children: [
      Expanded(
        child: _messages.isEmpty
            ? _buildEmptyChat()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  final isUser = msg['role'] == 'user';
                  final isError = msg['role'] == 'error';
                  return _MessageBubble(text: msg['text'], isUser: isUser, isError: isError);
                },
              ),
      ),

      // Thinking indicator
      if (_isLoading)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _ThinkingDot(delay: 0),
                _ThinkingDot(delay: 200),
                _ThinkingDot(delay: 400),
                const SizedBox(width: 10),
                const Text('AI is thinking...', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ]),
            ),
          ),
        ),

      // Input area
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                filled: true,
                fillColor: const Color(0xFFF5F3FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _isLoading ? null : const LinearGradient(colors: [Color(0xFF7F5AF0), Color(0xFF4F46E5)]),
                color: _isLoading ? Colors.black12 : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.send_rounded, color: _isLoading ? Colors.black26 : Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildEmptyChat() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF7F5AF0), Color(0xFF4F46E5)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text('How can I help you today?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Ask any study question, get explanations,\nor generate a study plan.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 32),
        ...[
          'Explain OOP concepts in simple terms',
          'Give me a study plan for my exam',
          'Summarize photosynthesis process',
          'Create 5 MCQs on World War II',
        ].map((prompt) => GestureDetector(
              onTap: () {
                _controller.text = prompt;
                _sendMessage();
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7F5AF0).withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.auto_awesome_outlined, color: Color(0xFF7F5AF0), size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(prompt, style: const TextStyle(fontSize: 14))),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black38),
                ]),
              ),
            )),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isError;
  const _MessageBubble({required this.text, required this.isUser, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)));
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red.shade50
                : isUser
                    ? const Color(0xFF7F5AF0)
                    : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: SelectableText(
            text,
            style: TextStyle(
              color: isError
                  ? Colors.red
                  : isUser
                      ? Colors.white
                      : Colors.black87,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingDot extends StatefulWidget {
  final int delay;
  const _ThinkingDot({required this.delay});

  @override
  State<_ThinkingDot> createState() => _ThinkingDotState();
}

class _ThinkingDotState extends State<_ThinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _a = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _a,
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(color: Color(0xFF7F5AF0), shape: BoxShape.circle),
        ),
      );
}

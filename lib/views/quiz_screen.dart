import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/activity_service.dart';

const String _apiKey = 'YOUR_GEMINI_API_KEY';
const String _model = 'gemini-2.5-flash';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _topicController = TextEditingController();
  String _difficulty = 'Medium';
  String _quizType = 'MCQ';
  int _questionCount = 5;
  bool _isGenerating = false;

  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _quizStarted = false;
  bool _quizFinished = false;

  //  Track actual quiz start time
  DateTime? _quizStartTime;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a topic')));
      return;
    }
    setState(() => _isGenerating = true);

    final prompt = '''
Generate exactly $_questionCount $_quizType quiz questions about "${_topicController.text}" at $_difficulty difficulty.

Return ONLY a JSON array like this:
[
  {
    "question": "Question text?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0,
    "explanation": "Brief explanation of the correct answer"
  }
]

For True/False, use options: ["True", "False"] and correctIndex 0 or 1.
For Short Answer, use options: ["Answer 1", "Answer 2", "Answer 3", "Answer 4"] where index 0 is correct.
Return ONLY valid JSON array, no markdown.
''';

    try {
      final res = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 2048}
        }),
      );

      final data = jsonDecode(res.body);
      final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final parsed = List<Map<String, dynamic>>.from(jsonDecode(clean));

      setState(() {
        _questions = parsed;
        _isGenerating = false;
        _quizStarted = true;
        _currentIndex = 0;
        _score = 0;
        _selectedAnswer = null;
        _answered = false;
        _quizFinished = false;
        // Record exact moment quiz started
        _quizStartTime = DateTime.now();
      });

      await ActivityService.addActivity('Quiz Started', subtitle: _topicController.text, type: 'quiz');
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate quiz. Try again.'), backgroundColor: Colors.red));
      }
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final correct = _questions[_currentIndex]['correctIndex'] as int;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == correct) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      setState(() => _quizFinished = true);
      //  Call proper completion handler
      _completeQuiz();
    }
  }

  //  Real time tracking + correct quiz count increment
  Future<void> _completeQuiz() async {
    if (_quizStartTime != null) {
      final minutes = DateTime.now().difference(_quizStartTime!).inMinutes;
      // Minimum 1 min so very fast quizzes still count
      final clampedMins = minutes.clamp(1, 120);
      await ActivityService.addStudyMinutes(clampedMins);
    }
    // This is what was missing — now quizCount increments
    await ActivityService.incrementQuizzes();

    final topic = _topicController.text;
    await ActivityService.addActivity(
      'Quiz Completed: $topic',
      subtitle: 'Score: $_score / ${_questions.length}',
      type: 'quiz',
    );
  }

  void _restartQuiz() {
    setState(() {
      _quizStarted = false;
      _quizFinished = false;
      _questions = [];
      _currentIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _quizStartTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C9A7),
        foregroundColor: Colors.white,
        title: const Text('Quiz Generator', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_quizStarted) IconButton(icon: const Icon(Icons.refresh), onPressed: _restartQuiz),
        ],
      ),
      body: _quizFinished
          ? _buildResults()
          : _quizStarted
              ? _buildQuiz()
              : _buildSetup(),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00B4DB)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.quiz_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            const Text('AI Quiz Generator', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Generate custom quizzes on any topic instantly', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 24),
        const Text('Topic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))),
        const SizedBox(height: 10),
        TextField(
          controller: _topicController,
          decoration: InputDecoration(
            hintText: 'e.g., World War II, Photosynthesis, Python basics...',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.lightbulb_outline, color: Color(0xFF00C9A7)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
        const SizedBox(height: 22),
        const Text('Quiz Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))),
        const SizedBox(height: 10),
        Row(
            children: ['MCQ', 'True/False', 'Short Answer']
                .map((type) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _quizType = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _quizType == type ? const Color(0xFF00C9A7) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                          ),
                          child: Text(type,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _quizType == type ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              )),
                        ),
                      ),
                    ))
                .toList()),
        const SizedBox(height: 22),
        const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))),
        const SizedBox(height: 10),
        Row(
            children: ['Easy', 'Medium', 'Hard'].map((d) {
          final color = d == 'Easy'
              ? Colors.green
              : d == 'Medium'
                  ? Colors.orange
                  : Colors.red;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _difficulty = d),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _difficulty == d ? color : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Text(d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _difficulty == d ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Number of Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))),
          Row(children: [
            IconButton(
                onPressed: () {
                  if (_questionCount > 3) setState(() => _questionCount--);
                },
                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF00C9A7))),
            Text('$_questionCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
                onPressed: () {
                  if (_questionCount < 15) setState(() => _questionCount++);
                },
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00C9A7))),
          ]),
        ]),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _generateQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: _isGenerating
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Generating Quiz...', style: TextStyle(fontSize: 16)),
                  ])
                : const Text('Generate Quiz', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_currentIndex];
    final options = List<String>.from(q['options']);
    final correctIndex = q['correctIndex'] as int;
    final progress = (_currentIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Question ${_currentIndex + 1} of ${_questions.length}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
          Text('Score: $_score', style: const TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF00C9A7)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00B4DB)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(_quizType, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(height: 14),
            Text(q['question'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
          ]),
        ),
        const SizedBox(height: 20),
        ...options.asMap().entries.map((entry) {
          final i = entry.key;
          final option = entry.value;
          Color bgColor = Colors.white;
          Color textColor = Colors.black87;
          IconData? icon;
          if (_answered) {
            if (i == correctIndex) {
              bgColor = Colors.green.shade50;
              textColor = Colors.green.shade700;
              icon = Icons.check_circle;
            } else if (i == _selectedAnswer) {
              bgColor = Colors.red.shade50;
              textColor = Colors.red.shade700;
              icon = Icons.cancel;
            }
          }
          return GestureDetector(
            onTap: () => _selectAnswer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedAnswer == i && !_answered ? const Color(0xFF00C9A7) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Center(child: Text(String.fromCharCode(65 + i), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00C9A7)))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(option, style: TextStyle(color: textColor, fontWeight: FontWeight.w500))),
                if (icon != null) Icon(icon, color: textColor),
              ]),
            ),
          );
        }),
        if (_answered && q['explanation'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(q['explanation'] as String, style: TextStyle(color: Colors.blue.shade700, height: 1.5))),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        if (_answered)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _questions.length - 1 ? 'Next Question →' : 'View Results',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildResults() {
    final percentage = (_score / _questions.length * 100).round();
    final grade = percentage >= 80
        ? 'Excellent! '
        : percentage >= 60
            ? 'Good Job! '
            : percentage >= 40
                ? 'Keep Practicing '
                : 'Needs Improvement ';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF00B4DB)]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(children: [
            const Text('Quiz Complete! ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: _score / _questions.length,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 10,
                ),
                Text('$percentage%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 16),
            Text(grade, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _ResultChip(label: 'Correct', value: '$_score', color: Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _ResultChip(label: 'Wrong', value: '${_questions.length - _score}', color: Colors.red)),
          const SizedBox(width: 12),
          Expanded(child: _ResultChip(label: 'Total', value: '${_questions.length}', color: const Color(0xFF00C9A7))),
        ]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _restartQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Try New Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _quizFinished = false;
                _quizStarted = true;
                _currentIndex = 0;
                _score = 0;
                _selectedAnswer = null;
                _answered = false;
                _quizStartTime = DateTime.now(); // reset timer
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00C9A7)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Retry Same Quiz', style: TextStyle(color: Color(0xFF00C9A7), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    );
  }
}

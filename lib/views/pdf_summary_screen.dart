import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../services/activity_service.dart';

const String _pdfApiKey = 'YOUR_GEMINI_API_KEY';
const String _pdfModel = 'gemini-2.5-flash';

class PdfSummaryScreen extends StatefulWidget {
  const PdfSummaryScreen({super.key});

  @override
  State<PdfSummaryScreen> createState() => _PdfSummaryScreenState();
}

class _PdfSummaryScreenState extends State<PdfSummaryScreen> with SingleTickerProviderStateMixin {
  String? _fileName;
  int _pageCount = 0;
  String _summary = '';
  List<String> _keyPoints = [];
  List<String> _importantQuestions = [];
  bool _isExtracting = false;
  bool _isGenerating = false;
  late TabController _tabController;

  //  Track time from when summary is ready (user reading time)
  DateTime? _summaryReadyTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    //  Save actual reading time when user leaves
    if (_summaryReadyTime != null) {
      final minutes = DateTime.now().difference(_summaryReadyTime!).inMinutes;
      // Min 2 minutes, max 60 minutes for reading a PDF summary
      final clampedMins = minutes.clamp(2, 60);
      ActivityService.addStudyMinutes(clampedMins);
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        _showError('Could not read file. Please try again.');
        return;
      }

      setState(() {
        _fileName = file.name;
        _isExtracting = true;
        _summary = '';
        _keyPoints = [];
        _importantQuestions = [];
        _summaryReadyTime = null;
      });

      final document = PdfDocument(inputBytes: file.bytes!);
      final extractor = PdfTextExtractor(document);
      final extractedText = extractor.extractText();
      final pages = document.pages.count;
      document.dispose();

      setState(() {
        _pageCount = pages;
        _isExtracting = false;
        _isGenerating = true;
      });

      await _generateSummary(extractedText);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExtracting = false;
          _isGenerating = false;
        });
        _showError('PDF Error: ${e.toString()}');
      }
    }
  }

  Future<void> _generateSummary(String text) async {
    final limitedText = text.length > 8000 ? text.substring(0, 8000) : text;

    if (limitedText.trim().isEmpty) {
      setState(() {
        _summary = 'Could not extract text. This PDF may be image-based.';
        _isGenerating = false;
      });
      return;
    }

    final prompt = '''
Analyze the following document and return ONLY a valid JSON object (no markdown, no extra text):
{
  "summary": "A comprehensive 3-5 paragraph summary",
  "keyPoints": ["point1", "point2", "point3", "point4", "point5", "point6"],
  "questions": ["exam question 1?", "exam question 2?", "exam question 3?", "exam question 4?", "exam question 5?"]
}

Document:
$limitedText
''';

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_pdfModel:generateContent?key=$_pdfApiKey'),
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
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 4096,
          }
        }),
      );

      final data = jsonDecode(response.body);
      final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final clean = raw.replaceAll(RegExp(r'```json|```'), '').trim();
      final parsed = jsonDecode(clean);

      setState(() {
        _summary = parsed['summary'] ?? 'No summary generated.';
        _keyPoints = List<String>.from(parsed['keyPoints'] ?? []);
        _importantQuestions = List<String>.from(parsed['questions'] ?? []);
        _isGenerating = false;
        // Start reading timer from when summary is ready
        _summaryReadyTime = DateTime.now();
      });

      //  Track PDF count so dashboard shows correct count
      await ActivityService.incrementPdfs();
      await ActivityService.addActivity(
        'PDF Summarized',
        subtitle: _fileName ?? 'PDF Document',
        type: 'pdf',
      );
    } catch (e) {
      setState(() {
        _summary = 'Failed to generate summary. Please try again.';
        _isGenerating = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _resetPdf() {
    setState(() {
      _fileName = null;
      _pageCount = 0;
      _summary = '';
      _keyPoints = [];
      _importantQuestions = [];
      _isExtracting = false;
      _isGenerating = false;
      _summaryReadyTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6A88),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('PDF Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_fileName != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _resetPdf,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: (_isExtracting || _isGenerating) ? null : _pickAndProcessPdf,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFF6A88).withOpacity(0.3), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF6A88), Color(0xFFFF8E53)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _fileName == null ? Icons.upload_file_rounded : Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _fileName == null ? 'Upload PDF' : _fileName!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _fileName == null ? const Color(0xFF1E1B4B) : const Color(0xFFFF6A88),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fileName == null ? 'Tap to select — notes, books, assignments' : '$_pageCount pages · Tap to change',
                    style: const TextStyle(color: Colors.black45, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            if (_isExtracting || _isGenerating)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  const CircularProgressIndicator(color: Color(0xFFFF6A88)),
                  const SizedBox(height: 16),
                  Text(
                    _isExtracting ? 'Extracting text from PDF...' : 'Generating AI summary...',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  const Text('This may take a moment', style: TextStyle(color: Colors.black45, fontSize: 13)),
                ]),
              ),
            if (_summary.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Column(children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFFF6A88),
                    unselectedLabelColor: Colors.black45,
                    indicatorColor: const Color(0xFFFF6A88),
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Key Points'),
                      Tab(text: 'Questions'),
                    ],
                  ),
                  SizedBox(
                    height: 480,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: SelectableText(
                            _summary,
                            style: const TextStyle(height: 1.7, fontSize: 14.5),
                          ),
                        ),
                        _keyPoints.isEmpty
                            ? const Center(child: Text('No key points found'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _keyPoints.length,
                                itemBuilder: (context, i) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6A88).withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFF6A88).withOpacity(0.15)),
                                  ),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(colors: [Color(0xFFFF6A88), Color(0xFFFF8E53)]),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                          child: Text('${i + 1}',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(_keyPoints[i], style: const TextStyle(height: 1.5))),
                                  ]),
                                ),
                              ),
                        _importantQuestions.isEmpty
                            ? const Center(child: Text('No questions generated'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _importantQuestions.length,
                                itemBuilder: (context, i) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFF6A88).withOpacity(0.2)),
                                  ),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Icon(Icons.help_outline, color: Color(0xFFFF6A88), size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(_importantQuestions[i], style: const TextStyle(height: 1.5))),
                                  ]),
                                ),
                              ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
            if (_fileName == null && !_isExtracting && !_isGenerating) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  const Text('How It Works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 20),
                  ...[
                    [Icons.upload_file_outlined, 'Upload PDF', 'Notes, books, or assignments'],
                    [Icons.text_snippet_outlined, 'Text Extracted', 'AI reads the content'],
                    [Icons.auto_awesome_outlined, 'AI Generates', 'Summary, key points & questions'],
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFFF6A88).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(item[0] as IconData, color: const Color(0xFFFF6A88)),
                          ),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item[1] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(item[2] as String, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                          ]),
                        ]),
                      )),
                ]),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

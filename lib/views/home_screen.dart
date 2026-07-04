import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'pdf_summary_screen.dart';
import 'planner_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _auth.getCurrentUserName();
    final uid = _auth.getCurrentUserId();

    final pages = [
      _buildHome(context, userName, uid),
      const ChatScreen(),
      const PlannerScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            setState(() {
              _currentIndex = i;
              _searchQuery = '';
              _searchController.clear();
              _isSearching = false;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF7F5AF0).withOpacity(0.15),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF7F5AF0)), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF7F5AF0)), label: 'AI Chat'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: Color(0xFF7F5AF0)),
                label: 'Planner'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF7F5AF0)), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context, String userName, String uid) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFF7F5AF0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LearnFlow AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('AI Study Assistant', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            onPressed: () => _showNotifications(context),
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_searchQuery.isEmpty) setState(() => _isSearching = false);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7F5AF0), Color(0xFF6246EA), Color(0xFF4F46E5)],
                  ),
                  boxShadow: [BoxShadow(color: const Color(0xFF7F5AF0).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome ', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(userName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('Ready to learn something new today?', style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.5, fontSize: 13)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, size: 36, color: Colors.white),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() {
                      _searchQuery = v.toLowerCase().trim();
                      _isSearching = v.isNotEmpty;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Search activities, topics, quizzes...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF7F5AF0)),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black38),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _isSearching = false;
                              }),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                      hintStyle: const TextStyle(color: Colors.black38),
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 12),
                    _buildSearchResults(uid),
                  ],
                ],
              ),

              if (!_isSearching) ...[
                const SizedBox(height: 28),
                const Text('Quick Access', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 14),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    _QuickCard(
                      title: 'AI Chat',
                      subtitle: 'Ask anything',
                      icon: Icons.chat_bubble_outline_rounded,
                      gradient: const [Color(0xFF7F5AF0), Color(0xFF6246EA)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                    ),
                    _QuickCard(
                      title: 'PDF Summary',
                      subtitle: 'Summarize notes',
                      icon: Icons.picture_as_pdf_outlined,
                      gradient: const [Color(0xFFFF6A88), Color(0xFFFF8E53)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfSummaryScreen())),
                    ),
                    _QuickCard(
                      title: 'Quiz Generator',
                      subtitle: 'Test yourself',
                      icon: Icons.quiz_outlined,
                      gradient: const [Color(0xFF00C9A7), Color(0xFF00B4DB)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                    ),
                    _QuickCard(
                      title: 'Study Planner',
                      subtitle: 'Manage schedule',
                      icon: Icons.calendar_month_outlined,
                      gradient: const [Color(0xFFFF9966), Color(0xFFFF5E62)],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen())),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                const Text('Study Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 14),

                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _firestore.collection('users').doc(uid).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() ?? {};
                    final studyMinutes = (data['studyMinutes'] ?? 0) as int;
                    final hours = studyMinutes ~/ 60;
                    final mins = studyMinutes % 60;
                    final timeLabel = studyMinutes == 0
                        ? '0m'
                        : hours > 0
                            ? '${hours}h ${mins}m'
                            : '${mins}m';

                    return Column(children: [
                      // Row 1
                      Row(children: [
                        Expanded(
                            child: _ProgressCard(title: 'Study Time', value: timeLabel, icon: Icons.timer_outlined, color: const Color(0xFF7F5AF0))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _ProgressCard(
                                title: 'AI Chats', value: '${data['chatCount'] ?? 0}', icon: Icons.chat_outlined, color: const Color(0xFF00C9A7))),
                      ]),
                      const SizedBox(height: 12),
                      // Row 2
                      Row(children: [
                        // ✅ FIX: Now correctly reads quizCount
                        Expanded(
                            child: _ProgressCard(
                                title: 'Quizzes Done',
                                value: '${data['quizCount'] ?? 0}',
                                icon: Icons.quiz_outlined,
                                color: const Color(0xFFFF6A88))),
                        const SizedBox(width: 12),
                        // ✅ NEW: PDF count card
                        Expanded(
                            child: _ProgressCard(
                                title: 'PDFs Done',
                                value: '${data['pdfCount'] ?? 0}',
                                icon: Icons.picture_as_pdf_outlined,
                                color: const Color(0xFFFF9966))),
                      ]),
                    ]);
                  },
                ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    //See All navigates to full list
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => _AllActivitiesScreen(uid: uid)),
                      ),
                      child: const Text('See All', style: TextStyle(color: Color(0xFF7F5AF0))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Only latest 5 activities shown
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore.collection('users').doc(uid).collection('activities').orderBy('time', descending: true).limit(5).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return _EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No Activity Yet',
                        subtitle: 'Start chatting, taking quizzes, or summarizing PDFs',
                      );
                    }
                    return _buildActivityList(docs);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(uid).collection('activities').orderBy('time', descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final allDocs = snapshot.data!.docs;
        final filtered = allDocs.where((doc) {
          final data = doc.data();
          final title = (data['title'] ?? '').toString().toLowerCase();
          final subtitle = (data['subtitle'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) || subtitle.contains(_searchQuery);
        }).toList();

        final quickItems = [
          {'title': 'AI Chat', 'screen': 'chat', 'icon': Icons.chat_bubble_outline},
          {'title': 'PDF Summary', 'screen': 'pdf', 'icon': Icons.picture_as_pdf_outlined},
          {'title': 'Quiz Generator', 'screen': 'quiz', 'icon': Icons.quiz_outlined},
          {'title': 'Study Planner', 'screen': 'planner', 'icon': Icons.calendar_month_outlined},
        ].where((item) => item['title'].toString().toLowerCase().contains(_searchQuery)).toList();

        if (filtered.isEmpty && quickItems.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.search_off, color: Colors.black38),
              const SizedBox(width: 12),
              Text('No results for "$_searchQuery"', style: const TextStyle(color: Colors.black45)),
            ]),
          );
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (quickItems.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text('Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black45)),
                ),
                ...quickItems.map((item) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF7F5AF0).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(item['icon'] as IconData, color: const Color(0xFF7F5AF0), size: 20),
                      ),
                      title: Text(item['title'] as String),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.black26),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        final screen = item['screen'];
                        Widget page = const ChatScreen();
                        if (screen == 'pdf') page = const PdfSummaryScreen();
                        if (screen == 'quiz') page = const QuizScreen();
                        if (screen == 'planner') page = const PlannerScreen();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
                      },
                    )),
              ],
              if (filtered.isNotEmpty) ...[
                if (quickItems.isNotEmpty) const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text('Activity Matches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black45)),
                ),
                ...filtered.take(5).map((doc) {
                  final data = doc.data();
                  final type = data['type'] ?? 'chat';
                  final color = type == 'quiz'
                      ? const Color(0xFF00C9A7)
                      : type == 'pdf'
                          ? const Color(0xFFFF6A88)
                          : const Color(0xFF7F5AF0);
                  final icon = type == 'quiz'
                      ? Icons.quiz_outlined
                      : type == 'pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.chat_bubble_outline;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(data['title']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                    subtitle: Text(data['subtitle']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    String? lastGroup;
    return Column(
      children: docs.map((doc) {
        final data = doc.data();
        final type = data['type'] ?? 'chat';
        final timestamp = data['time'] as Timestamp?;
        final time = timestamp?.toDate();
        final timeAgo = time != null ? _formatTimeAgo(time) : '';
        final groupLabel = time != null ? _getGroupLabel(time) : '';

        final color = type == 'quiz'
            ? const Color(0xFF00C9A7)
            : type == 'pdf'
                ? const Color(0xFFFF6A88)
                : const Color(0xFF7F5AF0);
        final icon = type == 'quiz'
            ? Icons.quiz_outlined
            : type == 'pdf'
                ? Icons.picture_as_pdf_outlined
                : Icons.chat_bubble_outline;
        final typeBadge = type == 'quiz'
            ? 'Quiz'
            : type == 'pdf'
                ? 'PDF'
                : 'Chat';

        final showGroup = groupLabel != lastGroup;
        if (showGroup) lastGroup = groupLabel;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showGroup) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 8, bottom: 6),
                child: Text(groupLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black45)),
              ),
            ],
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['title']?.toString() ?? 'Activity',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if ((data['subtitle']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(data['subtitle']?.toString() ?? '',
                          style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(typeBadge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 11, color: Colors.black38),
                      const SizedBox(width: 3),
                      Text(timeAgo, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                    ]),
                  ]),
                ),
              ]),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  String _getGroupLabel(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return 'This Week';
    return 'Earlier';
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Icon(Icons.notifications_none, size: 52, color: Colors.black26),
          const SizedBox(height: 12),
          const Text('No new notifications', style: TextStyle(color: Colors.black45, fontSize: 15)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// NEW: Full activity history screen (opened by See All button)
class _AllActivitiesScreen extends StatelessWidget {
  final String uid;
  const _AllActivitiesScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F5AF0),
        foregroundColor: Colors.white,
        title: const Text('All Activities', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('users').doc(uid).collection('activities').orderBy('time', descending: true).limit(100).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7F5AF0)));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.history_rounded, size: 72, color: Colors.black26),
                SizedBox(height: 16),
                Text('No activity yet', style: TextStyle(fontSize: 18, color: Colors.black45, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Your study activities will appear here', style: TextStyle(color: Colors.black38, fontSize: 13)),
              ]),
            );
          }

          String? lastGroup;
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final type = data['type'] ?? 'chat';
              final timestamp = data['time'] as Timestamp?;
              final time = timestamp?.toDate();
              final timeAgo = time != null ? _fmt(time) : '';
              final groupLabel = time != null ? _group(time) : '';

              final color = type == 'quiz'
                  ? const Color(0xFF00C9A7)
                  : type == 'pdf'
                      ? const Color(0xFFFF6A88)
                      : const Color(0xFF7F5AF0);
              final icon = type == 'quiz'
                  ? Icons.quiz_outlined
                  : type == 'pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.chat_bubble_outline;
              final badge = type == 'quiz'
                  ? 'Quiz'
                  : type == 'pdf'
                      ? 'PDF'
                      : 'Chat';

              final showGroup = groupLabel != lastGroup;
              if (showGroup) lastGroup = groupLabel;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showGroup) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                      child: Text(groupLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black45)),
                    ),
                  ],
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(data['title']?.toString() ?? 'Activity',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if ((data['subtitle']?.toString() ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(data['subtitle']?.toString() ?? '',
                                style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time, size: 11, color: Colors.black38),
                            const SizedBox(width: 3),
                            Text(timeAgo, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  String _group(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return 'This Week';
    return 'Earlier';
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _QuickCard({required this.title, required this.subtitle, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ]),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _ProgressCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ]),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(icon, size: 48, color: Colors.black26),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black45)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black38, fontSize: 13)),
      ]),
    );
  }
}

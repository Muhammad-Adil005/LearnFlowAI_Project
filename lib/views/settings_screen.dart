import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();
  bool _studyReminders = true;
  bool _quizReminders = false;
  bool _appNotifications = true;
  String _responseStyle = 'Balanced';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studyReminders = prefs.getBool('pref_study_reminders') ?? true;
      _quizReminders = prefs.getBool('pref_quiz_reminders') ?? false;
      _appNotifications = prefs.getBool('pref_app_notifications') ?? true;
      _responseStyle = prefs.getString('pref_response_style') ?? 'Balanced';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  //  FIXED: Logout properly clears stack and goes to WelcomeScreen
  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _auth.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  //  FIXED: Edit name dialog
  void _editProfile() {
    final nameController = TextEditingController(text: _auth.getCurrentUserName());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Your full name',
            filled: true,
            fillColor: const Color(0xFFF5F3FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7F5AF0)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  _showSnackBar('Name updated successfully!', Colors.green);
                }
              } catch (e) {
                _showSnackBar('Error: ${e.toString()}', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7F5AF0), foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  //  FIXED: Change password via email reset
  void _changePassword() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline, size: 48, color: Color(0xFF7F5AF0)),
          const SizedBox(height: 16),
          Text('A password reset link will be sent to:\n${user?.email}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                if (mounted) _showSnackBar('Password reset email sent!', Colors.green);
              } catch (e) {
                if (mounted) _showSnackBar('Error: ${e.toString()}', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7F5AF0), foregroundColor: Colors.white),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  //  FIXED: Privacy policy dialog
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'LearnFlow AI Privacy Policy\n\n'
            '1. Data Collection\nWe collect your name, email, and study activity data to personalize your learning experience.\n\n'
            '2. Data Usage\nYour data is used solely to provide AI study assistance and track your progress.\n\n'
            '3. Firebase\nWe use Google Firebase for authentication and secure data storage.\n\n'
            '4. Gemini AI\nChat messages are sent to Gemini AI API for processing. We do not store AI conversations permanently on our servers.\n\n'
            '5. Data Security\nAll data is encrypted in transit and at rest using industry-standard security.\n\n'
            '6. Your Rights\nYou can delete your account and all associated data at any time.\n\n'
            'Last updated: 2025',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7F5AF0), foregroundColor: Colors.white),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  //  FIXED: About dialog
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'LearnFlow AI',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7F5AF0), Color(0xFF4F46E5)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
      children: const [
        SizedBox(height: 12),
        Text(
          'LearnFlow AI is an AI-powered study assistant built with Flutter and Firebase, powered by Google Gemini AI.\n\n'
          'Features:\n• AI Chat Assistant\n• PDF Summarization\n• Quiz Generator\n• Study Planner\n• Progress Tracking',
          style: TextStyle(height: 1.5),
        ),
        SizedBox(height: 12),
        Text('Developed for students worldwide 🌍', style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _auth.getCurrentUserName();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F5AF0),
        foregroundColor: Colors.white,
        title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //  Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7F5AF0), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: _editProfile,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 13, color: Color(0xFF7F5AF0)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Student', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.verified, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        const Text('Verified', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: _editProfile,
                tooltip: 'Edit Profile',
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Notifications
          _SectionHeader(title: 'Notifications'),
          _SettingsCard(children: [
            _ToggleTile(
                title: 'Study Reminders',
                subtitle: 'Daily reminders to study',
                icon: Icons.school_outlined,
                value: _studyReminders,
                onChanged: (v) {
                  setState(() => _studyReminders = v);
                  _savePreference('pref_study_reminders', v);
                }),
            const Divider(height: 1, indent: 56),
            _ToggleTile(
                title: 'Quiz Reminders',
                subtitle: 'Daily quiz challenges',
                icon: Icons.quiz_outlined,
                value: _quizReminders,
                onChanged: (v) {
                  setState(() => _quizReminders = v);
                  _savePreference('pref_quiz_reminders', v);
                }),
            const Divider(height: 1, indent: 56),
            _ToggleTile(
                title: 'App Notifications',
                subtitle: 'General updates & alerts',
                icon: Icons.notifications_outlined,
                value: _appNotifications,
                onChanged: (v) {
                  setState(() => _appNotifications = v);
                  _savePreference('pref_app_notifications', v);
                }),
          ]),

          const SizedBox(height: 16),

          // AI Preferences
          _SectionHeader(title: 'AI Preferences'),
          _SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.tune_outlined, color: Color(0xFF7F5AF0), size: 20),
                  SizedBox(width: 12),
                  Text('Response Style', style: TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                Row(
                    children: ['Concise', 'Balanced', 'Detailed']
                        .map((style) => Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _responseStyle = style);
                                  _savePreference('pref_response_style', style);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _responseStyle == style ? const Color(0xFF7F5AF0) : const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(style,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _responseStyle == style ? Colors.white : Colors.black54,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      )),
                                ),
                              ),
                            ))
                        .toList()),
              ]),
            ),
          ]),

          const SizedBox(height: 16),

          // Account & Security
          _SectionHeader(title: 'Account & Security'),
          _SettingsCard(children: [
            _NavTile(title: 'Edit Profile', subtitle: 'Change your name', icon: Icons.person_outline, onTap: _editProfile),
            const Divider(height: 1, indent: 56),
            _NavTile(title: 'Change Password', subtitle: 'Send password reset email', icon: Icons.lock_outline, onTap: _changePassword),
            const Divider(height: 1, indent: 56),
            _NavTile(title: 'Privacy Policy', subtitle: 'How we use your data', icon: Icons.privacy_tip_outlined, onTap: _showPrivacyPolicy),
            const Divider(height: 1, indent: 56),
            _NavTile(title: 'About LearnFlow AI', subtitle: 'Version 1.0.0', icon: Icons.info_outline, onTap: _showAbout),
          ]),

          const SizedBox(height: 16),

          _SettingsCard(children: [
            _NavTile(
              title: 'Logout',
              subtitle: 'Sign out of your account',
              icon: Icons.logout_rounded,
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: _logout,
            ),
          ]),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(children: children),
      );
}

class _ToggleTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.title, required this.subtitle, required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        secondary: Icon(icon, color: const Color(0xFF7F5AF0)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF7F5AF0),
      );
}

class _NavTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color? iconColor, textColor;
  final VoidCallback onTap;
  const _NavTile({required this.title, required this.subtitle, required this.icon, required this.onTap, this.iconColor, this.textColor});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFF7F5AF0)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26),
        onTap: onTap,
      );
}

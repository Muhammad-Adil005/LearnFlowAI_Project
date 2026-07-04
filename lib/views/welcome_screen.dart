import 'package:flutter/material.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7F5AF0), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7F5AF0).withOpacity(0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 64, color: Colors.white),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'LearnFlow AI',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Your Smart AI Study Assistant\npowered by Gemini',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 1),


              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeatureIcon(
                      icon: Icons.chat_bubble_outline,
                      label: 'AI Chat',
                      color: const Color(0xFF7F5AF0)),
                  const SizedBox(width: 28),
                  _FeatureIcon(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDF',
                      color: const Color(0xFFFF6A88)),
                  const SizedBox(width: 28),
                  _FeatureIcon(
                      icon: Icons.quiz_outlined,
                      label: 'Quizzes',
                      color: const Color(0xFF00C9A7)),
                  const SizedBox(width: 28),
                  _FeatureIcon(
                      icon: Icons.calendar_month_outlined,
                      label: 'Planner',
                      color: const Color(0xFFFF9966)),
                ],
              ),

              const Spacer(flex: 2),


              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F5AF0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}


class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureIcon(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    ]);
  }
}
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'mock_test_screen.dart';
import 'road_signs_screen.dart';
import 'traffic_rules_screen.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Learning Center',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Driving License',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('Exam Preparation',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 8),
                        Text('Practice with 500+ questions and\npass on your first attempt!',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12,
                                height: 1.4)),
                      ],
                    ),
                  ),
                  const Icon(Icons.drive_eta_rounded,
                      size: 80, color: Colors.white24),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                _StatCard('500+', 'Questions', Icons.quiz_rounded, AppColors.primary),
                const SizedBox(width: 10),
                _StatCard('50+', 'Road Signs', Icons.warning_amber_rounded, AppColors.accent),
                const SizedBox(width: 10),
                _StatCard('20+', 'Mock Tests', Icons.assignment_rounded, AppColors.secondary),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Study Modules',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ModuleCard(
                  icon: Icons.quiz_rounded,
                  title: 'Mock Tests',
                  subtitle: '20 full tests available',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MockTestScreen())),
                ),
                _ModuleCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Road Signs',
                  subtitle: '50+ signs with meanings',
                  color: AppColors.accent,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RoadSignsScreen())),
                ),
                _ModuleCard(
                  icon: Icons.rule_rounded,
                  title: 'Traffic Rules',
                  subtitle: 'Complete rule book',
                  color: AppColors.secondary,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TrafficRulesScreen())),
                ),
                _ModuleCard(
                  icon: Icons.help_outline_rounded,
                  title: 'Practice Q&A',
                  subtitle: '500+ questions',
                  color: AppColors.info,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MockTestScreen())),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Coming Soon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),

            _ComingSoonCard(
              icon: Icons.account_balance_rounded,
              title: 'Loksewa Preparation',
              subtitle: 'Public Service Commission exam prep',
              color: const Color(0xFF4A148C),
            ),
            const SizedBox(height: 10),
            _ComingSoonCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'General Knowledge',
              subtitle: 'Nepal GK for all exams',
              color: const Color(0xFF00695C),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Soon',
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

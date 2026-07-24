import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/l10n_extension.dart';
import 'mock_test_screen.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _selectedCat = 0;

  final _categories = const [
    _Cat('All',       Icons.grid_view_rounded),
    _Cat('Driving',   Icons.directions_car_rounded),
    _Cat('Documents', Icons.folder_rounded),
    _Cat('Loksewa',   Icons.account_balance_rounded),
    _Cat('Finance',   Icons.bar_chart_rounded),
    _Cat('Rights',    Icons.gavel_rounded),
  ];

  String _getCategoryName(BuildContext context, String key) {
    switch (key) {
      case 'All': return context.l10n.all;
      case 'Driving': return context.l10n.categoryDriving;
      case 'Documents': return context.l10n.documents;
      case 'Loksewa': return context.l10n.categoryLoksewa;
      case 'Finance': return context.l10n.categoryFinance;
      case 'Rights': return context.l10n.categoryRights;
      default: return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader()],
        body: Column(
          children: [
            _buildStatsCard(context),
            _buildCategoryFilter(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildCoursesTab(context),
                  _buildQuizzesTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver header ─────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TutorialsHeaderDelegate(tab: _tab),
    );
  }

  // ── Floating stats card ───────────────────────────────────────────────────
  Widget _buildStatsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _StatCell(Icons.menu_book_rounded,    '500+', context.l10n.questions, AppColors.primary),
          _vDivider(),
          _StatCell(Icons.play_circle_rounded,  '50+',  context.l10n.tutorials, const Color(0xFFF57F17)),
          _vDivider(),
          _StatCell(Icons.assignment_rounded,   '20+',  context.l10n.mockTests, AppColors.secondary),
          _vDivider(),
          _StatCell(Icons.subject_rounded,      '4',    context.l10n.subjects,  const Color(0xFF7B1FA2)),
        ],
      ),
    );
  }

  Widget _StatCell(IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 5),
        Text(val,
            style: TextStyle(
                color: color, fontSize: 15, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8A96A3), fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _vDivider() => Container(
        width: 1, height: 38, color: const Color(0xFFEEF2F8));

  // ── Category filter ───────────────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final active = _selectedCat == i;
          final cat = _categories[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFF0F4FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cat.icon,
                    color: active ? Colors.white : const Color(0xFF7A8898),
                    size: 14),
                const SizedBox(width: 5),
                Text(_getCategoryName(context, cat.label),
                    style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF5A6A80),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Courses tab ───────────────────────────────────────────────────────────
  Widget _buildCoursesTab(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final featured = [
      _Course(
        isNepali ? 'सवारी चालक अनुमतिपत्र तयारी' : 'Driving License Exam Prep',
        isNepali ? 'पहिलो प्रयासमै उत्तीर्ण हुने पूर्ण निर्देशिका' : 'Complete guide to pass on first attempt',
        Icons.drive_eta_rounded, const Color(0xFF1565C0), isNepali ? '१२ पाठ' : '12 lessons', 0.85),
      _Course(
        isNepali ? 'नेपालको ट्राफिक नियमहरू' : 'Traffic Rules of Nepal',
        isNepali ? 'आधिकारिक ट्राफिक नियमहरूको व्याख्या' : 'Official traffic regulations explained',
        Icons.traffic_rounded, const Color(0xFF2E7D32), isNepali ? '८ पाठ' : '8 lessons', 0.60),
    ];

    final allCourses = [
      _Course(isNepali ? 'सवारी अनुमतिपत्र' : 'Driving License',    isNepali ? '२४ पाठ' : '24 lessons', Icons.drive_eta_rounded,        const Color(0xFFF57F17), isNepali ? '२४ पाठ' : '24 lessons', 0.0),
      _Course(isNepali ? 'लोकसेवा तयारी' : 'Loksewa Exam',       isNepali ? '१८ पाठ' : '18 lessons', Icons.account_balance_rounded,  const Color(0xFF4A148C), isNepali ? '१८ पाठ' : '18 lessons', 0.0),
      _Course(isNepali ? 'कागजात निर्देशिका' : 'Documents Guide',    isNepali ? '१६ पाठ' : '16 lessons', Icons.description_rounded,      const Color(0xFF2E7D32), isNepali ? '१६ पाठ' : '16 lessons', 0.0),
      _Course(isNepali ? 'वित्तीय साक्षरता' : 'Financial Literacy', isNepali ? '१२ पाठ' : '12 lessons', Icons.bar_chart_rounded,        const Color(0xFF1565C0), isNepali ? '१२ पाठ' : '12 lessons', 0.0),
      _Course(isNepali ? 'मतदाता अधिकार' : 'Voter Rights',       isNepali ? '८ पाठ' : '8 lessons',  Icons.how_to_vote_rounded,      const Color(0xFFD32F2F), isNepali ? '८ पाठ' : '8 lessons',  0.0),
      _Course(isNepali ? 'नागरिक अधिकार' : 'Citizens Rights',    isNepali ? '१० पाठ' : '10 lessons', Icons.gavel_rounded,            const Color(0xFF00695C), isNepali ? '१० पाठ' : '10 lessons', 0.0),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _SectionHeader(isNepali ? 'सिकाइ जारी राख्नुहोस्' : 'Continue Learning', onTap: () {}),
        const SizedBox(height: 10),
        ...featured.map((c) => _FeaturedCourseCard(course: c, onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MockTestScreen())))),
        const SizedBox(height: 20),
        _SectionHeader(isNepali ? 'सबै ट्यूटोरियलहरू' : 'All Tutorials', onTap: () {}),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.72,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: allCourses.length,
          itemBuilder: (_, i) => _CourseGridCard(course: allCourses[i], onTap: () {}),
        ),
      ],
    );
  }

  // ── Quizzes / Mock Tests tab ──────────────────────────────────────────────
  Widget _buildQuizzesTab(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final quizzes = [
      _Quiz(isNepali ? 'पूर्ण नमूना परीक्षा #१' : 'Full Mock Test #1', isNepali ? 'सबै विषयहरू · ५० प्रश्न · ३० मिनेट' : 'All topics · 50 questions · 30 min',
          Icons.assignment_rounded, AppColors.primary, isNepali ? 'सुरु गर्नुहोस्' : 'Start', false),
      _Quiz(isNepali ? 'सडक संकेत क्विज' : 'Road Signs Quiz', isNepali ? 'संकेत र इशारा · २० प्रश्न · १५ मिनेट' : 'Signs & signals · 20 questions · 15 min',
          Icons.warning_amber_rounded, const Color(0xFFF57F17), isNepali ? 'सुरु गर्नुहोस्' : 'Start', false),
      _Quiz(isNepali ? 'ट्राफिक नियम परीक्षा' : 'Traffic Rules Test', isNepali ? 'नियम र कानुन · ३० प्रश्न' : 'Rules & regulations · 30 questions',
          Icons.traffic_rounded, AppColors.secondary, isNepali ? 'सुरु गर्नुहोस्' : 'Start', false),
      _Quiz(isNepali ? 'अभ्यास सेट ए' : 'Practice Set A', isNepali ? 'मिश्रित विषय · २५ प्रश्न' : 'Mixed topics · 25 questions',
          Icons.quiz_rounded, AppColors.info, isNepali ? 'पुनः सुरु गर्नुहोस्' : 'Resume', true),
      _Quiz(isNepali ? 'लोकसेवा सामान्य ज्ञान' : 'Loksewa GK Round 1', isNepali ? 'सामान्य ज्ञान · ४० प्रश्न' : 'General knowledge · 40 questions',
          Icons.account_balance_rounded, const Color(0xFF4A148C), isNepali ? 'सुरु गर्नुहोस्' : 'Start', false),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Progress card
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(isNepali ? 'तपाईंको प्रगति' : 'Your Progress',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(isNepali ? 'यसरी नै अगाडि बढ्नुहोस्!' : 'Keep it up!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.35,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )),
                    const SizedBox(width: 10),
                    const Text('35%',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  Text(isNepali ? '२० मध्ये ७ नमूना परीक्षा पुरा भयो' : '7 of 20 mock tests completed',
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ])),
            const SizedBox(width: 16),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 32),
            ),
          ]),
        ),
        _SectionHeader(isNepali ? 'उपलब्ध परीक्षाहरू' : 'Available Tests', onTap: null),
        const SizedBox(height: 10),
        ...quizzes.map((q) => _QuizCard(
            quiz: q,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MockTestScreen())))),
      ],
    );
  }
}

// ─── Section header with View all ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionHeader(this.title, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2B4A))),
      const Spacer(),
      if (onTap != null)
        GestureDetector(
          onTap: onTap,
          child: const Row(children: [
            Text('View all',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 16),
          ]),
        ),
    ]);
  }
}

// ─── Featured course card ─────────────────────────────────────────────────────
class _FeaturedCourseCard extends StatelessWidget {
  final _Course course;
  final VoidCallback onTap;
  const _FeaturedCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: course.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(course.icon, color: course.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                    child: Text(course.title,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2B4A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.more_vert_rounded,
                      color: Color(0xFFCCD5E0), size: 18),
                ]),
                const SizedBox(height: 3),
                Text(course.subtitle,
                    style: const TextStyle(
                        color: Color(0xFF8A9BB0), fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 5,
                      backgroundColor: course.color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(course.color),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Text('${(course.progress * 100).toInt()}%',
                      style: TextStyle(
                          color: course.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                Text(course.lessons,
                    style: const TextStyle(
                        color: Color(0xFF9AAABB), fontSize: 10.5)),
              ])),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: course.color, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 20),
          ),
        ]),
      ),
    );
  }
}

// ─── Course grid card (4-column, icon + title + lessons + color bar) ──────────
class _CourseGridCard extends StatelessWidget {
  final _Course course;
  final VoidCallback onTap;
  const _CourseGridCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: course.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(course.icon, color: course.color, size: 20),
            ),
            const Spacer(),
            Text(course.title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B4A)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(course.lessons,
                style: TextStyle(
                    fontSize: 9.5,
                    color: course.color.withOpacity(0.8),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: course.progress,
                minHeight: 3,
                backgroundColor: course.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(course.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quiz card ────────────────────────────────────────────────────────────────
class _QuizCard extends StatelessWidget {
  final _Quiz quiz;
  final VoidCallback onTap;
  const _QuizCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: quiz.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(quiz.icon, color: quiz.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(quiz.title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2B4A))),
                const SizedBox(height: 3),
                Text(quiz.subtitle,
                    style: const TextStyle(
                        color: Color(0xFF8A9BB0), fontSize: 11.5)),
              ])),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: quiz.hasProgress
                  ? AppColors.secondary.withOpacity(0.12)
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(quiz.action,
                style: TextStyle(
                    color: quiz.hasProgress
                        ? AppColors.secondary
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

// ─── Tutorials SliverPersistentHeader delegate ────────────────────────────────
class _TutorialsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tab;
  const _TutorialsHeaderDelegate({required this.tab});

  static const double _minH = 100.0; // collapsed: status bar + app bar + tab bar
  static const double _maxH = 268.0; // expanded

  @override
  double get minExtent => _minH;
  @override
  double get maxExtent => _maxH;

  @override
  bool shouldRebuild(covariant _TutorialsHeaderDelegate old) =>
      old.tab != tab;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final expandRatio =
        1.0 - (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        // ── Temple image — always visible at all scroll states ──────────────
        Positioned.fill(
          child: Image.asset(
            'assets/Banner/temple.jpeg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // ── Subtle bottom scrim ─────────────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x00000000), Color(0x66000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // ── Expanded content (badge + title + subtitle) ─────────────────────
        Positioned(
          top: topPad + 12,
          left: 20,
          right: 60,
          child: Opacity(
            opacity: expandRatio,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.school_rounded,
                        color: Colors.white, size: 13),
                    SizedBox(width: 6),
                    Text('Nagarik+ Learning Portal',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.learningCenter,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 10),
                      ]),
                ),
                const SizedBox(height: 6),
                // Only the subtitle gets the frosted pill background
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    context.l10n.learnCenterSubtitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Tab bar — always pinned at bottom ──────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
            ),
            child: TabBar(
              controller: tab,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [Tab(text: context.l10n.tutorials), Tab(text: context.l10n.mockTests)],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────
class _Cat {
  final String label;
  final IconData icon;
  const _Cat(this.label, this.icon);
}

class _Course {
  final String title, subtitle, lessons;
  final IconData icon;
  final Color color;
  final double progress; // 0.0–1.0
  const _Course(this.title, this.subtitle, this.icon, this.color,
      this.lessons, this.progress);
}

class _Quiz {
  final String title, subtitle, action;
  final IconData icon;
  final Color color;
  final bool hasProgress;
  const _Quiz(this.title, this.subtitle, this.icon, this.color, this.action,
      this.hasProgress);
}

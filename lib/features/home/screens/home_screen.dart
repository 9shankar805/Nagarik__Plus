import 'package:flutter/material.dart';
import 'package:nagarik_plus/core/l10n/l10n_extension.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/language_switcher.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../documents/models/document_model.dart';
import '../../documents/providers/documents_provider.dart';
import '../../documents/screens/document_detail_screen.dart';
import '../../documents/screens/documents_screen.dart';
import '../../emergency/screens/emergency_screen.dart';
import '../../news/models/news_article.dart';
import '../../news/providers/news_provider.dart';
import '../../news/screens/news_screen.dart';
import '../../office_locator/screens/office_locator_screen.dart';
import '../../reminders/screens/reminders_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../nearby_share/presentation/screens/share_home_screen.dart';
import '../../advisors/screens/advisors_list_screen.dart';
import '../models/banner_model.dart';
import '../models/social_service_model.dart';
import '../models/vital_event_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData();
      context.read<NewsProvider>().loadNews(featured: true);
      context.read<DocumentsProvider>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar(context)),
            SliverToBoxAdapter(child: _buildBanner(context)),
            SliverToBoxAdapter(child: _buildNagarikAdvisorsSection(context)),
            SliverToBoxAdapter(child: _buildDocuments(context)),
            SliverToBoxAdapter(child: _buildSocialServices(context)),
            SliverToBoxAdapter(child: _buildVitalEvents(context)),
            SliverToBoxAdapter(child: _buildQuickServices(context)),
            SliverToBoxAdapter(child: _buildNews(context)),
            SliverToBoxAdapter(child: _buildOfficeLocator(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          // App icon as profile avatar
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1.5),
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(AppAssets.appIcon, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: AppColors.textLight, size: 18),
                  const SizedBox(width: 6),
                  Text(context.l10n.searchForAService,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Share button — shareit.png icon
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ShareHomeScreen())),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Image.asset(
                AppAssets.shareitIcon,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Notifications
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                final unread = notifProvider.unreadCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: AppColors.textMedium, size: 26),
                    if (unread > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner carousel ───────────────────────────────────────────────────────
  Widget _buildBanner(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final homeProvider = context.watch<HomeProvider>();
    final banners = homeProvider.banners;
    
    // Fallback to hardcoded banners if none from API
    final fallbackBanners = [
      _BannerData(
        gradient: const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
        titleNp: isNepali ? 'प्रहरी रिपोर्ट अब\nनागरिक एपबाट सजिलै।' : 'File Police Reports\nEasily via Nagarik App.',
        subtitleNp: isNepali ? 'जहाँ पनि, जतिबेला पनि – सुरक्षित, छिटो र भरपर्दो।' : 'Anywhere, anytime – secure, fast & reliable.',
        chips: [
          _ChipData(Icons.shield_rounded,      isNepali ? 'सुरक्षित' : 'Secure',    isNepali ? 'तपाईंको उज्ज्वल सुरक्षा' : 'Your safety'),
          _ChipData(Icons.bolt_rounded,         isNepali ? 'छिटो' : 'Fast',        isNepali ? 'केही सेकेन्डमै अद्यावधिक' : 'Instant update'),
          _ChipData(Icons.check_circle_rounded, isNepali ? 'सजिलो' : 'Easy',       isNepali ? 'सजिलो डिजिटल सेवा' : 'Easy service'),
        ],
        cta1: isNepali ? 'रिपोर्ट फाइल गर्नुहोस् →' : 'File Report →',
        cta2: isNepali ? 'कसरी प्रयोग गर्ने ?' : 'How to use?',
        assetBg: AppAssets.onboardingBg1,
      ),
      _BannerData(
        gradient: const [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
        titleNp: isNepali ? 'डिजिटल लకరमा\nसुरक्षित राख्नुस्।' : 'Store Documents Safely\nin Digital Locker.',
        subtitleNp: isNepali ? 'आफ्ना सबै कागजात एकै ठाउँमा राख्नुस्।' : 'Keep all your document cards in one place.',
        chips: [
          _ChipData(Icons.lock_rounded,         isNepali ? 'एन्क्रिप्टेड' : 'Encrypted', isNepali ? 'AES-256 सुरक्षा' : 'AES-256 Security'),
          _ChipData(Icons.cloud_done_rounded,   isNepali ? 'क्लाउड' : 'Cloud',     isNepali ? 'जहाँबाट पनि पहुँच' : 'Access anywhere'),
          _ChipData(Icons.verified_rounded,     isNepali ? 'प्रमाणित' : 'Verified',  isNepali ? 'सरकारी मान्यताप्राप्त' : 'Govt verified'),
        ],
        cta1: isNepali ? 'कागजात थप्नुस् →' : 'Add Document →',
        cta2: isNepali ? 'थप जान्नुस्' : 'Learn More',
        assetBg: AppAssets.onboardingBg2,
      ),
      _BannerData(
        gradient: const [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
        titleNp: isNepali ? 'सरकारी सेवाहरू\nएकै ठाउँमा।' : 'Government Services\nAll in One Place.',
        subtitleNp: isNepali ? 'पासपोर्ट, PAN, नागరिकता – सबै सेवा एपबाटै।' : 'Passport, PAN, Citizenship – all from the app.',
        chips: [
          _ChipData(Icons.book_rounded,         isNepali ? 'पासपोर्ट' : 'Passport', isNepali ? 'अनलाइन आवेदन' : 'Online apply'),
          _ChipData(Icons.receipt_rounded,      isNepali ? 'PAN' : 'PAN',       isNepali ? 'दर्ता र नवीकरण' : 'Reg & renewal'),
          _ChipData(Icons.badge_rounded,        isNepali ? 'NID' : 'NID',       isNepali ? 'नागरिकता सेवा' : 'NID service'),
        ],
        cta1: isNepali ? 'सेवाहरू हेर्नुस् →' : 'View Services →',
        cta2: isNepali ? 'थप जान्नुस्' : 'Learn More',
        assetBg: AppAssets.onboardingBg3,
      ),
    ];
    
    final displayBanners = banners.isNotEmpty ? banners : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: displayBanners != null 
              ? PageView.builder(
                  controller: _bannerController,
                  itemCount: displayBanners.length,
                  onPageChanged: (i) => setState(() => _bannerIndex = i),
                  itemBuilder: (_, index) {
                    final banner = displayBanners[index];
                    return _ApiBannerCard(banner: banner);
                  },
                )
              : PageView.builder(
                  controller: _bannerController,
                  itemCount: fallbackBanners.length,
                  onPageChanged: (i) => setState(() => _bannerIndex = i),
                  itemBuilder: (_, index) => _BannerCard(data: fallbackBanners[index]),
                ),
          ),
          const SizedBox(height: 10),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate((displayBanners?.length ?? fallbackBanners.length), (i) {
              final active = _bannerIndex == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Nagarik Advisors Home Feature Section ────────────────────────────
  Widget _buildNagarikAdvisorsSection(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNepali ? 'नागरिक सल्लाकार (Nagarik Advisors)' : 'Nagarik Advisors',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Text(
                      isNepali ? 'कानून, कर, राहदानी र जग्गा विशेषज्ञहरूसँग १-अन-१ सल्लाह' : '1-on-1 Chat & Call with certified Nepal government experts',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdvisorsListScreen(),
                    ),
                  );
                },
                child: Text(
                  context.l10n.viewAllArrow,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner Card with Temple Background Image
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdvisorsListScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage(AppAssets.templeBanner),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0xDC0F172A), // Dark slate blue overlay
                    BlendMode.darken,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF388E3C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isNepali ? 'प्रमाणीकृत विशेषज्ञहरू अनलाइन' : 'VERIFIED EXPERTS ONLINE',
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isNepali ? 'च्याट वा अडियो/भिडियो कलमा\nसरकारी सल्लाह लिनुहोस्।' : 'Chat & Call Consultation\nfor Legal, Tax & Passport.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('eSewa / Khalti Paid', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Instant Pass', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Documents section – real images ───────────────────────────────────────
  Widget _buildDocuments(BuildContext context) {
    final documentsProvider = context.watch<DocumentsProvider>();
    final docsFromProvider = documentsProvider.documents;
    
    final fallbackDocs = [
      _DocItem(context.l10n.nationalId,     AppAssets.nationalId,     const Color(0xFFE3F0FF), 'national_id'),
      _DocItem(context.l10n.drivingLicense, AppAssets.drivingLicense, const Color(0xFFE8F5E9), 'driving_license'),
      _DocItem(context.l10n.panCard,        AppAssets.pan,            const Color(0xFFF7F7F7), 'pan'),
      _DocItem(context.l10n.citizenship,    AppAssets.cims,           const Color(0xFFF3E5F5), 'citizenship'),
      _DocItem(context.l10n.passport,       AppAssets.passport,       const Color(0xFFE0F2F1), 'passport'),
      _DocItem(context.l10n.voterId,        AppAssets.voterId,        const Color(0xFFF7F7F7), 'voter_id'),
    ];
    
    final docs = docsFromProvider.isNotEmpty 
      ? docsFromProvider.map((doc) {
          final matched = fallbackDocs.firstWhere(
            (f) => f.typeId == doc.type || f.typeId == doc.id.toString(),
            orElse: () => _DocItem(
              doc.title,
              AppAssets.nationalId,
              const Color(0xFFE3F0FF),
              doc.type ?? 'other',
            ),
          );
          return _DocItem(doc.title, matched.imagePath, matched.bgColor, matched.typeId);
        }).toList() 
      : fallbackDocs;

    // total items = docs + 1 "Add Document" slot
    final itemCount = docs.length + 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(context.l10n.documentsSection,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212121))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.documents),
                  child: Text(context.l10n.viewAllArrow,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          if (docsProvider.expiringDocuments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.documents),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${docsProvider.expiringDocuments.length} Document(s) Expiring Soon',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                              ),
                            ),
                            Text(
                              'Renew ${docsProvider.expiringDocuments.first.title} to avoid service interruptions.',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.danger, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: itemCount,
            itemBuilder: (context, i) {
              // Last slot = Add Document
              if (i == docs.length) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.documents),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.add_rounded,
                                color: AppColors.primary, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(context.l10n.addDocumentNewline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              height: 1.2)),
                    ],
                  ),
                );
              }

              final d = docs[i];
              return GestureDetector(
                onTap: () => _openDocument(context, d.typeId),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: d.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (i == 2 || i == 5)
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(d.imagePath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.insert_drive_file_outlined,
                                          size: 32,
                                          color: AppColors.textMedium)),
                                )
                              : Image.asset(d.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: d.bgColor,
                                      child: const Icon(
                                          Icons.insert_drive_file_outlined,
                                          size: 32,
                                          color: AppColors.textMedium))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(d.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Social Services – real images where available ─────────────────────────
  Widget _buildSocialServices(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final homeProvider = context.watch<HomeProvider>();
    final services = homeProvider.socialServices;
    
    // Fallback
    final fallbackServices = [
      _SocialItem(context.l10n.cit,           context.l10n.citSubtitle,           AppAssets.cit,   true,  Icons.settings_rounded,          const Color(0xFFE3F0FF), AppColors.primary),
      _SocialItem(context.l10n.providentFund, context.l10n.providentFundSubtitle, AppAssets.dolma, true,  Icons.account_balance_rounded,   const Color(0xFFE8F5E9), AppColors.secondary),
      _SocialItem(context.l10n.ssf,           context.l10n.ssfSubtitle,           AppAssets.ssf,   true,  Icons.health_and_safety_rounded, const Color(0xFFE3F0FF), AppColors.primary),
    ];
    
    final displayServices = services.isNotEmpty ? services : null;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Text(context.l10n.socialService,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212121))),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Text(context.l10n.viewAllArrow,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: (displayServices != null 
                  ? displayServices.map((s) {
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE8EEF8), width: 1),
                          ),
                          child: Row(
                            children: [
                              // Circle image
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: s.color != null 
                                      ? Color(int.parse(s.color!.replaceFirst('#', '0xFF'))) 
                                      : const Color(0xFFE3F0FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: (s.color != null 
                                              ? Color(int.parse(s.color!.replaceFirst('#', '0xFF'))) 
                                              : AppColors.primary).withOpacity(0.15),
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: s.imageUrl != null
                                      ? Image.network(s.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                              Icons.settings_rounded,
                                              color: s.color != null 
                                                  ? Color(int.parse(s.color!.replaceFirst('#', '0xFF'))) 
                                                  : AppColors.primary,
                                              size: 26))
                                      : Icon(Icons.settings_rounded,
                                          color: s.color != null 
                                              ? Color(int.parse(s.color!.replaceFirst('#', '0xFF'))) 
                                              : AppColors.primary, size: 26),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isNepali ? (s.titleNp ?? s.title ?? '') : (s.title ?? ''),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A2B4A))),
                                    const SizedBox(height: 2),
                                    Text(isNepali ? (s.subtitleNp ?? s.subtitle ?? '') : (s.subtitle ?? ''),
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF7A8898))),
                                  ],
                                ),
                              ),
                              // Arrow
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 12, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList() 
                  : fallbackServices.map((s) {
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE8EEF8), width: 1),
                          ),
                          child: Row(
                            children: [
                              // Circle image
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: s.bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: s.iconColor.withOpacity(0.15),
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: s.hasImage
                                      ? Image.asset(s.imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                              s.fallbackIcon,
                                              color: s.iconColor,
                                              size: 26))
                                      : Icon(s.fallbackIcon,
                                          color: s.iconColor, size: 26),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.label,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A2B4A))),
                                    const SizedBox(height: 2),
                                    Text(s.subtitle,
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF7A8898))),
                                  ],
                                ),
                              ),
                              // Arrow
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 12, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vital Event Certificates ──────────────────────────────────────────────
  Widget _buildVitalEvents(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final homeProvider = context.watch<HomeProvider>();
    final events = homeProvider.vitalEvents;
    
    final fallbackEvents = [
      _VitalItem(context.l10n.birthCertificate,     AppAssets.birthCert,     const Color(0xFFE8F5E9)),
      _VitalItem(context.l10n.marriageCertificate,  AppAssets.marriageCert,  const Color(0xFFFFE4EC)),
      _VitalItem(context.l10n.deathCertificate,     AppAssets.deathCert,     const Color(0xFFF3E5F5)),
      _VitalItem(context.l10n.migrationCertificate, AppAssets.migrationCert, const Color(0xFFFFF8E1)),
    ];
    
    final displayEvents = events.isNotEmpty ? events : null;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text(context.l10n.vitalEventCertificates,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212121))),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: displayEvents?.length ?? fallbackEvents.length,
              itemBuilder: (context, i) {
                if (displayEvents != null) {
                  final e = displayEvents[i];
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 88,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: e.bgColor != null 
                                  ? Color(int.parse(e.bgColor!.replaceFirst('#', '0xFF'))) 
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: e.imageUrl != null 
                                    ? Image.network(
                                        e.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.description_outlined,
                                          size: 30,
                                          color: AppColors.textMedium,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.description_outlined,
                                        size: 30,
                                        color: AppColors.textMedium,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isNepali ? (e.titleNp ?? e.title ?? '') : (e.title ?? ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final e = fallbackEvents[i];
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 88,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: e.bgColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  e.imagePath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.description_outlined,
                                    size: 30,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Citizen Services quick grid ───────────────────────────────────────────
  // ── Citizen Services quick grid ───────────────────────────────────────────
  Widget _buildQuickServices(BuildContext context) {
    final services = [
      _QuickService(context.l10n.passport,       AppAssets.passport,      Icons.book_rounded,         const Color(0xFFE3F0FF), AppColors.primary),
      _QuickService(context.l10n.panCard,        AppAssets.pcr,           Icons.receipt_long_rounded, const Color(0xFFE8F5E9), AppColors.secondary),
      _QuickService(context.l10n.drivingLicense, AppAssets.drivingLicense,Icons.drive_eta_rounded,  const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      _QuickService(context.l10n.nationalId,     AppAssets.nationalId,    Icons.badge_rounded,        const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
    ];

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.citizenServices,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212121))),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.services),
                  child: Text(context.l10n.viewAll,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: services.map((s) {
              return GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.services),
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: s.bgColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          s.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(s.fallbackIcon, color: s.iconColor, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(s.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                            height: 1.2)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Citizen News ──────────────────────────────────────────────────────────
  Widget _buildNews(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final newsProvider = context.watch<NewsProvider>();
    final newsArticles = newsProvider.articles.take(3).toList();
    
    final fallbackItems = [
      _NewsSnippet(
        isNepali ? 'राहदानी सेवा सोमबारदेखि पुनः सञ्चालन हुने' : 'Passport Service Resuming Monday',
        isNepali ? 'राहదానी विभाग' : 'Dept. of Passports',
        isNepali ? '२ घण्टा अघि' : '2h ago',
      ),
      _NewsSnippet(
        isNepali ? 'नयाँ सवारी चालक अनुमतिपत्र नियम २०८१' : 'New Driving License Rules 2081',
        isNepali ? 'यातायात व्यवस्था विभाग' : 'DOTM Official',
        isNepali ? '१ दिन अघि' : '1d ago',
      ),
      _NewsSnippet(
        isNepali ? 'प्यान कार्ड दर्ता समय थप गरियो' : 'PAN Card Registration Extended',
        isNepali ? 'आन्तरिक राजस्व विभाग' : 'Inland Revenue Dept.',
        isNepali ? '२ दिन अघि' : '2d ago',
      ),
    ];
    
    final items = newsArticles.isNotEmpty 
      ? newsArticles.map((article) {
          // Map NewsArticle to _NewsSnippet, use article's title, source, time if available, else fallback
          final title = isNepali 
              ? (article.titleNp ?? article.title ?? 'News Item') 
              : (article.title ?? 'News Item');
          final source = article.source ?? (isNepali ? 'स्रोत' : 'Source');
          final time = article.publishedAt ?? (isNepali ? 'हालै' : 'Just now');
          return _NewsSnippet(title, source, time);
        }).toList() 
      : fallbackItems;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.citizenNews,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212121))),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NewsScreen())),
                  child: Text(context.l10n.viewAll,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          ...items.map((n) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewsScreen())),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F0FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.article_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF212121))),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded,
                                    color: AppColors.info, size: 11),
                                const SizedBox(width: 3),
                                Text(n.source,
                                    style: const TextStyle(
                                        color: AppColors.info,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(n.time,
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 10)),
                    ],
                  ),
                ),
              )).toList(),
        ],
      ),
    );
  }

  // ── Office Locator banner ─────────────────────────────────────────────────
  Widget _buildOfficeLocator(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const OfficeLocatorScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.findNearbyOffices,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  Text(context.l10n.officeLocatorSubtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white60, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _DocItem {
  final String label;
  final String imagePath;
  final Color bgColor;
  final String typeId;
  const _DocItem(this.label, this.imagePath, this.bgColor, this.typeId);
}

class _SocialItem {
  final String label;
  final String subtitle;
  final String imagePath;
  final bool hasImage;
  final IconData fallbackIcon;
  final Color bgColor;
  final Color iconColor;
  const _SocialItem(this.label, this.subtitle, this.imagePath, this.hasImage,
      this.fallbackIcon, this.bgColor, this.iconColor);
}

class _VitalItem {
  final String label;
  final String imagePath;
  final Color bgColor;
  const _VitalItem(this.label, this.imagePath, this.bgColor);
}

class _QuickService {
  final String label;
  final String imagePath;
  final IconData fallbackIcon;
  final Color bgColor;
  final Color iconColor;
  const _QuickService(this.label, this.imagePath, this.fallbackIcon,
      this.bgColor, this.iconColor);
}

class _NewsSnippet {
  final String title;
  final String source;
  final String time;
  const _NewsSnippet(this.title, this.source, this.time);
}

// ── Banner data models ────────────────────────────────────────────────────────
class _BannerData {
  final List<Color> gradient;
  final String titleNp;
  final String subtitleNp;
  final List<_ChipData> chips;
  final String cta1;
  final String cta2;
  final String assetBg;

  const _BannerData({
    required this.gradient,
    required this.titleNp,
    required this.subtitleNp,
    required this.chips,
    required this.cta1,
    required this.cta2,
    required this.assetBg,
  });
}

class _ChipData {
  final IconData icon;
  final String label;
  final String sublabel;
  const _ChipData(this.icon, this.label, this.sublabel);
}

// ── Rich banner card widget ───────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradient.last.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Background asset (mountain / scene) — right-aligned, faded ──
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 160,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18)),
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  data.assetBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          ),

          // ── Nagarik+ logo badge top-left ──
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        AppAssets.appIcon,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'नागरिक+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 34, 100, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  data.titleNp,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle
                Text(
                  data.subtitleNp,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiBannerCard extends StatelessWidget {
  final BannerModel banner;
  const _ApiBannerCard({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF388E3C).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (banner.imageUrl != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Opacity(
                  opacity: 0.3,
                  child: Image.network(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),
          // ── Nagarik+ logo badge top-left ──
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        AppAssets.appIcon,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'नागरिक+',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Main content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 34, 100, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  isNepali ? (banner.titleNp ?? banner.title ?? '') : (banner.title ?? ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                if (banner.description != null)
                  Text(
                    banner.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final _ChipData chip;
  const _FeatureChip({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, color: Colors.white, size: 10),
          const SizedBox(width: 3),
          Text(
            chip.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

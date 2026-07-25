import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../models/news_article.dart';
import '../models/news_category.dart';
import '../providers/news_provider.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  final int initialTab;
  final VoidCallback? onBackToHome;
  const NewsScreen({super.key, this.initialTab = 0, this.onBackToHome});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategory = 0;
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  final List<String> _categoriesEn = ['All', 'Notices', 'Services', 'Exam', 'Deadlines'];
  final List<String> _categoriesNe = ['सबै', 'सूचना', 'सेवाहरू', 'परीक्षा', 'म्याद'];

  // Sample Facebook Feed Posts
  final List<NewsFeedPost> _posts = [
    NewsFeedPost(
      id: 'post_1',
      sourceEn: 'Department of Passports',
      sourceNe: 'राहदानी विभाग',
      sourceUrl: 'https://dop.gov.np',
      timeEn: '2 hours ago',
      timeNe: '२ घण्टा अघि',
      categoryEn: 'Services',
      categoryNe: 'सेवाहरू',
      titleEn: 'Passport Service Resuming Monday After Holiday',
      titleNe: 'सार्वजनिक विदापछि सोमबारदेखि राहदानी सेवा पुनः सञ्चालन हुने',
      contentEn:
          'The Department of Passports announces that all passport issuance and renewal services will resume from this coming Monday. Citizens are advised to schedule online appointments prior to visiting the department premises.',
      contentNe:
          'राहदानी विभागले आगामी सोमबारदेखि सबै राहदानी वितरण तथा नवीकरण सेवाहरू पुनः सञ्चालनमा ल्याउने घोषणा गरेको छ। सेवाग्राहीहरूलाई विभाग आउनुअघि अनलाइन अपोइन्टमेन्ट लिन अनुरोध गरिन्छ।',
      imageAsset: AppAssets.banner1,
      icon: Icons.menu_book_rounded,
      iconColor: const Color(0xFF1E3A8A),
      likeCount: 1240,
      commentCount: 86,
      shareCount: 42,
      comments: [
        PostComment(userName: 'Ramesh Sharma', text: 'कति बजेबाट खुल्छ?', time: '1h ago'),
        PostComment(userName: 'Sita Karki', text: 'Great news! Online booking is smooth.', time: '45m ago'),
      ],
    ),
    NewsFeedPost(
      id: 'post_2',
      sourceEn: 'DOTM Official Notice',
      sourceNe: 'यातायात व्यवस्था विभाग',
      sourceUrl: 'https://dotm.gov.np',
      timeEn: '1 day ago',
      timeNe: '१ दिन अघि',
      categoryEn: 'Notices',
      categoryNe: 'सूचना',
      titleEn: 'New Driving License Smart Exam Rules Effective from 2081',
      titleNe: '२०८१ देखि सवारी चालक अनुमतिपत्रको नयाँ प्रविधि युक्त परीक्षा नियम लागू',
      contentEn:
          'The Department of Transport Management (DOTM) has released upgraded guidelines for driving license written and practical tests. A mandatory 3-hour road safety digital orientation module has been introduced.',
      contentNe:
          'यातायात व्यवस्था विभागले सवारी चालक अनुमतिपत्रको लिखित र प्रयोगात्मक परीक्षाका लागि परिमार्जित निर्देशिका जारी गरेको छ। ३ घण्टाको सडक सुरक्षा डिजिटल अभिमुखीकरण तालिम अनिवार्य गरिएको छ।',
      imageAsset: AppAssets.drivingLicense,
      icon: Icons.drive_eta_rounded,
      iconColor: const Color(0xFFD97706),
      likeCount: 2310,
      commentCount: 142,
      shareCount: 98,
      comments: [
        PostComment(userName: 'Bikash Thapa', text: 'trial date kahile hunchha?', time: '5h ago'),
        PostComment(userName: 'Anil Gurung', text: 'Important update for all drivers.', time: '3h ago'),
      ],
    ),
    NewsFeedPost(
      id: 'post_3',
      sourceEn: 'Inland Revenue Dept (IRD)',
      sourceNe: 'आन्तरिक राजस्व विभाग',
      sourceUrl: 'https://ird.gov.np',
      timeEn: '2 days ago',
      timeNe: '२ दिन अघि',
      categoryEn: 'Deadlines',
      categoryNe: 'म्याद',
      titleEn: 'Personal PAN Card Registration Deadline Extended to Poush End',
      titleNe: 'व्यक्तिगत प्यान (PAN) दर्ता गर्ने म्याद पुस मसान्तसम्म थप गरियो',
      contentEn:
          'Inland Revenue Department has officially extended the mandatory PAN registration deadline for all salaried employees and institutional workers to Poush 30, 2081.',
      contentNe:
          'आन्तरिक राजस्व विभागले सबै पारिश्रमिक प्राप्त कर्मचारी तथा संस्थागत कार्यकर्ताहरूका लागि व्यक्तिगत प्यान दर्ता गर्ने म्याद २०८१ पुस ३० गतेसम्म बढाएको छ।',
      imageAsset: AppAssets.pan,
      icon: Icons.badge_rounded,
      iconColor: const Color(0xFF059669),
      likeCount: 890,
      commentCount: 39,
      shareCount: 27,
      comments: [
        PostComment(userName: 'Pooja Rai', text: 'Nagarik app bata PAN lina milchha.', time: '1d ago'),
      ],
    ),
    NewsFeedPost(
      id: 'post_4',
      sourceEn: 'Department of National ID',
      sourceNe: 'राष्ट्रिय परिचयपत्र विभाग',
      sourceUrl: 'https://nid.gov.np',
      timeEn: '3 days ago',
      timeNe: '३ दिन अघि',
      categoryEn: 'Services',
      categoryNe: 'सेवाहरू',
      titleEn: 'National ID Card Enrollment Centers Expanded in All 77 Districts',
      titleNe: '७७ वटै जिल्लामा राष्ट्रिय परिचयपत्र दर्ता केन्द्र विस्तार',
      contentEn:
          'National ID enrollment services are now operational in all district administration offices and designated ward hubs across Nepal. Bring your original citizenship certificate for biometric capture.',
      contentNe:
          'नेपालका सबै ७७ जिल्ला प्रशासन कार्यालय तथा तोकिएका वडा केन्द्रहरूमा राष्ट्रिय परिचयपत्र बायोमेट्रिक दर्ता सेवा सञ्चालनमा आएको छ। सक्कल नागरिकता लिई जानुहोला।',
      imageAsset: AppAssets.nationalId,
      icon: Icons.fingerprint_rounded,
      iconColor: const Color(0xFF7C3AED),
      likeCount: 3450,
      commentCount: 215,
      shareCount: 160,
      comments: [
        PostComment(userName: 'Suman Shrestha', text: 'Very fast service in Lalitpur DAO.', time: '2d ago'),
      ],
    ),
    NewsFeedPost(
      id: 'post_5',
      sourceEn: 'Public Service Commission',
      sourceNe: 'लोक सेवा आयोग',
      sourceUrl: 'https://psc.gov.np',
      timeEn: '4 days ago',
      timeNe: '४ दिन अघि',
      categoryEn: 'Exam',
      categoryNe: 'परीक्षा',
      titleEn: 'Loksewa Written Examination Schedule & Admit Card Notice',
      titleNe: 'लोक सेवा आयोगको लिखित परीक्षा तालिका तथा प्रवेशपत्र सम्बन्धी सूचना',
      contentEn:
          'Public Service Commission has published the examination routine for Gazetted Officer and Non-Gazetted positions. Candidates can log in to psc.gov.np to download their admit cards.',
      contentNe:
          'लोक सेवा आयोगले विभिन्न पदका लिखित परीक्षाको कार्यतालिका सार्वजनिक गरेको छ। उम्मेदवारहरूले वेबसाइटबाट प्रवेशपत्र प्रिन्ट गर्न सक्नुहुनेछ।',
      imageAsset: AppAssets.banner2,
      icon: Icons.school_rounded,
      iconColor: const Color(0xFFDC2626),
      likeCount: 4120,
      commentCount: 310,
      shareCount: 245,
      comments: [
        PostComment(userName: 'Pradeep Poudel', text: 'Best of luck to all candidates!', time: '3d ago'),
      ],
    ),
  ];

  // Nagarik Shorts Data
  final List<_ShortItem> _shorts = [
    _ShortItem(
      id: 's1',
      titleEn: 'How to apply for e-Passport on Nagarik App in 2 minutes 🛂',
      titleNe: 'नागरिक एपबाट २ मिनेटमा ई-पासपोर्ट आवेदन दिने तरिका 🛂',
      authorEn: 'Nagarik Official',
      authorNe: 'नागरिक आधिकारिक',
      likes: '14.2K',
      comments: '890',
      shares: '1.2K',
      bgGradient: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
      icon: Icons.menu_book_rounded,
      tag: '#Passport2081 #NagarikApp',
      imageAsset: AppAssets.banner1,
    ),
    _ShortItem(
      id: 's2',
      titleEn: 'Driving License Online Payment & Renew Guide 🚗',
      titleNe: 'सवारी चालक अनुमतिपत्र अनलाइन भुक्तानी र नवीकरण निर्देशिका 🚗',
      authorEn: 'DOTM Nepal',
      authorNe: 'यातायात व्यवस्था',
      likes: '9.8K',
      comments: '412',
      shares: '640',
      bgGradient: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
      icon: Icons.drive_eta_rounded,
      tag: '#DOTM #DrivingLicense',
      imageAsset: AppAssets.drivingLicense,
    ),
    _ShortItem(
      id: 's3',
      titleEn: 'Instant Free Personal PAN Card Generation Steps 💳',
      titleNe: 'निशुल्क व्यक्तिगत प्यान कार्ड प्राप्त गर्ने सहज तरिका 💳',
      authorEn: 'IRD Updates',
      authorNe: 'आन्तरिक राजस्व',
      likes: '22.5K',
      comments: '1.1K',
      shares: '3.4K',
      bgGradient: [const Color(0xFF059669), const Color(0xFF10B981)],
      icon: Icons.credit_card_rounded,
      tag: '#PANCard #TaxNepal',
      imageAsset: AppAssets.pan,
    ),
    _ShortItem(
      id: 's4',
      titleEn: 'National ID Biometric Center Locator & Tips 🇳🇵',
      titleNe: 'राष्ट्रिय परिचयपत्र बायोमेट्रिक केन्द्र खोज्ने र टिप्स 🇳🇵',
      authorEn: 'NID Department',
      authorNe: 'परिचयपत्र विभाग',
      likes: '18.1K',
      comments: '630',
      shares: '1.5K',
      bgGradient: [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)],
      icon: Icons.fingerprint_rounded,
      tag: '#NationalID #Nepal',
      imageAsset: AppAssets.nationalId,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(_onTabChanged);
    
    // Load news from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NewsProvider>();
      provider.loadCategories();
      provider.loadNews();
    });
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showNewsMenuSheet(BuildContext context, bool isNepali) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.menu_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isNepali ? 'नागरिक समाचार मेनु' : 'Nagarik News Menu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.home_rounded, color: AppColors.primary),
                title: Text(isNepali ? 'मुख्य गृह पृष्ठ' : 'Go to Home'),
                onTap: () {
                  Navigator.pop(context);
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else if (widget.onBackToHome != null) {
                    widget.onBackToHome!();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.newspaper_outlined, color: AppColors.primary),
                title: Text(isNepali ? 'समाचार फिड (News Feed)' : 'News Feed'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.slow_motion_video_rounded, color: Colors.redAccent),
                title: Text(isNepali ? 'नागरिक सर्ट्स (Nagarik Shorts)' : 'Nagarik Shorts'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded, color: Colors.amber),
                title: Text(isNepali ? 'सुरक्षित गरिएका खबरहरू' : 'Saved News & Notices'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isNepali
                          ? 'सुरक्षित गरिएका समाचार सूची'
                          : 'Saved articles loaded'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final isShorts = _tabController.index == 1;

    return Scaffold(
      extendBodyBehindAppBar: isShorts,
      backgroundColor: isShorts ? Colors.black : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isShorts ? Colors.transparent : Colors.white,
        elevation: isShorts ? 0 : 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            size: 26,
            color: isShorts ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => _showNewsMenuSheet(context, isNepali),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(
                  color: isShorts ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: isNepali ? 'समाचार खोज्नुहोस्...' : 'Search news & notices...',
                  hintStyle: TextStyle(
                    color: isShorts ? Colors.white70 : AppColors.textLight,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      final cat = _selectedCategory > 0
                          ? (isNepali ? _categoriesNe[_selectedCategory] : _categoriesEn[_selectedCategory])
                          : null;
                      context.read<NewsProvider>().loadNews(
                        search: val.trim().isEmpty ? null : val.trim(),
                        category: cat,
                      );
                    }
                  });
                },
              )
            : Row(
                children: [
                  if (!isShorts) ...[
                    // News Feed Title (Facebook Feed Style)
                    Text(
                      isNepali ? 'नागरिक समाचार' : 'Nagarik News',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: Color(0xFF1D4ED8), size: 16),
                  ] else ...[
                    // Shorts Title (Facebook Shorts Style)
                    Text(
                      isNepali ? 'सर्ट्स' : 'Shorts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 21,
                        letterSpacing: -0.4,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.slow_motion_video_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'REELS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: isShorts ? Colors.white : const Color(0xFF1E293B),
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchCtrl.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!isShorts)
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF1E293B)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isNepali
                        ? 'सुरक्षित गरिएका समाचारहरू'
                        : 'Saved news & bookmarks'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.video_call_rounded, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isNepali
                        ? 'नयाँ नागरिक सर्ट रेकर्ड गर्नुहोस् 📹'
                        : 'Create new Nagarik Short 📹'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          // Show loading indicator
          if (provider.status == NewsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          // Show error
          if (provider.status == NewsStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  TextButton(
                    onPressed: () => provider.loadNews(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Render tabs with provider data
          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Facebook Style Feed ──────────────────────────────────
              _buildNewsFeedTab(isNepali, provider),

              // ── Tab 2: Nagarik Shorts (FB Reels Style) ──────────────────────
              _buildShortsTab(isNepali),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 60 + MediaQuery.of(context).padding.bottom / 2,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom / 2),
        decoration: BoxDecoration(
          color: _tabController.index == 1 ? const Color(0xFF0F172A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: _tabController.index == 1
                  ? Colors.white12
                  : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: Row(
          children: [
            // 📰 News Feed Button
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _tabController.animateTo(0);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabController.index == 0
                          ? Icons.newspaper_rounded
                          : Icons.newspaper_outlined,
                      color: _tabController.index == 0
                          ? AppColors.primary
                          : (_tabController.index == 1 ? Colors.white60 : const Color(0xFF64748B)),
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isNepali ? 'समाचार फिड' : 'News Feed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _tabController.index == 0
                            ? AppColors.primary
                            : (_tabController.index == 1 ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Divider line
            Container(
              height: 24,
              width: 1,
              color: _tabController.index == 1 ? Colors.white24 : const Color(0xFFE2E8F0),
            ),

            // 🎬 Nagarik Shorts Button
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _tabController.animateTo(1);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabController.index == 1
                          ? Icons.slow_motion_video_rounded
                          : Icons.slow_motion_video_outlined,
                      color: _tabController.index == 1
                          ? Colors.redAccent
                          : const Color(0xFF64748B),
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isNepali ? 'नागरिक सर्ट्स' : 'Nagarik Shorts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _tabController.index == 1
                            ? Colors.redAccent
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── NEWS FEED TAB IMPLEMENTATION ──────────────────────────────────────────
  Widget _buildNewsFeedTab(bool isNepali, NewsProvider provider) {
    final categories = provider.categories;
    final articles = provider.articles;
    final displayArticles = articles.isNotEmpty ? articles : null;
    final fallbackArticles = _posts.map((post) {
      // Convert fallback NewsFeedPost entries to a displayable NewsArticle style
      return post;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadNews(forceRefresh: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: (displayArticles?.length ?? fallbackArticles.length) + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildShortsStoriesTray(isNepali, provider);
          } else if (index == 1) {
            return _buildCategoryBar(categories);
          }

          final articleIndex = index - 2;
          if (displayArticles != null) {
            final article = displayArticles[articleIndex];
            return _NewsArticleCard(
              article: article,
              isNepali: isNepali,
              onLikeToggle: () {
                context.read<NewsProvider>().toggleLike(article.id);
              },
              onBookmarkToggle: () {
                context.read<NewsProvider>().toggleBookmark(article.id);
              },
              onCommentTap: () => _showCommentsBottomSheet(
                context,
                newsArticleToPost(article),
                isNepali,
              ),
            );
          } else {
            // Fallback: show our demo cards using _FacebookPostCard
            final post = fallbackArticles[articleIndex];
            return _FacebookPostCard(
              post: post,
              isNepali: isNepali,
              onLikeToggle: () {
                setState(() {
                  post.isLiked = !post.isLiked;
                  if (post.isLiked) {
                    post.likeCount++;
                  } else {
                    post.likeCount--;
                  }
                });
              },
              onBookmarkToggle: () {
                setState(() {
                  post.isBookmarked = !post.isBookmarked;
                });
              },
              onCommentTap: () => _showCommentsBottomSheet(context, post, isNepali),
            );
          }
        },
      ),
    );
  }

  // ── Facebook Shorts / Stories Horizontal Tray ──────────────────────────────
  Widget _buildShortsStoriesTray(bool isNepali, NewsProvider provider) {
    final featured = provider.featuredArticles;
    final _ = featured.isNotEmpty
        ? featured.map((a) => _ShortItem(
              id: a.id.toString(),
              titleEn: a.title,
              titleNe: a.titleNp ?? a.title,
              authorEn: a.source ?? 'Nagarik Notice',
              authorNe: a.source ?? 'नागरिक सूचना',
              likes: '${a.likeCount ?? 0}',
              comments: '${a.commentCount ?? 0}',
              shares: '${a.shareCount ?? 0}',
              bgGradient: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              icon: Icons.newspaper_rounded,
              tag: '#${a.category ?? "Notice"}',
              imageAsset: a.imageUrl ?? AppAssets.banner1,
            )).toList()
        : _shorts;
    return Container(
      color: Colors.white,
      height: 180,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 4),
                Text(
                  isNepali ? 'ताजा नागरिक सर्ट्स' : 'Breaking Nagarik Shorts',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: Text(
                    isNepali ? 'सबै हेर्नुहोस् >' : 'View All >',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _shorts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    width: 105,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isNepali ? 'सुझाव दिनुहोस्' : 'Create Post',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final short = _shorts[index - 1];
                return GestureDetector(
                  onTap: () {
                    _tabController.animateTo(1);
                  },
                  child: Container(
                    width: 105,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: short.bgGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: short.bgGradient.first.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            short.icon,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.play_arrow_rounded,
                                      size: 14, color: AppColors.primary),
                                ),
                              ),
                              Text(
                                isNepali ? short.titleNe : short.titleEn,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Selector Bar ──────────────────────────────────────────────────
  Widget _buildCategoryBar(List<NewsCategory> categories) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    return Container(
      color: Colors.white,
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          final category = categories[index];
          final displayName = isNepali ? (category.nameNp ?? category.name) : category.name;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = index;
              // If a category is selected, filter news; else load all news
              if (index == 0) {
                context.read<NewsProvider>().loadNews();
              } else {
                context.read<NewsProvider>().loadNews(category: category.id);
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── SHORTS TAB (Facebook Reels Full-Screen Vertical PageView) ───────────────
  Widget _buildShortsTab(bool isNepali) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _shorts.length,
      itemBuilder: (context, index) {
        final short = _shorts[index];
        return _FullScreenShortView(
          short: short,
          isNepali: isNepali,
          onCommentTap: () => _showCommentsBottomSheet(context, _posts[0], isNepali),
        );
      },
    );
  }

  // ── Comments Bottom Sheet ─────────────────────────────────────────────────
  void _showCommentsBottomSheet(
      BuildContext context, NewsFeedPost post, bool isNepali) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          isNepali ? 'प्रतिक्रियाहरू' : 'Comments',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${post.commentCount})',
                          style: const TextStyle(
                              color: AppColors.textMedium, fontSize: 14),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Comments List
                  Expanded(
                    child: post.comments.isEmpty
                        ? Center(
                            child: Text(
                              isNepali
                                  ? 'अझै कुनै प्रतिक्रिया छैन। पहिलो प्रतिक्रिया लेख्नुहोस्!'
                                  : 'No comments yet. Be the first to comment!',
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: post.comments.length,
                            itemBuilder: (context, idx) {
                              final comment = post.comments[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        comment.userName[0],
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  comment.userName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                Text(
                                                  comment.time,
                                                  style: const TextStyle(
                                                      color: AppColors.textLight,
                                                      fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment.text,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF334155)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Comment Input Bar
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 10,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            decoration: InputDecoration(
                              hintText: isNepali
                                  ? 'प्रतिक्रिया लेख्नुहोस्...'
                                  : 'Write a comment...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textLight, fontSize: 13),
                              fillColor: const Color(0xFFF1F5F9),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: AppColors.primary),
                          onPressed: () async {
                            final text = commentCtrl.text.trim();
                            if (text.isNotEmpty) {
                              commentCtrl.clear();
                              setSheetState(() {
                                post.comments.add(
                                  PostComment(
                                    userName: isNepali ? 'तपाईं (You)' : 'You',
                                    text: text,
                                    time: 'Just now',
                                  ),
                                );
                                post.commentCount += 1;
                              });
                              if (mounted) setState(() {});
                              final articleId = int.tryParse(post.id);
                              if (articleId != null && context.mounted) {
                                await context.read<NewsProvider>().addComment(articleId, text);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

NewsFeedPost newsArticleToPost(NewsArticle article) {
  return NewsFeedPost(
    id: article.id.toString(),
    sourceEn: article.source ?? 'Nagarik Notice',
    sourceNe: article.source ?? 'नागरिक सूचना',
    sourceUrl: article.sourceUrl ?? 'https://nagarikapp.gov.np',
    timeEn: article.publishedAt != null
        ? '${article.publishedAt!.day}/${article.publishedAt!.month}/${article.publishedAt!.year}'
        : 'Recently',
    timeNe: article.publishedAt != null
        ? '${article.publishedAt!.day}/${article.publishedAt!.month}/${article.publishedAt!.year}'
        : 'हालै',
    categoryEn: article.category ?? 'Notices',
    categoryNe: article.category ?? 'सूचना',
    titleEn: article.title,
    titleNe: article.titleNp ?? article.title,
    contentEn: article.content ?? '',
    contentNe: article.contentNp ?? article.content ?? '',
    imageAsset: (article.imageUrl != null && article.imageUrl!.isNotEmpty)
        ? article.imageUrl!
        : AppAssets.banner1,
    icon: Icons.newspaper_rounded,
    iconColor: const Color(0xFF1E3A8A),
    likeCount: article.likeCount ?? 0,
    commentCount: article.commentCount ?? 0,
    shareCount: article.shareCount ?? 0,
    isLiked: article.isLiked ?? false,
    isBookmarked: article.isBookmarked ?? false,
    comments: [],
  );
}

class _NewsArticleCard extends StatelessWidget {
  final NewsArticle article;
  final bool isNepali;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onCommentTap;

  const _NewsArticleCard({
    required this.article,
    required this.isNepali,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    required this.onCommentTap,
  });

  @override
  Widget build(BuildContext context) {
    final post = newsArticleToPost(article);
    return _FacebookPostCard(
      post: post,
      isNepali: isNepali,
      onLikeToggle: onLikeToggle,
      onBookmarkToggle: onBookmarkToggle,
      onCommentTap: onCommentTap,
    );
  }
}

// ── FACEBOOK STYLE POST CARD WIDGET ──────────────────────────────────────────
class _FacebookPostCard extends StatelessWidget {
  final NewsFeedPost post;
  final bool isNepali;
  final VoidCallback onLikeToggle;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onCommentTap;

  const _FacebookPostCard({
    required this.post,
    required this.isNepali,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
    required this.onCommentTap,
  });

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(post: post),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isNepali ? post.titleNe : post.titleEn;
    final content = isNepali ? post.contentNe : post.contentEn;
    final source = isNepali ? post.sourceNe : post.sourceEn;
    final time = isNepali ? post.timeNe : post.timeEn;
    final category = isNepali ? post.categoryNe : post.categoryEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Post Header ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openDetail(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: post.iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(post.icon, color: post.iconColor, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openDetail(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                source,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF1D4ED8), size: 15),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              time,
                              style: const TextStyle(
                                  color: AppColors.textLight, fontSize: 11),
                            ),
                            const Text(' • ',
                                style: TextStyle(
                                    color: AppColors.textLight, fontSize: 11)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: post.iconColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: post.iconColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: post.isBookmarked ? AppColors.primary : AppColors.textLight,
                  ),
                  onPressed: onBookmarkToggle,
                ),
              ],
            ),
          ),

          // ── Title & Content (Tappable to Open News Detail) ──
          GestureDetector(
            onTap: () => _openDetail(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    isNepali ? 'पूरा समाचार पढ्नुहोस् →' : 'Read Full Article →',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Post Image / Banner (Tappable to Open News Detail) ──
          if (post.imageAsset != null)
            GestureDetector(
              onTap: () => _openDetail(context),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: post.iconColor.withValues(alpha: 0.05),
                ),
                child: Image.asset(
                  post.imageAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: post.iconColor.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(post.icon, size: 64, color: post.iconColor),
                    ),
                  ),
                ),
              ),
            ),

          // ── Reaction Counter Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // FB Reaction Icons
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D4ED8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.thumb_up_rounded,
                      size: 10, color: Colors.white),
                ),
                Transform.translate(
                  offset: const Offset(-4, 0),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        size: 10, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likeCount}',
                  style: const TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  isNepali
                      ? '${post.commentCount} प्रतिक्रियाहरू  •  ${post.shareCount} सेयर'
                      : '${post.commentCount} Comments  •  ${post.shareCount} Shares',
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 12, endIndent: 12),

          // ── Post Action Buttons (Like / Comment / Share) ──
          Row(
            children: [
              // Like
              Expanded(
                child: InkWell(
                  onTap: onLikeToggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          post.isLiked
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_up_off_alt_rounded,
                          size: 18,
                          color: post.isLiked
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isNepali ? 'पसंद' : 'Like',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: post.isLiked
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Comment
              Expanded(
                child: InkWell(
                  onTap: onCommentTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isNepali ? 'प्रतिक्रिया' : 'Comment',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Share
              Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isNepali
                            ? 'पोस्ट सेयर गरियो!'
                            : 'Link copied to share'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── FULL SCREEN SHORTS REEL VIEW (TikTok / Reels Style) ──────────────────────
class _FullScreenShortView extends StatefulWidget {
  final _ShortItem short;
  final bool isNepali;
  final VoidCallback onCommentTap;

  const _FullScreenShortView({
    required this.short,
    required this.isNepali,
    required this.onCommentTap,
  });

  @override
  State<_FullScreenShortView> createState() => _FullScreenShortViewState();
}

class _FullScreenShortViewState extends State<_FullScreenShortView>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  bool isPlaying = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isNepali ? widget.short.titleNe : widget.short.titleEn;
    final author = widget.isNepali ? widget.short.authorNe : widget.short.authorEn;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Video Canvas Simulation
          if (widget.short.imageAsset != null)
            Image.asset(
              widget.short.imageAsset!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => _buildGradientFallback(),
            )
          else
            _buildGradientFallback(),

          // Dark Gradient Overlay for text contrast
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black45,
                  Colors.black12,
                  Colors.black87,
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Tap to Play / Pause Toggle
          GestureDetector(
            onTap: () => setState(() => isPlaying = !isPlaying),
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isPlaying ? 0.0 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Top Header Badge
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.slow_motion_video_rounded,
                      color: Colors.redAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'NAGARIK SHORTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side Action Column (Likes, Comments, Shares, Music Vinyl)
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              children: [
                // Like Button
                GestureDetector(
                  onTap: () => setState(() => isLiked = !isLiked),
                  child: Column(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isLiked ? Colors.redAccent : Colors.white,
                        size: 34,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.short.likes,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Comment Button
                GestureDetector(
                  onTap: widget.onCommentTap,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.short.comments,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Share Button
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isNepali
                            ? 'सर्ट सेयर गरियो!'
                            : 'Short video link copied'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.short.shares,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Rotating Disc Vinyl Icon
                RotationTransition(
                  turns: _animController,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: widget.short.bgGradient.first,
                      child: const Icon(Icons.music_note_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Info Overlay
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(widget.short.icon,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: Colors.blueAccent, size: 16),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Text(
                        widget.isNepali ? '+ पछ्याउनुहोस्' : '+ Follow',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.short.tag,
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.music_note_rounded,
                        color: Colors.white70, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Original Audio - Nagarik News Official Broadcast',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.short.bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          widget.short.icon,
          size: 140,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

// ── DATA MODELS ─────────────────────────────────────────────────────────────
class NewsFeedPost {
  final String id;
  final String sourceEn;
  final String sourceNe;
  final String sourceUrl;
  final String timeEn;
  final String timeNe;
  final String categoryEn;
  final String categoryNe;
  final String titleEn;
  final String titleNe;
  final String contentEn;
  final String contentNe;
  final String? imageAsset;
  final IconData icon;
  final Color iconColor;
  int likeCount;
  int commentCount;
  int shareCount;
  bool isLiked;
  bool isBookmarked;
  final List<PostComment> comments;

  NewsFeedPost({
    required this.id,
    required this.sourceEn,
    required this.sourceNe,
    required this.sourceUrl,
    required this.timeEn,
    required this.timeNe,
    required this.categoryEn,
    required this.categoryNe,
    required this.titleEn,
    required this.titleNe,
    required this.contentEn,
    required this.contentNe,
    this.imageAsset,
    required this.icon,
    required this.iconColor,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.isLiked = false,
    this.isBookmarked = false,
    required this.comments,
  });
}

class _ShortItem {
  final String id;
  final String titleEn;
  final String titleNe;
  final String authorEn;
  final String authorNe;
  final String likes;
  final String comments;
  final String shares;
  final List<Color> bgGradient;
  final IconData icon;
  final String tag;
  final String? imageAsset;

  const _ShortItem({
    required this.id,
    required this.titleEn,
    required this.titleNe,
    required this.authorEn,
    required this.authorNe,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.bgGradient,
    required this.icon,
    required this.tag,
    this.imageAsset,
  });
}

class PostComment {
  final String userName;
  final String text;
  final String time;

  PostComment({
    required this.userName,
    required this.text,
    required this.time,
  });
}

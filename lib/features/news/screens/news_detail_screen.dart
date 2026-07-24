import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import 'news_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsFeedPost post;

  const NewsDetailScreen({super.key, required this.post});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late bool isLiked;
  late bool isBookmarked;
  late int likeCount;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked;
    isBookmarked = widget.post.isBookmarked;
    likeCount = widget.post.likeCount;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    HapticFeedback.selectionClick();
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount++;
      } else {
        likeCount--;
      }
      widget.post.isLiked = isLiked;
      widget.post.likeCount = likeCount;
    });
  }

  void _toggleBookmark() {
    HapticFeedback.selectionClick();
    setState(() {
      isBookmarked = !isBookmarked;
      widget.post.isBookmarked = isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBookmarked
            ? 'समाचार बुकमार्क गरियो!'
            : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final title = isNepali ? widget.post.titleNe : widget.post.titleEn;
    final content = isNepali ? widget.post.contentNe : widget.post.contentEn;
    final source = isNepali ? widget.post.sourceNe : widget.post.sourceEn;
    final time = isNepali ? widget.post.timeNe : widget.post.timeEn;
    final category = isNepali ? widget.post.categoryNe : widget.post.categoryEn;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Hero Image Banner ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked ? Colors.amber : Colors.white,
                  ),
                ),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: Colors.white),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isNepali
                          ? 'समाचार लिङ्क कपी गरियो!'
                          : 'Article link copied'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.post.imageAsset != null)
                    Image.asset(
                      widget.post.imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackBanner(),
                    )
                  else
                    _buildFallbackBanner(),

                  // Dark Bottom Gradient Overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),

                  // Publisher Chip & Category Badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.post.iconColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Article Content Body ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Publisher Info Row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.post.iconColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.post.icon,
                            color: widget.post.iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  source,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded,
                                    color: Color(0xFF1D4ED8), size: 16),
                              ],
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () async {
                                final urlStr = widget.post.sourceUrl;
                                if (urlStr.isNotEmpty) {
                                  final uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                }
                              },
                              child: Text(
                                widget.post.sourceUrl.isNotEmpty ? widget.post.sourceUrl : 'https://nagarikapp.gov.np',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isNepali ? '+ पछ्याउनुहोस्' : '+ Follow',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Headline
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Main Text Content
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Color(0xFF334155),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Key Highlights Callout Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: widget.post.iconColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isNepali ? 'मुख्य बुँदाहरू' : 'Key Highlights',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isNepali
                              ? '• यो सूचना राष्ट्रिय नागरिक सेवा पोर्टलबाट प्रत्यक्ष प्रमाणीकरण गरिएको हो।\n• आवश्यक कागजातहरूको लागि nagarikapp.gov.np मा जान सक्नुहुन्छ।\n• सेवा सम्बन्धी थप सोधपुछका लागि पैसा नलाग्ने नम्बर १६६००१००००४ मा सम्पर्क गर्नुहोस्।'
                              : '• Verified directly from official government citizen portals.\n• Access all related documents at nagarikapp.gov.np.\n• Toll-free hotline for queries: 16600100004.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Official Source External Link Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.language_rounded, color: Colors.white),
                      label: Text(
                        isNepali
                            ? 'आधिकारिक पोर्टलमा हेर्नुहोस् ↗'
                            : 'Open Official Source Link ↗',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isNepali
                                ? 'आधिकारिक स्रोत: ${widget.post.sourceUrl}'
                                : 'Source: ${widget.post.sourceUrl}'),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Like / Comment / Share Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        onTap: _toggleLike,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.thumb_up_rounded
                                    : Icons.thumb_up_outlined,
                                color: isLiked
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$likeCount ${isNepali ? 'मनपर्यो' : 'Likes'}',
                                style: TextStyle(
                                  color: isLiked
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Comment Count Display
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                color: Color(0xFF64748B), size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.post.commentCount} ${isNepali ? 'प्रतिक्रिया' : 'Comments'}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Share Button
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isNepali
                                  ? 'समाचार सेयर गरियो!'
                                  : 'Article shared'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.share_rounded,
                                  color: Color(0xFF64748B), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                isNepali ? 'सेयर' : 'Share',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Comments Section Header
                  Text(
                    isNepali ? 'प्रतिक्रियाहरू' : 'Comments',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // User Comment Input Box
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: isNepali
                                ? 'आफ्नो विचार लेख्नुहोस्...'
                                : 'Add your comment...',
                            fillColor: const Color(0xFFF1F5F9),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          if (_commentController.text.trim().isNotEmpty) {
                            setState(() {
                              widget.post.comments.add(
                                PostComment(
                                  userName: isNepali ? 'तपाईं (You)' : 'You',
                                  text: _commentController.text.trim(),
                                  time: 'Just now',
                                ),
                              );
                              widget.post.commentCount += 1;
                              _commentController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Comments List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, idx) {
                      final c = widget.post.comments[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  c.time,
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.text,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.post.iconColor.withValues(alpha: 0.8),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          widget.post.icon,
          size: 90,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

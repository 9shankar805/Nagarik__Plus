import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../models/advisor_model.dart';
import '../providers/advisors_provider.dart';
import '../providers/advisor_payment_provider.dart';
import 'advisor_detail_screen.dart';
import 'my_consultations_screen.dart';

class AdvisorsListScreen extends StatelessWidget {
  const AdvisorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';

    return ChangeNotifierProvider(
      create: (_) => AdvisorsProvider()..loadAdvisors(),
      child: Consumer2<AdvisorsProvider, AdvisorPaymentProvider>(
        builder: (context, advisorsProv, paymentProv, _) {
          final advisors = advisorsProv.advisors;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: Column(
              children: [
                // Top Full Header Section with Temple background image covering status bar & app bar
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppAssets.templeBanner),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Color(0xD9002147),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Custom Header Top Bar (Back button, Title, My Consultations Action)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Text(
                                  isNepali ? 'नागरिक सल्लाकार (Nagarik Advisors)' : 'Nagarik Advisors',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: isNepali ? 'मेरो परामर्शहरू' : 'My Consultations',
                                icon: const Icon(Icons.history_edu_rounded, color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const MyConsultationsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Search & Filter controls inside temple banner header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Column(
                            children: [
                              // Search bar
                              TextField(
                                onChanged: advisorsProv.setSearchQuery,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: isNepali
                                      ? 'सल्लाकार वा सेवा खोज्नुहोस् (उदा: कानुन, कर, पासपोर्ट)'
                                      : 'Search expert, legal, tax, passport...',
                                  hintStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Online Switcher toggle
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    isNepali ? 'सरकारी प्रमाणीकृत सल्लाकारहरू' : 'Verified Government Advisors',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    isNepali ? 'अनलाइन मात्र' : 'Online Only',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    height: 24,
                                    child: Switch(
                                      value: advisorsProv.onlyOnline,
                                      onChanged: (_) => advisorsProv.toggleOnlyOnline(),
                                      activeColor: AppColors.accent,
                                      activeTrackColor: Colors.white30,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Category selection horizontal list
                Container(
                  height: 52,
                  color: Colors.white,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      // All category
                      _CategoryChip(
                        label: isNepali ? 'सबै (All)' : 'All Experts',
                        icon: Icons.grid_view_rounded,
                        isSelected: advisorsProv.selectedCategory == null,
                        color: AppColors.primary,
                        onTap: () => advisorsProv.setCategory(null),
                      ),
                      ...AdvisorCategory.values.map((cat) {
                        return _CategoryChip(
                          label: isNepali ? cat.displayNameNp : cat.displayNameEn,
                          icon: cat.icon,
                          isSelected: advisorsProv.selectedCategory == cat,
                          color: cat.color,
                          onTap: () => advisorsProv.setCategory(cat),
                        );
                      }),
                    ],
                  ),
                ),

                // Active Session Alert Bar if any active paid booking exists
                if (paymentProv.myBookings.any((b) => b.isActive))
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isNepali ? 'सक्रिय परामर्श उपलब्ध छ!' : 'Active Consultation Pass Available!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                isNepali
                                    ? 'तपाईंसँग खुला च्याट/कल सेसन छ। तुरुन्त सुरु गर्नुहोस्।'
                                    : 'You have paid active sessions. Tap to join now.',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B5E20),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MyConsultationsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            isNepali ? 'हेर्नुहोस्' : 'View Pass',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Advisors List
                Expanded(
                  child: advisors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search_rounded, size: 54, color: AppColors.textLight),
                              const SizedBox(height: 12),
                              Text(
                                isNepali ? 'कुनै सल्लाकार भेटिएन' : 'No advisors found matching filter',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isNepali ? 'कृपया अन्य श्रेणी वा खोज शब्द प्रयास गर्नुहोस्' : 'Try resetting search or category filter',
                                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: advisors.length,
                          itemBuilder: (context, index) {
                            final adv = advisors[index];
                            return _AdvisorCard(
                              advisor: adv,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdvisorDetailScreen(advisor: adv),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  final Advisor advisor;
  final VoidCallback onTap;

  const _AdvisorCard({required this.advisor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with online status badge
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: advisor.category.color.withOpacity(0.15),
                          backgroundImage: NetworkImage(advisor.avatarUrl),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: advisor.isOnline ? const Color(0xFF388E3C) : const Color(0xFF9E9E9E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Info section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  advisor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (advisor.isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified_rounded, color: AppColors.primary, size: 17),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isNepali ? advisor.titleNp : advisor.titleEn,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Rating and Experience
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFA000), size: 16),
                              const SizedBox(width: 3),
                              Text(
                                '${advisor.rating}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                ' (${advisor.reviewsCount})',
                                style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(color: AppColors.divider, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.work_outline_rounded, size: 13, color: AppColors.textMedium),
                              const SizedBox(width: 3),
                              Text(
                                isNepali ? '${advisor.experienceYears} वर्ष अनुभव' : '${advisor.experienceYears} yrs exp',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),

                // Bottom bar: Pricing & Quick Action Buttons
                Row(
                  children: [
                    // Consultation Fees
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNepali ? 'परामर्श शुल्क (Fee)' : 'Consultation Fee',
                          style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'NPR ${advisor.consultationFeeChat.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(' / chat  •  ', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                            Text(
                              'NPR ${advisor.consultationFeeCall.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const Text(' / call', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Action buttons
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                      onPressed: onTap,
                      icon: const Icon(Icons.forum_rounded, size: 15),
                      label: Text(
                        isNepali ? 'सल्लाह लिनुहोस्' : 'Consult',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

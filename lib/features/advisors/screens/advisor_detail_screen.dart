import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/advisor_model.dart';
import '../models/consultation_booking_model.dart';
import '../providers/advisor_payment_provider.dart';
import 'advisor_payment_screen.dart';
import 'advisor_chat_screen.dart';
import 'advisor_call_screen.dart';

class AdvisorDetailScreen extends StatelessWidget {
  final Advisor advisor;

  const AdvisorDetailScreen({super.key, required this.advisor});

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final paymentProv = Provider.of<AdvisorPaymentProvider>(context);

    // Check if user already has an active pass for this advisor
    final activeChatPass = paymentProv.getActiveBookingForAdvisor(advisor.id, ConsultationType.chat);
    final activeCallPass = paymentProv.getActiveBookingForAdvisor(advisor.id, ConsultationType.audioCall);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          isNepali ? 'सल्लाकार प्रोफाइल' : 'Advisor Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Header Profile Card ──────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: advisor.category.color.withValues(alpha: 0.15),
                        backgroundImage: NetworkImage(advisor.avatarUrl),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: advisor.isOnline ? const Color(0xFF388E3C) : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        advisor.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (advisor.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    isNepali ? advisor.titleNp : advisor.titleEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: advisor.category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: advisor.category.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(advisor.category.icon, size: 14, color: advisor.category.color),
                        const SizedBox(width: 6),
                        Text(
                          isNepali ? advisor.category.displayNameNp : advisor.category.displayNameEn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: advisor.category.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8EEF8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFFA000),
                          value: '${advisor.rating}',
                          label: isNepali ? '${advisor.reviewsCount} समीक्षा' : '${advisor.reviewsCount} reviews',
                        ),
                        const _VerticalDivider(),
                        _StatItem(
                          icon: Icons.workspace_premium_rounded,
                          iconColor: AppColors.primary,
                          value: '${advisor.experienceYears}+ Yrs',
                          label: isNepali ? 'अनुभव' : 'Experience',
                        ),
                        const _VerticalDivider(),
                        _StatItem(
                          icon: Icons.bolt_rounded,
                          iconColor: const Color(0xFF2E7D32),
                          value: advisor.responseTime,
                          label: isNepali ? 'प्रतिक्रिया समय' : 'Response time',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Active Pass Banner if available ──────────────────────────────
            if (activeChatPass != null || activeCallPass != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNepali ? 'सक्रिय परामर्श उपलब्ध छ' : 'Paid Session Ready!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            isNepali ? 'हजुरले यस सल्लाकारको सेसन भुक्तानी गरिसक्नुभएको छ।' : 'You already hold an active valid pass.',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Bio Section ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNepali ? 'परिचय तथा अनुभव (About Advisor)' : 'About Advisor',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isNepali ? advisor.bioNp : advisor.bioEn,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Languages & Location
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${isNepali ? "भाषा:" : "Languages:"} ${advisor.languages.join(", ")}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Text(
                        '${isNepali ? "स्थान:" : "Location:"} ${advisor.location}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Expertise Tags ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNepali ? 'विशेषज्ञताका क्षेत्रहरू (Expertise)' : 'Areas of Expertise',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: advisor.expertiseTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0D7DE)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── Consultation Pricing Options ─────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNepali ? 'परामर्शका प्रकार र दरहरू (Consultation Tiers)' : 'Consultation Options',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  // Option 1: Chat
                  _PricingCard(
                    icon: Icons.chat_bubble_rounded,
                    iconBg: const Color(0xFFE3F0FF),
                    iconColor: AppColors.primary,
                    title: isNepali ? 'च्याट परामर्श (Text & Document Chat)' : 'Chat Consultation',
                    subtitle: isNepali
                        ? 'च्याट मार्फत प्रश्न सोध्नुहोस्, सरकारी कागजात रिभ्यु गराउनुहोस्।'
                        : 'Ask questions via chat & share document photos for expert review.',
                    priceText: 'NPR ${advisor.consultationFeeChat.toInt()}',
                    hasActivePass: activeChatPass != null,
                    onTap: () {
                      if (activeChatPass != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdvisorChatScreen(advisor: advisor),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdvisorPaymentScreen(
                              advisor: advisor,
                              consultationType: ConsultationType.chat,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Audio/Video Call
                  _PricingCard(
                    icon: Icons.phone_in_talk_rounded,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    title: isNepali ? 'अडियो / भिडियो कल (1-on-1 Call)' : 'Voice / Video Call Consultation',
                    subtitle: isNepali
                        ? 'सल्लाकारसँग प्रत्यक्ष १-अन-१ फोन वा भिडियोमा कुराकानी गर्नुहोस्।'
                        : 'Direct 1-on-1 live phone call or video consultation session.',
                    priceText: 'NPR ${advisor.consultationFeeCall.toInt()}',
                    hasActivePass: activeCallPass != null,
                    onTap: () {
                      if (activeCallPass != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdvisorCallScreen(
                              advisor: advisor,
                              callType: ConsultationType.audioCall,
                            ),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdvisorPaymentScreen(
                              advisor: advisor,
                              consultationType: ConsultationType.audioCall,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Recent Reviews Section ───────────────────────────────────────
            if (advisor.recentReviews.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNepali ? 'नागरिकहरूको समीक्षा (Citizen Reviews)' : 'Recent Citizen Reviews',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    ...advisor.recentReviews.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(r.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: i < r.rating ? const Color(0xFFFFA000) : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(r.comment, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                            const SizedBox(height: 4),
                            Text(r.date, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom Bar with Fast CTAs
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chat CTA
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: Text(
                  activeChatPass != null
                      ? (isNepali ? 'च्याट खोल्नुहोस्' : 'Open Chat')
                      : 'Chat (NPR ${advisor.consultationFeeChat.toInt()})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  if (activeChatPass != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdvisorChatScreen(advisor: advisor),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdvisorPaymentScreen(
                          advisor: advisor,
                          consultationType: ConsultationType.chat,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),

            // Call CTA
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: Text(
                  activeCallPass != null
                      ? (isNepali ? 'कल गर्नुहोस्' : 'Call Now')
                      : 'Call (NPR ${advisor.consultationFeeCall.toInt()})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  if (activeCallPass != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdvisorCallScreen(
                          advisor: advisor,
                          callType: ConsultationType.audioCall,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdvisorPaymentScreen(
                          advisor: advisor,
                          consultationType: ConsultationType.audioCall,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE2E8F0),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String priceText;
  final bool hasActivePass;
  final VoidCallback onTap;

  const _PricingCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.priceText,
    required this.hasActivePass,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasActivePass ? const Color(0xFFF1F8E9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasActivePass ? const Color(0xFF81C784) : const Color(0xFFE2E8F0),
            width: hasActivePass ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceText,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasActivePass ? const Color(0xFF2E7D32) : iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasActivePass ? 'ACTIVE PASS' : 'PAY & BOOK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasActivePass ? Colors.white : iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

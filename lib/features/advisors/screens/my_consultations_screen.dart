import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/consultation_booking_model.dart';
import '../providers/advisor_payment_provider.dart';
import '../providers/advisors_provider.dart';
import 'advisor_chat_screen.dart';
import 'advisor_call_screen.dart';
import 'advisors_list_screen.dart';

class MyConsultationsScreen extends StatelessWidget {
  const MyConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final paymentProv = Provider.of<AdvisorPaymentProvider>(context);
    final bookings = paymentProv.myBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          isNepali ? 'मेरो परामर्श र भौचरहरू' : 'My Consultations & Receipts',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: bookings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_edu_rounded, size: 54, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      isNepali ? 'कुनै परामर्श भौचर भेटिएन' : 'No Consultation History Yet',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      isNepali
                          ? 'सल्लाकारहरूसँग च्याट वा फोन सल्लाह लिनको लागि अगाडि बढ्नुहोस्।'
                          : 'Book your first chat or call consultation with verified experts.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.support_agent_rounded, size: 18),
                      label: Text(
                        isNepali ? 'सल्लाकारहरू खोज्नुहोस्' : 'Explore Advisors',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const AdvisorsListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return _BookingPassCard(booking: b);
              },
            ),
    );
  }
}

class _BookingPassCard extends StatelessWidget {
  final ConsultationBooking booking;

  const _BookingPassCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final advisorsProv = Provider.of<AdvisorsProvider>(context, listen: false);
    final advisor = advisorsProv.findById(booking.advisorId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Top Bar Pass Status Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: booking.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  booking.isActive ? Icons.verified_rounded : Icons.history_rounded,
                  color: booking.isActive ? const Color(0xFF2E7D32) : AppColors.textMedium,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  booking.isActive
                      ? (isNepali ? 'सक्रिय परामर्श पास (Active Session Pass)' : 'ACTIVE SESSION PASS')
                      : (isNepali ? 'सम्पन्न / म्याद सकिएको' : 'EXPIRED PASS'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: booking.isActive ? const Color(0xFF1B5E20) : AppColors.textMedium,
                  ),
                ),
                const Spacer(),
                Text(
                  booking.sessionPassCode,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(booking.advisorAvatar),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.advisorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            booking.advisorTitle,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMedium),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NPR ${booking.netTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                        ),
                        Text(
                          booking.paymentMethod.logoText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: booking.paymentMethod.brandColor),
                        ),
                      ],
                    ),
                  ],
                ),

                const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Txn ID: ${booking.transactionId}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                    Text(
                      '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),

                if (booking.isActive && advisor != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: booking.consultationType == ConsultationType.chat
                            ? AppColors.primary
                            : const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(
                        booking.consultationType == ConsultationType.chat
                            ? Icons.chat_rounded
                            : Icons.phone_rounded,
                        size: 16,
                      ),
                      label: Text(
                        booking.consultationType == ConsultationType.chat
                            ? (isNepali ? 'च्याटमा प्रवेश गर्नुहोस्' : 'Enter Chat Session')
                            : (isNepali ? 'फोन कल सुरु गर्नुहोस्' : 'Start Voice Call'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        if (booking.consultationType == ConsultationType.chat) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdvisorChatScreen(advisor: advisor),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdvisorCallScreen(
                                advisor: advisor,
                                callType: booking.consultationType,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

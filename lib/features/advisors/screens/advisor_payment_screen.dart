import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/advisor_model.dart';
import '../models/consultation_booking_model.dart';
import '../providers/advisor_payment_provider.dart';
import 'advisor_chat_screen.dart';
import 'advisor_call_screen.dart';

class AdvisorPaymentScreen extends StatefulWidget {
  final Advisor advisor;
  final ConsultationType consultationType;

  const AdvisorPaymentScreen({
    super.key,
    required this.advisor,
    required this.consultationType,
  });

  @override
  State<AdvisorPaymentScreen> createState() => _AdvisorPaymentScreenState();
}

class _AdvisorPaymentScreenState extends State<AdvisorPaymentScreen> {
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  String? _promoError;
  bool _promoApplied = false;

  @override
  void dispose() {
    _promoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleApplyPromo(AdvisorPaymentProvider paymentProv) {
    FocusScope.of(context).unfocus();
    final success = paymentProv.applyPromoCode(_promoController.text);
    setState(() {
      if (success) {
        _promoApplied = true;
        _promoError = null;
      } else {
        _promoError = 'Invalid promo code. Try NAGARIK50';
      }
    });
  }

  void _showPinPaymentModal(AdvisorPaymentProvider paymentProv, double totalAmount) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    _pinController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: paymentProv.selectedMethod.brandColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: paymentProv.selectedMethod.brandColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentProv.selectedMethod.nameDisplay,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        isNepali ? 'भुक्तानी पुष्टि गर्नुहोस्' : 'Confirm Payment Authorization',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNepali ? 'कुल रकम (Payable Amount):' : 'Total Amount:',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'NPR ${totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: paymentProv.selectedMethod.brandColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isNepali ? '४-अङ्कको MPIN वा सेक्युरिटी कोड हाल्नुहोस्:' : 'Enter 4-Digit MPIN / Wallet Security Code:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '••••',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paymentProv.selectedMethod.brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (_pinController.text.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter 4-digit PIN')),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop(); // close bottom sheet

                    // Process Payment via provider
                    final booking = await paymentProv.processPayment(
                      advisor: widget.advisor,
                      consultationType: widget.consultationType,
                      pin: _pinController.text,
                    );

                    if (mounted) {
                      _showSuccessReceiptDialog(booking);
                    }
                  },
                  child: Text(
                    isNepali ? 'भुक्तानी सम्पन्न गर्नुहोस्' : 'Authorize & Pay Now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessReceiptDialog(ConsultationBooking booking) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 44),
              ),
              const SizedBox(height: 14),

              Text(
                isNepali ? 'भुक्तानी सफल भयो!' : 'Payment Successful!',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 4),

              Text(
                isNepali
                    ? 'तपाईंको परामर्श सेसन पास तयार छ।'
                    : 'Your consultation session pass is now activated.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
              ),
              const SizedBox(height: 16),

              // Digital Pass Voucher
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD0D7DE)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isNepali ? 'पास कोड:' : 'Pass Code:', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text(booking.sessionPassCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isNepali ? 'कारोबार ID:' : 'Txn ID:', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text(booking.transactionId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isNepali ? 'रकम भुक्तानी:' : 'Paid Total:', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        Text('NPR ${booking.netTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    widget.consultationType == ConsultationType.chat
                        ? Icons.chat_rounded
                        : Icons.phone_in_talk_rounded,
                    size: 18,
                  ),
                  label: Text(
                    widget.consultationType == ConsultationType.chat
                        ? (isNepali ? 'तुरुन्त च्याट सुरु गर्नुहोस्' : 'Start Chat Session Now')
                        : (isNepali ? 'तुरुन्त कल सुरु गर्नुहोस्' : 'Start Voice Call Now'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop(); // close dialog
                    Navigator.of(context).pop(); // close payment screen

                    if (widget.consultationType == ConsultationType.chat) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdvisorChatScreen(advisor: widget.advisor),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdvisorCallScreen(
                            advisor: widget.advisor,
                            callType: widget.consultationType,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final paymentProv = Provider.of<AdvisorPaymentProvider>(context);

    final fee = paymentProv.calculateFee(widget.advisor, widget.consultationType);
    final serviceCharge = paymentProv.calculateServiceCharge(fee);
    final discount = paymentProv.calculateDiscount(fee);
    final total = paymentProv.calculateTotal(widget.advisor, widget.consultationType);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          isNepali ? 'परामर्श भुक्तानी (Checkout)' : 'Consultation Checkout',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Consultation Booking Summary ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(widget.advisor.avatarUrl),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.advisor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          isNepali ? widget.advisor.titleNp : widget.advisor.titleEn,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isNepali ? widget.consultationType.labelNp : widget.consultationType.labelEn,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Fee Breakdown Card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNepali ? 'शुल्क विवरण (Fee Summary)' : 'Fee Details',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isNepali ? 'सल्लाकार परामर्श शुल्क' : 'Advisor Base Fee', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      Text('NPR ${fee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isNepali ? 'डिजिटल गेटवे शुल्क' : 'Digital Gateway Charge', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                      Text('NPR ${serviceCharge.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),

                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isNepali ? 'प्रोमो छुट (20% OFF)' : 'Promo Discount (20% OFF)', style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                        Text('- NPR ${discount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],

                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isNepali ? 'कुल भुक्तानी रकम:' : 'Total Payable Net:',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        'NPR ${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Promo Code Card ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        isNepali ? 'प्रोमो कोड प्रविष्टि (Promo Voucher)' : 'Have a Promo Code?',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. NAGARIK50',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            errorText: _promoError,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _promoApplied ? const Color(0xFF2E7D32) : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _handleApplyPromo(paymentProv),
                        child: Text(
                          _promoApplied ? (isNepali ? 'लागू भयो' : 'Applied') : (isNepali ? 'लागू गर्नुहोस्' : 'Apply'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Payment Gateway Selection Title ──────────────────────────────
            Text(
              isNepali ? 'भुक्तानीको माध्यम रोज्नुहोस् (Payment Method)' : 'Select Nepal Payment Gateway',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),

            // Payment Options List
            _PaymentOptionCard(
              method: PaymentMethod.esewa,
              title: 'eSewa Mobile Wallet',
              subtitle: 'Pay via eSewa digital wallet app',
              isSelected: paymentProv.selectedMethod == PaymentMethod.esewa,
              onTap: () => paymentProv.selectPaymentMethod(PaymentMethod.esewa),
            ),
            _PaymentOptionCard(
              method: PaymentMethod.khalti,
              title: 'Khalti Digital Wallet',
              subtitle: 'Pay instantly using Khalti balance',
              isSelected: paymentProv.selectedMethod == PaymentMethod.khalti,
              onTap: () => paymentProv.selectPaymentMethod(PaymentMethod.khalti),
            ),
            _PaymentOptionCard(
              method: PaymentMethod.fonepay,
              title: 'Fonepay QR / Mobile Banking',
              subtitle: 'Direct bank transfer from mobile app',
              isSelected: paymentProv.selectedMethod == PaymentMethod.fonepay,
              onTap: () => paymentProv.selectPaymentMethod(PaymentMethod.fonepay),
            ),
            _PaymentOptionCard(
              method: PaymentMethod.wallet,
              title: 'Nagarik Pay Wallet',
              subtitle: 'App Wallet Balance (Available: NPR 2,500)',
              isSelected: paymentProv.selectedMethod == PaymentMethod.wallet,
              onTap: () => paymentProv.selectPaymentMethod(PaymentMethod.wallet),
            ),

            const SizedBox(height: 30),

            // Pay Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: paymentProv.selectedMethod.brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                onPressed: () => _showPinPaymentModal(paymentProv, total),
                child: Text(
                  '${isNepali ? "भुक्तानी गर्नुहोस्" : "Pay & Start Session"} (NPR ${total.toStringAsFixed(0)})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final PaymentMethod method;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? method.brandColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: method.brandColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                method.logoText,
                style: TextStyle(
                  color: method.brandColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                ],
              ),
            ),

            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? method.brandColor : AppColors.textLight,
                  width: isSelected ? 6.5 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/advisor_model.dart';
import '../models/consultation_booking_model.dart';

class AdvisorPaymentProvider extends ChangeNotifier {
  PaymentMethod _selectedMethod = PaymentMethod.esewa;
  String _promoCode = '';
  double _discountPercent = 0.0;
  bool _isProcessing = false;

  final List<ConsultationBooking> _myBookings = [];

  PaymentMethod get selectedMethod => _selectedMethod;
  String get promoCode => _promoCode;
  double get discountPercent => _discountPercent;
  bool get isProcessing => _isProcessing;
  List<ConsultationBooking> get myBookings => List.unmodifiable(_myBookings);

  void selectPaymentMethod(PaymentMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  bool applyPromoCode(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'NAGARIK50' || clean == 'NEPAL2026') {
      _promoCode = clean;
      _discountPercent = 0.20; // 20% OFF
      notifyListeners();
      return true;
    }
    return false;
  }

  void removePromoCode() {
    _promoCode = '';
    _discountPercent = 0.0;
    notifyListeners();
  }

  double calculateFee(Advisor advisor, ConsultationType type) {
    return type == ConsultationType.chat
        ? advisor.consultationFeeChat
        : advisor.consultationFeeCall;
  }

  double calculateServiceCharge(double fee) {
    return 15.0; // NPR 15 flat digital government gateway fee
  }

  double calculateDiscount(double fee) {
    return fee * _discountPercent;
  }

  double calculateTotal(Advisor advisor, ConsultationType type) {
    final fee = calculateFee(advisor, type);
    final service = calculateServiceCharge(fee);
    final discount = calculateDiscount(fee);
    return (fee + service - discount).clamp(0.0, double.infinity);
  }

  Future<ConsultationBooking> processPayment({
    required Advisor advisor,
    required ConsultationType consultationType,
    required String pin,
  }) async {
    _isProcessing = true;
    notifyListeners();

    // Simulate Network delay for payment gateway authorization
    await Future.delayed(const Duration(seconds: 2));

    final fee = calculateFee(advisor, consultationType);
    final service = calculateServiceCharge(fee);
    final discount = calculateDiscount(fee);
    final total = calculateTotal(advisor, consultationType);

    final randomId = Random().nextInt(899999) + 100000;
    final txId = '${_selectedMethod.logoText.toUpperCase()}-$randomId';
    final passCode = 'PASS-${Random().nextInt(8999) + 1000}';

    final booking = ConsultationBooking(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      advisorId: advisor.id,
      advisorName: advisor.name,
      advisorTitle: advisor.titleNp,
      advisorAvatar: advisor.avatarUrl,
      consultationType: consultationType,
      feeAmount: fee,
      serviceCharge: service,
      discountAmount: discount,
      netTotal: total,
      paymentMethod: _selectedMethod,
      paymentStatus: PaymentStatus.paid,
      transactionId: txId,
      createdAt: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(hours: 24)),
      sessionPassCode: passCode,
    );

    _myBookings.insert(0, booking);
    _isProcessing = false;
    notifyListeners();

    return booking;
  }

  ConsultationBooking? getActiveBookingForAdvisor(String advisorId, ConsultationType type) {
    try {
      return _myBookings.firstWhere(
        (b) =>
            b.advisorId == advisorId &&
            b.consultationType == type &&
            b.isActive,
      );
    } catch (_) {
      return null;
    }
  }
}

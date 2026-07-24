import 'package:flutter/material.dart';

enum ConsultationType {
  chat,
  audioCall,
  videoCall,
}

extension ConsultationTypeExtension on ConsultationType {
  String get labelEn {
    switch (this) {
      case ConsultationType.chat:
        return 'Chat Consultation';
      case ConsultationType.audioCall:
        return 'Audio Voice Call';
      case ConsultationType.videoCall:
        return 'Video Call Session';
    }
  }

  String get labelNp {
    switch (this) {
      case ConsultationType.chat:
        return 'च्याट परामर्श';
      case ConsultationType.audioCall:
        return 'अडियो फोन कल';
      case ConsultationType.videoCall:
        return 'भिडियो कल परामर्श';
    }
  }

  IconData get icon {
    switch (this) {
      case ConsultationType.chat:
        return Icons.chat_bubble_outline_rounded;
      case ConsultationType.audioCall:
        return Icons.phone_in_talk_rounded;
      case ConsultationType.videoCall:
        return Icons.videocam_rounded;
    }
  }
}

enum PaymentMethod {
  esewa,
  khalti,
  fonepay,
  wallet,
}

extension PaymentMethodExtension on PaymentMethod {
  String get nameDisplay {
    switch (this) {
      case PaymentMethod.esewa:
        return 'eSewa Mobile Wallet';
      case PaymentMethod.khalti:
        return 'Khalti Digital Wallet';
      case PaymentMethod.fonepay:
        return 'Fonepay Direct Bank Transfer';
      case PaymentMethod.wallet:
        return 'Nagarik Pay Balance';
    }
  }

  String get logoText {
    switch (this) {
      case PaymentMethod.esewa:
        return 'eSewa';
      case PaymentMethod.khalti:
        return 'Khalti';
      case PaymentMethod.fonepay:
        return 'Fonepay';
      case PaymentMethod.wallet:
        return 'Nagarik';
    }
  }

  Color get brandColor {
    switch (this) {
      case PaymentMethod.esewa:
        return const Color(0xFF60BB46);
      case PaymentMethod.khalti:
        return const Color(0xFF5C2D91);
      case PaymentMethod.fonepay:
        return const Color(0xFFD32F2F);
      case PaymentMethod.wallet:
        return const Color(0xFF1565C0);
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

class ConsultationBooking {
  final String id;
  final String advisorId;
  final String advisorName;
  final String advisorTitle;
  final String advisorAvatar;
  final ConsultationType consultationType;
  final double feeAmount;
  final double serviceCharge;
  final double discountAmount;
  final double netTotal;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String transactionId;
  final DateTime createdAt;
  final DateTime validUntil;
  final String sessionPassCode;

  const ConsultationBooking({
    required this.id,
    required this.advisorId,
    required this.advisorName,
    required this.advisorTitle,
    required this.advisorAvatar,
    required this.consultationType,
    required this.feeAmount,
    required this.serviceCharge,
    required this.discountAmount,
    required this.netTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionId,
    required this.createdAt,
    required this.validUntil,
    required this.sessionPassCode,
  });

  bool get isActive =>
      paymentStatus == PaymentStatus.paid &&
      DateTime.now().isBefore(validUntil);
}

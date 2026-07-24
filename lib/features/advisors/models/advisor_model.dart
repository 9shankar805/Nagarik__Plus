import 'package:flutter/material.dart';

enum AdvisorCategory {
  legal,
  tax,
  passportNid,
  property,
  business,
  general,
}

extension AdvisorCategoryExtension on AdvisorCategory {
  String get displayNameEn {
    switch (this) {
      case AdvisorCategory.legal:
        return 'Legal & Law';
      case AdvisorCategory.tax:
        return 'Tax & Finance';
      case AdvisorCategory.passportNid:
        return 'Passport & NID';
      case AdvisorCategory.property:
        return 'Land & Property';
      case AdvisorCategory.business:
        return 'Business & Trade';
      case AdvisorCategory.general:
        return 'General Advice';
    }
  }

  String get displayNameNp {
    switch (this) {
      case AdvisorCategory.legal:
        return 'कानूनी सल्लाह';
      case AdvisorCategory.tax:
        return 'कर तथा वित्तीय सल्लाह';
      case AdvisorCategory.passportNid:
        return 'राहदानी र परिचयपत्र';
      case AdvisorCategory.property:
        return 'जग्गा जमिन र मालपोत';
      case AdvisorCategory.business:
        return 'व्यापार र कम्पनी दर्ता';
      case AdvisorCategory.general:
        return 'सामान्य नागरिक सल्लाह';
    }
  }

  IconData get icon {
    switch (this) {
      case AdvisorCategory.legal:
        return Icons.gavel_rounded;
      case AdvisorCategory.tax:
        return Icons.account_balance_wallet_rounded;
      case AdvisorCategory.passportNid:
        return Icons.badge_rounded;
      case AdvisorCategory.property:
        return Icons.landscape_rounded;
      case AdvisorCategory.business:
        return Icons.storefront_rounded;
      case AdvisorCategory.general:
        return Icons.support_agent_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AdvisorCategory.legal:
        return const Color(0xFFD32F2F);
      case AdvisorCategory.tax:
        return const Color(0xFF2E7D32);
      case AdvisorCategory.passportNid:
        return const Color(0xFF1565C0);
      case AdvisorCategory.property:
        return const Color(0xFFE65100);
      case AdvisorCategory.business:
        return const Color(0xFF6A1B9A);
      case AdvisorCategory.general:
        return const Color(0xFF00838F);
    }
  }

  static AdvisorCategory fromString(String? catStr) {
    switch (catStr?.toLowerCase()) {
      case 'legal': return AdvisorCategory.legal;
      case 'tax': return AdvisorCategory.tax;
      case 'passport_nid':
      case 'passport': return AdvisorCategory.passportNid;
      case 'property': return AdvisorCategory.property;
      case 'business': return AdvisorCategory.business;
      default: return AdvisorCategory.general;
    }
  }
}

class AdvisorReview {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final String date;

  const AdvisorReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory AdvisorReview.fromJson(Map<String, dynamic> json) {
    return AdvisorReview(
      id: json['id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['user']?.toString() ?? 'Citizen User',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment']?.toString() ?? '',
      date: json['date']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'date': date,
    };
  }
}

class Advisor {
  final String id;
  final String name;
  final String titleEn;
  final String titleNp;
  final AdvisorCategory category;
  final String avatarUrl;
  final double rating;
  final int reviewsCount;
  final int experienceYears;
  final String bioEn;
  final String bioNp;
  final double consultationFeeChat; // in NPR
  final double consultationFeeCall; // in NPR
  final bool isOnline;
  final List<String> languages;
  final List<String> expertiseTags;
  final String responseTime;
  final bool isVerified;
  final String location;
  final List<AdvisorReview> recentReviews;

  const Advisor({
    required this.id,
    required this.name,
    required this.titleEn,
    required this.titleNp,
    required this.category,
    required this.avatarUrl,
    required this.rating,
    required this.reviewsCount,
    required this.experienceYears,
    required this.bioEn,
    required this.bioNp,
    required this.consultationFeeChat,
    required this.consultationFeeCall,
    required this.isOnline,
    required this.languages,
    required this.expertiseTags,
    required this.responseTime,
    this.isVerified = true,
    required this.location,
    this.recentReviews = const [],
  });

  factory Advisor.fromJson(Map<String, dynamic> json) {
    final reviewsRaw = json['recent_reviews'] as List?;
    final reviews = reviewsRaw != null
        ? reviewsRaw.map((r) => AdvisorReview.fromJson(r as Map<String, dynamic>)).toList()
        : <AdvisorReview>[];

    final langsRaw = json['languages'] as List?;
    final langs = langsRaw != null ? langsRaw.map((l) => l.toString()).toList() : <String>['Nepali', 'English'];

    final tagsRaw = json['expertise_tags'] as List?;
    final tags = tagsRaw != null ? tagsRaw.map((t) => t.toString()).toList() : <String>[];

    return Advisor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? json['title']?.toString() ?? '',
      titleNp: json['title_np']?.toString() ?? json['title_en']?.toString() ?? '',
      category: AdvisorCategoryExtension.fromString(json['category']?.toString()),
      avatarUrl: json['avatar_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 5,
      bioEn: json['bio_en']?.toString() ?? json['bio']?.toString() ?? '',
      bioNp: json['bio_np']?.toString() ?? json['bio_en']?.toString() ?? '',
      consultationFeeChat: (json['consultation_fee_chat'] as num?)?.toDouble() ?? 200.0,
      consultationFeeCall: (json['consultation_fee_call'] as num?)?.toDouble() ?? 450.0,
      isOnline: json['is_online'] is bool ? json['is_online'] as bool : true,
      languages: langs,
      expertiseTags: tags,
      responseTime: json['response_time']?.toString() ?? '< 5 mins',
      isVerified: json['is_verified'] is bool ? json['is_verified'] as bool : true,
      location: json['location']?.toString() ?? 'Nepal',
      recentReviews: reviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title_en': titleEn,
      'title_np': titleNp,
      'category': category.name,
      'avatar_url': avatarUrl,
      'rating': rating,
      'reviews_count': reviewsCount,
      'experience_years': experienceYears,
      'bio_en': bioEn,
      'bio_np': bioNp,
      'consultation_fee_chat': consultationFeeChat,
      'consultation_fee_call': consultationFeeCall,
      'is_online': isOnline,
      'languages': languages,
      'expertise_tags': expertiseTags,
      'response_time': responseTime,
      'is_verified': isVerified,
      'location': location,
      'recent_reviews': recentReviews.map((r) => r.toJson()).toList(),
    };
  }
}

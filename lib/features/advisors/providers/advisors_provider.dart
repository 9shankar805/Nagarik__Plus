import 'package:flutter/material.dart';
import '../models/advisor_model.dart';
import '../repositories/advisors_repository.dart';

enum AdvisorsStatus { initial, loading, loaded, error }

class AdvisorsProvider extends ChangeNotifier {
  final AdvisorsRepository _repository;

  AdvisorsStatus _status = AdvisorsStatus.initial;
  AdvisorCategory? _selectedCategory;
  String _searchQuery = '';
  bool _onlyOnline = false;
  List<Advisor> _apiAdvisors = [];
  String? _errorMessage;

  AdvisorsStatus get status => _status;
  AdvisorCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get onlyOnline => _onlyOnline;
  String? get errorMessage => _errorMessage;

  AdvisorsProvider({AdvisorsRepository? repository})
      : _repository = repository ?? AdvisorsRepository();

  static const List<Advisor> _fallbackAdvisors = [
    Advisor(
      id: 'adv_001',
      name: 'Advocate Ramesh Bikram Shah',
      titleEn: 'Senior Public Rights & Legal Specialist',
      titleNp: 'वरिष्ठ अधिवक्ता तथा सार्वजनिक कानुन विशेषज्ञ',
      category: AdvisorCategory.legal,
      avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
      rating: 4.9,
      reviewsCount: 142,
      experienceYears: 14,
      bioEn: 'Specializes in citizenship disputes, property inheritance, legal documentation, and court filings across Nepal.',
      bioNp: 'नागरिकता विवाद, अंशबण्डा, कानूनी कागजात र अदालतसम्बन्धी प्रक्रियामा १४ वर्षभन्दा बढीको अनुभव।',
      consultationFeeChat: 250.0,
      consultationFeeCall: 500.0,
      isOnline: true,
      languages: ['Nepali', 'English', 'Bhojpuri'],
      expertiseTags: ['Citizenship Law', 'Property Dispute', 'Court Appeals', 'Contract Legal Review'],
      responseTime: '< 5 mins',
      location: 'Kathmandu, Nepal',
      recentReviews: [
        AdvisorReview(
          id: 'r1',
          userName: 'Sunil Shrestha',
          rating: 5.0,
          comment: 'Provided exact solution for citizenship name mismatch within 10 minutes chat.',
          date: 'Yesterday',
        ),
      ],
    ),
    Advisor(
      id: 'adv_002',
      name: 'CA Anjali Karki (FCA)',
      titleEn: 'Chartered Accountant & Tax Officer Advisor',
      titleNp: 'चार्टर्ड एकाउन्टेन्ट तथा वरिष्ठ कर सल्लाहकार',
      category: AdvisorCategory.tax,
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
      rating: 4.95,
      reviewsCount: 210,
      experienceYears: 11,
      bioEn: 'Expert in Personal PAN, Corporate Tax Returns, VAT Registration, Tax Clearance Certificates, and IRD online portal services.',
      bioNp: 'व्यक्तिगत PAN, संस्थागत कर चुक्ता, भ्याट दर्ता र आन्तरिक राजस्व विभागको सेवाहरूमा विशेष अनुभव।',
      consultationFeeChat: 200.0,
      consultationFeeCall: 450.0,
      isOnline: true,
      languages: ['Nepali', 'English', 'Newari'],
      expertiseTags: ['Personal Tax Filing', 'PAN Registration', 'VAT Filing', 'Audit Advice'],
      responseTime: '< 2 mins',
      location: 'Lalitpur, Nepal',
    ),
    Advisor(
      id: 'adv_003',
      name: 'Sub-Inspector Bishnu Raj Giri (Retd.)',
      titleEn: 'Consular & Passport Verification Consultant',
      titleNp: 'राहदानी तथा राष्ट्रिय परिचयपत्र परामर्शदाता',
      category: AdvisorCategory.passportNid,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      rating: 4.85,
      reviewsCount: 188,
      experienceYears: 18,
      bioEn: 'Former Consular Officer assisting citizens with e-Passport appointment booking, NID enrollment issues, Police Clearance Reports, and emergency visas.',
      bioNp: 'इ-पासपोर्ट अपोइन्टमेन्ट, राष्ट्रिय परिचयपत्र त्रुटि सच्याउने र प्रहरी प्रतिवेदन सम्बन्धी भरपर्दो परामर्श।',
      consultationFeeChat: 150.0,
      consultationFeeCall: 350.0,
      isOnline: true,
      languages: ['Nepali', 'English'],
      expertiseTags: ['e-Passport', 'NID Verification', 'Police Report Clearance', 'Emergency Consular'],
      responseTime: '< 3 mins',
      location: 'Bhaktapur, Nepal',
    ),
    Advisor(
      id: 'adv_004',
      name: 'Er. Prakash Raj Adhikari',
      titleEn: 'Land Surveyor & Malpot Document Specialist',
      titleNp: 'नापी इन्जिनियर तथा मालपोत सल्लाहकार',
      category: AdvisorCategory.property,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      rating: 4.88,
      reviewsCount: 165,
      experienceYears: 15,
      bioEn: 'Specialist in land valuation, parcel mapping (Kitta), land transfer (Rajnama), house building permits, and Malpot tax calculation.',
      bioNp: 'जग्गाको कित्ताकाट, कित्ता नक्शा, राजिनामा लिखत र मालपोत कर मूल्यांकनसम्बन्धी अनुभवी इन्जिनियर।',
      consultationFeeChat: 300.0,
      consultationFeeCall: 600.0,
      isOnline: false,
      languages: ['Nepali', 'English'],
      expertiseTags: ['Land Parcel Mapping', 'Malpot Tax', 'Property Transfer', 'Building Blueprint'],
      responseTime: '~ 15 mins',
      location: 'Pokhara, Nepal',
    ),
    Advisor(
      id: 'adv_005',
      name: 'Suman Pant, MBA',
      titleEn: 'Company Registrar & Business Consultant',
      titleNp: 'कम्पनी दर्ता तथा व्यवसाय विकास सल्लाहकार',
      category: AdvisorCategory.business,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      rating: 4.92,
      reviewsCount: 95,
      experienceYears: 9,
      bioEn: 'Guides entrepreneurs in registering Private Limited companies, Foreign Direct Investment (FDI), Department of Industry approvals, and trademark registration.',
      bioNp: 'प्राइभेट लिमिटेड कम्पनी दर्ता, उद्योग विभाग अनुमति, र ट्रेडमार्क दर्तासम्बन्धी विशेषज्ञ।',
      consultationFeeChat: 220.0,
      consultationFeeCall: 480.0,
      isOnline: true,
      languages: ['Nepali', 'English', 'Maithili'],
      expertiseTags: ['Pvt Ltd Registration', 'OCR Compliance', 'FDI Approval', 'Trademark Registration'],
      responseTime: '< 5 mins',
      location: 'Biratnagar, Nepal',
    ),
    Advisor(
      id: 'adv_006',
      name: 'Maya Devi Gurung',
      titleEn: 'Social Security & Vital Events Officer',
      titleNp: 'सामाजिक सुरक्षा तथा व्यक्तिगत घटना सल्लाहकार',
      category: AdvisorCategory.general,
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      rating: 4.79,
      reviewsCount: 84,
      experienceYears: 10,
      bioEn: 'Assists citizens with SSF enrolment, Pension scheme, Birth/Death certificate correction, and Senior Citizen Allowance procedures.',
      bioNp: 'सामाजिक सुरक्षा कोष, वृद्धभत्ता, र व्यक्तिगत घटना दर्ता संशोधनसम्बन्धी परामर्शदाता।',
      consultationFeeChat: 120.0,
      consultationFeeCall: 300.0,
      isOnline: true,
      languages: ['Nepali', 'English', 'Gurung'],
      expertiseTags: ['SSF Scheme', 'Senior Citizen Allowance', 'Vital Events', 'Ward Documentation'],
      responseTime: '< 4 mins',
      location: 'Chitwan, Nepal',
    ),
  ];

  Future<void> loadAdvisors() async {
    _status = AdvisorsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _apiAdvisors = await _repository.getAdvisors();
      _status = AdvisorsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AdvisorsStatus.error;
    }
    notifyListeners();
  }

  List<Advisor> get advisors {
    final source = _apiAdvisors.isNotEmpty ? _apiAdvisors : _fallbackAdvisors;
    return source.where((adv) {
      if (_selectedCategory != null && adv.category != _selectedCategory) {
        return false;
      }
      if (_onlyOnline && !adv.isOnline) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = adv.name.toLowerCase().contains(query);
        final titleEnMatch = adv.titleEn.toLowerCase().contains(query);
        final titleNpMatch = adv.titleNp.toLowerCase().contains(query);
        final tagMatch = adv.expertiseTags.any((t) => t.toLowerCase().contains(query));
        return nameMatch || titleEnMatch || titleNpMatch || tagMatch;
      }
      return true;
    }).toList();
  }

  Advisor? findById(String id) {
    final source = _apiAdvisors.isNotEmpty ? _apiAdvisors : _fallbackAdvisors;
    try {
      return source.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void setCategory(AdvisorCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleOnlyOnline() {
    _onlyOnline = !_onlyOnline;
    notifyListeners();
  }
}

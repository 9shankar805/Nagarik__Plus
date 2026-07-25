import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../advisors/screens/advisors_list_screen.dart';
import '../providers/services_provider.dart';
import 'service_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesProvider>().loadServices();
    });
  }
  final List<_ServiceData> _services = [
    _ServiceData(
      title: 'Passport',
      subtitle: 'Apply, renew or update your passport',
      icon: Icons.book_rounded,
      color: const Color(0xFF1565C0),
      eligibility: 'All Nepali citizens above 16 years',
      documents: ['Citizenship Certificate', 'Birth Certificate', 'Marriage Certificate (if applicable)', 'Old Passport (for renewal)'],
      steps: ['Visit the passport application portal', 'Fill the online form', 'Upload required documents', 'Pay the fee', 'Schedule biometrics appointment', 'Collect passport'],
      fee: 'NPR 5,000 – 15,000',
      processingTime: '7–21 working days',
      faqs: ['Can I apply online?', 'What is the validity period?', 'Can I expedite the process?'],
    ),
    _ServiceData(
      title: 'PAN Card',
      subtitle: 'Register for Permanent Account Number',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF2E7D32),
      eligibility: 'Any individual or business entity in Nepal',
      documents: ['Citizenship Certificate', 'Recent Passport Photo', 'Business Registration (for businesses)'],
      steps: ['Visit IRD website or office', 'Fill PAN registration form', 'Submit documents', 'Receive PAN card'],
      fee: 'Free (online) or NPR 100 (offline)',
      processingTime: '1–3 working days',
      faqs: ['Do I need PAN for employment?', 'Can I register online?'],
    ),
    _ServiceData(
      title: 'National ID',
      subtitle: 'Biometric National Identity Card',
      icon: Icons.badge_rounded,
      color: const Color(0xFF6A1B9A),
      eligibility: 'All Nepali citizens above 16 years',
      documents: ['Citizenship Certificate', 'Birth Certificate'],
      steps: ['Visit NID enrollment center', 'Fill application form', 'Biometric capture', 'Verify information', 'Receive NID'],
      fee: 'Free',
      processingTime: '7–14 working days',
      faqs: ['Is NID mandatory?', 'Can foreigners get NID?'],
    ),
    _ServiceData(
      title: 'Driving License',
      subtitle: 'Apply for or renew driving license',
      icon: Icons.drive_eta_rounded,
      color: const Color(0xFFF57F17),
      eligibility: 'Citizens above 16 years (two-wheelers), 18 years (four-wheelers)',
      documents: ['Citizenship Certificate', 'Medical Certificate', 'Passport Photo', 'Blood Group Certificate'],
      steps: ['Register on DOTM website', 'Submit documents', 'Written test', 'Trial (practical) test', 'Receive license'],
      fee: 'NPR 1,500 – 2,500',
      processingTime: '3–7 working days after passing tests',
      faqs: ['How often do I need to renew?', 'Can I apply for multiple categories?'],
    ),
    _ServiceData(
      title: 'Vehicle Registration',
      subtitle: 'Register your vehicle with DOTM',
      icon: Icons.directions_car_rounded,
      color: const Color(0xFF00695C),
      eligibility: 'Vehicle owners in Nepal',
      documents: ['Purchase Invoice', 'Tax Clearance', 'Citizenship Certificate', 'Insurance', 'Customs Clearance (for imported vehicles)'],
      steps: ['Submit documents to DOTM', 'Technical inspection', 'Pay registration fee', 'Receive bluebook'],
      fee: 'Based on engine capacity',
      processingTime: '3–5 working days',
      faqs: ['Is annual renewal required?', 'What is bluebook?'],
    ),
    _ServiceData(
      title: 'Business Registration',
      subtitle: 'Register sole proprietorship or firm',
      icon: Icons.store_rounded,
      color: const Color(0xFF00838F),
      eligibility: 'Any citizen planning to start a business',
      documents: ['Citizenship Certificate', 'Tenancy Agreement', 'PAN Card', 'Tax Clearance'],
      steps: ['Choose business type', 'Register at OCR or Ward Office', 'Obtain PAN', 'Open business bank account'],
      fee: 'NPR 500 – 2,000',
      processingTime: '1–3 working days',
      faqs: ['What is the difference between sole proprietorship and company?'],
    ),
    _ServiceData(
      title: 'Company Registration',
      subtitle: 'Register Pvt. Ltd. or Public company',
      icon: Icons.business_rounded,
      color: const Color(0xFF1565C0),
      eligibility: 'Minimum 2 promoters (for Pvt. Ltd.)',
      documents: ['Citizenship of all promoters', 'MoA / AoA', 'Office lease agreement', 'PAN of promoters'],
      steps: ['Reserve company name at OCR', 'Prepare MoA/AoA', 'Submit registration form', 'Pay registration fee', 'Receive registration certificate', 'Obtain PAN and tax registration'],
      fee: 'NPR 9,000 onwards',
      processingTime: '5–10 working days',
      faqs: ['Minimum capital required?', 'Can foreigners register a company in Nepal?'],
    ),
    _ServiceData(
      title: 'Tax Information',
      subtitle: 'VAT, income tax, and tax filing',
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF4A148C),
      eligibility: 'All taxable individuals and businesses',
      documents: ['PAN Card', 'Financial Statements', 'Income Documents'],
      steps: ['Register on IRD portal', 'File annual tax return', 'Pay taxes online or at bank', 'Obtain tax clearance'],
      fee: 'Based on income/turnover',
      processingTime: 'Annual filing deadline: Poush End',
      faqs: ['When is tax filing due?', 'What is VAT threshold?'],
    ),
    _ServiceData(
      title: 'Voter Registration',
      subtitle: 'Register or update voter details',
      icon: Icons.how_to_vote_rounded,
      color: AppColors.danger,
      eligibility: 'Nepali citizens above 18 years',
      documents: ['Citizenship Certificate', 'Recent Photo'],
      steps: ['Visit Election Commission office', 'Fill voter registration form', 'Submit documents', 'Verify in voter list'],
      fee: 'Free',
      processingTime: 'Seasonal (announced before elections)',
      faqs: ['How do I check my name in voter list?', 'Can I vote from abroad?'],
    ),
  ];

  String _searchQuery = '';

  List<_ServiceData> get _filteredServices {
    final providerServices = context.watch<ServicesProvider>().services;
    final List<_ServiceData> sourceList = providerServices.isNotEmpty
        ? providerServices.map((cs) => _ServiceData(
              title: cs.title,
              subtitle: cs.description ?? cs.category ?? '',
              icon: Icons.article_rounded,
              color: AppColors.primary,
              eligibility: cs.eligibility?.entries.map((e) => '${e.key}: ${e.value}').join(', ') ?? 'All Nepali citizens',
              documents: cs.documents?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
              steps: cs.steps?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
              fee: cs.fee ?? 'N/A',
              processingTime: cs.processingTime ?? 'Standard processing',
              faqs: cs.faqs?.map((f) => f.toString()).toList() ?? [],
            )).toList()
        : _services;

    if (_searchQuery.isEmpty) return sourceList;
    return sourceList
        .where((s) =>
            s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.citizenServices,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.l10n.searchServices,
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Featured Nagarik Advisors Banner Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdvisorsListScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.indigo.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNepali ? 'नागरिक सल्लाकार (Nagarik Advisors)' : 'Nagarik Advisors Portal',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isNepali ? 'विशेषज्ञहरूसँग १-अन-१ च्याट र फोन सल्लाह (Paid)' : 'Consult verified experts via Chat & Call',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return _ServiceCard(
                  service: service,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(service: service),
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
}

class _ServiceCard extends StatelessWidget {
  final _ServiceData service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  String _getLocalizedTitle(BuildContext context, String rawTitle) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    if (!isNepali) return rawTitle;
    switch (rawTitle) {
      case 'Passport':
        return 'राहदानी';
      case 'PAN Card':
        return 'प्यान कार्ड';
      case 'National ID':
        return 'राष्ट्रिय परिचयपत्र';
      case 'Driving License':
        return 'सवारी चालक अनुमतिपत्र';
      case 'Vehicle Registration':
        return 'सवारी दर्ता';
      case 'Business Registration':
        return 'व्यापार दर्ता';
      case 'Company Registration':
        return 'कम्पनी दर्ता';
      case 'Tax Information':
        return 'कर जानकारी';
      case 'Voter Registration':
        return 'मतदाता दर्ता';
      default:
        return rawTitle;
    }
  }

  String _getLocalizedSubtitle(BuildContext context, String rawSubtitle) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    if (!isNepali) return rawSubtitle;
    switch (rawSubtitle) {
      case 'Apply, renew or update your passport':
        return 'राहदानी आवेदन, नवीकरण वा अद्यावधिक गर्नुहोस्';
      case 'Register for Permanent Account Number':
        return 'स्थायी लेखा नम्बरका लागि दर्ता गर्नुहोस्';
      case 'Biometric National Identity Card':
        return 'बायोमेट्रिक राष्ट्रिय परिचयपत्र';
      case 'Apply for or renew driving license':
        return 'सवारी चालक अनुमतिपत्र आवेदन वा नवीकरण गर्नुहोस्';
      case 'Register your vehicle with DOTM':
        return 'यातायात व्यवस्था विभागमा सवारी दर्ता गर्नुहोस्';
      case 'Register sole proprietorship or firm':
        return 'एकल फर्म वा फर्म दर्ता गर्नुहोस्';
      case 'Register Pvt. Ltd. or Public company':
        return 'प्राइभेट लिमिटेड वा पब्लिक कम्पनी दर्ता गर्नुहोस्';
      case 'VAT, income tax, and tax filing':
        return 'मूल्य अभिवृद्धि कर, आयकर र कर चुक्ता';
      case 'Register or update voter details':
        return 'मतदाता विवरण दर्ता वा अद्यावधिक गर्नुहोस्';
      default:
        return rawSubtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: service.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(service.icon, color: service.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLocalizedTitle(context, service.title),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getLocalizedSubtitle(context, service.subtitle),
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textLight,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String eligibility;
  final List<String> documents;
  final List<String> steps;
  final String fee;
  final String processingTime;
  final List<String> faqs;

  const _ServiceData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.eligibility,
    required this.documents,
    required this.steps,
    required this.fee,
    required this.processingTime,
    required this.faqs,
  });
}

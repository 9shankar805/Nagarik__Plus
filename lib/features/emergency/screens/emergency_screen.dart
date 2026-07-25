import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/emergency_provider.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  static const List<_EmergencyContact> _fallbackContacts = [
    _EmergencyContact(
      name: 'Nepal Police',
      number: '100',
      subtitle: 'Emergency Police Line',
      icon: Icons.local_police_rounded,
      color: Color(0xFF1565C0),
    ),
    _EmergencyContact(
      name: 'Ambulance',
      number: '102',
      subtitle: 'Medical Emergency',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFD32F2F),
    ),
    _EmergencyContact(
      name: 'Fire Brigade',
      number: '101',
      subtitle: 'Fire Emergency',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE65100),
    ),
    _EmergencyContact(
      name: 'Disaster Management',
      number: '1149',
      subtitle: 'National Disaster Risk Reduction',
      icon: Icons.crisis_alert_rounded,
      color: Color(0xFF6A1B9A),
    ),
    _EmergencyContact(
      name: 'Traffic Police',
      number: '103',
      subtitle: 'Traffic Emergency',
      icon: Icons.traffic_rounded,
      color: Color(0xFF00838F),
    ),
    _EmergencyContact(
      name: 'Women Helpline',
      number: '1145',
      subtitle: 'Women & Children',
      icon: Icons.woman_rounded,
      color: Color(0xFFAD1457),
    ),
    _EmergencyContact(
      name: 'Nepal Telecom',
      number: '1498',
      subtitle: 'Telecom Helpline',
      icon: Icons.phone_rounded,
      color: Color(0xFF2E7D32),
    ),
    _EmergencyContact(
      name: 'COVID Helpline',
      number: '1115',
      subtitle: 'Health Emergency',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF00695C),
    ),
  ];

  static const List<_Hospital> _fallbackHospitals = [
    _Hospital(
      name: 'Bir Hospital',
      address: 'Mahaboudha, Kathmandu',
      phone: '01-4221119',
      type: 'Government',
    ),
    _Hospital(
      name: 'Patan Hospital',
      address: 'Lagankhel, Lalitpur',
      phone: '01-5522266',
      type: 'Government',
    ),
    _Hospital(
      name: 'Teaching Hospital',
      address: 'Maharajgunj, Kathmandu',
      phone: '01-4412505',
      type: 'Teaching',
    ),
    _Hospital(
      name: 'Norvic Hospital',
      address: 'Thapathali, Kathmandu',
      phone: '01-5970032',
      type: 'Private',
    ),
  ];

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyProvider>().loadEmergencyData();
    });
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  IconData _iconForCategory(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'police': return Icons.local_police_rounded;
      case 'ambulance': return Icons.local_hospital_rounded;
      case 'fire': return Icons.local_fire_department_rounded;
      case 'disaster': return Icons.crisis_alert_rounded;
      case 'traffic': return Icons.traffic_rounded;
      case 'women': return Icons.woman_rounded;
      default: return Icons.phone_in_talk_rounded;
    }
  }

  Color _colorForCategory(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'police': return const Color(0xFF1565C0);
      case 'ambulance': return const Color(0xFFD32F2F);
      case 'fire': return const Color(0xFFE65100);
      case 'disaster': return const Color(0xFF6A1B9A);
      case 'traffic': return const Color(0xFF00838F);
      case 'women': return const Color(0xFFAD1457);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyProvider>();
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';

    final contactsList = provider.contacts.isNotEmpty
        ? provider.contacts
            .map((c) => _EmergencyContact(
                  name: isNepali && c.nameNp != null ? c.nameNp! : c.name,
                  number: c.phone ?? '100',
                  subtitle: isNepali && c.descriptionNp != null
                      ? c.descriptionNp!
                      : (c.description ?? 'Emergency Helpline'),
                  icon: _iconForCategory(c.category),
                  color: _colorForCategory(c.category),
                ))
            .toList()
        : EmergencyScreen._fallbackContacts;

    final hospitalsList = provider.hospitals.isNotEmpty
        ? provider.hospitals
            .map((h) => _Hospital(
                  name: isNepali && h.nameNp != null ? h.nameNp! : h.name,
                  address: isNepali && h.addressNp != null ? h.addressNp! : (h.address ?? 'Nepal'),
                  phone: h.phone ?? 'N/A',
                  type: h.type ?? 'General',
                ))
            .toList()
        : EmergencyScreen._fallbackHospitals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        title: Text(isNepali ? 'संकटकालीन सम्पर्कहरू' : 'Emergency Contacts',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<EmergencyProvider>().loadEmergencyData(forceRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: AppColors.danger,
                child: Column(
                  children: [
                    const Icon(Icons.sos_rounded, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    Text(isNepali ? 'आपतकालीन सेवाहरू' : 'Emergency Services',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(isNepali ? 'तुरन्त फोन गर्न कुनै पनि कार्ड थिच्नुहोस्' : 'Tap any card to call immediately',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Emergency Contacts Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(isNepali ? 'आपतकालीन नम्बरहरू' : 'Emergency Numbers',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: contactsList.length,
                itemBuilder: (context, index) {
                  final contact = contactsList[index];
                  return GestureDetector(
                    onTap: () => _callNumber(contact.number),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: contact.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(contact.icon,
                                      color: contact.color, size: 20),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: contact.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(contact.number,
                                      style: TextStyle(
                                          color: contact.color,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(contact.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(contact.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Hospitals
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(isNepali ? 'नजिकका अस्पतालहरू' : 'Nearby Hospitals',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: hospitalsList.length,
                itemBuilder: (context, index) {
                  final hospital = hospitalsList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_hospital_rounded,
                              color: AppColors.danger, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hospital.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(hospital.address,
                                  style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12)),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(hospital.type,
                                    style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _callNumber(hospital.phone),
                          icon: const Icon(Icons.call_rounded,
                              color: AppColors.success),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyContact {
  final String name;
  final String number;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _EmergencyContact({
    required this.name,
    required this.number,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _Hospital {
  final String name;
  final String address;
  final String phone;
  final String type;
  const _Hospital({
    required this.name,
    required this.address,
    required this.phone,
    required this.type,
  });
}

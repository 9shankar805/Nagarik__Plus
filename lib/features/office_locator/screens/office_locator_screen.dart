import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../models/office_model.dart';
import '../providers/office_provider.dart';

class OfficeLocatorScreen extends StatefulWidget {
  const OfficeLocatorScreen({super.key});

  @override
  State<OfficeLocatorScreen> createState() => _OfficeLocatorScreenState();
}

class _OfficeLocatorScreenState extends State<OfficeLocatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfficeProvider>().loadOffices();
    });
  }
  int _selectedCategory = 0;
  String _searchQuery = '';

  final List<String> _categories = [
    'All', 'Passport', 'Transport', 'Tax', 'Municipality', 'Police',
  ];

  final List<_Office> _offices = [
    _Office(
      name: 'Department of Passports',
      address: 'Narayanhiti, Kathmandu',
      phone: '01-4416000',
      category: 'Passport',
      hours: '10:00 AM – 5:00 PM (Sun–Fri)',
      mapUrl: 'https://maps.google.com/?q=Department+of+Passports+Kathmandu',
      color: const Color(0xFF1565C0),
      icon: Icons.book_rounded,
    ),
    _Office(
      name: 'Pokhara Passport Office',
      address: 'Prithvipath, Pokhara',
      phone: '061-521000',
      category: 'Passport',
      hours: '10:00 AM – 5:00 PM (Sun–Fri)',
      mapUrl: 'https://maps.google.com/?q=Pokhara+Passport+Office',
      color: const Color(0xFF1565C0),
      icon: Icons.book_rounded,
    ),
    _Office(
      name: 'Dept. of Transport Management',
      address: 'Minbhawan, Kathmandu',
      phone: '01-4480204',
      category: 'Transport',
      hours: '10:00 AM – 5:00 PM (Sun–Fri)',
      mapUrl: 'https://maps.google.com/?q=DOTM+Kathmandu',
      color: const Color(0xFFF57F17),
      icon: Icons.drive_eta_rounded,
    ),
    _Office(
      name: 'Bagmati Province DOTM',
      address: 'Hetauda, Bagmati',
      phone: '057-520555',
      category: 'Transport',
      hours: '10:00 AM – 5:00 PM (Sun–Fri)',
      mapUrl: 'https://maps.google.com/?q=Hetauda+Transport+Office',
      color: const Color(0xFFF57F17),
      icon: Icons.drive_eta_rounded,
    ),
    _Office(
      name: 'Inland Revenue Dept. (IRD)',
      address: 'Lazimpat, Kathmandu',
      phone: '01-4415802',
      category: 'Tax',
      hours: '10:00 AM – 5:00 PM (Sun–Fri)',
      mapUrl: 'https://maps.google.com/?q=IRD+Kathmandu',
      color: const Color(0xFF2E7D32),
      icon: Icons.account_balance_rounded,
    ),
    _Office(
      name: 'KMC Ward Office 1',
      address: 'Kathmandu Metropolitan City',
      phone: '01-4270000',
      category: 'Municipality',
      hours: '9:00 AM – 4:00 PM (Sun–Fri)',
      mapUrl: 'https://maps.google.com/?q=KMC+Ward+1+Kathmandu',
      color: const Color(0xFF00695C),
      icon: Icons.location_city_rounded,
    ),
    _Office(
      name: 'Metropolitan Police, Ranipokhari',
      address: 'Ranipokhari, Kathmandu',
      phone: '01-4223100',
      category: 'Police',
      hours: '24/7',
      mapUrl: 'https://maps.google.com/?q=Metropolitan+Police+Ranipokhari',
      color: AppColors.danger,
      icon: Icons.local_police_rounded,
    ),
    _Office(
      name: 'District Administration Office',
      address: 'Babarmahal, Kathmandu',
      phone: '01-4224374',
      category: 'Municipality',
      hours: '10:00 AM – 5:00 PM (Sun–Fri)',
      mapUrl: 'https://maps.google.com/?q=DAO+Kathmandu',
      color: const Color(0xFF6A1B9A),
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  List<_Office> get _filtered {
    final providerOffices = context.watch<OfficeProvider>().offices;
    final List<_Office> sourceList = providerOffices.isNotEmpty
        ? providerOffices.map((o) => _Office(
              name: o.name,
              address: o.address ?? 'Nepal',
              phone: o.phone ?? 'N/A',
              category: o.category,
              hours: o.openingHours ?? '10:00 AM - 5:00 PM',
              mapUrl: (o.latitude != null && o.longitude != null)
                  ? 'https://maps.google.com/?q=${o.latitude},${o.longitude}'
                  : 'https://maps.google.com/?q=${Uri.encodeComponent(o.name)}',
              color: AppColors.primary,
              icon: Icons.location_on_rounded,
            )).toList()
        : _offices;

    var list = _selectedCategory == 0
        ? sourceList
        : sourceList.where((o) => o.category == _categories[_selectedCategory]).toList();

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((o) =>
              o.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              o.address.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  String _getCategoryName(BuildContext context, String cat) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    if (!isNepali) return cat;
    switch (cat) {
      case 'All': return 'सबै';
      case 'Passport': return 'राहदानी';
      case 'Transport': return 'यातायात';
      case 'Tax': return 'कर';
      case 'Municipality': return 'नगरपालिका';
      case 'Police': return 'प्रहरी';
      default: return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(context.l10n.findNearbyOffices,
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isNepali ? 'कार्यालय खोज्नुहोस्...' : 'Search offices...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Categories
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      _getCategoryName(context, _categories[index]),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textMedium,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(isNepali ? 'कुनै कार्यालय भेटिएन' : 'No offices found',
                        style: const TextStyle(color: AppColors.textLight)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final office = _filtered[index];
                      return _OfficeCard(office: office);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final _Office office;
  const _OfficeCard({required this.office});

  Future<void> _launchMap() async {
    final uri = Uri.parse(office.mapUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:${office.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _getLocalizedName(BuildContext context, String name) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    if (!isNepali) return name;
    switch (name) {
      case 'Department of Passports': return 'राहदानी विभाग';
      case 'Pokhara Passport Office': return 'पोखरा राहदानी कार्यालय';
      case 'Dept. of Transport Management': return 'यातायात व्यवस्था विभाग';
      case 'Bagmati Province DOTM': return 'बागमती प्रदेश यातायात कार्यालय';
      case 'Inland Revenue Dept. (IRD)': return 'आन्तरिक राजस्व विभाग';
      case 'KMC Ward Office 1': return 'का.म.पा. वडा कार्यालय १';
      case 'Metropolitan Police, Ranipokhari': return 'महानगरीय प्रहरी, रानीपोखरी';
      case 'District Administration Office': return 'जिल्ला प्रशासन कार्यालय';
      default: return name;
    }
  }

  String _getLocalizedAddress(BuildContext context, String address) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    if (!isNepali) return address;
    switch (address) {
      case 'Narayanhiti, Kathmandu': return 'नारायणहिटी, काठमाडौँ';
      case 'Prithvipath, Pokhara': return 'पृथ्वीपथ, पोखरा';
      case 'Minbhawan, Kathmandu': return 'मीनभवन, काठमाडौँ';
      case 'Hetauda, Bagmati': return 'हेटौँडा, बागमती';
      case 'Lazimpat, Kathmandu': return 'लाजिम्पाट, काठमाडौँ';
      case 'Kathmandu Metropolitan City': return 'काठमाडौँ महानगरपालिका';
      case 'Ranipokhari, Kathmandu': return 'रानीपोखरी, काठमाडौँ';
      case 'Babarmahal, Kathmandu': return 'बबरमहल, काठमाडौँ';
      default: return address;
    }
  }

  String _getLocalizedHours(BuildContext context, String hours) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    if (!isNepali) return hours;
    if (hours.contains('24/7')) return '२४ घण्टा खुला';
    if (hours.contains('9:00 AM')) return '९:०० AM – ४:०० PM (आइत–शुक्र)';
    return '१०:०० AM – ५:०० PM (आइत–शुक्र)';
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: office.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(office.icon, color: office.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getLocalizedName(context, office.name),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.textLight, size: 13),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(_getLocalizedAddress(context, office.address),
                                style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppColors.textLight, size: 13),
                const SizedBox(width: 4),
                Text(_getLocalizedHours(context, office.hours),
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _launchPhone,
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: Text(office.phone,
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _launchMap,
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: Text(isNepali ? 'दिशा-निर्देश' : 'Directions',
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: office.color,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

class _Office {
  final String name;
  final String address;
  final String phone;
  final String category;
  final String hours;
  final String mapUrl;
  final Color color;
  final IconData icon;

  const _Office({
    required this.name,
    required this.address,
    required this.phone,
    required this.category,
    required this.hours,
    required this.mapUrl,
    required this.color,
    required this.icon,
  });
}

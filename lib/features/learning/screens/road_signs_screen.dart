import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RoadSignsScreen extends StatefulWidget {
  const RoadSignsScreen({super.key});

  @override
  State<RoadSignsScreen> createState() => _RoadSignsScreenState();
}

class _RoadSignsScreenState extends State<RoadSignsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_SignCategory> _categories = [
    _SignCategory('Mandatory', [
      _Sign(Icons.stop_circle_rounded, 'Stop', AppColors.danger,
          'You must stop your vehicle completely'),
      _Sign(Icons.speed_rounded, 'Speed Limit', AppColors.danger,
          'Do not exceed the indicated speed'),
      _Sign(Icons.u_turn_right_rounded, 'No U-Turn', AppColors.danger,
          'U-turns are prohibited'),
      _Sign(Icons.do_not_disturb_rounded, 'No Entry', AppColors.danger,
          'Entry is prohibited for all vehicles'),
      _Sign(Icons.no_crash_rounded, 'No Overtaking', AppColors.danger,
          'Overtaking other vehicles is prohibited'),
      _Sign(Icons.turn_right_rounded, 'Turn Right', AppColors.primary,
          'You must turn right ahead'),
    ]),
    _SignCategory('Warning', [
      _Sign(Icons.warning_amber_rounded, 'Road Work Ahead', AppColors.warning,
          'Road construction ahead, slow down'),
      _Sign(Icons.child_care_rounded, 'School Zone', AppColors.warning,
          'School nearby, watch for children'),
      _Sign(Icons.waves_rounded, 'Slippery Road', AppColors.warning,
          'Road may be slippery, reduce speed'),
      _Sign(Icons.pets_rounded, 'Animals on Road', AppColors.warning,
          'Watch out for animals crossing'),
      _Sign(Icons.train_rounded, 'Railway Crossing', AppColors.warning,
          'Railway crossing ahead'),
      _Sign(Icons.roundabout_right_rounded, 'Roundabout', AppColors.warning,
          'Roundabout ahead, give way'),
    ]),
    _SignCategory('Informatory', [
      _Sign(Icons.local_hospital_rounded, 'Hospital', AppColors.secondary,
          'Hospital ahead'),
      _Sign(Icons.local_gas_station_rounded, 'Fuel Station', AppColors.secondary,
          'Fuel station available ahead'),
      _Sign(Icons.restaurant_rounded, 'Restaurant', AppColors.secondary,
          'Food available ahead'),
      _Sign(Icons.local_parking_rounded, 'Parking', AppColors.primary,
          'Parking area available'),
      _Sign(Icons.info_rounded, 'Information', AppColors.info,
          'Tourist information center'),
      _Sign(Icons.phone_rounded, 'Emergency Phone', AppColors.info,
          'Emergency telephone ahead'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Road Signs',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _categories
              .map((c) => Tab(text: c.name))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: category.signs.length,
            itemBuilder: (context, index) {
              final sign = category.signs[index];
              return GestureDetector(
                onTap: () => _showSignDetail(context, sign),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: sign.color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sign.icon, color: sign.color, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(sign.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _showSignDetail(BuildContext context, _Sign sign) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: sign.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(sign.icon, color: sign.color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(sign.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(sign.meaning,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMedium, fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SignCategory {
  final String name;
  final List<_Sign> signs;
  const _SignCategory(this.name, this.signs);
}

class _Sign {
  final IconData icon;
  final String name;
  final Color color;
  final String meaning;
  const _Sign(this.icon, this.name, this.color, this.meaning);
}

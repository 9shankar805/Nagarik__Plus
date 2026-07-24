import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TrafficRulesScreen extends StatelessWidget {
  const TrafficRulesScreen({super.key});

  static const List<_Rule> _rules = [
    _Rule(Icons.speed_rounded, 'Speed Limits',
        '• Residential: 30 km/h\n• Urban roads: 50 km/h\n• Highways: 80 km/h\n• Expressways: 100 km/h',
        AppColors.primary),
    _Rule(Icons.airline_seat_recline_normal_rounded, 'Seatbelts',
        '• Mandatory for driver and all passengers\n• Children must use appropriate child restraints\n• Fine for non-compliance',
        AppColors.secondary),
    _Rule(Icons.phone_android_rounded, 'Mobile Phones',
        '• Using handheld phone while driving is prohibited\n• Hands-free devices are allowed\n• Heavy fine for violations',
        AppColors.danger),
    _Rule(Icons.local_bar_rounded, 'Drink & Drive',
        '• Zero tolerance for drunk driving\n• Blood alcohol limit: 0.03%\n• Immediate license suspension',
        AppColors.danger),
    _Rule(Icons.priority_high_rounded, 'Right of Way',
        '• Vehicles on the right have priority at intersections\n• Emergency vehicles always have right of way\n• Pedestrians at zebra crossings',
        AppColors.accent),
    _Rule(Icons.directions_walk_rounded, 'Pedestrian Rules',
        '• Always use zebra crossings\n• Use footpaths when available\n• Do not jaywalk on highways',
        AppColors.secondary),
    _Rule(Icons.two_wheeler_rounded, 'Motorcycle Rules',
        '• Helmet mandatory for rider and pillion\n• No lane splitting at high speed\n• Valid license required',
        AppColors.primary),
    _Rule(Icons.night_shelter_rounded, 'Night Driving',
        '• Use headlights from dusk to dawn\n• Dim lights when approaching oncoming traffic\n• Avoid high beam in fog',
        AppColors.info),
    _Rule(Icons.local_parking_rounded, 'Parking Rules',
        '• No parking near intersections\n• No parking on zebra crossings\n• No parking within 5m of fire hydrant',
        AppColors.warning),
    _Rule(Icons.school_rounded, 'School Zones',
        '• Speed limit: 20 km/h near schools\n• No overtaking near school zones\n• Extra caution during school hours',
        AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Traffic Rules',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: rule.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(rule.icon, color: rule.color, size: 22),
                ),
                title: Text(rule.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(rule.content,
                        style: const TextStyle(
                            color: AppColors.textMedium,
                            height: 1.6,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Rule {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  const _Rule(this.icon, this.title, this.content, this.color);
}

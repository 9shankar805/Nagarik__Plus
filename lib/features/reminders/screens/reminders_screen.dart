import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/reminder_model.dart';
import '../providers/reminders_provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersProvider>().loadReminders();
    });
  }
  final List<_Reminder> _reminders = [
    _Reminder(
      title: 'Driving License Expiry',
      subtitle: 'License No: 02-78-002345',
      icon: Icons.drive_eta_rounded,
      color: AppColors.danger,
      dueDate: DateTime(2025, 6, 15),
      isEnabled: true,
    ),
    _Reminder(
      title: 'Vehicle Insurance',
      subtitle: 'Policy: INS-0012345',
      icon: Icons.security_rounded,
      color: AppColors.warning,
      dueDate: DateTime(2025, 1, 30),
      isEnabled: true,
    ),
    _Reminder(
      title: 'Passport Expiry',
      subtitle: 'No: Pa1234567',
      icon: Icons.book_rounded,
      color: AppColors.secondary,
      dueDate: DateTime(2028, 9, 20),
      isEnabled: true,
    ),
    _Reminder(
      title: 'Vehicle Bluebook Renewal',
      subtitle: 'Ba 3 Pa 2345',
      icon: Icons.directions_car_rounded,
      color: AppColors.primary,
      dueDate: DateTime(2025, 3, 10),
      isEnabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final urgent = _reminders.where(
        (r) => r.dueDate.difference(DateTime.now()).inDays < 30).toList();
    final upcoming = _reminders.where(
        (r) => r.dueDate.difference(DateTime.now()).inDays >= 30).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddReminderSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                _SummaryCard(
                  label: 'Urgent',
                  count: urgent.length,
                  color: AppColors.danger,
                  icon: Icons.warning_rounded,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'Upcoming',
                  count: upcoming.length,
                  color: AppColors.secondary,
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: 'Total',
                  count: _reminders.length,
                  color: AppColors.primary,
                  icon: Icons.notifications_rounded,
                ),
              ],
            ),

            if (urgent.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Urgent — Expiring Soon',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              ...urgent.map((r) => _ReminderCard(
                    reminder: r,
                    onToggle: (v) => setState(() => r.isEnabled = v),
                  )),
            ],

            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Upcoming',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              ...upcoming.map((r) => _ReminderCard(
                    reminder: r,
                    onToggle: (v) => setState(() => r.isEnabled = v),
                  )),
            ],

            const SizedBox(height: 20),

            // Add reminder button
            GestureDetector(
              onTap: () => _showAddReminderSheet(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Add New Reminder',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Add Reminder',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Document Name',
                  prefixIcon: Icon(Icons.article_rounded),
                ),
              ),
              const SizedBox(height: 14),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Reminder',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final _Reminder reminder;
  final ValueChanged<bool> onToggle;

  const _ReminderCard({required this.reminder, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final daysLeft = reminder.dueDate.difference(DateTime.now()).inDays;
    final isExpired = daysLeft < 0;
    final isUrgent = daysLeft < 30 && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isExpired || isUrgent
            ? Border.all(
                color: isExpired
                    ? AppColors.danger
                    : AppColors.warning,
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: reminder.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(reminder.icon, color: reminder.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(reminder.subtitle,
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isExpired
                            ? AppColors.danger
                            : isUrgent
                                ? AppColors.warning
                                : AppColors.secondary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isExpired
                        ? 'Expired'
                        : '$daysLeft days remaining',
                    style: TextStyle(
                      color: isExpired
                          ? AppColors.danger
                          : isUrgent
                              ? AppColors.warning
                              : AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.isEnabled,
            activeColor: AppColors.primary,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Reminder {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime dueDate;
  bool isEnabled;

  _Reminder({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.dueDate,
    required this.isEnabled,
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllNotifications(),
                  _buildUpdatesTab(),
                  _buildRemindersTab(),
                  _buildAlertsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF212121),
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded,
                  size: 20, color: AppColors.primary),
              onPressed: () => _showSettingsSheet(context),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMedium,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Updates'),
            Tab(text: 'Reminders'),
            Tab(text: 'Alerts'),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNotifications() {
    final notifications = _getAllNotifications();
    
    if (notifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No Notifications',
        subtitle: 'You\'re all caught up!',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: [
        _buildDateGroup('Today', notifications.where((n) => n.isToday).toList()),
        _buildDateGroup('Yesterday', notifications.where((n) => n.isYesterday).toList()),
        _buildDateGroup('Earlier', notifications.where((n) => !n.isToday && !n.isYesterday).toList()),
      ],
    );
  }

  Widget _buildDateGroup(String label, List<_Notification> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((n) => _buildNotificationCard(n)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNotificationCard(_Notification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                notification.isRead = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: notification.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notification.icon,
                      color: notification.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                  color: const Color(0xFF212121),
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(notification.timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (notification.category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: notification.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  notification.category!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: notification.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdatesTab() {
    final updates = _getAllNotifications()
        .where((n) => n.type == _NotificationType.update)
        .toList();

    if (updates.isEmpty) {
      return _buildEmptyState(
        icon: Icons.system_update_rounded,
        title: 'No Updates',
        subtitle: 'Check back later for system and service updates',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: updates.map((n) => _buildNotificationCard(n)).toList(),
    );
  }

  Widget _buildRemindersTab() {
    final reminders = _getAllNotifications()
        .where((n) => n.type == _NotificationType.reminder)
        .toList();

    if (reminders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_active_outlined,
        title: 'No Reminders',
        subtitle: 'Your document reminders will appear here',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: reminders.map((n) => _buildNotificationCard(n)).toList(),
    );
  }

  Widget _buildAlertsTab() {
    final alerts = _getAllNotifications()
        .where((n) => n.type == _NotificationType.alert)
        .toList();

    if (alerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.warning_amber_rounded,
        title: 'No Alerts',
        subtitle: 'Important alerts will appear here',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: alerts.map((n) => _buildNotificationCard(n)).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              icon: Icons.notifications_active_rounded,
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: true,
            ),
            _buildSettingItem(
              icon: Icons.vibration_rounded,
              title: 'Vibrate',
              subtitle: 'Vibrate on new notifications',
              value: true,
            ),
            _buildSettingItem(
              icon: Icons.volume_up_rounded,
              title: 'Sound',
              subtitle: 'Play sound for notifications',
              value: false,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Mark all as read logic
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mark All as Read',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  List<_Notification> _getAllNotifications() {
    final now = DateTime.now();
    return [
      _Notification(
        id: '1',
        title: 'Driving License Expiring Soon',
        message: 'Your driving license will expire in 15 days. Renew it now to avoid penalties.',
        icon: Icons.drive_eta_rounded,
        color: AppColors.danger,
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
        type: _NotificationType.reminder,
        category: 'License',
      ),
      _Notification(
        id: '2',
        title: 'Passport Service Update',
        message: 'Department of Passports will be closed on Friday, January 31st for maintenance.',
        icon: Icons.book_rounded,
        color: AppColors.info,
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: false,
        type: _NotificationType.update,
        category: 'Service',
      ),
      _Notification(
        id: '3',
        title: 'Document Uploaded Successfully',
        message: 'Your National ID card has been uploaded and verified successfully.',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        timestamp: now.subtract(const Duration(hours: 8)),
        isRead: true,
        type: _NotificationType.update,
        category: 'Document',
      ),
      _Notification(
        id: '4',
        title: 'Vehicle Insurance Due',
        message: 'Your vehicle insurance for Ba 3 Pa 2345 is due in 7 days.',
        icon: Icons.security_rounded,
        color: AppColors.warning,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: false,
        type: _NotificationType.reminder,
        category: 'Insurance',
      ),
      _Notification(
        id: '5',
        title: 'New Feature: AI Assistant',
        message: 'Ask questions about government services using our new AI assistant.',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.accent,
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        isRead: true,
        type: _NotificationType.update,
        category: 'Feature',
      ),
      _Notification(
        id: '6',
        title: 'Security Alert',
        message: 'New login detected from Windows PC. If this wasn\'t you, please secure your account.',
        icon: Icons.shield_rounded,
        color: AppColors.danger,
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
        type: _NotificationType.alert,
        category: 'Security',
      ),
      _Notification(
        id: '7',
        title: 'PAN Card Registration Extended',
        message: 'Inland Revenue Department has extended PAN card registration deadline to March 31.',
        icon: Icons.receipt_long_rounded,
        color: AppColors.secondary,
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
        type: _NotificationType.update,
        category: 'Tax',
      ),
    ];
  }
}

enum _NotificationType {
  update,
  reminder,
  alert,
}

class _Notification {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  bool isRead;
  final _NotificationType type;
  final String? category;

  _Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.category,
  });

  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/providers/locale_provider.dart';
import '../providers/profile_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../emergency/screens/emergency_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../office_locator/screens/office_locator_screen.dart';
import '../../reminders/screens/reminders_screen.dart';
import 'personal_information_screen.dart';
import 'security_pin_screen.dart';
import 'biometrics_screen.dart';
import '../../sync/providers/sync_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final provider = context.watch<LocaleProvider>();
        final isNepali = provider.locale.languageCode == 'ne';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.selectLanguage,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: const Text('English'),
                  trailing: !isNepali ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                  onTap: () {
                    provider.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.secondary),
                  title: const Text('नेपाली (Nepali)'),
                  trailing: isNepali ? const Icon(Icons.check_circle_rounded, color: AppColors.secondary) : null,
                  onTap: () {
                    provider.setLocale(const Locale('ne'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final isNepali = localeProvider.locale.languageCode == 'ne';

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context, profileProvider),
          SliverToBoxAdapter(child: _buildStats(context, profileProvider)),
          SliverToBoxAdapter(child: _buildQuickAccess(context)),
          SliverToBoxAdapter(child: _buildSection(
            context.l10n.accountSection,
            [
              _SettingItem(
                icon: Icons.person_rounded,
                iconBg: const Color(0xFFE3EEFF),
                iconColor: AppColors.primary,
                label: context.l10n.personalInformation,
                subtitle: context.l10n.personalInfoSubtitle,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PersonalInformationScreen())),
              ),
              _SettingItem(
                icon: Icons.lock_rounded,
                iconBg: const Color(0xFFFFEDE3),
                iconColor: const Color(0xFFE65100),
                label: context.l10n.securityAndPin,
                subtitle: context.l10n.securitySubtitle,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SecurityPinScreen())),
              ),
              _SettingItem(
                icon: Icons.fingerprint_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: AppColors.secondary,
                label: context.l10n.biometricLogin,
                subtitle: context.l10n.biometricsSubtitle,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BiometricsScreen())),
              ),
            ],
          )),
          SliverToBoxAdapter(child: _buildSection(
            context.l10n.preferencesSection,
            [
              _SettingItem(
                icon: Icons.language_rounded,
                iconBg: const Color(0xFFEDE7FF),
                iconColor: const Color(0xFF7B1FA2),
                label: context.l10n.language,
                subtitle: isNepali ? context.l10n.languageNepali : context.l10n.languageEnglish,
                onTap: () => _showLanguageBottomSheet(context),
              ),
              _SettingItem(
                icon: Icons.wb_sunny_rounded,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFF9A825),
                label: context.l10n.theme,
                subtitle: context.l10n.lightMode,
                onTap: () {},
              ),
              _SettingItem(
                icon: Icons.notifications_rounded,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: AppColors.info,
                label: context.l10n.notifications,
                subtitle: context.l10n.manageNotifications,
                trailing: _toggle(_notificationsOn,
                    (v) => setState(() => _notificationsOn = v)),
              ),
            ],
          )),
          SliverToBoxAdapter(child: _buildSection(
            context.l10n.supportSection,
            [
              _SettingItem(
                icon: Icons.help_rounded,
                iconBg: const Color(0xFFE3F2FD),
                iconColor: AppColors.info,
                label: 'Help & FAQ',
                subtitle: 'Get help and find answers',
                onTap: () {},
              ),
              _SettingItem(
                icon: Icons.star_rounded,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFF9A825),
                label: 'Rate the App',
                subtitle: 'Share your feedback',
                onTap: () {},
              ),
              _SettingItem(
                icon: Icons.privacy_tip_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: AppColors.secondary,
                label: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {},
              ),
              _SettingItem(
                icon: Icons.info_rounded,
                iconBg: const Color(0xFFE3EEFF),
                iconColor: AppColors.primary,
                label: context.l10n.aboutApp,
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
            ],
          )),
          SliverToBoxAdapter(child: _buildSyncSection(context)),
          SliverToBoxAdapter(child: _buildDisclaimer()),
          SliverToBoxAdapter(child: _buildSignOut(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Sliver header ──────────────────────────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context, ProfileProvider profileProvider) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileHeaderDelegate(
        onSettings: () {},
        user: profileProvider.user,
      ),
    );
  }

  // ── Stats card ─────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context, ProfileProvider profileProvider) {
    final user = profileProvider.user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            _StatCell(user?.documentCount?.toString() ?? '0', context.l10n.documentsVault, AppColors.primary),
            _vDivider(),
            _StatCell(user?.reminderCount?.toString() ?? '0', context.l10n.remindersCount, const Color(0xFFF9A825)),
            _vDivider(),
            _StatCell('12', context.l10n.securityStatus, AppColors.secondary),
            _vDivider(),
            _StatCell('5', context.l10n.services, AppColors.info),
          ],
        ),
      ),
    );
  }

  Widget _StatCell(String val, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Text(val,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8A96A3),
                fontSize: 10.5,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: const Color(0xFFEEF2F8));

  // ── Quick Access ──────────────────────────────────────────────────────────
  Widget _buildQuickAccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Access',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2B4A))),
          const SizedBox(height: 12),
          Row(
            children: [
              _QACard(
                icon: Icons.newspaper_rounded,
                label: 'News',
                iconColor: const Color(0xFF1565C0),
                bgColor: const Color(0xFFF0F5FF),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NewsScreen())),
              ),
              const SizedBox(width: 10),
              _QACard(
                icon: Icons.location_on_rounded,
                label: 'Offices',
                iconColor: AppColors.secondary,
                bgColor: const Color(0xFFF0FAF3),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OfficeLocatorScreen())),
              ),
              const SizedBox(width: 10),
              _QACard(
                icon: Icons.sos_rounded,
                label: 'Emergency',
                iconColor: AppColors.danger,
                bgColor: const Color(0xFFFFF0F0),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EmergencyScreen())),
              ),
              const SizedBox(width: 10),
              _QACard(
                icon: Icons.notifications_rounded,
                label: 'Reminders',
                iconColor: const Color(0xFFF9A825),
                bgColor: const Color(0xFFFFFBF0),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Settings section ───────────────────────────────────────────────────────
  Widget _buildSection(String title, List<_SettingItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B4A))),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Column(children: [
                _buildSettingTile(item),
                if (i < items.length - 1)
                  const Divider(
                      height: 1, indent: 68, color: Color(0xFFF0F4FA)),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildSettingTile(_SettingItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          // Icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          // Label + subtitle
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2B4A))),
              if (item.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(item.subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9AAABB))),
              ],
            ],
          )),
          // Trailing widget or chevron
          item.trailing ??
              (item.onTap != null
                  ? const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCCD5E0), size: 20)
                  : const SizedBox.shrink()),
        ]),
      ),
    );
  }

  Widget _toggle(bool val, ValueChanged<bool> onChanged) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: val,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSyncSection(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final isNepali = Localizations.localeOf(context).languageCode == 'ne';
    final lastSynced = syncProvider.lastSyncedAt != null
        ? syncProvider.lastSyncedAt!
        : (isNepali ? 'अहिलेसम्म भएको छैन' : 'Never');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNepali ? 'क्लाउड सिङ्क र डाटा' : 'Cloud Sync & Data',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2B4A)),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  _SettingItem(
                    icon: Icons.cloud_sync_rounded,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: AppColors.info,
                    label: isNepali ? 'स्वचालित क्लाउड सिङ्क' : 'Auto Cloud Sync',
                    subtitle: isNepali
                        ? 'अन्तिम सिङ्क: $lastSynced'
                        : 'Last synced: $lastSynced',
                    trailing: _toggle(
                      syncProvider.autoSyncEnabled,
                      (val) => syncProvider.toggleAutoSync(val),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 68, color: Color(0xFFF0F4FA)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: syncProvider.isSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, color: AppColors.secondary, size: 20),
                  ),
                  title: Text(
                    isNepali ? 'अहिले सिङ्क गर्नुहोस्' : 'Sync Now',
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2B4A)),
                  ),
                  subtitle: Text(
                    isNepali ? 'सबै परिवर्तनहरू क्लाउडमा पठाउनुहोस्' : 'Push offline changes to cloud',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9AAABB)),
                  ),
                  trailing: TextButton(
                    onPressed: syncProvider.isSyncing
                        ? null
                        : () => syncProvider.performManualSync(),
                    child: Text(
                      isNepali ? 'शुरू गर्नुहोस्' : 'Start',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ─────────────────────────────────────────────────────────────
  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withOpacity(0.15)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(AppStrings.disclaimer,
                  style: TextStyle(
                      color: Color(0xFF5A6A80),
                      fontSize: 11.5,
                      height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Widget _buildSignOut(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: _handleSignOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.danger.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Text(context.l10n.signOut,
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile SliverPersistentHeader delegate ──────────────────────────────────
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onSettings;
  final User? user;
  const _ProfileHeaderDelegate({required this.onSettings, this.user});

  static const double _minH = 80.0;  // collapsed (just enough for status bar + toolbar)
  static const double _maxH = 240.0; // expanded

  @override
  double get minExtent => _minH;
  @override
  double get maxExtent => _maxH;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate old) => user != old.user;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // shrinkOffset goes 0 (expanded) → maxH - minH (fully collapsed)
    final expandRatio =
        1.0 - (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        // ── Temple image — always fills the widget, always visible ──────────
        Positioned.fill(
          child: Image.asset(
            AppAssets.templeBanner,
            fit: BoxFit.cover,
            alignment: const Alignment(0.5, 0.0),
          ),
        ),

        // ── Subtle bottom scrim so text stays readable ──────────────────────
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x00000000), Color(0x66000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // ── Settings gear — always top right ───────────────────────────────
        Positioned(
          top: topPad + 4,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 24),
            onPressed: onSettings,
          ),
        ),

        // ── Profile row — fades in as expanded ─────────────────────────────
        Opacity(
          opacity: expandRatio,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 18 + (1 - expandRatio) * 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipOval(
                          child: user?.avatarUrl != null
                              ? Image.network(
                                  user!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: const Color(0xFFBBDEFB),
                                        child: const Icon(Icons.person_rounded, size:44, color: Color(0xFF1565C0)),
                                      ),
                                )
                              : Container(
                                  color: const Color(0xFFBBDEFB),
                                  child: const Icon(Icons.person_rounded, size:44, color: Color(0xFF1565C0)),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Name / email / verified
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Loading...',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                      color: Colors.black.withOpacity(0.6),
                                      blurRadius: 8),
                                ])),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Text(user?.email ?? '',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    color: Colors.white, size: 13),
                                const SizedBox(width: 4),
                                Text(context.l10n.verifiedCitizen,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700)),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quick Access card ────────────────────────────────────────────────────────
class _QACard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QACard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF8), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: iconColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────
class _SettingItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
}


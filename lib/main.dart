import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_routes.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/api_mode_provider.dart';
import 'core/network/api_client.dart';
import 'core/network/offline_queue.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/language_selection_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/main_screen.dart';
import 'features/documents/screens/documents_screen.dart';
import 'features/news/screens/news_screen.dart';

import 'features/advisors/providers/advisors_provider.dart';
import 'features/advisors/providers/advisor_payment_provider.dart';
import 'features/advisors/screens/advisors_list_screen.dart';
import 'features/advisors/screens/my_consultations_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/documents/providers/documents_provider.dart';
import 'features/news/providers/news_provider.dart';
import 'features/services/providers/services_provider.dart';
import 'features/emergency/providers/emergency_provider.dart';
import 'features/reminders/providers/reminders_provider.dart';
import 'features/ai_assistant/providers/ai_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/office_locator/providers/office_provider.dart';
import 'features/learning/providers/learning_provider.dart';
import 'features/sync/providers/sync_provider.dart';
import 'features/home/providers/home_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(QueuedRequestAdapter());
  await Hive.openBox<QueuedRequest>('offline_queue');

  // Initialize ApiClient
  ApiClient().init();

  // Load persisted locale and api mode BEFORE runApp to avoid flash
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  final apiModeProvider = ApiModeProvider();
  await apiModeProvider.load();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<ApiModeProvider>.value(value: apiModeProvider),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
        ChangeNotifierProvider<AdvisorsProvider>(create: (_) => AdvisorsProvider()),
        ChangeNotifierProvider<AdvisorPaymentProvider>(create: (_) => AdvisorPaymentProvider()),
        ChangeNotifierProvider<DocumentsProvider>(create: (_) => DocumentsProvider()),
        ChangeNotifierProvider<NewsProvider>(create: (_) => NewsProvider()),
        ChangeNotifierProvider<ServicesProvider>(create: (_) => ServicesProvider()),
        ChangeNotifierProvider<EmergencyProvider>(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider<RemindersProvider>(create: (_) => RemindersProvider()),
        ChangeNotifierProvider<AiProvider>(create: (_) => AiProvider()),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider()),
        ChangeNotifierProvider<OfficeProvider>(create: (_) => OfficeProvider()),
        ChangeNotifierProvider<LearningProvider>(create: (_) => LearningProvider()),
        ChangeNotifierProvider<SyncProvider>(create: (_) => SyncProvider()),
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
      ],
      child: const NagarikPlusApp(),
    ),
  );
}

class NagarikPlusApp extends StatelessWidget {
  const NagarikPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return MaterialApp(
          title: 'Nagarik+',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,

          // ── Localization ──────────────────────────────────
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // ─────────────────────────────────────────────────

          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.languageSelection: (_) => const LanguageSelectionScreen(),
            AppRoutes.onboarding: (_) => const OnboardingScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.main: (_) => const MainScreen(),
            AppRoutes.documents: (_) => const DocumentsScreen(),
            AppRoutes.news: (_) => const NewsScreen(),
            AppRoutes.advisors: (_) => const AdvisorsListScreen(),
            AppRoutes.myConsultations: (_) => const MyConsultationsScreen(),
          },
        );
      },
    );
  }
}


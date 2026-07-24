import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Nagarik+'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Secure Documents. Smarter Citizen Services.'**
  String get appTagline;

  /// No description provided for @appDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Nagarik+ is an independent platform and is NOT an official Government of Nepal application.'**
  String get appDisclaimer;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your Nagarik+ account'**
  String get signInToAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signInWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Biometrics'**
  String get signInWithBiometrics;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhone;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get validationPasswordTooShort;

  /// Validation message for required fields
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String validationFieldRequired(String fieldName);

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get validationPhoneInvalid;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @searchForAService.
  ///
  /// In en, this message translates to:
  /// **'Search for a service'**
  String get searchForAService;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewAllArrow.
  ///
  /// In en, this message translates to:
  /// **'View all →'**
  String get viewAllArrow;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @addDocumentNewline.
  ///
  /// In en, this message translates to:
  /// **'Add\nDocument'**
  String get addDocumentNewline;

  /// No description provided for @documentsSection.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsSection;

  /// No description provided for @socialService.
  ///
  /// In en, this message translates to:
  /// **'Social Service'**
  String get socialService;

  /// No description provided for @vitalEventCertificates.
  ///
  /// In en, this message translates to:
  /// **'Vital Event Certificates'**
  String get vitalEventCertificates;

  /// No description provided for @citizenServices.
  ///
  /// In en, this message translates to:
  /// **'Citizen Services'**
  String get citizenServices;

  /// No description provided for @citizenNews.
  ///
  /// In en, this message translates to:
  /// **'Citizen News'**
  String get citizenNews;

  /// No description provided for @officeLocator.
  ///
  /// In en, this message translates to:
  /// **'Office Locator'**
  String get officeLocator;

  /// No description provided for @quickServices.
  ///
  /// In en, this message translates to:
  /// **'Quick Services'**
  String get quickServices;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @drivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get drivingLicense;

  /// No description provided for @panCard.
  ///
  /// In en, this message translates to:
  /// **'PAN'**
  String get panCard;

  /// No description provided for @citizenship.
  ///
  /// In en, this message translates to:
  /// **'Citizenship'**
  String get citizenship;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @voterId.
  ///
  /// In en, this message translates to:
  /// **'Voter ID'**
  String get voterId;

  /// No description provided for @birthCertificate.
  ///
  /// In en, this message translates to:
  /// **'Birth\nCertificate'**
  String get birthCertificate;

  /// No description provided for @marriageCertificate.
  ///
  /// In en, this message translates to:
  /// **'Marriage\nCertificate'**
  String get marriageCertificate;

  /// No description provided for @deathCertificate.
  ///
  /// In en, this message translates to:
  /// **'Death\nCertificate'**
  String get deathCertificate;

  /// No description provided for @migrationCertificate.
  ///
  /// In en, this message translates to:
  /// **'Migration\nCertificate'**
  String get migrationCertificate;

  /// No description provided for @cit.
  ///
  /// In en, this message translates to:
  /// **'CIT'**
  String get cit;

  /// No description provided for @citSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay taxes easily'**
  String get citSubtitle;

  /// No description provided for @providentFund.
  ///
  /// In en, this message translates to:
  /// **'Provident Fund'**
  String get providentFund;

  /// No description provided for @providentFundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Self information service'**
  String get providentFundSubtitle;

  /// No description provided for @ssf.
  ///
  /// In en, this message translates to:
  /// **'SSF'**
  String get ssf;

  /// No description provided for @ssfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Social Security Fund'**
  String get ssfSubtitle;

  /// No description provided for @bannerPoliceTitle.
  ///
  /// In en, this message translates to:
  /// **'File Police Reports\nEasily via Citizen App.'**
  String get bannerPoliceTitle;

  /// No description provided for @bannerPoliceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anywhere, anytime — secure, fast and reliable.'**
  String get bannerPoliceSubtitle;

  /// No description provided for @bannerLockerTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep documents safe\nin your Digital Locker.'**
  String get bannerLockerTitle;

  /// No description provided for @bannerLockerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store all your documents in one place.'**
  String get bannerLockerSubtitle;

  /// No description provided for @bannerServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Services\nAll in One Place.'**
  String get bannerServicesTitle;

  /// No description provided for @bannerServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Passport, PAN, Citizenship — all from the app.'**
  String get bannerServicesSubtitle;

  /// No description provided for @bannerChipSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get bannerChipSecure;

  /// No description provided for @bannerChipFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get bannerChipFast;

  /// No description provided for @bannerChipEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get bannerChipEasy;

  /// No description provided for @bannerChipEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get bannerChipEncrypted;

  /// No description provided for @bannerChipCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get bannerChipCloud;

  /// No description provided for @bannerChipVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get bannerChipVerified;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get errorPermission;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Onboarding slide 1 title
  ///
  /// In en, this message translates to:
  /// **'Secure Digital Locker'**
  String get onboardingTitle1;

  /// Onboarding slide 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Store all your important documents safely with AES-256 encryption and biometric protection.'**
  String get onboardingSubtitle1;

  /// Onboarding slide 2 title
  ///
  /// In en, this message translates to:
  /// **'Citizen Service Guides'**
  String get onboardingTitle2;

  /// Onboarding slide 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Step-by-step guides for passport, PAN, National ID, driving license, and more government services.'**
  String get onboardingSubtitle2;

  /// Onboarding slide 3 title
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Assistant'**
  String get onboardingTitle3;

  /// Onboarding slide 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Ask questions about any government service and get instant, accurate answers in Nepali or English.'**
  String get onboardingSubtitle3;

  /// Onboarding slide 4 title
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get onboardingTitle4;

  /// Onboarding slide 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Never miss a document expiry. Get reminders for passport, license, insurance, and more.'**
  String get onboardingSubtitle4;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get askMeAnything;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @police.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// No description provided for @ambulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get ambulance;

  /// No description provided for @fireService.
  ///
  /// In en, this message translates to:
  /// **'Fire Service'**
  String get fireService;

  /// No description provided for @disasterManagement.
  ///
  /// In en, this message translates to:
  /// **'Disaster Management'**
  String get disasterManagement;

  /// No description provided for @nearbyOffices.
  ///
  /// In en, this message translates to:
  /// **'Nearby Offices'**
  String get nearbyOffices;

  /// No description provided for @publicNotices.
  ///
  /// In en, this message translates to:
  /// **'Public Notices'**
  String get publicNotices;

  /// No description provided for @learningCenter.
  ///
  /// In en, this message translates to:
  /// **'Learning Center'**
  String get learningCenter;

  /// No description provided for @drivingTest.
  ///
  /// In en, this message translates to:
  /// **'Driving License Test'**
  String get drivingTest;

  /// No description provided for @mockTests.
  ///
  /// In en, this message translates to:
  /// **'Mock Tests'**
  String get mockTests;

  /// No description provided for @practiceQuestions.
  ///
  /// In en, this message translates to:
  /// **'Practice Questions'**
  String get practiceQuestions;

  /// No description provided for @roadSigns.
  ///
  /// In en, this message translates to:
  /// **'Road Signs'**
  String get roadSigns;

  /// No description provided for @trafficRules.
  ///
  /// In en, this message translates to:
  /// **'Traffic Rules'**
  String get trafficRules;

  /// No description provided for @videoTutorials.
  ///
  /// In en, this message translates to:
  /// **'Video Tutorials'**
  String get videoTutorials;

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get startTest;

  /// No description provided for @viewResults.
  ///
  /// In en, this message translates to:
  /// **'View Results'**
  String get viewResults;

  /// No description provided for @scanDocument.
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scanDocument;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Scanner'**
  String get scannerTitle;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @usePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use Photo'**
  String get usePhoto;

  /// No description provided for @saveDocument.
  ///
  /// In en, this message translates to:
  /// **'Save Document'**
  String get saveDocument;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'NagarikShare'**
  String get shareTitle;

  /// No description provided for @sendFiles.
  ///
  /// In en, this message translates to:
  /// **'Send Files'**
  String get sendFiles;

  /// No description provided for @receiveFiles.
  ///
  /// In en, this message translates to:
  /// **'Receive Files'**
  String get receiveFiles;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @transferring.
  ///
  /// In en, this message translates to:
  /// **'Transferring...'**
  String get transferring;

  /// No description provided for @transferComplete.
  ///
  /// In en, this message translates to:
  /// **'Transfer Complete'**
  String get transferComplete;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @securityPin.
  ///
  /// In en, this message translates to:
  /// **'Security PIN'**
  String get securityPin;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get languageNepali;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get noReminders;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get reminderTitle;

  /// No description provided for @reminderDate.
  ///
  /// In en, this message translates to:
  /// **'Reminder Date'**
  String get reminderDate;

  /// No description provided for @tutorials.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get tutorials;

  /// No description provided for @digitalLocker.
  ///
  /// In en, this message translates to:
  /// **'Digital Locker'**
  String get digitalLocker;

  /// No description provided for @findNearbyOffices.
  ///
  /// In en, this message translates to:
  /// **'Find Nearby Offices'**
  String get findNearbyOffices;

  /// No description provided for @officeLocatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Passport, Transport, Tax & more'**
  String get officeLocatorSubtitle;

  /// No description provided for @aesEncrypted.
  ///
  /// In en, this message translates to:
  /// **'AES-256 Encrypted'**
  String get aesEncrypted;

  /// No description provided for @allDocsSecured.
  ///
  /// In en, this message translates to:
  /// **'All your documents are securely encrypted'**
  String get allDocsSecured;

  /// No description provided for @secureTag.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secureTag;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @categoryIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get categoryIdentity;

  /// No description provided for @categoryVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get categoryVehicle;

  /// No description provided for @categoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// No description provided for @categoryProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get categoryProperty;

  /// No description provided for @categoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get categoryMedical;

  /// No description provided for @categoryAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get categoryAcademic;

  /// No description provided for @categoryDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get categoryDriving;

  /// No description provided for @categoryLoksewa.
  ///
  /// In en, this message translates to:
  /// **'Loksewa'**
  String get categoryLoksewa;

  /// No description provided for @categoryRights.
  ///
  /// In en, this message translates to:
  /// **'Rights'**
  String get categoryRights;

  /// No description provided for @notUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded yet'**
  String get notUploadedYet;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @expiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiring;

  /// No description provided for @vehicleBluebook.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Bluebook'**
  String get vehicleBluebook;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @learnCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Master citizen services & prepare for tests'**
  String get learnCenterSubtitle;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @coursesAndGuides.
  ///
  /// In en, this message translates to:
  /// **'Courses & Guides'**
  String get coursesAndGuides;

  /// No description provided for @mockTestsAndQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Mock Tests & Quizzes'**
  String get mockTestsAndQuizzes;

  /// No description provided for @verifiedCitizen.
  ///
  /// In en, this message translates to:
  /// **'Verified Citizen'**
  String get verifiedCitizen;

  /// No description provided for @documentsVault.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsVault;

  /// No description provided for @remindersCount.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersCount;

  /// No description provided for @securityStatus.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityStatus;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @securityAndPin.
  ///
  /// In en, this message translates to:
  /// **'Security & PIN'**
  String get securityAndPin;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN and security settings'**
  String get securitySubtitle;

  /// No description provided for @biometricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage biometric authentication'**
  String get biometricsSubtitle;

  /// No description provided for @personalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal details'**
  String get personalInfoSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @manageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage notification settings'**
  String get manageNotifications;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get searchServices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

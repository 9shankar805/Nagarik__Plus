// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nagarik+';

  @override
  String get appTagline => 'Secure Documents. Smarter Citizen Services.';

  @override
  String get appDisclaimer =>
      'Nagarik+ is an independent platform and is NOT an official Government of Nepal application.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signOut => 'Sign Out';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToAccount => 'Sign in to your Nagarik+ account';

  @override
  String get createAccount => 'Create Account';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signInWithBiometrics => 'Sign in with Biometrics';

  @override
  String get orDivider => 'OR';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterYourPhone => 'Enter your phone number';

  @override
  String get validationEmailRequired => 'Please enter your email';

  @override
  String get validationEmailInvalid => 'Enter a valid email';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get validationPasswordTooShort => 'Minimum 6 characters';

  @override
  String validationFieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationPhoneInvalid => 'Enter a valid phone number';

  @override
  String get home => 'Home';

  @override
  String get documents => 'Documents';

  @override
  String get services => 'Services';

  @override
  String get learn => 'Learn';

  @override
  String get more => 'More';

  @override
  String get searchForAService => 'Search for a service';

  @override
  String get viewAll => 'View All';

  @override
  String get viewAllArrow => 'View all →';

  @override
  String get addDocument => 'Add Document';

  @override
  String get addDocumentNewline => 'Add\nDocument';

  @override
  String get documentsSection => 'Documents';

  @override
  String get socialService => 'Social Service';

  @override
  String get vitalEventCertificates => 'Vital Event Certificates';

  @override
  String get citizenServices => 'Citizen Services';

  @override
  String get citizenNews => 'Citizen News';

  @override
  String get officeLocator => 'Office Locator';

  @override
  String get quickServices => 'Quick Services';

  @override
  String get nationalId => 'National ID';

  @override
  String get drivingLicense => 'Driving License';

  @override
  String get panCard => 'PAN';

  @override
  String get citizenship => 'Citizenship';

  @override
  String get passport => 'Passport';

  @override
  String get voterId => 'Voter ID';

  @override
  String get birthCertificate => 'Birth\nCertificate';

  @override
  String get marriageCertificate => 'Marriage\nCertificate';

  @override
  String get deathCertificate => 'Death\nCertificate';

  @override
  String get migrationCertificate => 'Migration\nCertificate';

  @override
  String get cit => 'CIT';

  @override
  String get citSubtitle => 'Pay taxes easily';

  @override
  String get providentFund => 'Provident Fund';

  @override
  String get providentFundSubtitle => 'Self information service';

  @override
  String get ssf => 'SSF';

  @override
  String get ssfSubtitle => 'Social Security Fund';

  @override
  String get bannerPoliceTitle =>
      'File Police Reports\nEasily via Citizen App.';

  @override
  String get bannerPoliceSubtitle =>
      'Anywhere, anytime — secure, fast and reliable.';

  @override
  String get bannerLockerTitle =>
      'Keep documents safe\nin your Digital Locker.';

  @override
  String get bannerLockerSubtitle => 'Store all your documents in one place.';

  @override
  String get bannerServicesTitle => 'Government Services\nAll in One Place.';

  @override
  String get bannerServicesSubtitle =>
      'Passport, PAN, Citizenship — all from the app.';

  @override
  String get bannerChipSecure => 'Secure';

  @override
  String get bannerChipFast => 'Fast';

  @override
  String get bannerChipEasy => 'Easy';

  @override
  String get bannerChipEncrypted => 'Encrypted';

  @override
  String get bannerChipCloud => 'Cloud';

  @override
  String get bannerChipVerified => 'Verified';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get security => 'Security';

  @override
  String get privacy => 'Privacy';

  @override
  String get aboutApp => 'About App';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorPermission => 'Permission denied';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get continueText => 'Continue';

  @override
  String get onboardingTitle1 => 'Secure Digital Locker';

  @override
  String get onboardingSubtitle1 =>
      'Store all your important documents safely with AES-256 encryption and biometric protection.';

  @override
  String get onboardingTitle2 => 'Citizen Service Guides';

  @override
  String get onboardingSubtitle2 =>
      'Step-by-step guides for passport, PAN, National ID, driving license, and more government services.';

  @override
  String get onboardingTitle3 => 'AI-Powered Assistant';

  @override
  String get onboardingSubtitle3 =>
      'Ask questions about any government service and get instant, accurate answers in Nepali or English.';

  @override
  String get onboardingTitle4 => 'Smart Reminders';

  @override
  String get onboardingSubtitle4 =>
      'Never miss a document expiry. Get reminders for passport, license, insurance, and more.';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get askMeAnything => 'Ask me anything...';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get police => 'Police';

  @override
  String get ambulance => 'Ambulance';

  @override
  String get fireService => 'Fire Service';

  @override
  String get disasterManagement => 'Disaster Management';

  @override
  String get nearbyOffices => 'Nearby Offices';

  @override
  String get publicNotices => 'Public Notices';

  @override
  String get learningCenter => 'Learning Center';

  @override
  String get drivingTest => 'Driving License Test';

  @override
  String get mockTests => 'Mock Tests';

  @override
  String get practiceQuestions => 'Practice Questions';

  @override
  String get roadSigns => 'Road Signs';

  @override
  String get trafficRules => 'Traffic Rules';

  @override
  String get videoTutorials => 'Video Tutorials';

  @override
  String get startTest => 'Start Test';

  @override
  String get viewResults => 'View Results';

  @override
  String get scanDocument => 'Scan Document';

  @override
  String get scannerTitle => 'Document Scanner';

  @override
  String get retake => 'Retake';

  @override
  String get usePhoto => 'Use Photo';

  @override
  String get saveDocument => 'Save Document';

  @override
  String get shareTitle => 'NagarikShare';

  @override
  String get sendFiles => 'Send Files';

  @override
  String get receiveFiles => 'Receive Files';

  @override
  String get selectFiles => 'Select Files';

  @override
  String get connecting => 'Connecting...';

  @override
  String get transferring => 'Transferring...';

  @override
  String get transferComplete => 'Transfer Complete';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myProfile => 'My Profile';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get changePassword => 'Change Password';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get securityPin => 'Security PIN';

  @override
  String get setPin => 'Set PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get reminders => 'Reminders';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get noReminders => 'No reminders yet';

  @override
  String get reminderTitle => 'Reminder Title';

  @override
  String get reminderDate => 'Reminder Date';

  @override
  String get tutorials => 'Tutorials';

  @override
  String get digitalLocker => 'Digital Locker';

  @override
  String get findNearbyOffices => 'Find Nearby Offices';

  @override
  String get officeLocatorSubtitle => 'Passport, Transport, Tax & more';

  @override
  String get aesEncrypted => 'AES-256 Encrypted';

  @override
  String get allDocsSecured => 'All your documents are securely encrypted';

  @override
  String get secureTag => 'Secure';

  @override
  String get all => 'All';

  @override
  String get categoryIdentity => 'Identity';

  @override
  String get categoryVehicle => 'Vehicle';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categoryProperty => 'Property';

  @override
  String get categoryMedical => 'Medical';

  @override
  String get categoryAcademic => 'Academic';

  @override
  String get categoryDriving => 'Driving';

  @override
  String get categoryLoksewa => 'Loksewa';

  @override
  String get categoryRights => 'Rights';

  @override
  String get notUploadedYet => 'Not uploaded yet';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get missing => 'Missing';

  @override
  String get expiring => 'Expiring';

  @override
  String get vehicleBluebook => 'Vehicle Bluebook';

  @override
  String get insurance => 'Insurance';

  @override
  String get learnCenterSubtitle =>
      'Master citizen services & prepare for tests';

  @override
  String get questions => 'Questions';

  @override
  String get subjects => 'Subjects';

  @override
  String get coursesAndGuides => 'Courses & Guides';

  @override
  String get mockTestsAndQuizzes => 'Mock Tests & Quizzes';

  @override
  String get verifiedCitizen => 'Verified Citizen';

  @override
  String get documentsVault => 'Documents';

  @override
  String get remindersCount => 'Reminders';

  @override
  String get securityStatus => 'Security';

  @override
  String get accountSection => 'Account';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get supportSection => 'Support';

  @override
  String get securityAndPin => 'Security & PIN';

  @override
  String get securitySubtitle => 'Change PIN and security settings';

  @override
  String get biometricsSubtitle => 'Manage biometric authentication';

  @override
  String get personalInfoSubtitle => 'Manage your personal details';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get manageNotifications => 'Manage notification settings';

  @override
  String get searchServices => 'Search services...';
}

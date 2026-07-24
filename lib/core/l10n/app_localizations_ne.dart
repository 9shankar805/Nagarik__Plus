// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appName => 'नागरिक+';

  @override
  String get appTagline => 'सुरक्षित कागजात। स्मार्ट नागरिक सेवाहरू।';

  @override
  String get appDisclaimer =>
      'नागरिक+ एक स्वतन्त्र प्लेटफर्म हो र यो नेपाल सरकारको आधिकारिक एप्लिकेसन होइन।';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signUp => 'साइन अप';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get welcomeBack => 'फेरि स्वागत छ';

  @override
  String get signInToAccount => 'आफ्नो नागरिक+ खातामा साइन इन गर्नुहोस्';

  @override
  String get createAccount => 'खाता बनाउनुहोस्';

  @override
  String get dontHaveAccount => 'खाता छैन?';

  @override
  String get alreadyHaveAccount => 'पहिले नै खाता छ?';

  @override
  String get forgotPassword => 'पासवर्ड बिर्सनुभयो?';

  @override
  String get signInWithBiometrics => 'बायोमेट्रिक्सबाट साइन इन';

  @override
  String get orDivider => 'वा';

  @override
  String get emailAddress => 'इमेल ठेगाना';

  @override
  String get enterYourEmail => 'आफ्नो इमेल लेख्नुहोस्';

  @override
  String get password => 'पासवर्ड';

  @override
  String get enterYourPassword => 'आफ्नो पासवर्ड लेख्नुहोस्';

  @override
  String get confirmPassword => 'पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get enterYourFullName => 'आफ्नो पूरा नाम लेख्नुहोस्';

  @override
  String get phoneNumber => 'फोन नम्बर';

  @override
  String get enterYourPhone => 'आफ्नो फोन नम्बर लेख्नुहोस्';

  @override
  String get validationEmailRequired => 'कृपया आफ्नो इमेल लेख्नुहोस्';

  @override
  String get validationEmailInvalid => 'मान्य इमेल लेख्नुहोस्';

  @override
  String get validationPasswordRequired => 'कृपया आफ्नो पासवर्ड लेख्नुहोस्';

  @override
  String get validationPasswordTooShort => 'कम्तिमा ६ अक्षर चाहिन्छ';

  @override
  String validationFieldRequired(String fieldName) {
    return '$fieldName आवश्यक छ';
  }

  @override
  String get validationPasswordMismatch => 'पासवर्डहरू मेल खाँदैनन्';

  @override
  String get validationPhoneInvalid => 'मान्य फोन नम्बर लेख्नुहोस्';

  @override
  String get home => 'गृहपृष्ठ';

  @override
  String get documents => 'कागजातहरू';

  @override
  String get services => 'सेवाहरू';

  @override
  String get learn => 'सिक्नुस्';

  @override
  String get more => 'थप';

  @override
  String get searchForAService => 'सेवा खोज्नुस्';

  @override
  String get viewAll => 'सबै हेर्नुस्';

  @override
  String get viewAllArrow => 'सबै हेर्नुस् →';

  @override
  String get addDocument => 'कागजात थप्नुस्';

  @override
  String get addDocumentNewline => 'कागजात\nथप्नुस्';

  @override
  String get documentsSection => 'कागजातहरू';

  @override
  String get socialService => 'सामाजिक सेवा';

  @override
  String get vitalEventCertificates => 'महत्त्वपूर्ण घटना प्रमाणपत्रहरू';

  @override
  String get citizenServices => 'नागरिक सेवाहरू';

  @override
  String get citizenNews => 'नागरिक समाचार';

  @override
  String get officeLocator => 'कार्यालय खोज्नुस्';

  @override
  String get quickServices => 'द्रुत सेवाहरू';

  @override
  String get nationalId => 'राष्ट्रिय परिचयपत्र';

  @override
  String get drivingLicense => 'सवारी चालक अनुमतिपत्र';

  @override
  String get panCard => 'प्यान';

  @override
  String get citizenship => 'नागरिकता';

  @override
  String get passport => 'राहदानी';

  @override
  String get voterId => 'मतदाता परिचयपत्र';

  @override
  String get birthCertificate => 'जन्म\nदर्ता';

  @override
  String get marriageCertificate => 'विवाह\nदर्ता';

  @override
  String get deathCertificate => 'मृत्यु\nदर्ता';

  @override
  String get migrationCertificate => 'बसाइसराइ\nदर्ता';

  @override
  String get cit => 'सीआईटी';

  @override
  String get citSubtitle => 'कर तिर्नुस् सजिलै';

  @override
  String get providentFund => 'कर्मचारी सञ्चय कोष';

  @override
  String get providentFundSubtitle => 'स्वयं जानकारी सेवा';

  @override
  String get ssf => 'एसएसएफ';

  @override
  String get ssfSubtitle => 'सामाजिक सुरक्षा कोष';

  @override
  String get bannerPoliceTitle => 'प्रहरी रिपोर्ट अब\nनागरिक एपबाट सजिलै।';

  @override
  String get bannerPoliceSubtitle =>
      'जहाँ पनि, जतिबेला पनि – सुरक्षित, छिटो र भरपर्दो।';

  @override
  String get bannerLockerTitle => 'डिजिटल लकरमा\nसुरक्षित राख्नुस्।';

  @override
  String get bannerLockerSubtitle => 'आफ्ना सबै कागजात एकै ठाउँमा राख्नुस्।';

  @override
  String get bannerServicesTitle => 'सरकारी सेवाहरू\nएकै ठाउँमा।';

  @override
  String get bannerServicesSubtitle =>
      'पासपोर्ट, PAN, नागरिकता – सबै सेवा एपबाटै।';

  @override
  String get bannerChipSecure => 'सुरक्षित';

  @override
  String get bannerChipFast => 'छिटो';

  @override
  String get bannerChipEasy => 'सजिलो';

  @override
  String get bannerChipEncrypted => 'एन्क्रिप्टेड';

  @override
  String get bannerChipCloud => 'क्लाउड';

  @override
  String get bannerChipVerified => 'प्रमाणित';

  @override
  String get settings => 'सेटिङ';

  @override
  String get language => 'भाषा';

  @override
  String get notifications => 'सूचनाहरू';

  @override
  String get security => 'सुरक्षा';

  @override
  String get privacy => 'गोपनीयता';

  @override
  String get aboutApp => 'एपको बारेमा';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get ok => 'ठीक छ';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get save => 'सुरक्षित गर्नुहोस्';

  @override
  String get delete => 'मेट्नुहोस्';

  @override
  String get edit => 'सम्पादन';

  @override
  String get share => 'साझा गर्नुहोस्';

  @override
  String get download => 'डाउनलोड';

  @override
  String get upload => 'अपलोड';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get loading => 'लोड हुँदैछ...';

  @override
  String get noData => 'डेटा उपलब्ध छैन';

  @override
  String get errorGeneric => 'केही गडबड भयो';

  @override
  String get errorNetwork => 'नेटवर्क त्रुटि। कृपया आफ्नो जडान जाँच गर्नुहोस्।';

  @override
  String get errorPermission => 'अनुमति अस्वीकार';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get confirm => 'पुष्टि गर्नुहोस्';

  @override
  String get next => 'अर्को';

  @override
  String get back => 'पछाडि';

  @override
  String get skip => 'छोड्नुहोस्';

  @override
  String get getStarted => 'सुरु गर्नुहोस्';

  @override
  String get continueText => 'जारी राख्नुहोस्';

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
  String get aiAssistant => 'एआई सहायक';

  @override
  String get typeYourMessage => 'आफ्नो सन्देश लेख्नुहोस्...';

  @override
  String get askMeAnything => 'केही पनि सोध्नुस्...';

  @override
  String get emergencyContacts => 'आपतकालीन सम्पर्कहरू';

  @override
  String get police => 'प्रहरी';

  @override
  String get ambulance => 'एम्बुलेन्स';

  @override
  String get fireService => 'दमकल सेवा';

  @override
  String get disasterManagement => 'विपद् व्यवस्थापन';

  @override
  String get nearbyOffices => 'नजिकका कार्यालयहरू';

  @override
  String get publicNotices => 'सार्वजनिक सूचनाहरू';

  @override
  String get learningCenter => 'सिकाइ केन्द्र';

  @override
  String get drivingTest => 'सवारी अनुमतिपत्र परीक्षा';

  @override
  String get mockTests => 'अभ्यास परीक्षाहरू';

  @override
  String get practiceQuestions => 'अभ्यास प्रश्नहरू';

  @override
  String get roadSigns => 'सडक संकेतहरू';

  @override
  String get trafficRules => 'यातायात नियमहरू';

  @override
  String get videoTutorials => 'भिडियो ट्युटोरियलहरू';

  @override
  String get startTest => 'परीक्षा सुरु गर्नुहोस्';

  @override
  String get viewResults => 'नतिजा हेर्नुस्';

  @override
  String get scanDocument => 'कागजात स्क्यान';

  @override
  String get scannerTitle => 'कागजात स्क्यानर';

  @override
  String get retake => 'फेरि खिच्नुहोस्';

  @override
  String get usePhoto => 'फोटो प्रयोग गर्नुहोस्';

  @override
  String get saveDocument => 'कागजात सुरक्षित गर्नुहोस्';

  @override
  String get shareTitle => 'नागरिकशेयर';

  @override
  String get sendFiles => 'फाइल पठाउनुस्';

  @override
  String get receiveFiles => 'फाइल प्राप्त गर्नुस्';

  @override
  String get selectFiles => 'फाइल छान्नुस्';

  @override
  String get connecting => 'जोड्दैछ...';

  @override
  String get transferring => 'स्थानान्तरण हुँदैछ...';

  @override
  String get transferComplete => 'स्थानान्तरण सम्पन्न';

  @override
  String get profileTitle => 'प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल सम्पादन';

  @override
  String get myProfile => 'मेरो प्रोफाइल';

  @override
  String get personalInformation => 'व्यक्तिगत जानकारी';

  @override
  String get changePassword => 'पासवर्ड परिवर्तन';

  @override
  String get biometricLogin => 'बायोमेट्रिक लगइन';

  @override
  String get securityPin => 'सुरक्षा पिन';

  @override
  String get setPin => 'पिन सेट गर्नुहोस्';

  @override
  String get enterPin => 'पिन लेख्नुहोस्';

  @override
  String get confirmPin => 'पिन पुष्टि गर्नुहोस्';

  @override
  String get selectLanguage => 'भाषा छान्नुस्';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get languageChanged => 'भाषा सफलतापूर्वक परिवर्तन भयो';

  @override
  String get reminders => 'रिमाइन्डरहरू';

  @override
  String get addReminder => 'रिमाइन्डर थप्नुस्';

  @override
  String get noReminders => 'अहिले कुनै रिमाइन्डर छैन';

  @override
  String get reminderTitle => 'रिमाइन्डर शीर्षक';

  @override
  String get reminderDate => 'रिमाइन्डर मिति';

  @override
  String get tutorials => 'ट्युटोरियलहरू';

  @override
  String get digitalLocker => 'डिजिटल लकर';

  @override
  String get findNearbyOffices => 'नजिकका कार्यालयहरू खोज्नुहोस्';

  @override
  String get officeLocatorSubtitle => 'राहदानी, यातायात, कर र अन्य';

  @override
  String get aesEncrypted => 'AES-256 एन्क्रिप्टेड';

  @override
  String get allDocsSecured =>
      'तपाईंका सबै कागजातहरू सुरक्षित रूपमा एन्क्रिप्ट गरिएका छन्';

  @override
  String get secureTag => 'सुरक्षित';

  @override
  String get all => 'सबै';

  @override
  String get categoryIdentity => 'पहचान';

  @override
  String get categoryVehicle => 'सवारी';

  @override
  String get categoryFinance => 'वित्त';

  @override
  String get categoryProperty => 'सम्पत्ति';

  @override
  String get categoryMedical => 'स्वास्थ्य';

  @override
  String get categoryAcademic => 'शैक्षिक';

  @override
  String get categoryDriving => 'ड्राइभिङ';

  @override
  String get categoryLoksewa => 'लोकसेवा';

  @override
  String get categoryRights => 'अधिकार';

  @override
  String get notUploadedYet => 'अझै अपलोड गरिएको छैन';

  @override
  String get uploaded => 'अपलोड गरियो';

  @override
  String get missing => 'छुट्यो';

  @override
  String get expiring => 'म्याद समाप्त हुँदैछ';

  @override
  String get vehicleBluebook => 'सवारी बिलबुक';

  @override
  String get insurance => 'बीमा';

  @override
  String get learnCenterSubtitle =>
      'नागरिक सेवाहरू र परीक्षाको तयारी गर्नुहोस्';

  @override
  String get questions => 'प्रश्नहरू';

  @override
  String get subjects => 'विषयहरू';

  @override
  String get coursesAndGuides => 'पाठ्यक्रम र निर्देशिका';

  @override
  String get mockTestsAndQuizzes => 'नमूना परीक्षा र क्विज';

  @override
  String get verifiedCitizen => 'प्रमाणित नागरिक';

  @override
  String get documentsVault => 'कागजातहरू';

  @override
  String get remindersCount => 'रिमाइन्डरहरू';

  @override
  String get securityStatus => 'सुरक्षा';

  @override
  String get accountSection => 'खाता';

  @override
  String get preferencesSection => 'प्राथमिकताहरू';

  @override
  String get supportSection => 'सहयोग र बारे';

  @override
  String get securityAndPin => 'सुरक्षा र पिन';

  @override
  String get securitySubtitle => 'पिन र सुरक्षा सेटिङहरू परिवर्तन गर्नुहोस्';

  @override
  String get biometricsSubtitle =>
      'बायोमेट्रिक प्रमाणिकरण व्यवस्थापन गर्नुहोस्';

  @override
  String get personalInfoSubtitle => 'व्यक्तिगत विवरणहरू व्यवस्थापन गर्नुहोस्';

  @override
  String get theme => 'थिम';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get manageNotifications => 'सूचना सेटिङहरू व्यवस्थापन गर्नुहोस्';

  @override
  String get searchServices => 'सेवाहरू खोज्नुहोस्...';
}

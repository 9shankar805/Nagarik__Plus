class AppAssets {
  // Icons
  static const String appIcon  = 'assets/icons/app-icon.png';
  static const String splash   = 'assets/icons/splash.png';
  static const String scanIcon = 'assets/icons/scan.png';
  static const String shareitIcon = 'assets/icons/shareit.png';

  // Document images (used in document cards & home grid)
  static const String nationalId    = 'assets/images/nid1752476653129.png';
  static const String passport      = 'assets/images/passport1752476337775.png';
  static const String drivingLicense= 'assets/images/license1752476621950.png';
  static const String cit           = 'assets/images/cit1759940267390.png';
  static const String ssf           = 'assets/images/SSF1752476396810.png';
  static const String nea           = 'assets/images/nea1752476414169.png';
  static const String pcr           = 'assets/images/pcr1752476863055.png';
  static const String cims          = 'assets/images/cims1752476325868.png';
  static const String dolma         = 'assets/images/dolma1752476593369.png';
  static const String gunaso        = 'assets/images/gunaso1752476491251.png';
  static const String patrakar      = 'assets/images/patrakar1752477622244.png';
  static const String slc           = 'assets/images/slc1631011325238.jpg';
  static const String pan           = 'assets/images/pan.png';
  static const String voterId       = 'assets/images/voterid.png';

  // Vital event certificates
  static const String birthCert     = 'assets/images/birthcertificate.png';
  static const String marriageCert  = 'assets/images/marriagecertificate.png';
  static const String deathCert     = 'assets/images/deathcertificate.png';
  static const String migrationCert = 'assets/images/migrationcertificate.png';

  // Banner images (home screen hero carousel)
  static const String banner1 = 'assets/Banner/first.jpeg';
  static const String banner2 = 'assets/Banner/second.jpeg';
  static const String banner3 = 'assets/Banner/third.jpeg';
  static const String banner4 = 'assets/Banner/fourth.jpeg';
  static const String banner5 = 'assets/Banner/fifth.jpeg';
  static const String templeBanner = 'assets/Banner/temple.jpeg';

  // Background images
  static const String loginBg       = 'assets/bgimages/loginbg.jpeg';
  static const String onboardingBg1 = 'assets/bgimages/first.png';
  static const String onboardingBg2 = 'assets/bgimages/second.png';
  static const String onboardingBg3 = 'assets/bgimages/third.jpeg';
  static const String onboardingBg4 = 'assets/bgimages/fourth.jpeg';

  // Map document type to image
  static String? forDocType(String type) {
    switch (type) {
      case 'national_id':      return nationalId;
      case 'passport':         return passport;
      case 'driving_license':  return drivingLicense;
      case 'pan':              return pan;
      case 'citizenship':      return cims;
      case 'voter_id':         return voterId;
      case 'cit':              return cit;
      case 'ssf':              return ssf;
      default:                 return null;
    }
  }
}

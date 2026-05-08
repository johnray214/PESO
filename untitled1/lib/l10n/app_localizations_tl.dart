// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class STl extends S {
  STl([String locale = 'tl']) : super(locale);

  @override
  String get appName => 'Kabsat Empoy';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Mapa';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingMorning => 'Magandang Umaga';

  @override
  String get greetingAfternoon => 'Magandang Hapon';

  @override
  String get greetingEvening => 'Magandang Gabi';

  @override
  String jobsFound(int count) {
    return '$count Trabaho ang Nahanap';
  }

  @override
  String jobsFoundFiltered(int filtered, int total) {
    return '$filtered sa $total Trabaho ang Nahanap';
  }

  @override
  String get searchJobsHint => 'Maghanap ng trabaho, kompanya...';

  @override
  String get homeFindJobTitle => 'Maghanap ng trabaho';

  @override
  String get noJobsFound => 'Walang nahanap na trabaho';

  @override
  String get tryAdjustingFilters =>
      'Subukang baguhin ang iyong paghahanap o mga filter';

  @override
  String get loadMoreJobs => 'Naglo-load pa ng trabaho...';

  @override
  String get sortBy => 'Ayusin ayon sa';

  @override
  String get sortLatest => 'Pinakabago';

  @override
  String get sortOldest => 'Pinakaluma';

  @override
  String get sortBestMatch => 'Pinakabagay';

  @override
  String get filterEmploymentType => 'Uri ng Trabaho';

  @override
  String get filterSkills => 'Mga Kasanayan';

  @override
  String get filterClearAll => 'Burahin Lahat';

  @override
  String get filterApply => 'Gamitin ang Filters';

  @override
  String get filterReset => 'I-reset';

  @override
  String get searchSkillsHint => 'Maghanap ng kasanayan...';

  @override
  String get fullTime => 'Full-time';

  @override
  String get partTime => 'Part-time';

  @override
  String get contract => 'Kontrata';

  @override
  String get freelance => 'Freelance';

  @override
  String get internship => 'OJT / Internship';

  @override
  String get apply => 'Mag-apply';

  @override
  String get applyNow => 'Mag-apply Ngayon';

  @override
  String get applied => 'Nag-apply na';

  @override
  String get viewDetails => 'Tingnan ang Detalye';

  @override
  String get location => 'Lokasyon';

  @override
  String get salary => 'Sahod';

  @override
  String get employmentType => 'Uri ng Trabaho';

  @override
  String get experience => 'Karanasan';

  @override
  String get education => 'Edukasyon';

  @override
  String get skills => 'Mga Kasanayan';

  @override
  String get description => 'Deskripsyon';

  @override
  String get requirements => 'Mga Kinakailangan';

  @override
  String get jobDetailsTitle => 'Detalye ng Trabaho';

  @override
  String get aboutThisRoleTitle => 'Tungkol sa Role na Ito';

  @override
  String get skillsRequiredTitle => 'Mga Kailangang Kasanayan';

  @override
  String get companyAbout => 'Tungkol sa Kompanya';

  @override
  String get companyJobs => 'Mga Bakanteng Posisyon';

  @override
  String get viewOnMap => 'Tingnan sa Mapa';

  @override
  String get notifications => 'Mga Notifikasyon';

  @override
  String get markAllRead => 'Markahan lahat bilang nabasa';

  @override
  String get deleteAll => 'Burahin lahat';

  @override
  String get noNotifications => 'Wala pang notifikasyon';

  @override
  String get notifApplicationReceived => 'Natanggap ang aplikasyon';

  @override
  String get notifShortlisted => 'Ikaw ay na-shortlist';

  @override
  String get notifInterview => 'May naka-schedule na interview';

  @override
  String get notifHired => 'Congratulations! Ikaw ay na-hire';

  @override
  String get notifRejected => 'Hindi matagumpay ang aplikasyon';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'I-edit ang Profile';

  @override
  String get myDocuments => 'Mga Dokumento Ko';

  @override
  String get skillsProfile => 'Profile ng Kasanayan';

  @override
  String get myApplications => 'Mga Aplikasyon Ko';

  @override
  String get savedJobs => 'Mga Naka-save na Trabaho';

  @override
  String get signOut => 'Mag-sign Out';

  @override
  String get signOutConfirm => 'Sigurado ka bang gusto mong mag-sign out?';

  @override
  String get statApplied => 'Inaplayan';

  @override
  String get statProcessing => 'Pinoproseso';

  @override
  String get statSaved => 'Naka-save';

  @override
  String get docsComplete => 'Kumpleto';

  @override
  String docsMoreNeeded(int count) {
    return '$count pa';
  }

  @override
  String get settings => 'Mga Setting';

  @override
  String get preferences => 'Mga Kagustuhan';

  @override
  String get account => 'Account';

  @override
  String get language => 'Wika';

  @override
  String get changeEmail => 'Palitan ang email address';

  @override
  String get changeEmailSubtitle => 'I-secure gamit ang OTP verification';

  @override
  String get currentEmail => 'Kasalukuyang email';

  @override
  String get changeEmailOtpInfo =>
      'Magpapadala kami ng OTP sa iyong bagong email address.';

  @override
  String get changePassword => 'Palitan ang password';

  @override
  String get logout => 'Mag-logout';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTagalog => 'Tagalog (Filipino)';

  @override
  String get languageSelectTitle => 'Pumili ng Wika';

  @override
  String get languageSelectSubtitle => 'Piliin ang iyong gustong wika';

  @override
  String get helpSupport => 'Tulong at Suporta';

  @override
  String get quickHelp => 'Mabilisang Tulong';

  @override
  String get faq => 'Mga Karaniwang Tanong (FAQ)';

  @override
  String get contactSupport => 'Makipag-ugnay sa Support';

  @override
  String get replayTour => 'Ulitin ang App Tour';

  @override
  String get replayTourSubtitle => 'Tingnan muli ang guided walkthrough';

  @override
  String get goToMyDocuments => 'Mga Dokumento Ko';

  @override
  String get goToMyDocumentsSubtitle =>
      'I-upload ang mga kailangan bago mag-apply';

  @override
  String get openSettings => 'Buksan ang Settings';

  @override
  String get openSettingsSubtitle => 'I-manage ang account details at email';

  @override
  String get privacyPolicy => 'Patakaran sa Privacy';

  @override
  String get privacyPolicySubtitle =>
      'Paano namin pinoprotektahan ang iyong data';

  @override
  String get termsOfService => 'Mga Tuntunin ng Serbisyo';

  @override
  String get termsOfServiceSubtitle => 'Mga patakaran sa paggamit ng app';

  @override
  String get legal => 'Legal';

  @override
  String get applicationStatusGuide => 'Gabay sa Status ng Aplikasyon';

  @override
  String get statusRegistration => 'Rehistrasyon';

  @override
  String get statusRegistrationDesc =>
      'Naisumite at naitala na ng system ang aplikasyon.';

  @override
  String get statusProcessing => 'Pinoproseso';

  @override
  String get statusProcessingDesc =>
      'Sinusuri ng employer. Mga sub-stage: • Shortlisted • Interview • For Job Offer';

  @override
  String get statusPlacementHired => 'Na-hire na';

  @override
  String get statusPlacementHiredDesc =>
      'Huling yugto matapos ang desisyon sa pag-hire.';

  @override
  String get events => 'Mga Event';

  @override
  String get upcomingEvents => 'Mga Paparating na Event';

  @override
  String get noEvents => 'Walang event sa ngayon';

  @override
  String get register => 'Mag-rehistro';

  @override
  String get registered => 'Nakarehistro na';

  @override
  String get cancelRegistration => 'Kanselahin ang Rehistrasyon';

  @override
  String get eventDetails => 'Detalye ng Event';

  @override
  String get eventDate => 'Petsa';

  @override
  String get eventLocation => 'Lokasyon';

  @override
  String get eventSlots => 'Mga Slot';

  @override
  String get login => 'Mag-login';

  @override
  String get signup => 'Mag-signup';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Kumpirmahin ang password';

  @override
  String get forgotPassword => 'Nakalimutan ang password?';

  @override
  String get createAccount => 'Gumawa ng account';

  @override
  String get alreadyHaveAccount => 'May account ka na?';

  @override
  String get dontHaveAccount => 'Wala pang account?';

  @override
  String get welcomeBack => 'Maligayang pagbabalik';

  @override
  String get getStarted => 'Magsimula';

  @override
  String get sessionExpired => 'Nag-expire na ang session. Mag-login ulit.';

  @override
  String get firstName => 'Pangalan';

  @override
  String get middleName => 'Gitnang pangalan';

  @override
  String get lastName => 'Apelyido';

  @override
  String get suffix => 'Suffix';

  @override
  String get birthdate => 'Petsa ng kapanganakan';

  @override
  String get gender => 'Kasarian';

  @override
  String get contactNumber => 'Numero ng telepono';

  @override
  String get male => 'Lalaki';

  @override
  String get female => 'Babae';

  @override
  String get other => 'Iba pa';

  @override
  String get preferNotToSay => 'Ayaw sabihin';

  @override
  String get upload => 'I-upload';

  @override
  String get uploadResume => 'I-upload ang Resume';

  @override
  String get uploadPhoto => 'I-upload ang Larawan';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get chooseFile => 'Pumili ng File';

  @override
  String get resume => 'Resume / CV';

  @override
  String get certificate => 'Sertipiko / Diploma';

  @override
  String get barangayClearance => 'Barangay Clearance';

  @override
  String get documentUploaded => 'Matagumpay na na-upload ang dokumento';

  @override
  String get documentDeleted => 'Nabura ang dokumento';

  @override
  String get noDocumentYet => 'Wala pang na-upload na dokumento';

  @override
  String get tapToUpload => 'I-tap para mag-upload';

  @override
  String get viewDocument => 'Tingnan';

  @override
  String get replaceDocument => 'Palitan';

  @override
  String get deleteDocument => 'Burahin';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get confirm => 'Kumpirmahin';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Oo';

  @override
  String get no => 'Hindi';

  @override
  String get done => 'Tapos na';

  @override
  String get next => 'Susunod';

  @override
  String get back => 'Bumalik';

  @override
  String get skip => 'Laktawan';

  @override
  String get submit => 'Ipasa';

  @override
  String get save => 'I-save';

  @override
  String get saveChanges => 'I-save ang mga Pagbabago';

  @override
  String get delete => 'Burahin';

  @override
  String get edit => 'I-edit';

  @override
  String get close => 'Isara';

  @override
  String get retry => 'Subukan Muli';

  @override
  String get search => 'Maghanap';

  @override
  String get clear => 'Burahin';

  @override
  String get loading => 'Naglo-load...';

  @override
  String get loadingJobs => 'Naglo-load ng trabaho...';

  @override
  String get refreshing => 'Nagre-refresh...';

  @override
  String get noConnection => 'Walang Koneksyon';

  @override
  String get noInternetConnection => 'Walang internet connection';

  @override
  String get checkConnection => 'Pakisuri ang iyong koneksyon at subukan muli.';

  @override
  String get success => 'Matagumpay';

  @override
  String get error => 'May Error';

  @override
  String get warning => 'Babala';

  @override
  String get info => 'Impormasyon';

  @override
  String get applicationSubmitted => 'Matagumpay na naisumite ang aplikasyon';

  @override
  String get applicationFailed => 'Hindi naisumite ang aplikasyon';

  @override
  String get jobSaved => 'Naka-save ang trabaho';

  @override
  String get jobUnsaved => 'Natanggal sa mga naka-save';

  @override
  String get profileUpdated => 'Matagumpay na na-update ang profile';

  @override
  String get passwordChanged => 'Matagumpay na napalitan ang password';

  @override
  String get areYouSure => 'Sigurado ka ba?';

  @override
  String get logoutConfirm => 'Sigurado ka bang gusto mong mag-logout?';

  @override
  String get deleteConfirm => 'Hindi na ito maibabalik';

  @override
  String get today => 'Ngayon';

  @override
  String get yesterday => 'Kahapon';

  @override
  String daysAgo(int count) {
    return '$count araw na ang nakalipas';
  }

  @override
  String matchPercentage(int percent) {
    return '$percent% Bagay';
  }

  @override
  String slotsAvailable(int count) {
    return '$count slot na bakante';
  }

  @override
  String get deadline => 'Deadline';

  @override
  String get postedDate => 'Nai-post';

  @override
  String expiresIn(int days) {
    return 'Mag-e-expire sa $days araw';
  }

  @override
  String get resumeRequired => 'Kailangan ng Resume';

  @override
  String get resumeRequiredMessage =>
      'Kailangan mong mag-upload ng resume bago mag-apply sa trabaho.';

  @override
  String get goToDocuments => 'Pumunta sa Mga Dokumento';

  @override
  String get skillsTab => 'Mga Kasanayan';

  @override
  String get jobMatchesTab => 'Mga Bagay na Trabaho';

  @override
  String get yourSkills => 'Mga Kasanayan Mo';

  @override
  String get browseSkills =>
      'Mag-browse at magdagdag ng kasanayan mula sa catalog';

  @override
  String get saveSkills => 'I-save ang Kasanayan';

  @override
  String get savingSkills => 'Nag-se-save...';

  @override
  String get skillsSaved => 'Matagumpay na na-save ang mga kasanayan';

  @override
  String get noSkillsYet => 'Wala pang naidagdag na kasanayan';

  @override
  String get addSkillsPrompt =>
      'Magdagdag ng kasanayan para mapaganda ang job matching';

  @override
  String get searchSkills => 'Maghanap ng kasanayan...';

  @override
  String get allCategories => 'Lahat ng Kategorya';

  @override
  String selectedCount(int count) {
    return '$count ang napili';
  }

  @override
  String get editSkills => 'I-edit ang Kasanayan';

  @override
  String get noMatchedJobs => 'Wala pang nahanap na bagay na trabaho';

  @override
  String get addSkillsForMatches =>
      'Magdagdag ng kasanayan para makita ang mga bagay na trabaho';

  @override
  String get guideFinishTutorialFirst => 'Tapusin muna ang tutorial.';

  @override
  String get currentPassword => 'Kasalukuyang password';

  @override
  String get newPassword => 'Bagong password';

  @override
  String get confirmNewPassword => 'Kumpirmahin ang bagong password';

  @override
  String get confirmYourNewPassword => 'Kumpirmahin ang iyong bagong password';

  @override
  String get passwordsDoNotMatch => 'Hindi magkatugma ang mga password';

  @override
  String otpSentTo(String email) {
    return 'Naipadala ang OTP sa $email';
  }

  @override
  String get newEmailAddress => 'Bagong email address';

  @override
  String get enterOtp => 'Ilagay ang OTP';

  @override
  String get verifyOtp => 'I-verify ang OTP';

  @override
  String get resendOtp => 'Ipadala muli ang OTP';

  @override
  String get sendOtp => 'Ipadala ang OTP';

  @override
  String resendIn(int seconds) {
    return 'Ipadala muli sa ${seconds}s';
  }

  @override
  String noResultsFor(String query) {
    return 'Walang resulta para sa \"$query\"';
  }

  @override
  String get mapSearchThisArea => 'I-search ang lugar na ito';

  @override
  String get mapClosestCompanyNearYou => 'Pinakamalapit na kumpanya sa iyo';

  @override
  String get mapClosestCompanyInArea =>
      'Pinakamalapit na kumpanya sa lugar na ito';

  @override
  String get searchBusinessesHint => 'Maghanap ng kumpanya...';

  @override
  String get mapBestMatchOnly => 'Pinakabagay Lamang';

  @override
  String get mapLocationProfiles => 'Mga Location Profile';

  @override
  String get mapExactLocation => 'Eksaktong Lokasyon';

  @override
  String get mapLiveGps => 'Live GPS';

  @override
  String get mapNearbyCompanies => 'Mga Kalapit na Kompanya';

  @override
  String get mapCompare => 'Ihambing';

  @override
  String get mapDirections => 'Direksyon';

  @override
  String get mapNoCompaniesNearby => 'Walang nakitang kalapit na kompanya';

  @override
  String get selectGender => 'Pumili ng kasarian';

  @override
  String get personalInfo => 'Personal na Impormasyon';

  @override
  String get saveProfile => 'I-save ang Profile';

  @override
  String get updatePhoto => 'I-update ang Larawan';

  @override
  String get openEmailApp => 'Buksan ang email app';

  @override
  String get facebookMessenger => 'Facebook Messenger';

  @override
  String get couldNotOpenEmail =>
      'Hindi mabuksan ang email app sa device na ito.';

  @override
  String get couldNotOpenLink => 'Hindi mabuksan ang link.';
}

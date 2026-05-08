// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kabsat Empoy';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String jobsFound(int count) {
    return '$count Jobs Found';
  }

  @override
  String jobsFoundFiltered(int filtered, int total) {
    return '$filtered of $total Jobs Found';
  }

  @override
  String get searchJobsHint => 'Search jobs, companies...';

  @override
  String get homeFindJobTitle => 'Find a job';

  @override
  String get noJobsFound => 'No jobs found';

  @override
  String get tryAdjustingFilters => 'Try adjusting your search or filters';

  @override
  String get loadMoreJobs => 'Loading more jobs...';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortLatest => 'Latest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortBestMatch => 'Best Match';

  @override
  String get filterEmploymentType => 'Employment Type';

  @override
  String get filterSkills => 'Skills';

  @override
  String get filterClearAll => 'Clear All';

  @override
  String get filterApply => 'Apply Filters';

  @override
  String get filterReset => 'Reset';

  @override
  String get searchSkillsHint => 'Search skills...';

  @override
  String get fullTime => 'Full-time';

  @override
  String get partTime => 'Part-time';

  @override
  String get contract => 'Contract';

  @override
  String get freelance => 'Freelance';

  @override
  String get internship => 'Internship';

  @override
  String get apply => 'Apply';

  @override
  String get applyNow => 'Apply Now';

  @override
  String get applied => 'Applied';

  @override
  String get viewDetails => 'View Details';

  @override
  String get location => 'Location';

  @override
  String get salary => 'Salary';

  @override
  String get employmentType => 'Employment Type';

  @override
  String get experience => 'Experience';

  @override
  String get education => 'Education';

  @override
  String get skills => 'Skills';

  @override
  String get description => 'Description';

  @override
  String get requirements => 'Requirements';

  @override
  String get jobDetailsTitle => 'Job Details';

  @override
  String get aboutThisRoleTitle => 'About This Role';

  @override
  String get skillsRequiredTitle => 'Skills Required';

  @override
  String get companyAbout => 'About Company';

  @override
  String get companyJobs => 'Available Jobs';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get notifApplicationReceived => 'Application received';

  @override
  String get notifShortlisted => 'You have been shortlisted';

  @override
  String get notifInterview => 'Interview scheduled';

  @override
  String get notifHired => 'Congratulations! You are hired';

  @override
  String get notifRejected => 'Application not successful';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myDocuments => 'My Documents';

  @override
  String get skillsProfile => 'Skills Profile';

  @override
  String get myApplications => 'My Applications';

  @override
  String get savedJobs => 'Saved Jobs';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get statApplied => 'Applied';

  @override
  String get statProcessing => 'Processing';

  @override
  String get statSaved => 'Saved';

  @override
  String get docsComplete => 'Complete';

  @override
  String docsMoreNeeded(int count) {
    return '$count more';
  }

  @override
  String get settings => 'Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get account => 'Account';

  @override
  String get language => 'Language';

  @override
  String get changeEmail => 'Change email address';

  @override
  String get changeEmailSubtitle => 'Secure this change using OTP verification';

  @override
  String get currentEmail => 'Current email';

  @override
  String get changeEmailOtpInfo =>
      'We will send an OTP to your new email address.';

  @override
  String get changePassword => 'Change password';

  @override
  String get logout => 'Log out';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTagalog => 'Tagalog (Filipino)';

  @override
  String get languageSelectTitle => 'Select Language';

  @override
  String get languageSelectSubtitle => 'Choose your preferred language';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get quickHelp => 'Quick Help';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get replayTour => 'Replay App Tour';

  @override
  String get replayTourSubtitle => 'See the guided walkthrough again';

  @override
  String get goToMyDocuments => 'Go to My Documents';

  @override
  String get goToMyDocumentsSubtitle => 'Upload required files before applying';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get openSettingsSubtitle => 'Manage account details and email';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'How we handle personal data';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceSubtitle => 'Rules for using the app';

  @override
  String get legal => 'Legal';

  @override
  String get applicationStatusGuide => 'Application Status Guide';

  @override
  String get statusRegistration => 'Registration';

  @override
  String get statusRegistrationDesc =>
      'Application submitted and recorded by the system.';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusProcessingDesc =>
      'Employer review stage. Sub-stages can appear as: • Shortlisted • Interview • For Job Offer';

  @override
  String get statusPlacementHired => 'Placement/Hired';

  @override
  String get statusPlacementHiredDesc => 'Final stage after hiring decision.';

  @override
  String get events => 'Events';

  @override
  String get upcomingEvents => 'Upcoming Events';

  @override
  String get noEvents => 'No events at the moment';

  @override
  String get register => 'Register';

  @override
  String get registered => 'Registered';

  @override
  String get cancelRegistration => 'Cancel Registration';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get eventDate => 'Date';

  @override
  String get eventLocation => 'Location';

  @override
  String get eventSlots => 'Slots';

  @override
  String get login => 'Log in';

  @override
  String get signup => 'Sign up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get getStarted => 'Get started';

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get firstName => 'First name';

  @override
  String get middleName => 'Middle name';

  @override
  String get lastName => 'Last name';

  @override
  String get suffix => 'Suffix';

  @override
  String get birthdate => 'Birthdate';

  @override
  String get gender => 'Gender';

  @override
  String get contactNumber => 'Contact number';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get upload => 'Upload';

  @override
  String get uploadResume => 'Upload Resume';

  @override
  String get uploadPhoto => 'Upload Photo';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get resume => 'Resume / CV';

  @override
  String get certificate => 'Certificate / Diploma';

  @override
  String get barangayClearance => 'Barangay Clearance';

  @override
  String get documentUploaded => 'Document uploaded successfully';

  @override
  String get documentDeleted => 'Document deleted';

  @override
  String get noDocumentYet => 'No document uploaded yet';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get viewDocument => 'View';

  @override
  String get replaceDocument => 'Replace';

  @override
  String get deleteDocument => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get submit => 'Submit';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingJobs => 'Loading jobs...';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get noConnection => 'No Connection';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get checkConnection =>
      'Please check your internet connection and try again.';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get applicationSubmitted => 'Application submitted successfully';

  @override
  String get applicationFailed => 'Failed to submit application';

  @override
  String get jobSaved => 'Job saved';

  @override
  String get jobUnsaved => 'Job removed from saved';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get passwordChanged => 'Password changed successfully';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get deleteConfirm => 'This action cannot be undone';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String matchPercentage(int percent) {
    return '$percent% Match';
  }

  @override
  String slotsAvailable(int count) {
    return '$count slots available';
  }

  @override
  String get deadline => 'Deadline';

  @override
  String get postedDate => 'Posted';

  @override
  String expiresIn(int days) {
    return 'Expires in $days days';
  }

  @override
  String get resumeRequired => 'Resume Required';

  @override
  String get resumeRequiredMessage =>
      'You need to upload your resume first before applying to jobs.';

  @override
  String get goToDocuments => 'Go to Documents';

  @override
  String get skillsTab => 'Skills';

  @override
  String get jobMatchesTab => 'Job Matches';

  @override
  String get yourSkills => 'Your Skills';

  @override
  String get browseSkills => 'Browse & add skills from the catalog below';

  @override
  String get saveSkills => 'Save Skills';

  @override
  String get savingSkills => 'Saving...';

  @override
  String get skillsSaved => 'Skills saved successfully';

  @override
  String get noSkillsYet => 'No skills added yet';

  @override
  String get addSkillsPrompt => 'Add your key skills to improve job matching';

  @override
  String get searchSkills => 'Search skills...';

  @override
  String get allCategories => 'All Categories';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get editSkills => 'Edit Skills';

  @override
  String get noMatchedJobs => 'No matched jobs yet';

  @override
  String get addSkillsForMatches => 'Add skills to see matching jobs';

  @override
  String get guideFinishTutorialFirst => 'Finish the tutorial first.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get confirmYourNewPassword => 'Confirm your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String otpSentTo(String email) {
    return 'OTP sent to $email';
  }

  @override
  String get newEmailAddress => 'New email address';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get mapSearchThisArea => 'Search this area';

  @override
  String get mapClosestCompanyNearYou => 'Closest company near you';

  @override
  String get mapClosestCompanyInArea => 'Closest company in this area';

  @override
  String get searchBusinessesHint => 'Search businesses...';

  @override
  String get mapBestMatchOnly => 'Best Match Only';

  @override
  String get mapLocationProfiles => 'Location Profiles';

  @override
  String get mapExactLocation => 'Exact Location';

  @override
  String get mapLiveGps => 'Live GPS';

  @override
  String get mapNearbyCompanies => 'Nearby Companies';

  @override
  String get mapCompare => 'Compare';

  @override
  String get mapDirections => 'Directions';

  @override
  String get mapNoCompaniesNearby => 'No companies found nearby';

  @override
  String get selectGender => 'Select gender';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get updatePhoto => 'Update Photo';

  @override
  String get openEmailApp => 'Open email app';

  @override
  String get facebookMessenger => 'Facebook Messenger';

  @override
  String get couldNotOpenEmail => 'Could not open an email app on this device.';

  @override
  String get couldNotOpenLink => 'Could not open the link.';
}

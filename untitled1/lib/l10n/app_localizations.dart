import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
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
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

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
    Locale('tl')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kabsat Empoy'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greetingEvening;

  /// No description provided for @jobsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} Jobs Found'**
  String jobsFound(int count);

  /// No description provided for @jobsFoundFiltered.
  ///
  /// In en, this message translates to:
  /// **'{filtered} of {total} Jobs Found'**
  String jobsFoundFiltered(int filtered, int total);

  /// No description provided for @searchJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Search jobs, companies...'**
  String get searchJobsHint;

  /// No description provided for @homeFindJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a job'**
  String get homeFindJobTitle;

  /// No description provided for @noJobsFound.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingFilters;

  /// No description provided for @loadMoreJobs.
  ///
  /// In en, this message translates to:
  /// **'Loading more jobs...'**
  String get loadMoreJobs;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sortLatest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldest;

  /// No description provided for @sortBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best Match'**
  String get sortBestMatch;

  /// No description provided for @filterEmploymentType.
  ///
  /// In en, this message translates to:
  /// **'Employment Type'**
  String get filterEmploymentType;

  /// No description provided for @filterSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get filterSkills;

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get filterClearAll;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filterApply;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @searchSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'Search skills...'**
  String get searchSkillsHint;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get fullTime;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get partTime;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get freelance;

  /// No description provided for @internship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get internship;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applied;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @employmentType.
  ///
  /// In en, this message translates to:
  /// **'Employment Type'**
  String get employmentType;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @requirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirements;

  /// No description provided for @jobDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetailsTitle;

  /// No description provided for @aboutThisRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'About This Role'**
  String get aboutThisRoleTitle;

  /// No description provided for @skillsRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills Required'**
  String get skillsRequiredTitle;

  /// No description provided for @companyAbout.
  ///
  /// In en, this message translates to:
  /// **'About Company'**
  String get companyAbout;

  /// No description provided for @companyJobs.
  ///
  /// In en, this message translates to:
  /// **'Available Jobs'**
  String get companyJobs;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notifApplicationReceived.
  ///
  /// In en, this message translates to:
  /// **'Application received'**
  String get notifApplicationReceived;

  /// No description provided for @notifShortlisted.
  ///
  /// In en, this message translates to:
  /// **'You have been shortlisted'**
  String get notifShortlisted;

  /// No description provided for @notifInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview scheduled'**
  String get notifInterview;

  /// No description provided for @notifHired.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You are hired'**
  String get notifHired;

  /// No description provided for @notifRejected.
  ///
  /// In en, this message translates to:
  /// **'Application not successful'**
  String get notifRejected;

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

  /// No description provided for @myDocuments.
  ///
  /// In en, this message translates to:
  /// **'My Documents'**
  String get myDocuments;

  /// No description provided for @skillsProfile.
  ///
  /// In en, this message translates to:
  /// **'Skills Profile'**
  String get skillsProfile;

  /// No description provided for @myApplications.
  ///
  /// In en, this message translates to:
  /// **'My Applications'**
  String get myApplications;

  /// No description provided for @savedJobs.
  ///
  /// In en, this message translates to:
  /// **'Saved Jobs'**
  String get savedJobs;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @statApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get statApplied;

  /// No description provided for @statProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statProcessing;

  /// No description provided for @statSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get statSaved;

  /// No description provided for @docsComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get docsComplete;

  /// No description provided for @docsMoreNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String docsMoreNeeded(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get changeEmail;

  /// No description provided for @changeEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure this change using OTP verification'**
  String get changeEmailSubtitle;

  /// No description provided for @currentEmail.
  ///
  /// In en, this message translates to:
  /// **'Current email'**
  String get currentEmail;

  /// No description provided for @changeEmailOtpInfo.
  ///
  /// In en, this message translates to:
  /// **'We will send an OTP to your new email address.'**
  String get changeEmailOtpInfo;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTagalog.
  ///
  /// In en, this message translates to:
  /// **'Tagalog (Filipino)'**
  String get languageTagalog;

  /// No description provided for @languageSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageSelectTitle;

  /// No description provided for @languageSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSelectSubtitle;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @quickHelp.
  ///
  /// In en, this message translates to:
  /// **'Quick Help'**
  String get quickHelp;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @replayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay App Tour'**
  String get replayTour;

  /// No description provided for @replayTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the guided walkthrough again'**
  String get replayTourSubtitle;

  /// No description provided for @goToMyDocuments.
  ///
  /// In en, this message translates to:
  /// **'Go to My Documents'**
  String get goToMyDocuments;

  /// No description provided for @goToMyDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload required files before applying'**
  String get goToMyDocumentsSubtitle;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @openSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage account details and email'**
  String get openSettingsSubtitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle personal data'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rules for using the app'**
  String get termsOfServiceSubtitle;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @applicationStatusGuide.
  ///
  /// In en, this message translates to:
  /// **'Application Status Guide'**
  String get applicationStatusGuide;

  /// No description provided for @statusRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get statusRegistration;

  /// No description provided for @statusRegistrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Application submitted and recorded by the system.'**
  String get statusRegistrationDesc;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusProcessingDesc.
  ///
  /// In en, this message translates to:
  /// **'Employer review stage. Sub-stages can appear as: • Shortlisted • Interview • For Job Offer'**
  String get statusProcessingDesc;

  /// No description provided for @statusPlacementHired.
  ///
  /// In en, this message translates to:
  /// **'Placement/Hired'**
  String get statusPlacementHired;

  /// No description provided for @statusPlacementHiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Final stage after hiring decision.'**
  String get statusPlacementHiredDesc;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events at the moment'**
  String get noEvents;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @cancelRegistration.
  ///
  /// In en, this message translates to:
  /// **'Cancel Registration'**
  String get cancelRegistration;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @eventDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get eventDate;

  /// No description provided for @eventLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventLocation;

  /// No description provided for @eventSlots.
  ///
  /// In en, this message translates to:
  /// **'Slots'**
  String get eventSlots;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get middleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @suffix.
  ///
  /// In en, this message translates to:
  /// **'Suffix'**
  String get suffix;

  /// No description provided for @birthdate.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact number'**
  String get contactNumber;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploadResume.
  ///
  /// In en, this message translates to:
  /// **'Upload Resume'**
  String get uploadResume;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume / CV'**
  String get resume;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate / Diploma'**
  String get certificate;

  /// No description provided for @barangayClearance.
  ///
  /// In en, this message translates to:
  /// **'Barangay Clearance'**
  String get barangayClearance;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded successfully'**
  String get documentUploaded;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted'**
  String get documentDeleted;

  /// No description provided for @noDocumentYet.
  ///
  /// In en, this message translates to:
  /// **'No document uploaded yet'**
  String get noDocumentYet;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @viewDocument.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewDocument;

  /// No description provided for @replaceDocument.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceDocument;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDocument;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

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

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingJobs.
  ///
  /// In en, this message translates to:
  /// **'Loading jobs...'**
  String get loadingJobs;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get noConnection;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get checkConnection;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application submitted successfully'**
  String get applicationSubmitted;

  /// No description provided for @applicationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit application'**
  String get applicationFailed;

  /// No description provided for @jobSaved.
  ///
  /// In en, this message translates to:
  /// **'Job saved'**
  String get jobSaved;

  /// No description provided for @jobUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Job removed from saved'**
  String get jobUnsaved;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get deleteConfirm;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @matchPercentage.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String matchPercentage(int percent);

  /// No description provided for @slotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} slots available'**
  String slotsAvailable(int count);

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @postedDate.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get postedDate;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String expiresIn(int days);

  /// No description provided for @resumeRequired.
  ///
  /// In en, this message translates to:
  /// **'Resume Required'**
  String get resumeRequired;

  /// No description provided for @resumeRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to upload your resume first before applying to jobs.'**
  String get resumeRequiredMessage;

  /// No description provided for @goToDocuments.
  ///
  /// In en, this message translates to:
  /// **'Go to Documents'**
  String get goToDocuments;

  /// No description provided for @skillsTab.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillsTab;

  /// No description provided for @jobMatchesTab.
  ///
  /// In en, this message translates to:
  /// **'Job Matches'**
  String get jobMatchesTab;

  /// No description provided for @yourSkills.
  ///
  /// In en, this message translates to:
  /// **'Your Skills'**
  String get yourSkills;

  /// No description provided for @browseSkills.
  ///
  /// In en, this message translates to:
  /// **'Browse & add skills from the catalog below'**
  String get browseSkills;

  /// No description provided for @saveSkills.
  ///
  /// In en, this message translates to:
  /// **'Save Skills'**
  String get saveSkills;

  /// No description provided for @savingSkills.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingSkills;

  /// No description provided for @skillsSaved.
  ///
  /// In en, this message translates to:
  /// **'Skills saved successfully'**
  String get skillsSaved;

  /// No description provided for @noSkillsYet.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet'**
  String get noSkillsYet;

  /// No description provided for @addSkillsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add your key skills to improve job matching'**
  String get addSkillsPrompt;

  /// No description provided for @searchSkills.
  ///
  /// In en, this message translates to:
  /// **'Search skills...'**
  String get searchSkills;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @editSkills.
  ///
  /// In en, this message translates to:
  /// **'Edit Skills'**
  String get editSkills;

  /// No description provided for @noMatchedJobs.
  ///
  /// In en, this message translates to:
  /// **'No matched jobs yet'**
  String get noMatchedJobs;

  /// No description provided for @addSkillsForMatches.
  ///
  /// In en, this message translates to:
  /// **'Add skills to see matching jobs'**
  String get addSkillsForMatches;

  /// No description provided for @guideFinishTutorialFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish the tutorial first.'**
  String get guideFinishTutorialFirst;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @confirmYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get confirmYourNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {email}'**
  String otpSentTo(String email);

  /// No description provided for @newEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'New email address'**
  String get newEmailAddress;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @mapSearchThisArea.
  ///
  /// In en, this message translates to:
  /// **'Search this area'**
  String get mapSearchThisArea;

  /// No description provided for @mapClosestCompanyNearYou.
  ///
  /// In en, this message translates to:
  /// **'Closest company near you'**
  String get mapClosestCompanyNearYou;

  /// No description provided for @mapClosestCompanyInArea.
  ///
  /// In en, this message translates to:
  /// **'Closest company in this area'**
  String get mapClosestCompanyInArea;

  /// No description provided for @searchBusinessesHint.
  ///
  /// In en, this message translates to:
  /// **'Search businesses...'**
  String get searchBusinessesHint;

  /// No description provided for @mapBestMatchOnly.
  ///
  /// In en, this message translates to:
  /// **'Best Match Only'**
  String get mapBestMatchOnly;

  /// No description provided for @mapLocationProfiles.
  ///
  /// In en, this message translates to:
  /// **'Location Profiles'**
  String get mapLocationProfiles;

  /// No description provided for @mapExactLocation.
  ///
  /// In en, this message translates to:
  /// **'Exact Location'**
  String get mapExactLocation;

  /// No description provided for @mapLiveGps.
  ///
  /// In en, this message translates to:
  /// **'Live GPS'**
  String get mapLiveGps;

  /// No description provided for @mapNearbyCompanies.
  ///
  /// In en, this message translates to:
  /// **'Nearby Companies'**
  String get mapNearbyCompanies;

  /// No description provided for @mapCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get mapCompare;

  /// No description provided for @mapDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mapDirections;

  /// No description provided for @mapNoCompaniesNearby.
  ///
  /// In en, this message translates to:
  /// **'No companies found nearby'**
  String get mapNoCompaniesNearby;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get selectGender;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @updatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update Photo'**
  String get updatePhoto;

  /// No description provided for @openEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Open email app'**
  String get openEmailApp;

  /// No description provided for @facebookMessenger.
  ///
  /// In en, this message translates to:
  /// **'Facebook Messenger'**
  String get facebookMessenger;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open an email app on this device.'**
  String get couldNotOpenEmail;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get couldNotOpenLink;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tl'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'tl':
      return STl();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

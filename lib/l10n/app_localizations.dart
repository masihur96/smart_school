import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @settingManagement.
  ///
  /// In en, this message translates to:
  /// **'Setting Management'**
  String get settingManagement;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homework;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @securityDescription.
  ///
  /// In en, this message translates to:
  /// **'Update your account security'**
  String get securityDescription;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @organizationalDetails.
  ///
  /// In en, this message translates to:
  /// **'Organizational Details'**
  String get organizationalDetails;

  /// No description provided for @accountMetadata.
  ///
  /// In en, this message translates to:
  /// **'Account Metadata'**
  String get accountMetadata;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @verifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Verified User'**
  String get verifiedUser;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit your account?'**
  String get signOutConfirmation;

  /// No description provided for @keepSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep Signed In'**
  String get keepSignedIn;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sign Out'**
  String get confirmSignOut;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @teachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachers;

  /// No description provided for @classSetup.
  ///
  /// In en, this message translates to:
  /// **'Class & Setup'**
  String get classSetup;

  /// No description provided for @routine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get routine;

  /// No description provided for @notices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get notices;

  /// No description provided for @exams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exams;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @markEntry.
  ///
  /// In en, this message translates to:
  /// **'Mark Entry'**
  String get markEntry;

  /// No description provided for @schoolManagement.
  ///
  /// In en, this message translates to:
  /// **'School Management'**
  String get schoolManagement;

  /// No description provided for @systemConfig.
  ///
  /// In en, this message translates to:
  /// **'System Config'**
  String get systemConfig;

  /// No description provided for @globalAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Global Audit Logs'**
  String get globalAuditLogs;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @studentManagement.
  ///
  /// In en, this message translates to:
  /// **'Student Management'**
  String get studentManagement;

  /// No description provided for @examManagement.
  ///
  /// In en, this message translates to:
  /// **'Exam Management'**
  String get examManagement;

  /// No description provided for @schoolNotices.
  ///
  /// In en, this message translates to:
  /// **'School Notices'**
  String get schoolNotices;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @exitAppConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the app?'**
  String get exitAppConfirmation;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @schoolOverview.
  ///
  /// In en, this message translates to:
  /// **'School Overview'**
  String get schoolOverview;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @totalTeachers.
  ///
  /// In en, this message translates to:
  /// **'Total Teachers'**
  String get totalTeachers;

  /// No description provided for @totalClasses.
  ///
  /// In en, this message translates to:
  /// **'Total Classes'**
  String get totalClasses;

  /// No description provided for @activeNotices.
  ///
  /// In en, this message translates to:
  /// **'Active Notices'**
  String get activeNotices;

  /// No description provided for @attendanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Attendance Overview'**
  String get attendanceOverview;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudent;

  /// No description provided for @editStudent.
  ///
  /// In en, this message translates to:
  /// **'Edit Student'**
  String get editStudent;

  /// No description provided for @updateStudent.
  ///
  /// In en, this message translates to:
  /// **'Update Student'**
  String get updateStudent;

  /// No description provided for @saveStudent.
  ///
  /// In en, this message translates to:
  /// **'Save Student'**
  String get saveStudent;

  /// No description provided for @addTeacher.
  ///
  /// In en, this message translates to:
  /// **'Add Teacher'**
  String get addTeacher;

  /// No description provided for @postNotice.
  ///
  /// In en, this message translates to:
  /// **'Post Notice'**
  String get postNotice;

  /// No description provided for @manageRoutine.
  ///
  /// In en, this message translates to:
  /// **'Manage Routine'**
  String get manageRoutine;

  /// No description provided for @teacherAttendance.
  ///
  /// In en, this message translates to:
  /// **'Teacher Attendance'**
  String get teacherAttendance;

  /// No description provided for @marqueeMessage.
  ///
  /// In en, this message translates to:
  /// **'Marquee Message'**
  String get marqueeMessage;

  /// No description provided for @allClasses.
  ///
  /// In en, this message translates to:
  /// **'All Classes'**
  String get allClasses;

  /// No description provided for @schoolPerformance.
  ///
  /// In en, this message translates to:
  /// **'School Performance'**
  String get schoolPerformance;

  /// No description provided for @classPerformance.
  ///
  /// In en, this message translates to:
  /// **'Class Performance'**
  String get classPerformance;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @classBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Class Breakdown'**
  String get classBreakdown;

  /// No description provided for @studentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsLabel;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'INVALID'**
  String get invalid;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expired;

  /// No description provided for @teacherDashboard.
  ///
  /// In en, this message translates to:
  /// **'Teacher Dashboard'**
  String get teacherDashboard;

  /// No description provided for @marks.
  ///
  /// In en, this message translates to:
  /// **'Marks'**
  String get marks;

  /// No description provided for @scheduleToday.
  ///
  /// In en, this message translates to:
  /// **'Schedule Today'**
  String get scheduleToday;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @classesToday.
  ///
  /// In en, this message translates to:
  /// **'Classes Today'**
  String get classesToday;

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock In'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get clockOut;

  /// No description provided for @clockedOut.
  ///
  /// In en, this message translates to:
  /// **'Clocked Out'**
  String get clockedOut;

  /// No description provided for @locationNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Attendance location not configured by admin.'**
  String get locationNotConfigured;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied.'**
  String get locationPermissionsDenied;

  /// No description provided for @locationPermissionsPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied.'**
  String get locationPermissionsPermanentlyDenied;

  /// No description provided for @fetchingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching current location...'**
  String get fetchingCurrentLocation;

  /// No description provided for @attendanceMarkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Attendance marked successfully!'**
  String get attendanceMarkedSuccessfully;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed'**
  String get submissionFailed;

  /// No description provided for @outOfRange.
  ///
  /// In en, this message translates to:
  /// **'You are out of range'**
  String get outOfRange;

  /// No description provided for @upcomingExams.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Exams'**
  String get upcomingExams;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @recentHomework.
  ///
  /// In en, this message translates to:
  /// **'Recent Homework'**
  String get recentHomework;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgent;

  /// No description provided for @myRoutine.
  ///
  /// In en, this message translates to:
  /// **'My Routine'**
  String get myRoutine;

  /// No description provided for @examResults.
  ///
  /// In en, this message translates to:
  /// **'Exam Results'**
  String get examResults;

  /// No description provided for @material.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material;

  /// No description provided for @queries.
  ///
  /// In en, this message translates to:
  /// **'Queries'**
  String get queries;

  /// No description provided for @classInfoMissing.
  ///
  /// In en, this message translates to:
  /// **'Class info missing'**
  String get classInfoMissing;

  /// No description provided for @noPendingHomework.
  ///
  /// In en, this message translates to:
  /// **'No pending homework'**
  String get noPendingHomework;

  /// No description provided for @homeworkDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Homework data unavailable'**
  String get homeworkDataUnavailable;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @fullReport.
  ///
  /// In en, this message translates to:
  /// **'Full Report'**
  String get fullReport;

  /// No description provided for @noAttendanceRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No attendance records found.'**
  String get noAttendanceRecordsFound;

  /// No description provided for @systemOverview.
  ///
  /// In en, this message translates to:
  /// **'System Overview'**
  String get systemOverview;

  /// No description provided for @systemPerformance.
  ///
  /// In en, this message translates to:
  /// **'System Performance'**
  String get systemPerformance;

  /// No description provided for @systemStatusHealthy.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM STATUS: HEALTHY'**
  String get systemStatusHealthy;

  /// No description provided for @totalSchools.
  ///
  /// In en, this message translates to:
  /// **'Total Schools'**
  String get totalSchools;

  /// No description provided for @activeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Active Subscription'**
  String get activeSubscription;

  /// No description provided for @schools.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get schools;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @managedSchools.
  ///
  /// In en, this message translates to:
  /// **'Managed Schools'**
  String get managedSchools;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @systemConfiguration.
  ///
  /// In en, this message translates to:
  /// **'System Configuration'**
  String get systemConfiguration;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenanceMode;

  /// No description provided for @systemSubscription.
  ///
  /// In en, this message translates to:
  /// **'System Subscription'**
  String get systemSubscription;

  /// No description provided for @subscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscriptionDetails;

  /// No description provided for @systemPlanManagement.
  ///
  /// In en, this message translates to:
  /// **'Manage and upgrade your system plan'**
  String get systemPlanManagement;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @noNewNotices.
  ///
  /// In en, this message translates to:
  /// **'No new notices at this time'**
  String get noNewNotices;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @config.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get config;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @setupBiometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Setup Biometric Login'**
  String get setupBiometricLogin;

  /// No description provided for @biometricSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials to enable biometric login.'**
  String get biometricSetupDescription;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device.'**
  String get biometricNotAvailable;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @subscriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Required'**
  String get subscriptionRequired;

  /// No description provided for @noPricingPlansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No pricing plans available'**
  String get noPricingPlansAvailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Active Subscription'**
  String get noActiveSubscription;

  /// No description provided for @noActiveSubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Your institution needs an active plan to access the dashboard.'**
  String get noActiveSubscriptionDesc;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your plan expired on {date}. Please renew to continue.'**
  String subscriptionExpiredDesc(String date);

  /// No description provided for @activeSubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Your institution is on the {planName} plan, valid until\n {validUntil}.'**
  String activeSubscriptionDesc(String planName, String validUntil);

  /// No description provided for @customPlan.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM'**
  String get customPlan;

  /// No description provided for @yourCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'YOUR CURRENT PLAN'**
  String get yourCurrentPlan;

  /// No description provided for @monthlyBilling.
  ///
  /// In en, this message translates to:
  /// **'Monthly Billing'**
  String get monthlyBilling;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonth;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE THIS PLAN'**
  String get choosePlan;

  /// No description provided for @alreadyUsedFreePlan.
  ///
  /// In en, this message translates to:
  /// **'ALREADY USED THIS FREE PLAN FOR THIS ACCOUNT'**
  String get alreadyUsedFreePlan;

  /// No description provided for @failedToAssignPlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign plan'**
  String get failedToAssignPlan;

  /// No description provided for @perfectChoice.
  ///
  /// In en, this message translates to:
  /// **'Perfect Choice!'**
  String get perfectChoice;

  /// No description provided for @planRegisteredDesc.
  ///
  /// In en, this message translates to:
  /// **'You have successfully registered for the {planName} plan. To activate your account, a request needs to be sent to our administration team.'**
  String planRegisteredDesc(String planName);

  /// No description provided for @sendActivationRequest.
  ///
  /// In en, this message translates to:
  /// **'SEND ACTIVATION REQUEST'**
  String get sendActivationRequest;

  /// No description provided for @decideLater.
  ///
  /// In en, this message translates to:
  /// **'Decide Later'**
  String get decideLater;

  /// No description provided for @activationRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Activation request sent successfully. You will receive a confirmation email within 12 hours.'**
  String get activationRequestSent;

  /// No description provided for @studentsCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max} Students'**
  String studentsCount(int current, int max);

  /// No description provided for @studentAttendance.
  ///
  /// In en, this message translates to:
  /// **'Student Attendance'**
  String get studentAttendance;

  /// No description provided for @teacherAttendanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher Attendance'**
  String get teacherAttendanceLabel;

  /// No description provided for @classWiseRecords.
  ///
  /// In en, this message translates to:
  /// **'Class Wise Records'**
  String get classWiseRecords;

  /// No description provided for @todaysRecords.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Records'**
  String get todaysRecords;

  /// No description provided for @noRecordsForToday.
  ///
  /// In en, this message translates to:
  /// **'No records for today'**
  String get noRecordsForToday;

  /// No description provided for @currentExams.
  ///
  /// In en, this message translates to:
  /// **'Current Exams'**
  String get currentExams;

  /// No description provided for @recentNotices.
  ///
  /// In en, this message translates to:
  /// **'Recent Notices'**
  String get recentNotices;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT'**
  String get important;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'PUBLISHED'**
  String get published;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get draft;

  /// No description provided for @forAudience.
  ///
  /// In en, this message translates to:
  /// **'For: {audience}'**
  String forAudience(String audience);

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntil(String date);

  /// No description provided for @expiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired on {date}'**
  String expiredOn(String date);

  /// No description provided for @noPlan.
  ///
  /// In en, this message translates to:
  /// **'No Plan'**
  String get noPlan;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'RATE'**
  String get rate;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @examDateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String examDateRange(String start, String end);

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @classInfoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Class info not available'**
  String get classInfoNotAvailable;

  /// No description provided for @noHomeworkAssigned.
  ///
  /// In en, this message translates to:
  /// **'No homework assigned to your class yet.'**
  String get noHomeworkAssigned;

  /// No description provided for @allSubjects.
  ///
  /// In en, this message translates to:
  /// **'All Subjects'**
  String get allSubjects;

  /// No description provided for @examinerLabel.
  ///
  /// In en, this message translates to:
  /// **'Examiner: {name}'**
  String examinerLabel(String name);

  /// No description provided for @examsAndResults.
  ///
  /// In en, this message translates to:
  /// **'Exams & Results'**
  String get examsAndResults;

  /// No description provided for @classInfoNotFound.
  ///
  /// In en, this message translates to:
  /// **'Class information not found for student.'**
  String get classInfoNotFound;

  /// No description provided for @teacherManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Management'**
  String get teacherManagementTitle;

  /// No description provided for @deleteTeacher.
  ///
  /// In en, this message translates to:
  /// **'Delete Teacher'**
  String get deleteTeacher;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotification;

  /// No description provided for @editTeacher.
  ///
  /// In en, this message translates to:
  /// **'Edit Teacher'**
  String get editTeacher;

  /// No description provided for @teacherUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Teacher updated successfully'**
  String get teacherUpdatedSuccessfully;

  /// No description provided for @teacherRegisteredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Teacher registered successfully'**
  String get teacherRegisteredSuccessfully;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @updateTeacher.
  ///
  /// In en, this message translates to:
  /// **'Update Teacher'**
  String get updateTeacher;

  /// No description provided for @registerTeacher.
  ///
  /// In en, this message translates to:
  /// **'Register Teacher'**
  String get registerTeacher;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @notifyTeacher.
  ///
  /// In en, this message translates to:
  /// **'Notify {name}'**
  String notifyTeacher(String name);

  /// No description provided for @pleaseEnterTitleAndMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter title and message'**
  String get pleaseEnterTitleAndMessage;

  /// No description provided for @notificationSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully'**
  String get notificationSentSuccessfully;

  /// No description provided for @failedToSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notification'**
  String get failedToSendNotification;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @allSections.
  ///
  /// In en, this message translates to:
  /// **'All Sections'**
  String get allSections;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @activeOnly.
  ///
  /// In en, this message translates to:
  /// **'Active Only'**
  String get activeOnly;

  /// No description provided for @inactiveOnly.
  ///
  /// In en, this message translates to:
  /// **'Inactive Only'**
  String get inactiveOnly;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students found.'**
  String get noStudentsFound;

  /// No description provided for @rollLabel.
  ///
  /// In en, this message translates to:
  /// **'Roll: {roll}'**
  String rollLabel(String roll);

  /// No description provided for @deleteStudent.
  ///
  /// In en, this message translates to:
  /// **'Delete Student'**
  String get deleteStudent;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @notifyStudent.
  ///
  /// In en, this message translates to:
  /// **'Notify {name}'**
  String notifyStudent(String name);

  /// No description provided for @viewDetailsOption.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsOption;

  /// No description provided for @editExam.
  ///
  /// In en, this message translates to:
  /// **'Edit Exam'**
  String get editExam;

  /// No description provided for @publishResult.
  ///
  /// In en, this message translates to:
  /// **'Publish Result'**
  String get publishResult;

  /// No description provided for @unpublishResult.
  ///
  /// In en, this message translates to:
  /// **'Unpublish Result'**
  String get unpublishResult;

  /// No description provided for @duplicateExam.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Exam'**
  String get duplicateExam;

  /// No description provided for @deleteExam.
  ///
  /// In en, this message translates to:
  /// **'Delete Exam'**
  String get deleteExam;

  /// No description provided for @newNotice.
  ///
  /// In en, this message translates to:
  /// **'New Notice'**
  String get newNotice;

  /// No description provided for @viewAttachment.
  ///
  /// In en, this message translates to:
  /// **'View Attachment'**
  String get viewAttachment;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @studentsAudience.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsAudience;

  /// No description provided for @teachersAudience.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachersAudience;

  /// No description provided for @parentsAudience.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parentsAudience;

  /// No description provided for @markAsImportant.
  ///
  /// In en, this message translates to:
  /// **'Mark as Important'**
  String get markAsImportant;

  /// No description provided for @titleAndContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and content are required.'**
  String get titleAndContentRequired;

  /// No description provided for @deleteNotice.
  ///
  /// In en, this message translates to:
  /// **'Delete Notice'**
  String get deleteNotice;

  /// No description provided for @noticeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notice deleted'**
  String get noticeDeleted;

  /// No description provided for @routineDetails.
  ///
  /// In en, this message translates to:
  /// **'Routine Details'**
  String get routineDetails;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @allSectionsOption.
  ///
  /// In en, this message translates to:
  /// **'All Sections'**
  String get allSectionsOption;

  /// No description provided for @pleaseSelectSubjectAndTeacher.
  ///
  /// In en, this message translates to:
  /// **'Please select subject and teacher.'**
  String get pleaseSelectSubjectAndTeacher;

  /// No description provided for @routineEntryAdded.
  ///
  /// In en, this message translates to:
  /// **'Routine entry added successfully'**
  String get routineEntryAdded;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLabel(String error);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @deleteHomework.
  ///
  /// In en, this message translates to:
  /// **'Delete Homework'**
  String get deleteHomework;

  /// No description provided for @deleteHomeworkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this homework?'**
  String get deleteHomeworkConfirm;

  /// No description provided for @failedToDeleteHomework.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete homework'**
  String get failedToDeleteHomework;

  /// No description provided for @errorNoActiveUser.
  ///
  /// In en, this message translates to:
  /// **'Error: No active user found.'**
  String get errorNoActiveUser;

  /// No description provided for @attendanceSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved successfully!'**
  String get attendanceSavedSuccessfully;

  /// No description provided for @failedToSaveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Failed to save attendance.'**
  String get failedToSaveAttendance;

  /// No description provided for @saveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Save Attendance'**
  String get saveAttendance;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login'**
  String get pleaseLogin;

  /// No description provided for @noStudentsForSelection.
  ///
  /// In en, this message translates to:
  /// **'No students found for this selection'**
  String get noStudentsForSelection;

  /// No description provided for @rollNumber.
  ///
  /// In en, this message translates to:
  /// **'Roll: {roll}'**
  String rollNumber(String roll);

  /// No description provided for @marksEnteredRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter marks for at least one student'**
  String get marksEnteredRequired;

  /// No description provided for @marksSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Marks saved successfully!'**
  String get marksSavedSuccessfully;

  /// No description provided for @failedToSaveMarks.
  ///
  /// In en, this message translates to:
  /// **'Failed to save marks: {error}'**
  String failedToSaveMarks(String error);

  /// No description provided for @homeworkDetails.
  ///
  /// In en, this message translates to:
  /// **'Homework Details'**
  String get homeworkDetails;

  /// No description provided for @homeworkNotFound.
  ///
  /// In en, this message translates to:
  /// **'Homework not found'**
  String get homeworkNotFound;

  /// No description provided for @bulkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Bulk Update'**
  String get bulkUpdate;

  /// No description provided for @noStudentsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No students assigned to this homework'**
  String get noStudentsAssigned;

  /// No description provided for @updateStatusAndComment.
  ///
  /// In en, this message translates to:
  /// **'Update Status & Comment'**
  String get updateStatusAndComment;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @doneStatus.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneStatus;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @attendanceRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance Records'**
  String get attendanceRecordsTitle;

  /// No description provided for @myClassRoutine.
  ///
  /// In en, this message translates to:
  /// **'My Class Routine'**
  String get myClassRoutine;

  /// No description provided for @noRoutinesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No routines assigned for this exam.'**
  String get noRoutinesAssigned;

  /// No description provided for @noRoutinesYet.
  ///
  /// In en, this message translates to:
  /// **'No routines assigned yet.'**
  String get noRoutinesYet;

  /// No description provided for @confirmAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Attendance'**
  String get confirmAttendanceTitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String anErrorOccurred(String error);

  /// No description provided for @galleryOption.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryOption;

  /// No description provided for @cameraOption.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraOption;

  /// No description provided for @locationFetchedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location fetched successfully'**
  String get locationFetchedSuccessfully;

  /// No description provided for @errorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location'**
  String get errorGettingLocation;

  /// No description provided for @pleaseSelectClassAndSection.
  ///
  /// In en, this message translates to:
  /// **'Please select Class and Section'**
  String get pleaseSelectClassAndSection;

  /// No description provided for @profileImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated successfully'**
  String get profileImageUpdated;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String copiedToClipboard(String label);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationDetails.
  ///
  /// In en, this message translates to:
  /// **'Notification Details'**
  String get notificationDetails;

  /// No description provided for @deleteInstitution.
  ///
  /// In en, this message translates to:
  /// **'Delete Institution?'**
  String get deleteInstitution;

  /// No description provided for @deleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'Delete Subscription'**
  String get deleteSubscription;

  /// No description provided for @schoolUuidCopied.
  ///
  /// In en, this message translates to:
  /// **'School UUID copied to clipboard'**
  String get schoolUuidCopied;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @sendNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotificationTitle;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Setting up your school...'**
  String get registrationSuccessful;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deletePricingPlan.
  ///
  /// In en, this message translates to:
  /// **'Delete Pricing Plan?'**
  String get deletePricingPlan;

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit Plan'**
  String get editPlan;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @sendNotificationAction.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotificationAction;

  /// No description provided for @fillAllFieldsAction.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFieldsAction;

  /// No description provided for @sendAction.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get sendAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancelAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAction;

  /// No description provided for @noRoutinesForClass.
  ///
  /// In en, this message translates to:
  /// **'No class routine found.'**
  String get noRoutinesForClass;

  /// No description provided for @addAtLeastOneAssignment.
  ///
  /// In en, this message translates to:
  /// **'Add at least one academic assignment.'**
  String get addAtLeastOneAssignment;

  /// No description provided for @createExam.
  ///
  /// In en, this message translates to:
  /// **'Create Exam'**
  String get createExam;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @nameAndDates.
  ///
  /// In en, this message translates to:
  /// **'Name & dates'**
  String get nameAndDates;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @addedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} added'**
  String addedCount(int count);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @nextAddAssignments.
  ///
  /// In en, this message translates to:
  /// **'Next: Add Assignments'**
  String get nextAddAssignments;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @addAssignment.
  ///
  /// In en, this message translates to:
  /// **'Add Assignment'**
  String get addAssignment;

  /// No description provided for @editAssignment.
  ///
  /// In en, this message translates to:
  /// **'Edit Assignment'**
  String get editAssignment;

  /// No description provided for @examSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Exam \"{examName}\" saved successfully.'**
  String examSavedSuccessfully(String examName);

  /// No description provided for @errorNoSchoolIdAssigned.
  ///
  /// In en, this message translates to:
  /// **'Error: User has no schoolId assigned.'**
  String get errorNoSchoolIdAssigned;

  /// No description provided for @schoolRegisteredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'School registered successfully!'**
  String get schoolRegisteredSuccessfully;

  /// No description provided for @failedToRegisterSchool.
  ///
  /// In en, this message translates to:
  /// **'Failed to register school.'**
  String get failedToRegisterSchool;

  /// No description provided for @registerSchool.
  ///
  /// In en, this message translates to:
  /// **'Register School'**
  String get registerSchool;

  /// No description provided for @schoolLogo.
  ///
  /// In en, this message translates to:
  /// **'School Logo'**
  String get schoolLogo;

  /// No description provided for @registerSchoolAction.
  ///
  /// In en, this message translates to:
  /// **'REGISTER SCHOOL'**
  String get registerSchoolAction;

  /// No description provided for @completeYourSchoolProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your school profile'**
  String get completeYourSchoolProfile;

  /// No description provided for @schoolName.
  ///
  /// In en, this message translates to:
  /// **'School Name'**
  String get schoolName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @homeworkManagement.
  ///
  /// In en, this message translates to:
  /// **'Homework Management'**
  String get homeworkManagement;

  /// No description provided for @assignHomework.
  ///
  /// In en, this message translates to:
  /// **'Assign Homework'**
  String get assignHomework;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @noHomeworkFound.
  ///
  /// In en, this message translates to:
  /// **'No homework found'**
  String get noHomeworkFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @homeworkDeleted.
  ///
  /// In en, this message translates to:
  /// **'Homework deleted'**
  String get homeworkDeleted;

  /// No description provided for @teacherPrefix.
  ///
  /// In en, this message translates to:
  /// **'Teacher: '**
  String get teacherPrefix;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @duePrefix.
  ///
  /// In en, this message translates to:
  /// **'Due: '**
  String get duePrefix;

  /// No description provided for @createdPrefix.
  ///
  /// In en, this message translates to:
  /// **'Created: '**
  String get createdPrefix;

  /// No description provided for @homeworkAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Homework assigned successfully!'**
  String get homeworkAssignedSuccessfully;

  /// No description provided for @homeworkUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Homework updated successfully!'**
  String get homeworkUpdatedSuccessfully;

  /// No description provided for @pleaseSelectClassSubjectTeacher.
  ///
  /// In en, this message translates to:
  /// **'Please select class, subject and teacher'**
  String get pleaseSelectClassSubjectTeacher;

  /// No description provided for @failedToSaveHomework.
  ///
  /// In en, this message translates to:
  /// **'Failed to save homework'**
  String get failedToSaveHomework;

  /// No description provided for @addHomework.
  ///
  /// In en, this message translates to:
  /// **'Add Homework'**
  String get addHomework;

  /// No description provided for @marqueeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Marquee updated successfully'**
  String get marqueeUpdatedSuccessfully;

  /// No description provided for @addEditMarquee.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Marquee'**
  String get addEditMarquee;

  /// No description provided for @scrollType.
  ///
  /// In en, this message translates to:
  /// **'Scroll Type'**
  String get scrollType;

  /// No description provided for @speedPixelsFrame.
  ///
  /// In en, this message translates to:
  /// **'Speed (pixels/frame)'**
  String get speedPixelsFrame;

  /// No description provided for @saveMarquee.
  ///
  /// In en, this message translates to:
  /// **'Save Marquee'**
  String get saveMarquee;

  /// No description provided for @failedToUpdateMarquee.
  ///
  /// In en, this message translates to:
  /// **'Failed to update marquee'**
  String get failedToUpdateMarquee;

  /// No description provided for @marqueeTarget.
  ///
  /// In en, this message translates to:
  /// **'Marquee Target'**
  String get marqueeTarget;

  /// No description provided for @marqueeText.
  ///
  /// In en, this message translates to:
  /// **'Marquee Text'**
  String get marqueeText;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get limitReached;

  /// No description provided for @studentLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached your student limit ({count} / {max}).\n\nUpgrade your plan to add more students.'**
  String studentLimitReached(int count, int max);

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @publishStatus.
  ///
  /// In en, this message translates to:
  /// **'Publish Status'**
  String get publishStatus;

  /// No description provided for @publishedOption.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishedOption;

  /// No description provided for @unpublishedOption.
  ///
  /// In en, this message translates to:
  /// **'Unpublished'**
  String get unpublishedOption;

  /// No description provided for @noExamsFound.
  ///
  /// In en, this message translates to:
  /// **'No exams found'**
  String get noExamsFound;

  /// No description provided for @assignmentCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Assignment(s)'**
  String assignmentCountLabel(int count);

  /// No description provided for @egLabel.
  ///
  /// In en, this message translates to:
  /// **'e.g.'**
  String get egLabel;
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
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

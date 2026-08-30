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
  /// **'No students found'**
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
  /// **'View details'**
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

  /// No description provided for @monthlyAttendanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Monthly Attendance Overview'**
  String get monthlyAttendanceOverview;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String yearLabel(int year);

  /// No description provided for @topTeachers.
  ///
  /// In en, this message translates to:
  /// **'Top Teachers ({month})'**
  String topTeachers(String month);

  /// No description provided for @topStudents.
  ///
  /// In en, this message translates to:
  /// **'Top Students ({month})'**
  String topStudents(String month);

  /// No description provided for @teacherPerformance.
  ///
  /// In en, this message translates to:
  /// **'Teacher Performance'**
  String get teacherPerformance;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @attLabel.
  ///
  /// In en, this message translates to:
  /// **'Att'**
  String get attLabel;

  /// No description provided for @hwLabel.
  ///
  /// In en, this message translates to:
  /// **'HW'**
  String get hwLabel;

  /// No description provided for @onlineClasses.
  ///
  /// In en, this message translates to:
  /// **'Online Classes'**
  String get onlineClasses;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @bulkSms.
  ///
  /// In en, this message translates to:
  /// **'Bulk SMS'**
  String get bulkSms;

  /// No description provided for @expenseTracking.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracking'**
  String get expenseTracking;

  /// No description provided for @academicBooks.
  ///
  /// In en, this message translates to:
  /// **'Academic Books'**
  String get academicBooks;

  /// No description provided for @globalDashboard.
  ///
  /// In en, this message translates to:
  /// **'Global Dashboard'**
  String get globalDashboard;

  /// No description provided for @classAndSubjectSetup.
  ///
  /// In en, this message translates to:
  /// **'Class & Subject Setup'**
  String get classAndSubjectSetup;

  /// No description provided for @classesTab.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classesTab;

  /// No description provided for @sectionsTab.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get sectionsTab;

  /// No description provided for @subjectsTab.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsTab;

  /// No description provided for @noClassesYet.
  ///
  /// In en, this message translates to:
  /// **'No classes yet'**
  String get noClassesYet;

  /// No description provided for @noSectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sections yet'**
  String get noSectionsYet;

  /// No description provided for @noSubjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No subjects yet'**
  String get noSubjectsYet;

  /// No description provided for @tapPlusToAddOne.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tapPlusToAddOne;

  /// No description provided for @noneAssigned.
  ///
  /// In en, this message translates to:
  /// **'None assigned'**
  String get noneAssigned;

  /// No description provided for @addClass.
  ///
  /// In en, this message translates to:
  /// **'Add Class'**
  String get addClass;

  /// No description provided for @editClass.
  ///
  /// In en, this message translates to:
  /// **'Edit Class'**
  String get editClass;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get addSection;

  /// No description provided for @editSection.
  ///
  /// In en, this message translates to:
  /// **'Edit Section'**
  String get editSection;

  /// No description provided for @addSubject.
  ///
  /// In en, this message translates to:
  /// **'Add Subject'**
  String get addSubject;

  /// No description provided for @editSubject.
  ///
  /// In en, this message translates to:
  /// **'Edit Subject'**
  String get editSubject;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class Name'**
  String get className;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @selectClass.
  ///
  /// In en, this message translates to:
  /// **'Select Class'**
  String get selectClass;

  /// No description provided for @sectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Section Name (e.g. A)'**
  String get sectionNameHint;

  /// No description provided for @subjectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Subject Name (e.g. Mathematics)'**
  String get subjectNameHint;

  /// No description provided for @subjectCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Subject Code (e.g. MATH101)'**
  String get subjectCodeHint;

  /// No description provided for @classDetails.
  ///
  /// In en, this message translates to:
  /// **'Class Details'**
  String get classDetails;

  /// No description provided for @sectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Section Details'**
  String get sectionDetails;

  /// No description provided for @subjectDetails.
  ///
  /// In en, this message translates to:
  /// **'Subject Details'**
  String get subjectDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @sectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get sectionLabel;

  /// No description provided for @subjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subjectLabel;

  /// No description provided for @classLabel2.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel2;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{label}\"?\nThis action cannot be undone.'**
  String deleteConfirmMessage(String label);

  /// No description provided for @classAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Class added successfully'**
  String get classAddedSuccessfully;

  /// No description provided for @classUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Class updated successfully'**
  String get classUpdatedSuccessfully;

  /// No description provided for @failedToAddClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to add class'**
  String get failedToAddClass;

  /// No description provided for @failedToUpdateClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to update class'**
  String get failedToUpdateClass;

  /// No description provided for @sectionAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Section added successfully'**
  String get sectionAddedSuccessfully;

  /// No description provided for @sectionUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Section updated successfully'**
  String get sectionUpdatedSuccessfully;

  /// No description provided for @failedToAddSection.
  ///
  /// In en, this message translates to:
  /// **'Failed to add section'**
  String get failedToAddSection;

  /// No description provided for @failedToUpdateSection.
  ///
  /// In en, this message translates to:
  /// **'Failed to update section'**
  String get failedToUpdateSection;

  /// No description provided for @subjectAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Subject added successfully'**
  String get subjectAddedSuccessfully;

  /// No description provided for @subjectUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Subject updated successfully'**
  String get subjectUpdatedSuccessfully;

  /// No description provided for @failedToAddSubject.
  ///
  /// In en, this message translates to:
  /// **'Failed to add subject'**
  String get failedToAddSubject;

  /// No description provided for @failedToUpdateSubject.
  ///
  /// In en, this message translates to:
  /// **'Failed to update subject'**
  String get failedToUpdateSubject;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{label} deleted successfully'**
  String deletedSuccessfully(String label);

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete {label}'**
  String failedToDelete(String label);

  /// No description provided for @saveAssignments.
  ///
  /// In en, this message translates to:
  /// **'Save Assignments'**
  String get saveAssignments;

  /// No description provided for @assignTeachersTo.
  ///
  /// In en, this message translates to:
  /// **'Assign Teachers to {sectionName}'**
  String assignTeachersTo(String sectionName);

  /// No description provided for @updatedTeachersForSection.
  ///
  /// In en, this message translates to:
  /// **'Updated teachers for Section {sectionName}'**
  String updatedTeachersForSection(String sectionName);

  /// No description provided for @errorSavingAssignments.
  ///
  /// In en, this message translates to:
  /// **'Error saving assignments: {error}'**
  String errorSavingAssignments(String error);

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @generatePrintRoutinePdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Generate / Print Routine PDF'**
  String get generatePrintRoutinePdfTooltip;

  /// No description provided for @classRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Class Routine'**
  String get classRoutineTitle;

  /// No description provided for @classRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage weekly timetable for each class'**
  String get classRoutineSubtitle;

  /// No description provided for @noSections.
  ///
  /// In en, this message translates to:
  /// **'No Sections'**
  String get noSections;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous Day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next Day'**
  String get nextDay;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @doneCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} Done'**
  String doneCountFormat(int completed, int total);

  /// No description provided for @chooseClassToViewRoutine.
  ///
  /// In en, this message translates to:
  /// **'Choose a class above\nto view or manage the routine.'**
  String get chooseClassToViewRoutine;

  /// No description provided for @noClassesOnDay.
  ///
  /// In en, this message translates to:
  /// **'No classes on {day}'**
  String noClassesOnDay(String day);

  /// No description provided for @unknownSubject.
  ///
  /// In en, this message translates to:
  /// **'Unknown Subject'**
  String get unknownSubject;

  /// No description provided for @unknownTeacher.
  ///
  /// In en, this message translates to:
  /// **'Unknown Teacher'**
  String get unknownTeacher;

  /// No description provided for @dayAndDate.
  ///
  /// In en, this message translates to:
  /// **'Day & Date'**
  String get dayAndDate;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @attendanceStatus.
  ///
  /// In en, this message translates to:
  /// **'Attendance Status'**
  String get attendanceStatus;

  /// No description provided for @attendanceCompletedFormat.
  ///
  /// In en, this message translates to:
  /// **'Completed ({present} Present, {absent} Absent)'**
  String attendanceCompletedFormat(int present, int absent);

  /// No description provided for @attendancePendingNotTaken.
  ///
  /// In en, this message translates to:
  /// **'Pending (Not Taken)'**
  String get attendancePendingNotTaken;

  /// No description provided for @homeworkStatus.
  ///
  /// In en, this message translates to:
  /// **'Homework Status'**
  String get homeworkStatus;

  /// No description provided for @homeworkAssignedFormat.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {title}'**
  String homeworkAssignedFormat(String title);

  /// No description provided for @manageClass.
  ///
  /// In en, this message translates to:
  /// **'Manage Class'**
  String get manageClass;

  /// No description provided for @deleteRoutineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this routine entry?'**
  String get deleteRoutineConfirm;

  /// No description provided for @attendanceSummaryShort.
  ///
  /// In en, this message translates to:
  /// **'Attendance: {present} P / {absent} A'**
  String attendanceSummaryShort(int present, int absent);

  /// No description provided for @attendanceDoneShort.
  ///
  /// In en, this message translates to:
  /// **'Attendance: Done'**
  String get attendanceDoneShort;

  /// No description provided for @attendancePendingShort.
  ///
  /// In en, this message translates to:
  /// **'Attendance: Pending'**
  String get attendancePendingShort;

  /// No description provided for @hwSummaryShort.
  ///
  /// In en, this message translates to:
  /// **'HW: {title}'**
  String hwSummaryShort(String title);

  /// No description provided for @noHwShort.
  ///
  /// In en, this message translates to:
  /// **'No HW'**
  String get noHwShort;

  /// No description provided for @roomNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Room {roomNumber}'**
  String roomNumberFormat(String roomNumber);

  /// No description provided for @donePlusHw.
  ///
  /// In en, this message translates to:
  /// **'Done + HW'**
  String get donePlusHw;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @hwAdded.
  ///
  /// In en, this message translates to:
  /// **'HW Added'**
  String get hwAdded;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @editRoutineEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Routine Entry'**
  String get editRoutineEntry;

  /// No description provided for @addRoutineEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Routine Entry'**
  String get addRoutineEntry;

  /// No description provided for @updateApplySelectedDays.
  ///
  /// In en, this message translates to:
  /// **'Update and apply to selected days'**
  String get updateApplySelectedDays;

  /// No description provided for @updateDetailsBelow.
  ///
  /// In en, this message translates to:
  /// **'Update the details below'**
  String get updateDetailsBelow;

  /// No description provided for @selectDaysFillDetails.
  ///
  /// In en, this message translates to:
  /// **'Select days & fill in the details'**
  String get selectDaysFillDetails;

  /// No description provided for @selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select Day'**
  String get selectDay;

  /// No description provided for @countSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String countSelected(int count);

  /// No description provided for @noneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get noneSelected;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @chooseSubject.
  ///
  /// In en, this message translates to:
  /// **'Choose a subject'**
  String get chooseSubject;

  /// No description provided for @searchSubject.
  ///
  /// In en, this message translates to:
  /// **'Search subject...'**
  String get searchSubject;

  /// No description provided for @assignTeacher.
  ///
  /// In en, this message translates to:
  /// **'Assign a teacher'**
  String get assignTeacher;

  /// No description provided for @searchTeacher.
  ///
  /// In en, this message translates to:
  /// **'Search teacher...'**
  String get searchTeacher;

  /// No description provided for @timeSlot.
  ///
  /// In en, this message translates to:
  /// **'Time Slot'**
  String get timeSlot;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @roomNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Room Number (Optional)'**
  String get roomNumberOptional;

  /// No description provided for @roomNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 101, Lab-A'**
  String get roomNumberHint;

  /// No description provided for @updateSaveEntriesFormat.
  ///
  /// In en, this message translates to:
  /// **'Update & Save {count} Entries'**
  String updateSaveEntriesFormat(int count);

  /// No description provided for @updateEntry.
  ///
  /// In en, this message translates to:
  /// **'Update Entry'**
  String get updateEntry;

  /// No description provided for @saveEntriesFormat.
  ///
  /// In en, this message translates to:
  /// **'Save {count} Entries'**
  String saveEntriesFormat(int count);

  /// No description provided for @saveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get saveEntry;

  /// No description provided for @pleaseSelectAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one day.'**
  String get pleaseSelectAtLeastOneDay;

  /// No description provided for @routineEntriesUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} routine entries updated & saved successfully!'**
  String routineEntriesUpdatedSuccess(int count);

  /// No description provided for @routineEntriesSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} routine entries saved successfully!'**
  String routineEntriesSavedSuccess(int count);

  /// No description provided for @studentAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Attendance'**
  String get studentAttendanceTitle;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @searchByStudentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by Student Name...'**
  String get searchByStudentNameHint;

  /// No description provided for @allClassHint.
  ///
  /// In en, this message translates to:
  /// **'All Class'**
  String get allClassHint;

  /// No description provided for @allSectionHint.
  ///
  /// In en, this message translates to:
  /// **'All Section'**
  String get allSectionHint;

  /// No description provided for @allSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'All Subject'**
  String get allSubjectHint;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get allDates;

  /// No description provided for @totalCountFormat.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}'**
  String totalCountFormat(int total);

  /// No description provided for @showingCountFormat.
  ///
  /// In en, this message translates to:
  /// **'Showing: {count} / {total}'**
  String showingCountFormat(int count, int total);

  /// No description provided for @noRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No records found'**
  String get noRecordsFound;

  /// No description provided for @noStatusRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No {status} records found'**
  String noStatusRecordsFound(String status);

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get statusAll;

  /// No description provided for @statusPresent.
  ///
  /// In en, this message translates to:
  /// **'PRESENT'**
  String get statusPresent;

  /// No description provided for @statusAbsent.
  ///
  /// In en, this message translates to:
  /// **'ABSENT'**
  String get statusAbsent;

  /// No description provided for @statusLate.
  ///
  /// In en, this message translates to:
  /// **'LATE'**
  String get statusLate;

  /// No description provided for @statusLeave.
  ///
  /// In en, this message translates to:
  /// **'LEAVE'**
  String get statusLeave;

  /// No description provided for @noAttendanceRecordsToExport.
  ///
  /// In en, this message translates to:
  /// **'No attendance records to export'**
  String get noAttendanceRecordsToExport;

  /// No description provided for @failedToGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate PDF: {error}'**
  String failedToGeneratePdf(String error);

  /// No description provided for @unknownStudent.
  ///
  /// In en, this message translates to:
  /// **'Unknown Student'**
  String get unknownStudent;

  /// No description provided for @classAndSectionFormat.
  ///
  /// In en, this message translates to:
  /// **'{className} • Sec {sectionName}'**
  String classAndSectionFormat(String className, String sectionName);

  /// No description provided for @rollNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Roll #{rollNumber}'**
  String rollNumberFormat(String rollNumber);

  /// No description provided for @teacherLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherLabel;

  /// No description provided for @roomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomLabel;

  /// No description provided for @recordIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Record ID'**
  String get recordIdLabel;

  /// No description provided for @teacherAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher Attendance'**
  String get teacherAttendanceTitle;

  /// No description provided for @searchByTeacherNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by Teacher Name...'**
  String get searchByTeacherNameHint;

  /// No description provided for @dateRangeFormat.
  ///
  /// In en, this message translates to:
  /// **'Date: {start} to {end}'**
  String dateRangeFormat(String start, String end);

  /// No description provided for @dateAllTime.
  ///
  /// In en, this message translates to:
  /// **'Date: All Time'**
  String get dateAllTime;

  /// No description provided for @resultsForFormat.
  ///
  /// In en, this message translates to:
  /// **'Results for \'{query}\''**
  String resultsForFormat(String query);

  /// No description provided for @statusClockIn.
  ///
  /// In en, this message translates to:
  /// **'CLOCK-IN'**
  String get statusClockIn;

  /// No description provided for @statusClockOut.
  ///
  /// In en, this message translates to:
  /// **'CLOCK-OUT'**
  String get statusClockOut;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get statusUnknown;

  /// No description provided for @inTime.
  ///
  /// In en, this message translates to:
  /// **'In Time'**
  String get inTime;

  /// No description provided for @outTime.
  ///
  /// In en, this message translates to:
  /// **'Out Time'**
  String get outTime;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @fetchingLabel.
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get fetchingLabel;

  /// No description provided for @invalidCoords.
  ///
  /// In en, this message translates to:
  /// **'Invalid coords'**
  String get invalidCoords;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @createAttendance.
  ///
  /// In en, this message translates to:
  /// **'Create Attendance'**
  String get createAttendance;

  /// No description provided for @pleaseSelectTeacher.
  ///
  /// In en, this message translates to:
  /// **'Please select a teacher'**
  String get pleaseSelectTeacher;

  /// No description provided for @attendanceCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Attendance created successfully'**
  String get attendanceCreatedSuccess;

  /// No description provided for @selectTeacher.
  ///
  /// In en, this message translates to:
  /// **'Select Teacher'**
  String get selectTeacher;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeLabel;

  /// No description provided for @timeNotRequiredInfo.
  ///
  /// In en, this message translates to:
  /// **'Start & End times are not required for {status}.'**
  String timeNotRequiredInfo(String status);

  /// No description provided for @submitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButton;

  /// No description provided for @onlineClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'Online Classes'**
  String get onlineClassesTitle;

  /// No description provided for @deleteClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Class'**
  String get deleteClassTitle;

  /// No description provided for @deleteClassConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this class?'**
  String get deleteClassConfirmation;

  /// No description provided for @classDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Class deleted successfully'**
  String get classDeletedSuccess;

  /// No description provided for @failedToDeleteClass.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete class'**
  String get failedToDeleteClass;

  /// No description provided for @couldNotLaunchUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {url}'**
  String couldNotLaunchUrl(String url);

  /// No description provided for @allClassesAndSections.
  ///
  /// In en, this message translates to:
  /// **'All Classes & Sections'**
  String get allClassesAndSections;

  /// No description provided for @newClass.
  ///
  /// In en, this message translates to:
  /// **'New Class'**
  String get newClass;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

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

  /// No description provided for @inMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count}m'**
  String inMinutes(int count);

  /// No description provided for @inHours.
  ///
  /// In en, this message translates to:
  /// **'in {count}h'**
  String inHours(int count);

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'in {count}d'**
  String inDays(int count);

  /// No description provided for @googleMeet.
  ///
  /// In en, this message translates to:
  /// **'Google Meet'**
  String get googleMeet;

  /// No description provided for @zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// No description provided for @msTeams.
  ///
  /// In en, this message translates to:
  /// **'MS Teams'**
  String get msTeams;

  /// No description provided for @webex.
  ///
  /// In en, this message translates to:
  /// **'Webex'**
  String get webex;

  /// No description provided for @onlineMeeting.
  ///
  /// In en, this message translates to:
  /// **'Online Meeting'**
  String get onlineMeeting;

  /// No description provided for @unableToLoadClasses.
  ///
  /// In en, this message translates to:
  /// **'Unable to Load Classes'**
  String get unableToLoadClasses;

  /// No description provided for @unableToLoadClassesMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the server. Please check your network connection and try again.'**
  String get unableToLoadClassesMessage;

  /// No description provided for @noOnlineClassesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No Online Classes Scheduled'**
  String get noOnlineClassesScheduled;

  /// No description provided for @noOnlineClassesAdminMessage.
  ///
  /// In en, this message translates to:
  /// **'There are currently no online classes scheduled. Tap below to schedule a new live class or pull down to refresh.'**
  String get noOnlineClassesAdminMessage;

  /// No description provided for @noOnlineClassesStudentMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no upcoming online classes scheduled at this time. Pull down to refresh or check back later.'**
  String get noOnlineClassesStudentMessage;

  /// No description provided for @scheduleClass.
  ///
  /// In en, this message translates to:
  /// **'Schedule Class'**
  String get scheduleClass;

  /// No description provided for @statusLiveNow.
  ///
  /// In en, this message translates to:
  /// **'LIVE NOW'**
  String get statusLiveNow;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @statusLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get statusLive;

  /// No description provided for @classEnded.
  ///
  /// In en, this message translates to:
  /// **'Class Ended'**
  String get classEnded;

  /// No description provided for @joinLiveClass.
  ///
  /// In en, this message translates to:
  /// **'Join Live Class'**
  String get joinLiveClass;

  /// No description provided for @joinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get joinMeeting;

  /// No description provided for @newBook.
  ///
  /// In en, this message translates to:
  /// **'New Book'**
  String get newBook;

  /// No description provided for @allBooksTab.
  ///
  /// In en, this message translates to:
  /// **'📚  All Books'**
  String get allBooksTab;

  /// No description provided for @issuedTab.
  ///
  /// In en, this message translates to:
  /// **'🔖  Issued'**
  String get issuedTab;

  /// No description provided for @schoolLibrary.
  ///
  /// In en, this message translates to:
  /// **'School Library'**
  String get schoolLibrary;

  /// No description provided for @manageBooksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage books & track issues'**
  String get manageBooksSubtitle;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @issuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issuedLabel;

  /// No description provided for @returnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returnedLabel;

  /// No description provided for @overdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueLabel;

  /// No description provided for @searchBookHint.
  ///
  /// In en, this message translates to:
  /// **'Search title or author…'**
  String get searchBookHint;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @booksFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book found} other{{count} books found}}'**
  String booksFoundCount(int count);

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or category'**
  String get tryDifferentSearch;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get filterIssued;

  /// No description provided for @filterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// No description provided for @filterReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get filterReturned;

  /// No description provided for @noFilteredBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No {filter} books found'**
  String noFilteredBooksFound(String filter);

  /// No description provided for @noBooksIssuedTitle.
  ///
  /// In en, this message translates to:
  /// **'No Books Issued'**
  String get noBooksIssuedTitle;

  /// No description provided for @noBooksIssuedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All books are currently available.'**
  String get noBooksIssuedSubtitle;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// No description provided for @sectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get sectionOverdue;

  /// No description provided for @sectionCurrentlyIssued.
  ///
  /// In en, this message translates to:
  /// **'Currently Issued'**
  String get sectionCurrentlyIssued;

  /// No description provided for @sectionReturnedHistory.
  ///
  /// In en, this message translates to:
  /// **'Returned History'**
  String get sectionReturnedHistory;

  /// No description provided for @sectionLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Sec'**
  String get sectionLabelShort;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDate;

  /// No description provided for @returnDate.
  ///
  /// In en, this message translates to:
  /// **'Return Date'**
  String get returnDate;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @returnedOn.
  ///
  /// In en, this message translates to:
  /// **'Returned on {date}'**
  String returnedOn(String date);

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String daysOverdue(int count);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today!'**
  String get dueToday;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day remaining} other{{count} days remaining}}'**
  String daysRemaining(int count);

  /// No description provided for @returnBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Book'**
  String get returnBookTitle;

  /// No description provided for @returnBookConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark \"{title}\" as returned by {student}?'**
  String returnBookConfirmation(String title, String student);

  /// No description provided for @returnBookButton.
  ///
  /// In en, this message translates to:
  /// **'Return Book'**
  String get returnBookButton;

  /// No description provided for @markAsReturned.
  ///
  /// In en, this message translates to:
  /// **'Mark as Returned'**
  String get markAsReturned;

  /// No description provided for @bookReturnedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Book marked as returned successfully!'**
  String get bookReturnedSuccess;

  /// No description provided for @addBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get addBookTitle;

  /// No description provided for @editBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Book'**
  String get editBookTitle;

  /// No description provided for @basicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get basicDetails;

  /// No description provided for @bookTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Book Title'**
  String get bookTitleLabel;

  /// No description provided for @bookTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Fundamentals of Physics'**
  String get bookTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @authorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Author Name'**
  String get authorNameLabel;

  /// No description provided for @authorNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., David Halliday'**
  String get authorNameHint;

  /// No description provided for @authorRequired.
  ///
  /// In en, this message translates to:
  /// **'Author is required'**
  String get authorRequired;

  /// No description provided for @isbnNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'ISBN Number'**
  String get isbnNumberLabel;

  /// No description provided for @isbnNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 978-0471320005'**
  String get isbnNumberHint;

  /// No description provided for @isbnRequired.
  ///
  /// In en, this message translates to:
  /// **'ISBN is required'**
  String get isbnRequired;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get additionalInfo;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @selectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get selectCategoryError;

  /// No description provided for @coverImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover Image URL or Path'**
  String get coverImageLabel;

  /// No description provided for @coverImageHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/image.jpg'**
  String get coverImageHint;

  /// No description provided for @coverImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Cover image is required'**
  String get coverImageRequired;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional book description'**
  String get descriptionHint;

  /// No description provided for @saveBookButton.
  ///
  /// In en, this message translates to:
  /// **'Save Book'**
  String get saveBookButton;

  /// No description provided for @bookAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Book added successfully!'**
  String get bookAddedSuccess;

  /// No description provided for @bookUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Book updated successfully!'**
  String get bookUpdatedSuccess;

  /// No description provided for @generateRandomCover.
  ///
  /// In en, this message translates to:
  /// **'Generate Random Cover'**
  String get generateRandomCover;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takeAPhoto;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String failedToUploadImage(String error);

  /// No description provided for @deleteBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Book?'**
  String get deleteBookTitle;

  /// No description provided for @deleteBookConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String deleteBookConfirmation(String title);

  /// No description provided for @bookDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Book deleted successfully!'**
  String get bookDeletedSuccess;

  /// No description provided for @issueBookToTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Book To'**
  String get issueBookToTitle;

  /// No description provided for @howIdentifyStudent.
  ///
  /// In en, this message translates to:
  /// **'How would you like to identify the student?'**
  String get howIdentifyStudent;

  /// No description provided for @scanIdCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan ID Card'**
  String get scanIdCardTitle;

  /// No description provided for @scanIdCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the camera to scan student\'s barcode'**
  String get scanIdCardSubtitle;

  /// No description provided for @selectStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Student'**
  String get selectStudentTitle;

  /// No description provided for @selectStudentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search and pick from the student list'**
  String get selectStudentSubtitle;

  /// No description provided for @setDueDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Due Date'**
  String get setDueDateTitle;

  /// No description provided for @chooseWhenReturn.
  ///
  /// In en, this message translates to:
  /// **'Choose when the book must be returned'**
  String get chooseWhenReturn;

  /// No description provided for @plusDays.
  ///
  /// In en, this message translates to:
  /// **'+{count} days'**
  String plusDays(int count);

  /// No description provided for @confirmAndIssue.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Issue'**
  String get confirmAndIssue;

  /// No description provided for @bookIssuedSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Issued!'**
  String get bookIssuedSuccessTitle;

  /// No description provided for @bookIssuedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" has been successfully assigned.'**
  String bookIssuedSuccessMessage(String title);

  /// No description provided for @studentLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentLabel;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueLabel;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @descriptionHeader.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionHeader;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available for this book.'**
  String get noDescriptionAvailable;

  /// No description provided for @requestIssueButton.
  ///
  /// In en, this message translates to:
  /// **'Request Issue'**
  String get requestIssueButton;

  /// No description provided for @bookCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Book Currently Unavailable'**
  String get bookCurrentlyUnavailable;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get statusUnavailable;

  /// No description provided for @statusNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get statusNotAvailable;

  /// No description provided for @searchStudentHint.
  ///
  /// In en, this message translates to:
  /// **'Search student name from server…'**
  String get searchStudentHint;

  /// No description provided for @studentsFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student found} other{{count} students found}}'**
  String studentsFoundCount(int count);

  /// No description provided for @bookRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Requests'**
  String get bookRequestsTitle;

  /// No description provided for @noPendingBookRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending book requests.'**
  String get noPendingBookRequests;

  /// No description provided for @requestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request declined.'**
  String get requestDeclined;

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted!'**
  String get requestAccepted;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// No description provided for @scanIdCardScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan ID Card'**
  String get scanIdCardScreenTitle;

  /// No description provided for @pointCameraInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the student\'s\nID card barcode'**
  String get pointCameraInstruction;

  /// No description provided for @idCardScannedTitle.
  ///
  /// In en, this message translates to:
  /// **'ID Card Scanned!'**
  String get idCardScannedTitle;

  /// No description provided for @confirmStudentDetailsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the student details below.'**
  String get confirmStudentDetailsMessage;

  /// No description provided for @studentIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentIdLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @rescanButton.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescanButton;

  /// No description provided for @bulkSmsBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk SMS Broadcast'**
  String get bulkSmsBroadcastTitle;

  /// No description provided for @bulkSmsBroadcastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach parents & guardians instantly'**
  String get bulkSmsBroadcastSubtitle;

  /// No description provided for @selectionActions.
  ///
  /// In en, this message translates to:
  /// **'Selection Actions'**
  String get selectionActions;

  /// No description provided for @selectAllWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Select All with Phone'**
  String get selectAllWithPhone;

  /// No description provided for @selectAllVisible.
  ///
  /// In en, this message translates to:
  /// **'Select All Visible'**
  String get selectAllVisible;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get statSelected;

  /// No description provided for @statSmsReady.
  ///
  /// In en, this message translates to:
  /// **'SMS Ready'**
  String get statSmsReady;

  /// No description provided for @statMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get statMissing;

  /// No description provided for @searchStudentByRollHint.
  ///
  /// In en, this message translates to:
  /// **'Search student by name or roll...'**
  String get searchStudentByRollHint;

  /// No description provided for @filterChipAllCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String filterChipAllCount(int count);

  /// No description provided for @filterChipSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected ({count})'**
  String filterChipSelectedCount(int count);

  /// No description provided for @filterChipWithPhoneCount.
  ///
  /// In en, this message translates to:
  /// **'With Phone ({count})'**
  String filterChipWithPhoneCount(int count);

  /// No description provided for @filterChipNoPhoneCount.
  ///
  /// In en, this message translates to:
  /// **'No Phone ({count})'**
  String filterChipNoPhoneCount(int count);

  /// No description provided for @noStudentsSelectedYet.
  ///
  /// In en, this message translates to:
  /// **'No students selected yet.'**
  String get noStudentsSelectedYet;

  /// No description provided for @noStudentsMatchingFilter.
  ///
  /// In en, this message translates to:
  /// **'No students found matching filter.'**
  String get noStudentsMatchingFilter;

  /// No description provided for @noContactNumberRegistered.
  ///
  /// In en, this message translates to:
  /// **'No contact number registered'**
  String get noContactNumberRegistered;

  /// No description provided for @doesNotHaveContact.
  ///
  /// In en, this message translates to:
  /// **'{name} does not have a contact number.'**
  String doesNotHaveContact(String name);

  /// No description provided for @normalSmsDirect.
  ///
  /// In en, this message translates to:
  /// **'Normal SMS (Direct)'**
  String get normalSmsDirect;

  /// No description provided for @maskSmsCare.
  ///
  /// In en, this message translates to:
  /// **'Mask SMS (School Care)'**
  String get maskSmsCare;

  /// No description provided for @maskedSchoolCare.
  ///
  /// In en, this message translates to:
  /// **'Masked (School Care)'**
  String get maskedSchoolCare;

  /// No description provided for @normalSmsDirectValue.
  ///
  /// In en, this message translates to:
  /// **'Normal SMS (Direct)'**
  String get normalSmsDirectValue;

  /// No description provided for @quickTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get quickTemplatesTitle;

  /// No description provided for @quickTemplateInsertTooltip.
  ///
  /// In en, this message translates to:
  /// **'Insert Quick Template'**
  String get quickTemplateInsertTooltip;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message or pick a template above...'**
  String get typeMessageHint;

  /// No description provided for @selectedRecipientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected recipient(s)'**
  String selectedRecipientsCount(int count);

  /// No description provided for @charsAndSmsCount.
  ///
  /// In en, this message translates to:
  /// **'{chars}/{maxChars} chars ({parts} SMS)'**
  String charsAndSmsCount(int chars, int maxChars, int parts);

  /// No description provided for @broadcastingSms.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting SMS...'**
  String get broadcastingSms;

  /// No description provided for @sendBulkSmsButton.
  ///
  /// In en, this message translates to:
  /// **'Send Bulk SMS ({count})'**
  String sendBulkSmsButton(int count);

  /// No description provided for @confirmBulkSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Bulk SMS Broadcast'**
  String get confirmBulkSmsTitle;

  /// No description provided for @reviewCampaignDetails.
  ///
  /// In en, this message translates to:
  /// **'Review campaign details before sending'**
  String get reviewCampaignDetails;

  /// No description provided for @recipientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipients'**
  String get recipientsLabel;

  /// No description provided for @parentsGuardiansCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Parents/Guardians'**
  String parentsGuardiansCount(int count);

  /// No description provided for @smsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS Type'**
  String get smsTypeLabel;

  /// No description provided for @estimatedSmsCredits.
  ///
  /// In en, this message translates to:
  /// **'Estimated SMS Credits'**
  String get estimatedSmsCredits;

  /// No description provided for @smsCreditsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{totalCredits} Credits ({partsPerMsg} part × {recipients} rec.)'**
  String smsCreditsBreakdown(int totalCredits, int partsPerMsg, int recipients);

  /// No description provided for @messagePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Message Preview:'**
  String get messagePreviewLabel;

  /// No description provided for @sendNowButton.
  ///
  /// In en, this message translates to:
  /// **'Send Now'**
  String get sendNowButton;

  /// No description provided for @selectAtLeastOneStudent.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one student recipient.'**
  String get selectAtLeastOneStudent;

  /// No description provided for @enterSmsMessageToBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Please enter an SMS message to broadcast.'**
  String get enterSmsMessageToBroadcast;

  /// No description provided for @noSelectedStudentsHavePhone.
  ///
  /// In en, this message translates to:
  /// **'None of the selected students have a valid phone number.'**
  String get noSelectedStudentsHavePhone;

  /// No description provided for @bulkSmsSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bulk SMS broadcast sent to {count} recipients!'**
  String bulkSmsSentSuccess(int count);

  /// No description provided for @bulkSmsSentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send SMS. Please check credentials or API gateway.'**
  String get bulkSmsSentFailed;

  /// No description provided for @templateSchoolClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'School Closed'**
  String get templateSchoolClosedTitle;

  /// No description provided for @templateSchoolClosedText.
  ///
  /// In en, this message translates to:
  /// **'Dear Parent, the school will remain closed on [Date] due to [Reason]. Regular classes will resume on [Date].'**
  String get templateSchoolClosedText;

  /// No description provided for @templateExamReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Reminder'**
  String get templateExamReminderTitle;

  /// No description provided for @templateExamReminderText.
  ///
  /// In en, this message translates to:
  /// **'Dear Parent, term examinations begin on [Date]. Please ensure your child carries their admit card and arrives on time.'**
  String get templateExamReminderText;

  /// No description provided for @templateFeeDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Fee Due Notice'**
  String get templateFeeDueTitle;

  /// No description provided for @templateFeeDueText.
  ///
  /// In en, this message translates to:
  /// **'Dear Parent, this is a reminder regarding pending school fees for [Month]. Please clear the dues at the school office.'**
  String get templateFeeDueText;

  /// No description provided for @templatePtmTitle.
  ///
  /// In en, this message translates to:
  /// **'PTM Meeting'**
  String get templatePtmTitle;

  /// No description provided for @templatePtmText.
  ///
  /// In en, this message translates to:
  /// **'Dear Parent, the Parent-Teacher Meeting (PTM) is scheduled on [Date] at [Time]. Your presence is highly requested.'**
  String get templatePtmText;

  /// No description provided for @templateEmergencyAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get templateEmergencyAlertTitle;

  /// No description provided for @templateEmergencyAlertText.
  ///
  /// In en, this message translates to:
  /// **'Urgent: Due to unavoidable circumstances, classes for today are suspended. Please arrange to pick up your child.'**
  String get templateEmergencyAlertText;

  /// No description provided for @schoolWalletAndExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'School Wallet & Expenses'**
  String get schoolWalletAndExpensesTitle;

  /// No description provided for @retryFetching.
  ///
  /// In en, this message translates to:
  /// **'Retry Fetching'**
  String get retryFetching;

  /// No description provided for @noMatchingTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions found.'**
  String get noMatchingTransactionsFound;

  /// No description provided for @noIncomeRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No fee / income records found.'**
  String get noIncomeRecordsFound;

  /// No description provided for @noExpenseRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No expense records found.'**
  String get noExpenseRecordsFound;

  /// No description provided for @noRecentTransactionsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions recorded.'**
  String get noRecentTransactionsRecorded;

  /// No description provided for @tapToAddTransactionHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"+ Add Money\" or \"- Add Expense\" to record a transaction.'**
  String get tapToAddTransactionHint;

  /// No description provided for @netBalanceMonth.
  ///
  /// In en, this message translates to:
  /// **'Net Balance • {month} {year}'**
  String netBalanceMonth(String month, String year);

  /// No description provided for @netBalanceYear.
  ///
  /// In en, this message translates to:
  /// **'Net Balance • FY {year}'**
  String netBalanceYear(String year);

  /// No description provided for @availableTreasuryBalanceAllTime.
  ///
  /// In en, this message translates to:
  /// **'Available Treasury Balance (All-Time)'**
  String get availableTreasuryBalanceAllTime;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @fyYear.
  ///
  /// In en, this message translates to:
  /// **'FY {year}'**
  String fyYear(String year);

  /// No description provided for @allTimeTab.
  ///
  /// In en, this message translates to:
  /// **'All-Time'**
  String get allTimeTab;

  /// No description provided for @surplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get surplus;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanced;

  /// No description provided for @deficit.
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get deficit;

  /// No description provided for @totalInflow.
  ///
  /// In en, this message translates to:
  /// **'Total Inflow'**
  String get totalInflow;

  /// No description provided for @totalOutflow.
  ///
  /// In en, this message translates to:
  /// **'Total Outflow'**
  String get totalOutflow;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Records'**
  String recordsCount(int count);

  /// No description provided for @searchTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, category, voucher...'**
  String get searchTransactionsHint;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @feesAndIncomeFilter.
  ///
  /// In en, this message translates to:
  /// **'+ Fees & Income'**
  String get feesAndIncomeFilter;

  /// No description provided for @expensesFilter.
  ///
  /// In en, this message translates to:
  /// **'- Expenses'**
  String get expensesFilter;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @academicBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic Books'**
  String get academicBooksTitle;

  /// No description provided for @academicBooksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Digital soft copies by class & subject'**
  String get academicBooksSubtitle;

  /// No description provided for @deleteBookConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently removed.'**
  String deleteBookConfirmMessage(String title);

  /// No description provided for @noPdfAvailableForBook.
  ///
  /// In en, this message translates to:
  /// **'No PDF available for this book'**
  String get noPdfAvailableForBook;

  /// No description provided for @searchBooksOrSubjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Search books or subjects…'**
  String get searchBooksOrSubjectsHint;

  /// No description provided for @addBookButton.
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get addBookButton;

  /// No description provided for @totalBooksStat.
  ///
  /// In en, this message translates to:
  /// **'Total Books'**
  String get totalBooksStat;

  /// No description provided for @classesStat.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get classesStat;

  /// No description provided for @subjectsStat.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjectsStat;

  /// No description provided for @noBooksFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Books Found'**
  String get noBooksFoundTitle;

  /// No description provided for @noBooksMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No books match your search.'**
  String get noBooksMatchSearch;

  /// No description provided for @noAcademicBooksUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'No academic books have been uploaded yet.'**
  String get noAcademicBooksUploadedYet;

  /// No description provided for @failedToUpdateProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile image'**
  String get failedToUpdateProfileImage;

  /// No description provided for @schoolAvatarUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'School avatar updated successfully'**
  String get schoolAvatarUpdatedSuccessfully;

  /// No description provided for @failedToUpdateSchoolAvatar.
  ///
  /// In en, this message translates to:
  /// **'Failed to update school avatar'**
  String get failedToUpdateSchoolAvatar;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @schoolProfileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'School profile updated successfully'**
  String get schoolProfileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateSchoolProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update school profile'**
  String get failedToUpdateSchoolProfile;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @schoolNameLabel.
  ///
  /// In en, this message translates to:
  /// **'School Name'**
  String get schoolNameLabel;

  /// No description provided for @schoolEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'School Email'**
  String get schoolEmailLabel;

  /// No description provided for @schoolPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'School Phone'**
  String get schoolPhoneLabel;

  /// No description provided for @schoolAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'School Address'**
  String get schoolAddressLabel;

  /// No description provided for @accountRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Role'**
  String get accountRoleLabel;

  /// No description provided for @rollNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Roll Number'**
  String get rollNumberLabel;

  /// No description provided for @designationLabel.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get designationLabel;

  /// No description provided for @organizationAdmins.
  ///
  /// In en, this message translates to:
  /// **'Organization Admins'**
  String get organizationAdmins;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @accountActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Active'**
  String get accountActiveStatus;

  /// No description provided for @accountInactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Inactive'**
  String get accountInactiveStatus;

  /// No description provided for @noAdminsFound.
  ///
  /// In en, this message translates to:
  /// **'No admins found'**
  String get noAdminsFound;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @changeToTeacherTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change to Teacher'**
  String get changeToTeacherTooltip;

  /// No description provided for @changeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRoleTitle;

  /// No description provided for @changeRoleConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Change {name}\'s role from {oldRole} to {newRole}?\n\nThis will remove their admin privileges.'**
  String changeRoleConfirmationMessage(
    String name,
    String oldRole,
    String newRole,
  );

  /// No description provided for @nowATeacherMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now a Teacher'**
  String nowATeacherMessage(String name);

  /// No description provided for @failedToChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Failed to change role'**
  String get failedToChangeRole;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and all data.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data will be deleted from our servers.'**
  String get deleteAccountWarning;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get typeDeleteToConfirm;

  /// No description provided for @deleteUppercase.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteUppercase;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @myAttendance.
  ///
  /// In en, this message translates to:
  /// **'My Attendance'**
  String get myAttendance;

  /// No description provided for @filterAttendance.
  ///
  /// In en, this message translates to:
  /// **'Filter Attendance'**
  String get filterAttendance;

  /// No description provided for @noAttendanceRecordsFoundFilter.
  ///
  /// In en, this message translates to:
  /// **'No attendance records found for the selected filters.'**
  String get noAttendanceRecordsFoundFilter;

  /// No description provided for @academicSchedule.
  ///
  /// In en, this message translates to:
  /// **'Academic Schedule'**
  String get academicSchedule;

  /// No description provided for @noScheduleYet.
  ///
  /// In en, this message translates to:
  /// **'No Schedule Yet'**
  String get noScheduleYet;

  /// No description provided for @noScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your weekly class routine will appear here.'**
  String get noScheduleSubtitle;

  /// No description provided for @allAssignmentsDone.
  ///
  /// In en, this message translates to:
  /// **'All Assignments Done'**
  String get allAssignmentsDone;

  /// No description provided for @noPendingHomeworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No pending homework for your class.'**
  String get noPendingHomeworkSubtitle;

  /// No description provided for @teacherNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Teacher Not Assigned'**
  String get teacherNotAssigned;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @submittedStatus.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedStatus;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;
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

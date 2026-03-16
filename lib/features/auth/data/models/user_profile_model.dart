
class UserProfile {
  String id;
  String companyId;
  String branchId;
  String departmentName;
  String departmentId;
  String employeeCode;
  String scheduleUID;
  bool allowAppAttendance;
  String firstname;
  String lastName;
  String gender;
  String joiningDate;
  String emailAddress;
  String mobileNo;
  String birthday;
  String employmentstatus;
  String employmenttype;
  List<dynamic> leavePrivileges;
  String status;
  bool is_eligible_for_multiple_worklog;
  String? permanentAddress;
  String address1;
  String address2;
  String city;
  String postCode;
  String country;
  String avatar;
  String? designation;
  Roll roleInfo;
  Template? template;
  bool locationRestriction;
  bool flexibilityStatus;
  bool isTracking;
  int flexibilityLimit;
  String workspace;
  BranchDetails branchDetails;

  UserProfile({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.employeeCode,
    required this.departmentName,
    required this.departmentId,
    required this.scheduleUID,
    required this.allowAppAttendance,
    required this.firstname,
    required this.lastName,
    required this.gender,
    required this.joiningDate,
    required this.emailAddress,
    required this.mobileNo,
    required this.birthday,
    required this.employmentstatus,
    required this.employmenttype,
    required this.leavePrivileges,
    required this.status,
    required this.is_eligible_for_multiple_worklog,
    this.permanentAddress,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postCode,
    required this.country,
    required this.avatar,
    this.designation,
    required this.roleInfo,
    required this.locationRestriction,
    required this.flexibilityLimit,
    required this.flexibilityStatus,
    required this.isTracking,
    required this.workspace,
    required this.branchDetails,
    this.template,
  });


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'branchId': branchId,
      'employeeCode': employeeCode,
      'departmentName': departmentName,
      'departmentId': departmentId,
      'scheduleUID': scheduleUID,
      'allowAppAttendance': allowAppAttendance,
      'firstname': firstname,
      'lastName': lastName,
      'gender': gender,
      'joining_date': joiningDate,
      'emailAddress': emailAddress,
      'mobileNo': mobileNo,
      'birthday': birthday,
      'employmentstatus': employmentstatus,
      'employmenttype': employmenttype,
      'leavePrivileges': leavePrivileges,
      'status': status,
      'is_eligible_for_multiple_worklog': is_eligible_for_multiple_worklog,
      'permanent_address': permanentAddress,
      'address_line_1': address1,
      'address_line_2': address2,
      'city': city,
      'post_code': postCode,
      'country': country,
      'avatar': avatar,
      'designation': designation,
      'roleInfo': roleInfo.toJson(),
      'template': template?.toJson(),
      'locationRestriction': locationRestriction,
      'attendence_flexibility_status': flexibilityStatus,
      'tracking': isTracking,
      'flexibility_limit': flexibilityLimit,
      "branch_details": branchDetails.toJson(),
      'workspace': workspace,
    };
  }

// Create User object from a Map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      companyId: json['companyId'],
      branchId: json['branchId'],
      employeeCode: json['employeeCode'],
      departmentName: json['departmentName'],
      departmentId: json['departmentId'],
      scheduleUID: json['scheduleUID'],
      allowAppAttendance: json['allowAppAttendance'],
      firstname: json['firstname'],
      lastName: json['lastName'],
      gender: json['gender'],
      joiningDate: json['joining_date'],
      emailAddress: json['emailAddress'],
      mobileNo: json['mobileNo'],
      birthday: json['birthday'],
      employmentstatus: json['employmentstatus'],
      employmenttype: json['employmenttype'],
      leavePrivileges: List<dynamic>.from(json['leavePrivileges']),
      status: json['status'],
      is_eligible_for_multiple_worklog:
      json['is_eligible_for_multiple_worklog'],
      permanentAddress: json['permanent_address'] ?? "",
      address1: json['address']?['address_line_1'] ?? "",
      address2: json['address']?['address_line_2'] ?? "",
      city: json['address']?['city'] ?? "",
      postCode: json['address']?['post_code'] ?? "",
      country: json['address']?['country'] ?? "",
      avatar: json['avatar'],
      workspace: json['workspace'],
      designation: json['designation'],
      roleInfo: Roll.fromJson(json['roleInfo']),
      locationRestriction: json['locationRestriction'],
      flexibilityStatus: json['attendence_flexibility_status'] ?? true,
      isTracking: json['tracking'] ?? false,
      flexibilityLimit: json['flexibility_limit'] ?? 0,
      branchDetails: BranchDetails.fromJson(json['branch_details']),
      template:
      json['template'] != null ? Template.fromJson(json['template']) : null,
    );
  }

// /// Current User
// User? _userModel;
// User? get userModel => _userModel;
// void setUserModel(User userModel) {
//   _userModel = userModel;
//   notifyListeners();
// }
//
}

class Roll {
  String uuid;
  String roleName;
  List<UserPermission> permissions;

  Roll({
    required this.uuid,
    required this.roleName,
    required this.permissions,
  });
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'roleName': roleName,
      'permissions': permissions,
    };
  }

// Create Roll object from a Map
  factory Roll.fromJson(Map<String, dynamic> json) {
    return Roll(
      uuid: json['uuid'],
      roleName: json['roleName'],
      permissions: (json['permissions'] as List<dynamic>?)!
          .map((item) => UserPermission.fromJson(item))
          .toList(),
    );
  }
}

class UserPermission {
  bool create;
  bool read;
  bool update;
  bool delete;
  String featureName;

  UserPermission({
    required this.create,
    required this.read,
    required this.update,
    required this.delete,
    required this.featureName,
  });
  Map<String, dynamic> toJson() {
    return {
      'create': create,
      'read': read,
      'update': update,
      'delete': delete,
      'feature_name': featureName,
    };
  }

// Create Roll object from a Map
  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      create: json['create'],
      read: json['read'],
      update: json['update'],
      delete: json['delete'],
      featureName: json['feature_name'],
    );
  }
}

class Template {
  String saturdayIn;
  String sundayIn;
  String mondayIn;
  String tuesdayIn;
  String wednesdayIn;
  String thursdayIn;
  String fridayIn;
  //add out
  String saturdayOut;
  String sundayOut;
  String mondayOut;
  String tuesdayOut;
  String wednesdayOut;
  String thursdayOut;
  String fridayOut;

  int breakTime;

  Template({
    required this.saturdayIn,
    required this.sundayIn,
    required this.mondayIn,
    required this.tuesdayIn,
    required this.wednesdayIn,
    required this.thursdayIn,
    required this.fridayIn,
    required this.saturdayOut,
    required this.sundayOut,
    required this.mondayOut,
    required this.tuesdayOut,
    required this.wednesdayOut,
    required this.thursdayOut,
    required this.fridayOut,
    required this.breakTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'saturdayIn': saturdayIn,
      'sundayIn': sundayIn,
      'mondayIn': mondayIn,
      'tuesdayIn': tuesdayIn,
      'wednesdayIn': wednesdayIn,
      'thursdayIn': thursdayIn,
      'fridayIn': fridayIn,
      'saturdayOut': saturdayOut,
      'sundayOut': sundayOut,
      'mondayOut': mondayOut,
      'tuesdayOut': tuesdayOut,
      'wednesdayOut': wednesdayOut,
      'thursdayOut': thursdayOut,
      'fridayOut': fridayOut,
      'breakTime': breakTime,
    };
  }

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      saturdayIn: json['saturdayIn'],
      sundayIn: json['sundayIn'],
      mondayIn: json['mondayIn'],
      tuesdayIn: json['tuesdayIn'],
      wednesdayIn: json['wednesdayIn'],
      thursdayIn: json['thursdayIn'],
      fridayIn: json['fridayIn'],
      saturdayOut: json['saturdayOut'],
      sundayOut: json['sundayOut'],
      mondayOut: json['mondayOut'],
      tuesdayOut: json['tuesdayOut'],
      wednesdayOut: json['wednesdayOut'],
      thursdayOut: json['thursdayOut'],
      fridayOut: json['fridayOut'],
      breakTime: json['breakTime'],
    );
  }
}


class BranchDetails {
  final String uuid;
  final String branchCode;
  final String branchName;
  final String branchAddress;
  final String branchCountry;
  final String branchTimezone;
  final double latitude;
  final double longitude;
  final double radius;
  final bool locationRestriction;
  final bool dstTime;
  final String? isPreApprovalRequired;
  final String preApprovalBy;
  final String status;

  BranchDetails({
    required this.uuid,
    required this.branchCode,
    required this.branchName,

    required this.branchAddress,
    required this.branchCountry,
    required this.branchTimezone,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.locationRestriction,
    required this.dstTime,
    this.isPreApprovalRequired,
    required this.preApprovalBy,
    required this.status,

  });

  factory BranchDetails.fromJson(Map<String, dynamic> json) {
    return BranchDetails(
      uuid: json['uuid'],
      branchCode: json['branch_code'],
      branchName: json['branch_name'],

      branchAddress: json['branch_address'],
      branchCountry: json['branch_country'],
      branchTimezone: json['branch_timezone'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      locationRestriction: json['location_restriction'],
      dstTime: json['dst_time'],
      isPreApprovalRequired: json['is_pre_approval_required'],
      preApprovalBy: json['pre_approval_by'],
      status: json['status'],

    );
  }

  Map<String, dynamic> toJson() => {
    "uuid": uuid,
    "branch_code": branchCode,
    "branch_name": branchName,
    "branch_address": branchAddress,
    "branch_country": branchCountry,
    "branch_timezone": branchTimezone,
    "latitude": latitude,
    "longitude": longitude,
    "radius": radius,
    "location_restriction": locationRestriction,
    "dst_time": dstTime,
    "is_pre_approval_required": isPreApprovalRequired,
    "pre_approval_by": preApprovalBy,
    "status": status,
  };
}


// class UsersProvider extends ChangeNotifier {
//   /// Current User
//   UserProfile? _userModel;
//   UserProfile? get userModel => _userModel;
//   void setUserModel(UserProfile userModel) {
//     _userModel = userModel;
//     notifyListeners();
//   }
// }
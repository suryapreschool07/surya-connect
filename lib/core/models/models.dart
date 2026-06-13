class StudentModel {
  StudentModel({
    required this.studentId,
    required this.name,
    required this.className,
    required this.section,
    this.dob = '',
    this.admissionDate = '',
    this.fatherName = '',
    this.fatherPhone = '',
    this.fatherEmail = '',
    this.motherName = '',
    this.motherPhone = '',
    this.motherEmail = '',
    this.address = '',
    this.aadharNo = '',
    this.totalFees = 0,
    this.profilePhotoUrl = '',
    this.active = true,
  });

  final String studentId;
  final String name;
  final String className;
  final String section;
  final String dob;
  final String admissionDate;
  final String fatherName;
  final String fatherPhone;
  final String fatherEmail;
  final String motherName;
  final String motherPhone;
  final String motherEmail;
  final String address;
  final String aadharNo;
  final int totalFees;
  final String profilePhotoUrl;
  final bool active;

  String get classId => '${className.trim()}-${section.trim()}';
  String get displayLabel => '$studentId - $name';

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: '${json['studentId'] ?? ''}',
      name: '${json['name'] ?? ''}',
      className: '${json['class'] ?? json['className'] ?? ''}',
      section: '${json['section'] ?? ''}',
      dob: '${json['dob'] ?? ''}',
      admissionDate: '${json['admissionDate'] ?? ''}',
      fatherName: '${json['fatherName'] ?? ''}',
      fatherPhone: '${json['fatherPhone'] ?? ''}',
      fatherEmail: '${json['fatherEmail'] ?? ''}',
      motherName: '${json['motherName'] ?? ''}',
      motherPhone: '${json['motherPhone'] ?? ''}',
      motherEmail: '${json['motherEmail'] ?? ''}',
      address: '${json['address'] ?? ''}',
      aadharNo: '${json['aadharNo'] ?? ''}',
      totalFees: _toInt(json['totalFees']),
      profilePhotoUrl: '${json['profilePhotoUrl'] ?? ''}',
      active: _toBool(json['active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'name': name,
        'class': className,
        'section': section,
        'dob': dob,
        'admissionDate': admissionDate,
        'fatherName': fatherName,
        'fatherPhone': fatherPhone,
        'fatherEmail': fatherEmail,
        'motherName': motherName,
        'motherPhone': motherPhone,
        'motherEmail': motherEmail,
        'address': address,
        'aadharNo': aadharNo,
        'totalFees': totalFees,
        'profilePhotoUrl': profilePhotoUrl,
        'active': active,
      };

  StudentModel copyWith({
    String? studentId,
    String? name,
    String? className,
    String? section,
    String? dob,
    String? admissionDate,
    String? fatherName,
    String? fatherPhone,
    String? fatherEmail,
    String? motherName,
    String? motherPhone,
    String? motherEmail,
    String? address,
    String? aadharNo,
    int? totalFees,
    String? profilePhotoUrl,
    bool? active,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      className: className ?? this.className,
      section: section ?? this.section,
      dob: dob ?? this.dob,
      admissionDate: admissionDate ?? this.admissionDate,
      fatherName: fatherName ?? this.fatherName,
      fatherPhone: fatherPhone ?? this.fatherPhone,
      fatherEmail: fatherEmail ?? this.fatherEmail,
      motherName: motherName ?? this.motherName,
      motherPhone: motherPhone ?? this.motherPhone,
      motherEmail: motherEmail ?? this.motherEmail,
      address: address ?? this.address,
      aadharNo: aadharNo ?? this.aadharNo,
      totalFees: totalFees ?? this.totalFees,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      active: active ?? this.active,
    );
  }
}

class ClassModel {
  ClassModel({
    required this.classId,
    required this.name,
    required this.section,
    this.academicYear = '2025-2026',
    this.active = true,
  });

  final String classId;
  final String name;
  final String section;
  final String academicYear;
  final bool active;

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: '${json['classId'] ?? ''}',
      name: '${json['name'] ?? ''}',
      section: '${json['section'] ?? ''}',
      academicYear: '${json['academicYear'] ?? '2025-2026'}',
      active: _toBool(json['active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'name': name,
        'section': section,
        'academicYear': academicYear,
        'active': active,
      };
}

class FeePaymentModel {
  FeePaymentModel({
    required this.paymentId,
    required this.paymentDate,
    required this.studentId,
    required this.studentName,
    required this.amountPaid,
    this.method = 'cash',
    this.remarks = '',
  });

  final String paymentId;
  final String paymentDate;
  final String studentId;
  final String studentName;
  final int amountPaid;
  final String method;
  final String remarks;

  factory FeePaymentModel.fromJson(Map<String, dynamic> json) {
    return FeePaymentModel(
      paymentId: '${json['paymentId'] ?? ''}',
      paymentDate: '${json['paymentDate'] ?? ''}',
      studentId: '${json['studentId'] ?? ''}',
      studentName: '${json['studentName'] ?? ''}',
      amountPaid: _toInt(json['amountPaid']),
      method: '${json['method'] ?? 'cash'}',
      remarks: '${json['remarks'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'paymentDate': paymentDate,
        'studentId': studentId,
        'studentName': studentName,
        'amountPaid': amountPaid,
        'method': method,
        'remarks': remarks,
      };
}

class AttendanceModel {
  AttendanceModel({
    required this.date,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.status,
  });

  final String date;
  final String studentId;
  final String studentName;
  final String classId;
  final String status;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      date: '${json['date'] ?? ''}',
      studentId: '${json['studentId'] ?? ''}',
      studentName: '${json['studentName'] ?? ''}',
      classId: '${json['classId'] ?? ''}',
      status: '${json['status'] ?? 'P'}'.toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'status': status,
      };
}

class TestModel {
  TestModel({
    required this.testId,
    required this.classId,
    required this.testName,
    required this.subject,
    required this.testDate,
    required this.maxMarks,
    this.active = true,
  });

  final String testId;
  final String classId;
  final String testName;
  final String subject;
  final String testDate;
  final int maxMarks;
  final bool active;

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      testId: '${json['testId'] ?? ''}',
      classId: '${json['classId'] ?? ''}',
      testName: '${json['testName'] ?? ''}',
      subject: '${json['subject'] ?? ''}',
      testDate: '${json['testDate'] ?? ''}',
      maxMarks: _toInt(json['maxMarks']),
      active: _toBool(json['active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'classId': classId,
        'testName': testName,
        'subject': subject,
        'testDate': testDate,
        'maxMarks': maxMarks,
        'active': active,
      };
}

class TestResultModel {
  TestResultModel({
    required this.resultId,
    required this.testId,
    required this.studentId,
    required this.marks,
    this.grade = '',
  });

  final String resultId;
  final String testId;
  final String studentId;
  final num marks;
  final String grade;

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      resultId: '${json['resultId'] ?? ''}',
      testId: '${json['testId'] ?? ''}',
      studentId: '${json['studentId'] ?? ''}',
      marks: num.tryParse('${json['marks']}') ?? 0,
      grade: '${json['grade'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'resultId': resultId,
        'testId': testId,
        'studentId': studentId,
        'marks': marks,
        'grade': grade,
      };
}

class GalleryItemModel {
  GalleryItemModel({
    required this.itemId,
    required this.date,
    required this.type,
    required this.title,
    required this.url,
    this.thumbnailUrl = '',
  });

  final String itemId;
  final String date;
  final String type;
  final String title;
  final String url;
  final String thumbnailUrl;

  bool get isYoutube => type.toLowerCase() == 'youtube';

  factory GalleryItemModel.fromJson(Map<String, dynamic> json) {
    return GalleryItemModel(
      itemId: '${json['itemId'] ?? ''}',
      date: '${json['date'] ?? ''}',
      type: '${json['type'] ?? 'photo'}',
      title: '${json['title'] ?? ''}',
      url: '${json['url'] ?? ''}',
      thumbnailUrl: '${json['thumbnailUrl'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'date': date,
        'type': type,
        'title': title,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
      };
}

class StaffModel {
  StaffModel({
    required this.staffId,
    required this.name,
    required this.designation,
    this.phone = '',
    this.email = '',
    this.profilePhotoUrl = '',
    this.classIds = '',
    this.salary = 0,
    this.active = true,
  });

  final String staffId;
  final String name;
  final String designation;
  final String phone;
  final String email;
  final String profilePhotoUrl;
  final String classIds;
  final int salary;
  final bool active;

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      staffId: '${json['staffId'] ?? ''}',
      name: '${json['name'] ?? ''}',
      designation: '${json['designation'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      email: '${json['email'] ?? ''}',
      profilePhotoUrl: '${json['profilePhotoUrl'] ?? ''}',
      classIds: '${json['classIds'] ?? ''}',
      salary: _toInt(json['salary']),
      active: _toBool(json['active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'staffId': staffId,
        'name': name,
        'designation': designation,
        'phone': phone,
        'email': email,
        'profilePhotoUrl': profilePhotoUrl,
        'classIds': classIds,
        'salary': salary,
        'active': active,
      };
}

class SyncData {
  SyncData({
    this.students = const [],
    this.classes = const [],
    this.feePayments = const [],
    this.attendance = const [],
    this.tests = const [],
    this.testResults = const [],
    this.gallery = const [],
    this.staff = const [],
    this.linkedStudentIds = const [],
  });

  final List<StudentModel> students;
  final List<ClassModel> classes;
  final List<FeePaymentModel> feePayments;
  final List<AttendanceModel> attendance;
  final List<TestModel> tests;
  final List<TestResultModel> testResults;
  final List<GalleryItemModel> gallery;
  final List<StaffModel> staff;
  final List<String> linkedStudentIds;

  factory SyncData.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      dynamic value,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (value is! List) return [];
      return value
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return SyncData(
      students: mapList(json['students'], StudentModel.fromJson),
      classes: mapList(json['classes'], ClassModel.fromJson),
      feePayments: mapList(json['feePayments'], FeePaymentModel.fromJson),
      attendance: mapList(json['attendance'], AttendanceModel.fromJson),
      tests: mapList(json['tests'], TestModel.fromJson),
      testResults: mapList(json['testResults'], TestResultModel.fromJson),
      gallery: mapList(json['gallery'], GalleryItemModel.fromJson),
      staff: mapList(json['staff'], StaffModel.fromJson),
      linkedStudentIds: (json['linkedStudentIds'] as List?)
              ?.map((e) => '$e')
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'students': students.map((e) => e.toJson()).toList(),
        'classes': classes.map((e) => e.toJson()).toList(),
        'feePayments': feePayments.map((e) => e.toJson()).toList(),
        'attendance': attendance.map((e) => e.toJson()).toList(),
        'tests': tests.map((e) => e.toJson()).toList(),
        'testResults': testResults.map((e) => e.toJson()).toList(),
        'gallery': gallery.map((e) => e.toJson()).toList(),
        'staff': staff.map((e) => e.toJson()).toList(),
        'linkedStudentIds': linkedStudentIds,
      };
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse('$value'.replaceAll(',', '')) ?? 0;
}

bool _toBool(dynamic value, {required bool defaultValue}) {
  if (value is bool) return value;
  final s = '$value'.toLowerCase();
  if (s == 'true' || s == 'yes' || s == '1') return true;
  if (s == 'false' || s == 'no' || s == '0') return false;
  return defaultValue;
}

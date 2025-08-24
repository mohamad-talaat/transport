import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfileModel {
  final String id;
  final String driverId;
  final String carModel;
  final String carBrand;
  final String plateNumber;
  final String carColor;
  final int carYear;
  final String carPhotoUrl;
  final String licensePhotoUrl;
  final String licenseNumber;
  final String phoneNumber;
  final String city;
  final String area;
  final bool isApproved;
  final bool isComplete;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverProfileModel({
    required this.id,
    required this.driverId,
    required this.carModel,
    required this.carBrand,
    required this.plateNumber,
    required this.carColor,
    required this.carYear,
    required this.carPhotoUrl,
    required this.licensePhotoUrl,
    required this.licenseNumber,
    required this.phoneNumber,
    required this.city,
    required this.area,
    this.isApproved = false,
    this.isComplete = false,
    this.approvedAt,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return DriverProfileModel(
      id: id,
      driverId: map['driverId'] ?? '',
      carModel: map['carModel'] ?? '',
      carBrand: map['carBrand'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      carColor: map['carColor'] ?? '',
      carYear: map['carYear'] ?? 0,
      carPhotoUrl: map['carPhotoUrl'] ?? '',
      licensePhotoUrl: map['licensePhotoUrl'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      city: map['city'] ?? '',
      area: map['area'] ?? '',
      isApproved: map['isApproved'] ?? false,
      isComplete: map['isComplete'] ?? false,
      approvedAt: map['approvedAt'] != null 
          ? (map['approvedAt'] as Timestamp).toDate() 
          : null,
      approvedBy: map['approvedBy'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'carModel': carModel,
      'carBrand': carBrand,
      'plateNumber': plateNumber,
      'carColor': carColor,
      'carYear': carYear,
      'carPhotoUrl': carPhotoUrl,
      'licensePhotoUrl': licensePhotoUrl,
      'licenseNumber': licenseNumber,
      'phoneNumber': phoneNumber,
      'city': city,
      'area': area,
      'isApproved': isApproved,
      'isComplete': isComplete,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isFullyComplete {
    return carModel.isNotEmpty && 
           carBrand.isNotEmpty && 
           plateNumber.isNotEmpty && 
           carColor.isNotEmpty && 
           carYear > 0 &&
           carPhotoUrl.isNotEmpty && 
           licensePhotoUrl.isNotEmpty &&
           phoneNumber.isNotEmpty &&
           city.isNotEmpty &&
           area.isNotEmpty &&
           licenseNumber.isNotEmpty;
  }

  String get profileStatus {
    if (isApproved) return 'مفعل';
    if (isFullyComplete) return 'في انتظار المراجعة';
    return 'غير مكتمل';
  }
}

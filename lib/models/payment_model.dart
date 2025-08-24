import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
}

enum PaymentMethod {
  cash,
  card,
  wallet,
  bankTransfer,
  discountCode,
}

class PaymentModel {
  final String id;
  final String userId;
  final String tripId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? transactionId;
  final String? gatewayResponse;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.amount,
    required this.status,
    required this.method,
    this.transactionId,
    this.gatewayResponse,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      tripId: map['tripId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethod.cash,
      ),
      transactionId: map['transactionId'],
      gatewayResponse: map['gatewayResponse'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tripId': tripId,
      'amount': amount,
      'status': status.name,
      'method': method.name,
      'transactionId': transactionId,
      'gatewayResponse': gatewayResponse,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? tripId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? method,
    String? transactionId,
    String? gatewayResponse,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class DriverEarningsModel {
  final String driverId;
  final double totalEarnings;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final int totalTrips;
  final int todayTrips;
  final int weekTrips;
  final int monthTrips;
  final DateTime lastUpdated;

  DriverEarningsModel({
    required this.driverId,
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.totalTrips,
    required this.todayTrips,
    required this.weekTrips,
    required this.monthTrips,
    required this.lastUpdated,
  });

  factory DriverEarningsModel.fromMap(Map<String, dynamic> map) {
    return DriverEarningsModel(
      driverId: map['driverId'] ?? '',
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      todayEarnings: (map['todayEarnings'] ?? 0.0).toDouble(),
      weekEarnings: (map['weekEarnings'] ?? 0.0).toDouble(),
      monthEarnings: (map['monthEarnings'] ?? 0.0).toDouble(),
      totalTrips: map['totalTrips'] ?? 0,
      todayTrips: map['todayTrips'] ?? 0,
      weekTrips: map['weekTrips'] ?? 0,
      monthTrips: map['monthTrips'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'totalEarnings': totalEarnings,
      'todayEarnings': todayEarnings,
      'weekEarnings': weekEarnings,
      'monthEarnings': monthEarnings,
      'totalTrips': totalTrips,
      'todayTrips': todayTrips,
      'weekTrips': weekTrips,
      'monthTrips': monthTrips,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

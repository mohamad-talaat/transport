class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final bool isRead;
  final bool isDeleted;
  final List<String>? targetUserIds;
  final TargetAudience? targetAudience;
  final AppPriority priority;
  final bool autoDelete;
  final Duration? autoDeleteAfter;
  final String? createdBy;
  final Map<String, dynamic>? actionData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.type,
    required this.data,
    required this.createdAt,
    this.scheduledAt,
    this.isRead = false,
    this.isDeleted = false,
    this.targetUserIds,
    this.targetAudience,
    this.priority = AppPriority.normal,
    this.autoDelete = false,
    this.autoDeleteAfter,
    this.createdBy,
    this.actionData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['imageUrl'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      scheduledAt: json['scheduledAt'] != null
          ? (json['scheduledAt'] is String
              ? DateTime.parse(json['scheduledAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['scheduledAt']))
          : null,
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      targetUserIds: json['targetUserIds'] != null
          ? List<String>.from(json['targetUserIds'])
          : null,
      targetAudience: json['targetAudience'] != null
          ? TargetAudience.values.firstWhere(
              (e) => e.name == json['targetAudience'],
              orElse: () => TargetAudience.all,
            )
          : null,
      priority: AppPriority.values.firstWhere(
        (e) => e.name == json['AppPriority'],
        orElse: () => AppPriority.normal,
      ),
      autoDelete: json['autoDelete'] ?? false,
      autoDeleteAfter: json['autoDeleteAfter'] != null
          ? Duration(seconds: json['autoDeleteAfter'])
          : null,
      createdBy: json['createdBy'],
      actionData: json['actionData'] != null
          ? Map<String, dynamic>.from(json['actionData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'scheduledAt': scheduledAt?.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDeleted': isDeleted,
      'targetUserIds': targetUserIds,
      'targetAudience': targetAudience?.name,
      'priority': priority.name,
      'autoDelete': autoDelete,
      'autoDeleteAfter': autoDeleteAfter?.inSeconds,
      'createdBy': createdBy,
      'actionData': actionData,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? scheduledAt,
    bool? isRead,
    bool? isDeleted,
    List<String>? targetUserIds,
    TargetAudience? targetAudience,
    AppPriority? priority,
    bool? autoDelete,
    Duration? autoDeleteAfter,
    String? createdBy,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      targetAudience: targetAudience ?? this.targetAudience,
      priority: priority ?? this.priority,
      autoDelete: autoDelete ?? this.autoDelete,
      autoDeleteAfter: autoDeleteAfter ?? this.autoDeleteAfter,
      createdBy: createdBy ?? this.createdBy,
      actionData: actionData ?? this.actionData,
    );
  }
}

enum NotificationType {
  tripRequested,
  tripAccepted,
  tripDeclined,
  driverArrived,
  tripStarted,
  tripCompleted,
  tripCancelled,
 
  paymentCompleted,
  paymentFailed,
  balanceAdded,
  balanceDeducted,

  adminMessage,
  systemUpdate,
  maintenance,
  promotion,
  welcome,
  accountVerified,
  accountSuspended,

  chatMessage,

  general,
  reminder,
  emergency,
  news,
}

enum TargetAudience {
  all,
  riders,
  drivers,
  activeRiders,
  activeDrivers,
  newUsers,
  vipUsers,
}

enum AppPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationStatus {
  draft,
  scheduled,
  sent,
  delivered,
  read,
  failed,
  cancelled,
}

class NotificationTemplate {
  final String id;
  final String name;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> defaultData;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.body,
    required this.type,
    required this.defaultData,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      defaultData: Map<String, dynamic>.from(json['defaultData'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'body': body,
      'type': type.name,
      'defaultData': defaultData,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
    };
  }
}

class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime scheduledAt;
  final TargetAudience? targetAudience;
  final List<String>? targetUserIds;
  final Map<String, dynamic> data;
  final NotificationStatus status;
  final String createdBy;
  final DateTime createdAt;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledAt,
    this.targetAudience,
    this.targetUserIds,
    required this.data,
    this.status = NotificationStatus.scheduled,
    required this.createdBy,
    required this.createdAt,
  });

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(json['scheduledAt']),
      targetAudience: json['targetAudience'] != null
          ? TargetAudience.values.firstWhere(
              (e) => e.name == json['targetAudience'],
            )
          : null,
      targetUserIds: json['targetUserIds'] != null
          ? List<String>.from(json['targetUserIds'])
          : null,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      createdBy: json['createdBy'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
      'targetAudience': targetAudience?.name,
      'targetUserIds': targetUserIds,
      'data': data,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class NotificationTemplates {
  static const Map<String, Map<String, String>> riderTemplates = {
    'trip_accepted': {
      'title': '🚕 تم العثور على سائق',
      'body': '{driverName} في الطريق إليك - سيصل خلال {eta} دقائق',
      'icon': '🚕',
    },
    'driver_arrived': {
      'title': '✅ السائق وصل',
      'body': 'سائقك {driverName} ينتظرك الآن في نقطة الالتقاء',
      'icon': '✅',
    },
    'trip_started': {
      'title': '🏁 بدأت رحلتك',
      'body': 'أنت في الطريق إلى {destination}',
      'icon': '🏁',
    },
    'trip_completed': {
      'title': '🎯 وصلت بأمان',
      'body': 'انتهت الرحلة - التكلفة: {fare} د.ع',
      'icon': '🎯',
    },
    'trip_cancelled_by_driver': {
      'title': '❌ تم إلغاء الرحلة',
      'body': 'اعتذر السائق عن عدم القدرة على إكمال الرحلة',
      'icon': '❌',
    },
    'payment_completed': {
      'title': '💳 تم الدفع بنجاح',
      'body': 'تم خصم {amount} د.ع من رصيدك',
      'icon': '💳',
    },
    'balance_added': {
      'title': '💰 تم إضافة رصيد',
      'body': 'تم إضافة {amount} د.ع إلى رصيدك',
      'icon': '💰',
    },
  };

  static const Map<String, Map<String, String>> driverTemplates = {
    'new_trip_request': {
      'title': '🔔 طلب رحلة جديد',
      'body': 'راكب يطلب رحلة من {pickup} إلى {destination}',
      'icon': '🔔',
    },
    'trip_cancelled_by_rider': {
      'title': '❌ ألغى الراكب الرحلة',
      'body': 'تم إلغاء الرحلة من قبل الراكب',
      'icon': '❌',
    },
    'payment_received': {
      'title': '💰 تم استلام الدفع',
      'body': 'تم إضافة {earnings} د.ع إلى أرباحك',
      'icon': '💰',
    },
    'daily_summary': {
      'title': '📊 ملخص اليوم',
      'body': 'أكملت {trips} رحلات وحققت {earnings} د.ع',
      'icon': '📊',
    },
  };

  static const Map<String, Map<String, String>> adminTemplates = {
    'welcome_new_user': {
      'title': '🎉 مرحباً بك في تطبيق النقل',
      'body': 'نشكرك على انضمامك إلينا. نتمنى لك تجربة رائعة!',
      'icon': '🎉',
    },
    'account_verified': {
      'title': '✅ تم التحقق من حسابك',
      'body': 'تم قبول مستنداتك ويمكنك الآن استخدام التطبيق بالكامل',
      'icon': '✅',
    },
    'system_maintenance': {
      'title': '🔧 صيانة مجدولة',
      'body': 'سيتم إجراء صيانة على النظام {maintenanceTime}',
      'icon': '🔧',
    },
    'app_update_available': {
      'title': '📱 تحديث جديد متاح',
      'body': 'يتوفر إصدار جديد من التطبيق مع ميزات محسنة',
      'icon': '📱',
    },
    'promotion_offer': {
      'title': '🎁 عرض خاص لك',
      'body': 'احصل على خصم {discount}% على رحلتك القادمة',
      'icon': '🎁',
    },
    'emergency_alert': {
      'title': '⚠️ تنبيه مهم',
      'body': '{alertMessage}',
      'icon': '⚠️',
    },
  };

  static Map<String, String>? getTemplate(String templateId) {
    if (riderTemplates.containsKey(templateId)) {
      return riderTemplates[templateId];
    }

    if (driverTemplates.containsKey(templateId)) {
      return driverTemplates[templateId];
    }

    if (adminTemplates.containsKey(templateId)) {
      return adminTemplates[templateId];
    }

    return null;
  }

  static String replaceVariables(String text, Map<String, dynamic> variables) {
    String result = text;
    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}

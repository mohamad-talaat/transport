import 'package:logger/logger.dart';

final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // عدد الأساليب المراد عرضها في التتبع (الأقل هو الأفضل في الإنتاج)
    errorMethodCount: 8, // عدد الأساليب المراد عرضها عند وجود خطأ
    lineLength: 120, // طول السطر
    colors: true, // تفعيل الألوان
    printEmojis: true, // طباعة الرموز التعبيرية
    printTime: true, // طباعة الوقت
  ),
);
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main.dart';

/// 🎨 Helper class لعرض الصور بشكل صحيح
class ImageHelper {
  /// ✅ دالة محسّنة لعرض الصورة (تدعم URLs و File Paths و Firebase Storage)
  static ImageProvider? getImageProvider(String? imagePath) {
    // ✅ التحقق من وجود الصورة
    if (imagePath == null || imagePath.isEmpty || imagePath == 'null') {
      return null;
    }

    // ✅ إذا كانت الصورة URL من الإنترنت (Firebase Storage, ImgBB, etc.)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImageProvider(imagePath);
    }

    // ✅ إذا كانت الصورة من Firebase Storage بدون البروتوكول
    if (imagePath.startsWith('gs://')) {
      logger.w('⚠️ مسار Firebase Storage يحتاج تحويل: $imagePath');
      return null;
    }

    // ✅ إذا كانت الصورة File Path محلي
    if (imagePath.startsWith('/') || imagePath.contains('app_flutter')) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          logger.w('❌ الملف غير موجود: $imagePath');
          return null;
        }
      } catch (e) {
        logger.e('❌ خطأ في قراءة الملف: $e');
        return null;
      }
    }

    return null;
  }

  /// ✅ Widget محسّن لعرض الصورة الشخصية مع Caching
  static Widget buildAvatar({
    required String? imagePath,
    double radius = 30,
    IconData fallbackIcon = Icons.person,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    // ✅ التحقق من وجود الصورة
    if (imagePath == null || imagePath.isEmpty || imagePath == 'null') {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.blue.shade100,
        child: Icon(
          fallbackIcon,
          size: radius * 0.8,
          color: iconColor ?? Colors.white,
        ),
      );
    }

    // ✅ إذا كانت URL من الإنترنت
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.blue.shade100,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imagePath,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: radius * 0.5,
                height: radius * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    iconColor ?? Colors.white,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              return Icon(
                fallbackIcon,
                size: radius * 0.8,
                color: iconColor ?? Colors.white,
              );
            },
          ),
        ),
      );
    }

    // ✅ إذا كانت File محلي
    if (imagePath.startsWith('/') || imagePath.contains('app_flutter')) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? Colors.blue.shade100,
            backgroundImage: FileImage(file),
            onBackgroundImageError: (exception, stackTrace) {
              logger.e('❌ خطأ: $exception');
            },
          );
        }
      } catch (e) {
        logger.e('❌ خطأ: $e');
      }
    }

    // ✅ Fallback إذا فشل كل شيء
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.blue.shade100,
      child: Icon(
        fallbackIcon,
        size: radius * 0.8,
        color: iconColor ?? Colors.white,
      ),
    );
  }

  /// ✅ Widget لعرض صورة عادية (ليست دائرية) مع Caching
  static Widget buildImage({
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    // ✅ Widget الافتراضي عند عدم وجود صورة
    final defaultWidget = errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: borderRadius,
          ),
          child: Icon(
            Icons.broken_image,
            color: Colors.grey.shade400,
            size: 40,
          ),
        );

    // ✅ التحقق من وجود الصورة
    if (imagePath == null || imagePath.isEmpty || imagePath == 'null') {
      return defaultWidget;
    }

    // ✅ إذا كانت URL من الإنترنت
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: imagePath,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) =>
              placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          errorWidget: (context, url, error) {
            return defaultWidget;
          },
        ),
      );
    }

    // ✅ إذا كانت File محلي
    if (imagePath.startsWith('/') || imagePath.contains('app_flutter')) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return defaultWidget;
              },
            ),
          );
        }
      } catch (e) {
        logger.e('❌ خطأ: $e');
      }
    }

    return defaultWidget;
  }

  /// ✅ دالة للتحقق من صلاحية الصورة
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') {
      return false;
    }
    
    return url.startsWith('http://') || 
           url.startsWith('https://') || 
           url.startsWith('/');
  }

  /// ✅ دالة لعرض صورة مع Loading و Error Handling
  static Widget buildImageWithStates({
    required String? imagePath,
    required double size,
    IconData fallbackIcon = Icons.image,
    BoxFit fit = BoxFit.cover,
    bool isCircular = false,
  }) {
    if (!isValidImageUrl(imagePath)) {
      final fallbackWidget = Icon(
        fallbackIcon,
        size: size * 0.5,
        color: Colors.grey.shade400,
      );

      return isCircular
          ? CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.grey.shade200,
              child: fallbackWidget,
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
              ),
              child: Center(child: fallbackWidget),
            );
    }

    if (isCircular) {
      return buildAvatar(
        imagePath: imagePath,
        radius: size / 2,
        fallbackIcon: fallbackIcon,
      );
    } else {
      return buildImage(
        imagePath: imagePath,
        width: size,
        height: size,
        fit: fit,
      );
    }
  }
}

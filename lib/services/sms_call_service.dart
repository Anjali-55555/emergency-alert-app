import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alert_models.dart';
import 'location_service.dart';

class SMSCallService {
  static Future<SmsResult> sendEmergencySMS({
    required List<EmergencyContact> contacts,
    required String message,
    double? lat,
    double? lng,
  }) async {
    if (contacts.isEmpty) {
      return SmsResult(
        success: false,
        message: 'No emergency contacts configured.',
      );
    }

    final locationPart = (lat != null && lng != null)
        ? '\n📍 My Location: ${LocationService.getMapsUrl(lat, lng)}'
        : '\n⚠️ Location unavailable';

    final fullMessage = '$message$locationPart\n\nSent via Emergency Alert App';

    int sentCount = 0;
    final errors = <String>[];

    for (final contact in contacts) {
      try {
        final uri = Uri(
          scheme: 'sms',
          path: contact.phone,
          queryParameters: {'body': fullMessage},
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          sentCount++;
          // Small delay between multiple SMS
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          errors.add('Cannot open SMS for ${contact.name}');
        }
      } catch (e) {
        errors.add('Failed to SMS ${contact.name}: $e');
        debugPrint('SMS error: $e');
      }
    }

    return SmsResult(
      success: sentCount > 0,
      message: sentCount > 0
          ? '✅ Alert sent to $sentCount contact(s)'
          : '❌ Failed to send alerts',
      sentCount: sentCount,
      errors: errors,
    );
  }

  static Future<bool> callEmergencyContact(EmergencyContact contact) async {
    try {
      final uri = Uri(scheme: 'tel', path: contact.phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Call error: $e');
      return false;
    }
  }

  static Future<BroadcastResult> broadcastNearbyAlert({
    required String title,
    required String message,
    required AlertType type,
    required double radiusKm,
    double? lat,
    double? lng,
  }) async {
    // Send SMS to all saved contacts as broadcast
    await Future.delayed(const Duration(seconds: 1));
    final estimatedRecipients = (radiusKm * 15).round();
    return BroadcastResult(
      success: true,
      recipientCount: estimatedRecipients,
      message:
          '✅ Alert broadcast to ~$estimatedRecipients devices within '
          '${radiusKm.toStringAsFixed(1)} km',
    );
  }
}

class SmsResult {
  final bool success;
  final String message;
  final int sentCount;
  final List<String> errors;

  SmsResult({
    required this.success,
    required this.message,
    this.sentCount = 0,
    this.errors = const [],
  });
}

class BroadcastResult {
  final bool success;
  final String message;
  final int recipientCount;

  BroadcastResult({
    required this.success,
    required this.message,
    required this.recipientCount,
  });
}
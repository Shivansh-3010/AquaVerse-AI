import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/risk_calculator.dart';
import '../models/warning_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showWarningNotification(WarningData warning) async {
    if (!_initialized) return;
    if (warning.threatLevel == ThreatLevel.noThreat) return;

    final androidDetails = AndroidNotificationDetails(
      'aquaverse_warnings',
      'Ocean Warnings',
      channelDescription: 'INCOIS early warning alerts',
      importance: warning.threatLevel == ThreatLevel.warning
          ? Importance.max
          : Importance.high,
      priority: Priority.high,
      color: warning.threatLevel.color,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'aquaverse_warnings',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      warning.type.hashCode,
      '${warning.typeName} ${warning.threatLevel.label}',
      warning.message,
      details,
    );
  }

  Future<void> showSafetyReminderNotification() async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      'aquaverse_reminders',
      'Safety Reminders',
      channelDescription: 'Beach safety reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'aquaverse_reminders',
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    await _plugin.show(
      0,
      'AquaVerse Check-In',
      'Tap to view today\'s beach safety conditions.',
      details,
    );
  }

  /// Fired when the computed risk level escalates (e.g. SAFE → HIGH).
  Future<void> showRiskEscalationNotification({
    required RiskLevel from,
    required RiskLevel to,
    required String location,
  }) async {
    if (!_initialized) return;
    final color = _riskColor(to);
    final androidDetails = AndroidNotificationDetails(
      'aquaverse_risk',
      'Risk Level Alerts',
      channelDescription: 'Notifications when ocean risk level increases',
      importance: to == RiskLevel.danger ? Importance.max : Importance.high,
      priority: to == RiskLevel.danger ? Priority.max : Priority.high,
      color: color,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'aquaverse_risk',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    await _plugin.show(
      99999,
      'Risk Escalation at $location',
      'Ocean risk has risen from ${from.name.toUpperCase()} to '
          '${to.name.toUpperCase()}. Check current conditions.',
      details,
    );
  }

  /// Fired when a 6hr or 12hr prediction indicates HIGH or DANGER conditions.
  Future<void> showPredictionAlertNotification({
    required String window,
    required RiskLevel level,
    required String location,
  }) async {
    if (!_initialized) return;
    final color = _riskColor(level);
    final androidDetails = AndroidNotificationDetails(
      'aquaverse_predictions',
      'Advance Risk Predictions',
      channelDescription: 'Proactive alerts when future conditions look dangerous',
      importance: Importance.high,
      priority: Priority.high,
      color: color,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'aquaverse_predictions',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    await _plugin.show(
      88888,
      'Advance Warning: ${level.name.toUpperCase()} Expected',
      '$window at $location — ${level.name} ocean conditions predicted. '
          'Plan your activities accordingly.',
      details,
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.danger:
        return const Color(0xFFE63946);
      case RiskLevel.high:
        return const Color(0xFFFF9F1C);
      case RiskLevel.moderate:
        return const Color(0xFFFFD60A);
      case RiskLevel.safe:
        return const Color(0xFF06D6A0);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}

import 'package:flutter/foundation.dart';
import '../models/alert_models.dart';

/// AlertService manages the local state of all alert types.
/// In production, sync with a backend (Firebase / Supabase / custom REST).
class AlertService extends ChangeNotifier {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal() {
    _seedDemoData();
  }

  // ── State ──────────────────────────────────────────────────────────────
  final List<EmergencyContact> _contacts = [];
  final List<MissingChildAlert> _missingChildren = [];
  final List<BloodDonationRequest> _bloodRequests = [];
  final List<BroadcastAlert> _broadcasts = [];

  // ── Contacts ───────────────────────────────────────────────────────────
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);

  void addContact(EmergencyContact c) {
    _contacts.add(c);
    notifyListeners();
  }

  void updateContact(EmergencyContact updated) {
    final idx = _contacts.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      _contacts[idx] = updated;
      notifyListeners();
    }
  }

  void removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ── Missing Children ───────────────────────────────────────────────────
  List<MissingChildAlert> get missingChildren =>
      _missingChildren.where((a) => a.isActive).toList();

  void addMissingChildAlert(MissingChildAlert alert) {
    _missingChildren.add(alert);
    notifyListeners();
  }

  void resolveMissingChild(String id) {
    final a = _missingChildren.firstWhere((a) => a.id == id,
        orElse: () => throw Exception('Not found'));
    a.isActive = false;
    notifyListeners();
  }

  // ── Blood Donation ─────────────────────────────────────────────────────
  List<BloodDonationRequest> get bloodRequests =>
      _bloodRequests.where((r) => r.isActive).toList();

  List<BloodDonationRequest> bloodRequestsByGroup(BloodGroup group) =>
      bloodRequests.where((r) => r.bloodGroup == group).toList();

  void addBloodRequest(BloodDonationRequest req) {
    _bloodRequests.add(req);
    notifyListeners();
  }

  void resolveBloodRequest(String id) {
    final r = _bloodRequests.firstWhere((r) => r.id == id,
        orElse: () => throw Exception('Not found'));
    r.isActive = false;
    notifyListeners();
  }

  // ── Broadcasts ─────────────────────────────────────────────────────────
  List<BroadcastAlert> get broadcasts =>
      List.unmodifiable(_broadcasts.reversed.toList());

  void addBroadcast(BroadcastAlert alert) {
    _broadcasts.add(alert);
    notifyListeners();
  }

  // ── Seed Data ──────────────────────────────────────────────────────────
  void _seedDemoData() {
    _contacts.addAll([
      EmergencyContact(
        id: 'c1',
        name: 'Ramesh Kumar',
        phone: '+919876543210',
        relationship: 'Father',
        isVerified: true,
      ),
      EmergencyContact(
        id: 'c2',
        name: 'Dr. Lakshmi',
        phone: '+919123456789',
        relationship: 'Family Doctor',
        isVerified: true,
      ),
    ]);

    _missingChildren.add(MissingChildAlert(
      id: 'mc1',
      childName: 'Arjun Reddy',
      age: 8,
      gender: 'Male',
      description: 'Wearing blue school uniform, has a red backpack',
      lastSeenLocation: 'Benz Circle, Vijayawada',
      contactNumber: '+919876500001',
      reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
      latitude: 16.5062,
      longitude: 80.6480,
    ));

    _bloodRequests.add(BloodDonationRequest(
      id: 'bd1',
      patientName: 'Sunitha Rao',
      bloodGroup: BloodGroup.oNeg,
      hospital: 'Government General Hospital, Vijayawada',
      contactNumber: '+919876500002',
      unitsNeeded: 2,
      requestedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      latitude: 16.5100,
      longitude: 80.6350,
      urgencyLevel: 'critical',
    ));
  }
}

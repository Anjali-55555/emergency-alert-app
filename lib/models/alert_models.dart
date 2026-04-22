// ─── Emergency Contact Model ───────────────────────────────────────────────
class EmergencyContact {
  final String id;
  String name;
  String phone;
  String relationship;
  bool isVerified;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'isVerified': isVerified,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        relationship: json['relationship'],
        isVerified: json['isVerified'] ?? false,
      );
}

// ─── Alert Type Enum ────────────────────────────────────────────────────────
enum AlertType { emergency, missingChild, bloodDonation }

extension AlertTypeExt on AlertType {
  String get label {
    switch (this) {
      case AlertType.emergency:
        return 'Emergency Alert';
      case AlertType.missingChild:
        return 'Missing Child';
      case AlertType.bloodDonation:
        return 'Blood Donation Needed';
    }
  }

  String get emoji {
    switch (this) {
      case AlertType.emergency:
        return '🆘';
      case AlertType.missingChild:
        return '👦';
      case AlertType.bloodDonation:
        return '🩸';
    }
  }
}

// ─── Blood Group Enum ───────────────────────────────────────────────────────
enum BloodGroup { aNeg, aPos, bNeg, bPos, abNeg, abPos, oNeg, oPos }

extension BloodGroupExt on BloodGroup {
  String get label {
    const labels = {
      BloodGroup.aNeg: 'A-',
      BloodGroup.aPos: 'A+',
      BloodGroup.bNeg: 'B-',
      BloodGroup.bPos: 'B+',
      BloodGroup.abNeg: 'AB-',
      BloodGroup.abPos: 'AB+',
      BloodGroup.oNeg: 'O-',
      BloodGroup.oPos: 'O+',
    };
    return labels[this]!;
  }
}

// ─── Missing Child Model ────────────────────────────────────────────────────
class MissingChildAlert {
  final String id;
  final String childName;
  final int age;
  final String gender;
  final String description;
  final String lastSeenLocation;
  final String contactNumber;
  final DateTime reportedAt;
  final double? latitude;
  final double? longitude;
  bool isActive;

  MissingChildAlert({
    required this.id,
    required this.childName,
    required this.age,
    required this.gender,
    required this.description,
    required this.lastSeenLocation,
    required this.contactNumber,
    required this.reportedAt,
    this.latitude,
    this.longitude,
    this.isActive = true,
  });
}

// ─── Blood Donation Request Model ───────────────────────────────────────────
class BloodDonationRequest {
  final String id;
  final String patientName;
  final BloodGroup bloodGroup;
  final String hospital;
  final String contactNumber;
  final int unitsNeeded;
  final DateTime requestedAt;
  final double? latitude;
  final double? longitude;
  final String urgencyLevel; // 'critical', 'urgent', 'normal'
  bool isActive;

  BloodDonationRequest({
    required this.id,
    required this.patientName,
    required this.bloodGroup,
    required this.hospital,
    required this.contactNumber,
    required this.unitsNeeded,
    required this.requestedAt,
    this.latitude,
    this.longitude,
    required this.urgencyLevel,
    this.isActive = true,
  });
}

// ─── Alert Broadcast Model ──────────────────────────────────────────────────
class BroadcastAlert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final DateTime sentAt;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  bool isVerified;

  BroadcastAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.sentAt,
    this.latitude,
    this.longitude,
    required this.radiusKm,
    this.isVerified = false,
  });
}

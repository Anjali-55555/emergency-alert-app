import 'package:flutter/material.dart';
import '../models/alert_models.dart';
import '../services/alert_service.dart';
import '../services/sms_call_service.dart';
import '../services/location_service.dart';

class MissingChildScreen extends StatefulWidget {
  const MissingChildScreen({super.key});

  @override
  State<MissingChildScreen> createState() => _MissingChildScreenState();
}

class _MissingChildScreenState extends State<MissingChildScreen> {
  final _alertService = AlertService();

  @override
  Widget build(BuildContext context) {
    final alerts = _alertService.missingChildren;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missing Children'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showReportDialog,
            tooltip: 'Report missing child',
          ),
        ],
      ),
      body: alerts.isEmpty
          ? _EmptyState(
              icon: Icons.child_care,
              message: 'No missing child alerts in your area.',
              actionLabel: 'Report Missing Child',
              onAction: _showReportDialog,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (ctx, i) => _MissingChildCard(
                alert: alerts[i],
                onBroadcast: () => _broadcastAlert(alerts[i]),
                onResolved: () {
                  _alertService.resolveMissingChild(alerts[i].id);
                  setState(() {});
                },
              ),
            ),
    );
  }

  Future<void> _broadcastAlert(MissingChildAlert alert) async {
    final loc = await LocationService.getCurrentLocation();
    final result = await SMSCallService.broadcastNearbyAlert(
      title: 'Missing Child Alert',
      message:
          '⚠️ MISSING CHILD: ${alert.childName}, ${alert.age}y/o ${alert.gender}.\n'
          '${alert.description}\nLast seen: ${alert.lastSeenLocation}\n'
          'Contact: ${alert.contactNumber}',
      type: AlertType.missingChild,
      radiusKm: 5,
      lat: loc?['lat'] as double?,
      lng: loc?['lng'] as double?,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  void _showReportDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String gender = 'Male';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Report Missing Child'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: "Child's Name", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Age', border: OutlineInputBorder())),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: gender,
                    items: ['Male', 'Female', 'Other']
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setDlg(() => gender = v!),
                  ),
                ]),
                const SizedBox(height: 10),
                TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Description (clothing, marks...)',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Last Seen Location',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0)),
              onPressed: () {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                _alertService.addMissingChildAlert(MissingChildAlert(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  childName: nameCtrl.text,
                  age: int.tryParse(ageCtrl.text) ?? 0,
                  gender: gender,
                  description: descCtrl.text,
                  lastSeenLocation: locationCtrl.text,
                  contactNumber: phoneCtrl.text,
                  reportedAt: DateTime.now(),
                ));
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingChildCard extends StatelessWidget {
  final MissingChildAlert alert;
  final VoidCallback onBroadcast;
  final VoidCallback onResolved;

  const _MissingChildCard({
    required this.alert,
    required this.onBroadcast,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(alert.reportedAt);
    final timeStr = elapsed.inHours > 0
        ? '${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago'
        : '${elapsed.inMinutes}m ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.child_care, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MISSING: ${alert.childName.toUpperCase()}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
                Text(timeStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(Icons.person, 'Age/Gender',
                    '${alert.age} years old, ${alert.gender}'),
                _InfoRow(
                    Icons.description, 'Description', alert.description),
                _InfoRow(Icons.location_on, 'Last Seen',
                    alert.lastSeenLocation),
                _InfoRow(Icons.phone, 'Contact', alert.contactNumber),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.broadcast_on_personal),
                        label: const Text('Broadcast'),
                        onPressed: onBroadcast,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1565C0)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Found Safe'),
                        onPressed: onResolved,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          SizedBox(
              width: 80,
              child: Text('$label:',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message,
              style:
                  TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel)),
        ],
      ),
    );
  }
}

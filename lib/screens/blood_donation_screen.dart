import 'package:flutter/material.dart';
import '../models/alert_models.dart';
import '../services/alert_service.dart';
import '../services/sms_call_service.dart';
import '../services/location_service.dart';

class BloodDonationScreen extends StatefulWidget {
  const BloodDonationScreen({super.key});

  @override
  State<BloodDonationScreen> createState() => _BloodDonationScreenState();
}

class _BloodDonationScreenState extends State<BloodDonationScreen> {
  final _alertService = AlertService();
  BloodGroup? _filterGroup;

  List<BloodDonationRequest> get _filteredRequests {
    if (_filterGroup == null) return _alertService.bloodRequests;
    return _alertService.bloodRequestsByGroup(_filterGroup!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Donation'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showRequestDialog,
            tooltip: 'Request blood',
          ),
        ],
      ),
      body: Column(
        children: [
          // Blood group filter chips
          Container(
            color: const Color(0xFFC62828).withOpacity(0.08),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _GroupChip(
                    label: 'All',
                    selected: _filterGroup == null,
                    onTap: () => setState(() => _filterGroup = null),
                  ),
                  ...BloodGroup.values.map((g) => _GroupChip(
                        label: g.label,
                        selected: _filterGroup == g,
                        onTap: () =>
                            setState(() => _filterGroup = g),
                      )),
                ],
              ),
            ),
          ),
          // Requests list
          Expanded(
            child: _filteredRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _filterGroup == null
                              ? 'No blood donation requests nearby.'
                              : 'No requests for ${_filterGroup!.label} blood.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showRequestDialog,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              foregroundColor: Colors.white),
                          child: const Text('Post Request'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (ctx, i) => _BloodRequestCard(
                      request: _filteredRequests[i],
                      onBroadcast: () =>
                          _broadcastRequest(_filteredRequests[i]),
                      onFulfilled: () {
                        _alertService.resolveBloodRequest(
                            _filteredRequests[i].id);
                        setState(() {});
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _broadcastRequest(BloodDonationRequest req) async {
    final loc = await LocationService.getCurrentLocation();
    final result = await SMSCallService.broadcastNearbyAlert(
      title: '🩸 Blood Donation Urgently Needed',
      message:
          '🩸 URGENT: ${req.bloodGroup.label} blood needed for ${req.patientName}.\n'
          '${req.unitsNeeded} unit(s) required.\nHospital: ${req.hospital}\n'
          'Contact: ${req.contactNumber}',
      type: AlertType.bloodDonation,
      radiusKm: 10,
      lat: loc?['lat'] as double?,
      lng: loc?['lng'] as double?,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: const Color(0xFFC62828),
      ),
    );
  }

  void _showRequestDialog() {
    final patientCtrl = TextEditingController();
    final hospitalCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final unitsCtrl = TextEditingController(text: '1');
    BloodGroup selectedGroup = BloodGroup.oPos;
    String urgency = 'urgent';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.water_drop, color: Color(0xFFC62828)),
            SizedBox(width: 8),
            Text('Request Blood Donation'),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: patientCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Patient Name',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<BloodGroup>(
                  value: selectedGroup,
                  decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder()),
                  items: BloodGroup.values
                      .map((g) => DropdownMenuItem(
                          value: g, child: Text(g.label)))
                      .toList(),
                  onChanged: (v) => setDlg(() => selectedGroup = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: hospitalCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Hospital Name',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Contact Number',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: unitsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Units Needed',
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: urgency,
                  decoration: const InputDecoration(
                      labelText: 'Urgency Level',
                      border: OutlineInputBorder()),
                  items: ['critical', 'urgent', 'normal']
                      .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setDlg(() => urgency = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828)),
              onPressed: () {
                if (patientCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                _alertService.addBloodRequest(BloodDonationRequest(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  patientName: patientCtrl.text,
                  bloodGroup: selectedGroup,
                  hospital: hospitalCtrl.text,
                  contactNumber: phoneCtrl.text,
                  unitsNeeded: int.tryParse(unitsCtrl.text) ?? 1,
                  requestedAt: DateTime.now(),
                  urgencyLevel: urgency,
                ));
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Submit',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodRequestCard extends StatelessWidget {
  final BloodDonationRequest request;
  final VoidCallback onBroadcast;
  final VoidCallback onFulfilled;

  const _BloodRequestCard({
    required this.request,
    required this.onBroadcast,
    required this.onFulfilled,
  });

  Color get _urgencyColor {
    switch (request.urgencyLevel) {
      case 'critical':
        return Colors.red[900]!;
      case 'urgent':
        return Colors.orange[800]!;
      default:
        return Colors.green[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(request.requestedAt);
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
            decoration: BoxDecoration(
              color: _urgencyColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.bloodGroup.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.patientName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(request.urgencyLevel.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Text(timeStr,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(Icons.local_hospital, 'Hospital', request.hospital),
                _InfoRow(Icons.water_drop, 'Units Needed',
                    '${request.unitsNeeded} unit(s)'),
                _InfoRow(Icons.phone, 'Contact', request.contactNumber),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.broadcast_on_personal),
                        label: const Text('Broadcast'),
                        onPressed: onBroadcast,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC62828)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Donate'),
                        onPressed: onFulfilled,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
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

class _GroupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GroupChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFC62828)
                : Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
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

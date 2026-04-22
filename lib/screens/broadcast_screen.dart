import 'package:flutter/material.dart';
import '../models/alert_models.dart';
import '../services/alert_service.dart';
import '../services/sms_call_service.dart';
import '../services/location_service.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _alertService = AlertService();
  double _radiusKm = 5.0;
  AlertType _selectedType = AlertType.emergency;
  bool _isBroadcasting = false;
  String? _locationText;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _locationText = loc != null
            ? (loc['address'] as String? ?? '${loc['lat']}, ${loc['lng']}')
            : 'Location unavailable';
      });
    }
  }

  Future<void> _broadcast() async {
    setState(() => _isBroadcasting = true);
    final loc = await LocationService.getCurrentLocation();

    final result = await SMSCallService.broadcastNearbyAlert(
      title: _selectedType.label,
      message: _selectedType == AlertType.emergency
          ? '🆘 Emergency alert from your area. Stay alert!'
          : _selectedType == AlertType.missingChild
              ? '⚠️ Missing child reported in your area. Please be vigilant.'
              : '🩸 Blood donation urgently needed nearby.',
      type: _selectedType,
      radiusKm: _radiusKm,
      lat: loc?['lat'] as double?,
      lng: loc?['lng'] as double?,
    );

    if (!mounted) return;
    setState(() => _isBroadcasting = false);

    _alertService.addBroadcast(BroadcastAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      title: _selectedType.label,
      message: 'Broadcast to ~${result.recipientCount} devices',
      sentAt: DateTime.now(),
      latitude: loc?['lat'] as double?,
      longitude: loc?['lng'] as double?,
      radiusKm: _radiusKm,
    ));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Broadcast Sent'),
        ]),
        content: Text(result.message),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Alert'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFE65100)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Broadcast from',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text(
                            _locationText ?? 'Fetching...',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _loadLocation,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Alert type selector
            const Text('Alert Type',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...AlertType.values.map((t) => RadioListTile<AlertType>(
                  value: t,
                  groupValue: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v!),
                  title: Text(t.label),
                  secondary: Text(t.emoji,
                      style: const TextStyle(fontSize: 22)),
                  activeColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                )),
            const SizedBox(height: 20),

            // Radius slider
            const Text('Broadcast Radius',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1 km'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_radiusKm.toStringAsFixed(1)} km radius',
                            style: const TextStyle(
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text('25 km'),
                      ],
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 1,
                      max: 25,
                      divisions: 48,
                      activeColor: const Color(0xFFE65100),
                      onChanged: (v) =>
                          setState(() => _radiusKm = v),
                    ),
                    Text(
                      'Estimated reach: ~${(_radiusKm * 15).round()} devices',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Verification note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your broadcast is subject to community verification. '
                      'False alerts may result in account suspension.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Broadcast button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: _isBroadcasting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.broadcast_on_personal),
                label: Text(
                    _isBroadcasting ? 'Broadcasting...' : 'Send Broadcast Alert',
                    style: const TextStyle(fontSize: 16)),
                onPressed: _isBroadcasting ? null : _broadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            // Broadcast history
            if (_alertService.broadcasts.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text('Recent Broadcasts',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ..._alertService.broadcasts.take(5).map((b) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Text(b.type.emoji,
                          style: const TextStyle(fontSize: 22)),
                      title: Text(b.type.label,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(b.message,
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        _formatTime(b.sentAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

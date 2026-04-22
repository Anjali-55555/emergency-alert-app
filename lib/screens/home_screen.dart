import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alert_models.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../services/sms_call_service.dart';
import 'missing_child_screen.dart';
import 'blood_donation_screen.dart';
import 'contacts_screen.dart';
import 'broadcast_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _alertService = AlertService();
  int _selectedIndex = 0;

  late AnimationController _sosController;
  late Animation<double> _sosPulse;

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _sosPulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
    );
    _requestPermissions();
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.sms,
      Permission.phone,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          MissingChildScreen(),
          BloodDonationScreen(),
          ContactsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.child_care_outlined),
              selectedIcon: Icon(Icons.child_care),
              label: 'Missing'),
          NavigationDestination(
              icon: Icon(Icons.water_drop_outlined),
              selectedIcon: Icon(Icons.water_drop),
              label: 'Blood'),
          NavigationDestination(
              icon: Icon(Icons.contacts_outlined),
              selectedIcon: Icon(Icons.contacts),
              label: 'Contacts'),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with TickerProviderStateMixin {
  final _alertService = AlertService();
  bool _isSendingAlert = false;
  String _locationText = 'Fetching location...';
  double? _lat;
  double? _lng;

  late AnimationController _sosController;
  late Animation<double> _sosPulse;
  late AnimationController _ringController;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _sosPulse = Tween(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ringAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _loadLocation();
  }

  @override
  void dispose() {
    _sosController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    if (mounted) setState(() => _locationText = 'Fetching GPS...');
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        if (loc != null) {
          _lat = loc['lat'] as double?;
          _lng = loc['lng'] as double?;
          _locationText =
              loc['address'] as String? ?? '$_lat, $_lng';
        } else {
          _locationText = 'Location unavailable — check GPS';
        }
      });
    }
  }

  Future<void> _sendSos() async {
    if (_isSendingAlert) return;

    final contacts = _alertService.contacts;

    if (contacts.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('No Contacts'),
          ]),
          content: const Text(
            'Please add at least one emergency contact first.\n\n'
            'Go to the Contacts tab to add your contact.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Colors.red),
          SizedBox(width: 8),
          Text('Send SOS Alert'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency SMS will be sent to ${contacts.length} contact(s):',
            ),
            const SizedBox(height: 8),
            ...contacts.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${c.name} — ${c.phone}',
                        style: const TextStyle(fontSize: 13)),
                  ]),
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_locationText,
                      style: const TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SEND SOS',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSendingAlert = true);

    final loc = await LocationService.getCurrentLocation();
    final lat = loc?['lat'] as double? ?? _lat;
    final lng = loc?['lng'] as double? ?? _lng;

    final result = await SMSCallService.sendEmergencySMS(
      contacts: contacts,
      message: '🆘 EMERGENCY! I need immediate help!',
      lat: lat,
      lng: lng,
    );

    if (!mounted) return;
    setState(() => _isSendingAlert = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor:
            result.success ? Colors.green[700] : Colors.red[700],
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final hasAlerts = _alertService.missingChildren.isNotEmpty ||
        _alertService.bloodRequests.isNotEmpty;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFFD32F2F),
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Emergency Alert',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD32F2F), Color(0xFF880E0E)],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.broadcast_on_personal,
                  color: Colors.white),
              tooltip: 'Broadcast Alert',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BroadcastScreen())),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LocationCard(
                  locationText: _locationText,
                  onRefresh: _loadLocation,
                ),
                const SizedBox(height: 20),

                // SOS Button
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ringAnim,
                        builder: (_, __) => Container(
                          width: 200 + (_ringAnim.value * 40),
                          height: 200 + (_ringAnim.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(
                                  (1 - _ringAnim.value) * 0.4),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _sosPulse,
                        child: GestureDetector(
                          onTap: _sendSos,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isSendingAlert
                                  ? Colors.orange
                                  : const Color(0xFFD32F2F),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: _isSendingAlert
                                ? const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3)
                                : const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emergency,
                                          color: Colors.white, size: 52),
                                      SizedBox(height: 6),
                                      Text('SOS',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 4)),
                                      Text('TAP TO ALERT',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              letterSpacing: 1.5)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // No contacts warning
                if (_alertService.contacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.orange.withOpacity(0.4)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.warning_amber,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No contacts saved! Go to Contacts tab to add '
                          'your emergency contact before using SOS.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ]),
                  ),

                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _QuickActionCard(
                      icon: Icons.child_care,
                      label: 'Missing Child',
                      subtitle:
                          '${_alertService.missingChildren.length} active',
                      color: const Color(0xFF1565C0),
                      onTap: () {},
                    ),
                    _QuickActionCard(
                      icon: Icons.water_drop,
                      label: 'Blood Needed',
                      subtitle:
                          '${_alertService.bloodRequests.length} requests',
                      color: const Color(0xFFC62828),
                      onTap: () {},
                    ),
                    _QuickActionCard(
                      icon: Icons.broadcast_on_personal,
                      label: 'Broadcast',
                      subtitle: 'Alert nearby',
                      color: const Color(0xFFE65100),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BroadcastScreen())),
                    ),
                    _QuickActionCard(
                      icon: Icons.contacts,
                      label: 'Contacts',
                      subtitle: '${_alertService.contacts.length} saved',
                      color: const Color(0xFF2E7D32),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (hasAlerts) ...[
                  const Text('Active Nearby Alerts',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._alertService.missingChildren.map((a) =>
                      _AlertSummaryCard(
                        icon: Icons.child_care,
                        color: const Color(0xFF1565C0),
                        title: 'Missing: ${a.childName}, ${a.age}',
                        subtitle: a.lastSeenLocation,
                        phone: a.contactNumber,
                        onCall: () => _callNumber(a.contactNumber),
                      )),
                  ..._alertService.bloodRequests.map((r) =>
                      _AlertSummaryCard(
                        icon: Icons.water_drop,
                        color: const Color(0xFFC62828),
                        title:
                            '${r.bloodGroup.label} blood — ${r.urgencyLevel.toUpperCase()}',
                        subtitle: r.hospital,
                        phone: r.contactNumber,
                        onCall: () => _callNumber(r.contactNumber),
                      )),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final String locationText;
  final VoidCallback onRefresh;
  const _LocationCard(
      {required this.locationText, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFFD32F2F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(locationText,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onRefresh,
              tooltip: 'Refresh location',
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: color),
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertSummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String phone;
  final VoidCallback onCall;

  const _AlertSummaryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle:
            Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.green),
          onPressed: onCall,
          tooltip: 'Call $phone',
        ),
      ),
    );
  }
}

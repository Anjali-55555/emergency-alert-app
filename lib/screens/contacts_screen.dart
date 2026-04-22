import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/alert_models.dart';
import '../services/alert_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _alertService = AlertService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('emergency_contacts') ?? [];
    if (saved.isNotEmpty) {
      _alertService.contacts.clear();
      for (final json in saved) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _alertService.addContact(EmergencyContact.fromJson(map));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _alertService.contacts
        .map((c) => jsonEncode(c.toJson()))
        .toList();
    await prefs.setStringList('emergency_contacts', list);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _alertService.contacts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showEditDialog(null),
            tooltip: 'Add contact',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No emergency contacts yet.',
                          style: TextStyle(color: Colors.grey[500])),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Contact'),
                        onPressed: () => _showEditDialog(null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SOS alerts will be sent to all '
                              '${contacts.length} contact(s) below.',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: contacts.length,
                        itemBuilder: (ctx, i) => _ContactCard(
                          contact: contacts[i],
                          onCall: () => _callContact(contacts[i]),
                          onEdit: () => _showEditDialog(contacts[i]),
                          onDelete: () => _deleteContact(contacts[i]),
                        ),
                      ),
                    ),
                    // Emergency numbers section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('EMERGENCY NUMBERS',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        _EmergencyTile('👮', '100', 'Police'),
                        _EmergencyTile('🚑', '108', 'Ambulance'),
                        _EmergencyTile('🧒', '1098', 'Child'),
                        _EmergencyTile('🔥', '101', 'Fire'),
                      ],
                    ),
                  ],
                ),
    );
  }

  Future<void> _callContact(EmergencyContact contact) async {
    final uri = Uri(scheme: 'tel', path: contact.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove ${contact.name} from emergency contacts?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _alertService.removeContact(contact.id);
      await _saveContacts();
      setState(() {});
    }
  }

  void _showEditDialog(EmergencyContact? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phone ?? '');
    final relCtrl =
        TextEditingController(text: existing?.relationship ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null
            ? 'Add Emergency Contact'
            : 'Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number (+91XXXXXXXXXX)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: relCtrl,
                decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                return;
              }
              if (existing != null) {
                existing.name = nameCtrl.text;
                existing.phone = phoneCtrl.text;
                existing.relationship = relCtrl.text;
                _alertService.updateContact(existing);
              } else {
                _alertService.addContact(EmergencyContact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  phone: phoneCtrl.text,
                  relationship: relCtrl.text,
                ));
              }
              await _saveContacts();
              if (!mounted) return;
              setState(() {});
              Navigator.pop(ctx);
            },
            child: Text(existing == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = contact.name.isNotEmpty
        ? contact.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E7D32).withOpacity(0.15),
          child: Text(initials.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(contact.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phone, style: const TextStyle(fontSize: 13)),
            if (contact.relationship.isNotEmpty)
              Text(contact.relationship,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: onCall,
              tooltip: 'Call',
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final String emoji;
  final String number;
  final String label;
  const _EmergencyTile(this.emoji, this.number, this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri(scheme: 'tel', path: number);
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            Text(number,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1565C0))),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
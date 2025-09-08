import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart'; // AppTheme, CustomIconWidget, etc.

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _emailCtl = TextEditingController(); // read-only here
  final _bioCtl = TextEditingController();
  String? _avatarUrl;
  XFile? _pickedImage;

  // Role / Language / Privacy
  final _languages = const ['English', 'हिंदी', 'मराठी'];
  final _roles = const ['tenant', 'owner', 'both'];
  String _selectedLanguage = 'English';
  String _role = 'tenant';
  bool _notificationsEnabled = true;
  bool _marketingOptIn = false;
  bool _allowContact = true;
  bool _publicProfile = true;

  // Address
  final _addrLine1Ctl = TextEditingController();
  final _cityCtl = TextEditingController();
  final _stateCtl = TextEditingController();
  final _zipCtl = TextEditingController();
  final _countryCtl = TextEditingController(text: 'India');

  // Preferences
  final _budgetMinCtl = TextEditingController();
  final _budgetMaxCtl = TextEditingController();
  int _bedrooms = 1;
  bool _petsAllowed = false;

  // KYC-lite (safe: last 4 only)
  final _govtIdLast4Ctl = TextEditingController();
  final _kycStatuses = const ['unverified', 'pending', 'verified'];
  String _kycStatus = 'unverified';

  // DOB
  DateTime? _dob;

  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _emailCtl.dispose();
    _bioCtl.dispose();
    _addrLine1Ctl.dispose();
    _cityCtl.dispose();
    _stateCtl.dispose();
    _zipCtl.dispose();
    _countryCtl.dispose();
    _budgetMinCtl.dispose();
    _budgetMaxCtl.dispose();
    _govtIdLast4Ctl.dispose();
    super.dispose();
  }

  // ---------- helpers for safe casting ----------
  Map<String, dynamic> _asMap(Object? m) {
    if (m is Map) {
      return m.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  int _asInt(Object? v, {int def = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  bool _asBool(Object? v, {bool def = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return def;
  }

  DateTime? _asDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      final t = DateTime.tryParse(v);
      return t;
    }
    return null;
  }

  // ---------- load ----------
  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    final userRef = _userRef;
    if (user == null || userRef == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      final snap = await userRef.get();
      final data = snap.data() ?? <String, dynamic>{};

      // Basic
      _nameCtl.text   = (data['name'] ?? user.displayName ?? '').toString();
      _phoneCtl.text  = (data['phone'] ?? '').toString();
      _emailCtl.text  = (data['email'] ?? user.email ?? '').toString();
      _bioCtl.text    = (data['bio'] ?? '').toString();
      _avatarUrl      = (data['avatar'] ?? user.photoURL ?? '').toString();
      _role           = (data['role'] ?? 'tenant').toString();

      // Settings
      final settings = _asMap(data['settings']);
      _selectedLanguage     = (settings['language'] ?? 'English').toString();
      _notificationsEnabled = _asBool(settings['notificationsEnabled'], def: true);
      _marketingOptIn       = _asBool(settings['marketingOptIn']);
      _allowContact         = _asBool(settings['allowContact'], def: true);
      _publicProfile        = _asBool(settings['publicProfile'], def: true);

      // Address
      final address = _asMap(data['address']);
      _addrLine1Ctl.text = (address['line1'] ?? '').toString();
      _cityCtl.text      = (address['city']  ?? '').toString();
      _stateCtl.text     = (address['state'] ?? '').toString();
      _zipCtl.text       = (address['zip']   ?? '').toString();
      _countryCtl.text   = (address['country'] ?? _countryCtl.text).toString();

      // Preferences
      final prefs = _asMap(data['preferences']);
      _budgetMinCtl.text = _asInt(prefs['budgetMin']).toString();
      _budgetMaxCtl.text = _asInt(prefs['budgetMax']).toString();
      _bedrooms          = _asInt(prefs['bedrooms'], def: 1).clamp(0, 10);
      _petsAllowed       = _asBool(prefs['petsAllowed']);

      // KYC
      final kyc = _asMap(data['kyc']);
      _kycStatus = (kyc['status'] ?? 'unverified').toString();
      _govtIdLast4Ctl.text = (kyc['govtIdLast4'] ?? '').toString();

      // DOB
      _dob = _asDate(data['dob']);
    } catch (_) {
      // ignore, user can still edit
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- image pick / upload ----------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<String?> _uploadAvatarIfNeeded(String uid) async {
    if (_pickedImage == null) return _avatarUrl;
    try {
      final file = File(_pickedImage!.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return _avatarUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar upload failed: $e')),
      );
      return _avatarUrl;
    }
  }

  // ---------- save ----------
  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final userRef = _userRef;
    if (user == null || userRef == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final newAvatar = await _uploadAvatarIfNeeded(user.uid);

      // nested payload
      final payload = <String, dynamic>{
        'name'  : _nameCtl.text.trim(),
        'phone' : _phoneCtl.text.trim(),
        'email' : _emailCtl.text.trim(), // NOTE: changing Auth email needs reauth
        'bio'   : _bioCtl.text.trim(),
        'avatar': newAvatar ?? '',
        'role'  : _role,
        'dob'   : _dob, // Firestore will store as Timestamp
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        // address block
        'address': {
          'line1'  : _addrLine1Ctl.text.trim(),
          'city'   : _cityCtl.text.trim(),
          'state'  : _stateCtl.text.trim(),
          'zip'    : _zipCtl.text.trim(),
          'country': _countryCtl.text.trim(),
        },
        // preferences block
        'preferences': {
          'budgetMin' : _toIntOrNull(_budgetMinCtl.text.trim()),
          'budgetMax' : _toIntOrNull(_budgetMaxCtl.text.trim()),
          'bedrooms'  : _bedrooms,
          'petsAllowed': _petsAllowed,
        },
        // settings block
        'settings': {
          'language'            : _selectedLanguage,
          'notificationsEnabled': _notificationsEnabled,
          'marketingOptIn'      : _marketingOptIn,
          'allowContact'        : _allowContact,
          'publicProfile'       : _publicProfile,
        },
        // kyc-lite
        'kyc': {
          'status'     : _kycStatus,
          'govtIdLast4': _govtIdLast4Ctl.text.trim(),
        },
      };

      // completion score (simple heuristic)
      final completion = _completionPercent(payload);
      payload['completionPercentage'] = completion;

      // set once if missing
      payload['memberSince'] = FieldValue.serverTimestamp();

      await userRef.set(payload, SetOptions(merge: true));

      await user.updateDisplayName(_nameCtl.text.trim());
      if ((newAvatar ?? '').isNotEmpty) {
        await user.updatePhotoURL(newAvatar);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to save')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _completionPercent(Map<String, dynamic> p) {
    // count a subset of important fields
    int filled = 0, total = 0;

    bool _has(String key) {
      total++;
      final v = p[key];
      return (v is String && v.trim().isNotEmpty) ||
             (v is Map && v.isNotEmpty) ||
             (v is bool) ||
             (v is num) ||
             (v is DateTime);
    }

    if (_has('name'))           if (p['name'].toString().isNotEmpty) filled++;
    if (_has('phone'))          if (p['phone'].toString().isNotEmpty) filled++;
    if (_has('avatar'))         if (p['avatar'].toString().isNotEmpty) filled++;
    if (_has('role'))           if (p['role'].toString().isNotEmpty) filled++;
    if (_has('dob'))            if (p['dob'] != null) filled++;

    final addr = _asMap(p['address']);
    total += 3;
    if ((addr['city'] ?? '').toString().isNotEmpty) filled++;
    if ((addr['state'] ?? '').toString().isNotEmpty) filled++;
    if ((addr['country'] ?? '').toString().isNotEmpty) filled++;

    final prefs = _asMap(p['preferences']);
    total += 2;
    if (prefs['budgetMin'] != null || prefs['budgetMax'] != null) filled++;
    if (prefs['bedrooms'] != null) filled++;

    final settings = _asMap(p['settings']);
    total += 2;
    if (settings['language'] != null) filled++;
    if (settings['notificationsEnabled'] != null) filled++;

    return ((filled / total) * 100).round().clamp(0, 100);
  }

  int? _toIntOrNull(String s) {
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: theme.colorScheme.surface,
                            backgroundImage: _pickedImage != null
                                ? FileImage(File(_pickedImage!.path))
                                : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                    ? NetworkImage(_avatarUrl!) as ImageProvider
                                    : null,
                            child: (_avatarUrl == null || _avatarUrl!.isEmpty) && _pickedImage == null
                                ? Text(
                                    _initials(_nameCtl.text),
                                    style: GoogleFonts.inter(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'camera_alt',
                                  color: theme.colorScheme.onPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),

                    _SectionHeader('Basic Info'),
                    _Labeled(
                      'Full Name',
                      TextFormField(
                        controller: _nameCtl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'Enter your name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                    ),
                    _Labeled(
                      'Role',
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: _roles
                            .map((r) => DropdownMenuItem(value: r, child: Text(r[0].toUpperCase() + r.substring(1))))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? 'tenant'),
                        decoration: const InputDecoration(),
                      ),
                    ),
                    _Labeled(
                      'Date of Birth',
                      InkWell(
                        onTap: _pickDob,
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(
                            _dob == null
                                ? 'Select your birth date'
                                : '${_dob!.day.toString().padLeft(2, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.year}',
                          ),
                        ),
                      ),
                    ),
                    _Labeled(
                      'About',
                      TextFormField(
                        controller: _bioCtl,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: 'Tell us a bit about yourself'),
                      ),
                    ),

                    _SectionHeader('Contact'),
                    _Labeled(
                      'Phone',
                      TextFormField(
                        controller: _phoneCtl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: '+91 98xxxxxx'),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Phone is required';
                          if (!RegExp(r'^\+?\d[\d\s\-]{6,}$').hasMatch(t)) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                    _Labeled(
                      'Email',
                      TextFormField(
                        controller: _emailCtl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'you@email.com',
                          suffixIcon: Tooltip(
                            message: 'Changing email requires re-authentication.',
                            child: Icon(Icons.info_outline),
                          ),
                        ),
                      ),
                    ),

                    _SectionHeader('Address'),
                    _Labeled(
                      'Address Line 1',
                      TextFormField(
                        controller: _addrLine1Ctl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'House / Flat, Street'),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _Labeled(
                            'City',
                            TextFormField(
                              controller: _cityCtl,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _Labeled(
                            'State',
                            TextFormField(
                              controller: _stateCtl,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _Labeled(
                            'PIN/ZIP',
                            TextFormField(
                              controller: _zipCtl,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _Labeled(
                            'Country',
                            TextFormField(
                              controller: _countryCtl,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ),
                      ],
                    ),

                    _SectionHeader('Preferences'),
                    Row(
                      children: [
                        Expanded(
                          child: _Labeled(
                            'Budget Min (₹)',
                            TextFormField(
                              controller: _budgetMinCtl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g. 15000'),
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: _Labeled(
                            'Budget Max (₹)',
                            TextFormField(
                              controller: _budgetMaxCtl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'e.g. 45000'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _Labeled(
                      'Bedrooms',
                      DropdownButtonFormField<int>(
                        value: _bedrooms,
                        items: List.generate(8, (i) => i)
                            .map((n) => DropdownMenuItem(value: n, child: Text(n == 0 ? 'Studio' : '$n BHK')))
                            .toList(),
                        onChanged: (v) => setState(() => _bedrooms = v ?? 1),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      value: _petsAllowed,
                      onChanged: (v) => setState(() => _petsAllowed = v),
                      title: const Text('Pets Allowed'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    _SectionHeader('Privacy & Notifications'),
                    _Labeled(
                      'Language',
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        items: _languages
                            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedLanguage = v ?? 'English'),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                      title: const Text('Push Notifications'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile.adaptive(
                      value: _marketingOptIn,
                      onChanged: (v) => setState(() => _marketingOptIn = v),
                      title: const Text('Marketing Updates'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile.adaptive(
                      value: _allowContact,
                      onChanged: (v) => setState(() => _allowContact = v),
                      title: const Text('Allow Contact by Owners/Agents'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile.adaptive(
                      value: _publicProfile,
                      onChanged: (v) => setState(() => _publicProfile = v),
                      title: const Text('Public Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    _SectionHeader('Identity (KYC-lite)'),
                    _Labeled(
                      'Status',
                      DropdownButtonFormField<String>(
                        value: _kycStatus,
                        items: _kycStatuses
                            .map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1))))
                            .toList(),
                        onChanged: (v) => setState(() => _kycStatus = v ?? 'unverified'),
                      ),
                    ),
                    _Labeled(
                      'Govt ID (last 4 only)',
                      TextFormField(
                        controller: _govtIdLast4Ctl,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1234'),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null; // optional
                          if (!RegExp(r'^\d{4}$').hasMatch(t)) {
                            return 'Enter exactly last 4 digits';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: CustomIconWidget(
                          iconName: 'save',
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          _saving ? 'Saving...' : 'Save Changes',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      initialDate: initial,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

// ---------- small UI helpers ----------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;
    return Padding(
      padding: EdgeInsets.only(top: 1.2.h, bottom: 0.6.h),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 1.4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 0.6.h),
          child,
        ],
      ),
    );
  }
}

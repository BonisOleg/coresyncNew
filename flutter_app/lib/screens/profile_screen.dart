import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../providers/providers.dart';
import '../widgets/glass_panel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _firstNameCtl;
  late TextEditingController _lastNameCtl;
  late TextEditingController _emailCtl;

  @override
  void initState() {
    super.initState();
    _firstNameCtl = TextEditingController();
    _lastNameCtl = TextEditingController();
    _emailCtl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    super.dispose();
  }

  void _startEditing() {
    final guest = ref.read(authStateProvider).guest;
    if (guest == null) return;
    _firstNameCtl.text = guest.firstName;
    _lastNameCtl.text = guest.lastName;
    _emailCtl.text = guest.email;
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updateProfile({
        'first_name': _firstNameCtl.text.trim(),
        'last_name': _lastNameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
      });
      await ref.read(authStateProvider.notifier).loadProfile();
      if (mounted) setState(() => _isEditing = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authStateProvider.notifier).logout();
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CoreSyncColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: CoreSyncColors.textPrimary),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
          style: TextStyle(
            color: CoreSyncColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(authStateProvider.notifier).deleteAccount();
  }

  String _initials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final guest = authState.guest;

    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing && guest != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: _startEditing,
            ),
        ],
      ),
      body: guest == null
          ? const Center(
              child: Text(
                'Not logged in',
                style: TextStyle(color: CoreSyncColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: CoreSyncColors.glass,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CoreSyncColors.glassBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials(guest.firstName, guest.lastName)
                                .isNotEmpty
                            ? _initials(
                                guest.firstName, guest.lastName)
                            : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: CoreSyncColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_isEditing) ...[
                    // Display mode
                    if (guest.fullName.isNotEmpty)
                      Text(
                        guest.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: CoreSyncColors.textPrimary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      guest.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CoreSyncColors.textSecondary,
                      ),
                    ),
                    if (guest.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        guest.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CoreSyncColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Info card
                    GlassPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Phone',
                            value: guest.phone,
                          ),
                          if (guest.email.isNotEmpty)
                            _InfoRow(
                              label: 'Email',
                              value: guest.email,
                            ),
                          _InfoRow(
                            label: 'Status',
                            value: guest.isRegistered
                                ? 'Registered'
                                : 'Guest',
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Edit mode
                    const SizedBox(height: 16),
                    TextField(
                      controller: _firstNameCtl,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _lastNameCtl,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelEditing,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  CoreSyncColors.textSecondary,
                              side: const BorderSide(
                                color: CoreSyncColors.glassBorder,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: CoreSyncColors.bg,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // AI Concierge button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => context.go('/profile/concierge'),
                      child: GlassPanel(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: CoreSyncColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CoreSyncColors.glassBorder,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_outlined,
                                size: 20,
                                color: CoreSyncColors.accent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Concierge',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: CoreSyncColors
                                          .textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Get personalised assistance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CoreSyncColors
                                          .textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: CoreSyncColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CoreSyncColors.textSecondary,
                        side: const BorderSide(
                          color: CoreSyncColors.glassBorder,
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Delete account
                  const Text(
                    'DANGER ZONE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleDeleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side:
                            const BorderSide(color: Colors.redAccent),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: CoreSyncColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: CoreSyncColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

/// Guest profile and settings screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        centerTitle: true,
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          final guest = auth.guest;
          if (guest == null) {
            return const Center(child: Text('Not logged in'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar / initials
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: CoreSyncTheme.surfaceColor,
                  child: Text(
                    guest.fullName.isNotEmpty
                        ? guest.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      color: CoreSyncTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (guest.fullName.isNotEmpty)
                Center(
                  child: Text(
                    guest.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  guest.phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CoreSyncTheme.textMuted,
                      ),
                ),
              ),
              const SizedBox(height: 32),
              // Info cards
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: CoreSyncTheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(context, 'Phone', guest.phone),
                      if (guest.email.isNotEmpty)
                        _infoRow(context, 'Email', guest.email),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: CoreSyncTheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        context,
                        'Registration',
                        guest.isRegistered ? 'Registered' : 'Guest',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('SIGN OUT'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: CoreSyncTheme.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

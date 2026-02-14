import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/device.dart';

/// Device control card for the SPA control screen.
class DeviceControlCard extends StatelessWidget {
  final Device device;
  final void Function(Map<String, dynamic> state)? onStateChange;

  const DeviceControlCard({
    super.key,
    required this.device,
    this.onStateChange,
  });

  IconData get _deviceIcon {
    switch (device.deviceType.name.toLowerCase()) {
      case 'light':
        return Icons.lightbulb_outline;
      case 'thermostat':
        return Icons.thermostat;
      case 'audio':
        return Icons.music_note;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPowered = device.currentState['power'] == 'on';
    final brightness = (device.currentState['brightness'] as num?)?.toDouble();
    final temperature = (device.currentState['temperature'] as num?)?.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _deviceIcon,
                  color: isPowered
                      ? CoreSyncTheme.textPrimary
                      : CoreSyncTheme.textMuted,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (device.room.isNotEmpty)
                        Text(
                          device.room,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: CoreSyncTheme.textMuted,
                              ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: isPowered,
                  onChanged: (value) {
                    onStateChange?.call({'power': value ? 'on' : 'off'});
                  },
                  activeThumbColor: CoreSyncTheme.textPrimary,
                ),
              ],
            ),
            if (isPowered && brightness != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.brightness_6,
                    size: 16,
                    color: CoreSyncTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: brightness.clamp(0, 100),
                      min: 0,
                      max: 100,
                      activeColor: CoreSyncTheme.textPrimary,
                      inactiveColor: CoreSyncTheme.glassBorder,
                      onChanged: (value) {
                        onStateChange?.call({'brightness': value.round()});
                      },
                    ),
                  ),
                  Text(
                    '${brightness.round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CoreSyncTheme.textMuted,
                        ),
                  ),
                ],
              ),
            ],
            if (isPowered && temperature != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.thermostat,
                    size: 16,
                    color: CoreSyncTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: temperature.clamp(16, 30),
                      min: 16,
                      max: 30,
                      divisions: 28,
                      activeColor: CoreSyncTheme.textPrimary,
                      inactiveColor: CoreSyncTheme.glassBorder,
                      onChanged: (value) {
                        onStateChange?.call({'temperature': value.round()});
                      },
                    ),
                  ),
                  Text(
                    '${temperature.round()}°C',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CoreSyncTheme.textMuted,
                        ),
                  ),
                ],
              ),
            ],
            if (!device.isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Offline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.withAlpha(180),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

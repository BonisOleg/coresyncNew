import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/spa_control_service.dart';
import '../widgets/device_control_card.dart';

/// SPA device control screen — lights, temperature, audio.
class SpaControlScreen extends StatefulWidget {
  const SpaControlScreen({super.key});

  @override
  State<SpaControlScreen> createState() => _SpaControlScreenState();
}

class _SpaControlScreenState extends State<SpaControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpaControlService>().fetchDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTROLS'),
        centerTitle: true,
      ),
      body: Consumer<SpaControlService>(
        builder: (context, spaService, _) {
          if (spaService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: CoreSyncTheme.textMuted,
                strokeWidth: 2,
              ),
            );
          }

          if (spaService.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune_outlined,
                    size: 48,
                    color: CoreSyncTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No devices available',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Devices will appear when configured',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CoreSyncTheme.textMuted,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => spaService.fetchDevices(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: spaService.devices.length,
              itemBuilder: (context, index) {
                final device = spaService.devices[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DeviceControlCard(
                    device: device,
                    onStateChange: (state) {
                      spaService.controlDevice(device.id, state);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

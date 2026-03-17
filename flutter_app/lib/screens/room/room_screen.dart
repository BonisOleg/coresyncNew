import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/device.dart';
import '../../models/scene.dart';
import '../../models/scent.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_panel.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreSyncColors.bg,
      appBar: AppBar(
        title: const Text(
          'ROOM',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CoreSyncColors.accent,
          indicatorWeight: 1.5,
          labelColor: CoreSyncColors.textPrimary,
          unselectedLabelColor: CoreSyncColors.textMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: 'Scenes'),
            Tab(text: 'Scent'),
            Tab(text: 'Controls'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ScenesTab(),
          _ScentTab(),
          _ControlsTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCENES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ScenesTab extends ConsumerStatefulWidget {
  const _ScenesTab();

  @override
  ConsumerState<_ScenesTab> createState() => _ScenesTabState();
}

class _ScenesTabState extends ConsumerState<_ScenesTab> {
  List<Scene> _scenes = [];
  ActiveRoomScene? _activeScene;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    setState(() => _isLoading = true);
    final sceneService = ref.read(sceneServiceProvider);
    final results = await Future.wait([
      sceneService.getScenes(),
      sceneService.getActiveScene(),
    ]);
    if (!mounted) return;
    setState(() {
      _scenes = results[0] as List<Scene>;
      _activeScene = results[1] as ActiveRoomScene?;
      _isLoading = false;
    });
  }

  void _showSceneSheet(Scene scene) {
    final isActive = _activeScene?.scene.id == scene.id;
    bool musicEnabled = _activeScene?.musicEnabled ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: CoreSyncColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CoreSyncColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (scene.thumbnailUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        scene.thumbnailUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: CoreSyncColors.glass,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.landscape_outlined,
                            size: 48,
                            color: CoreSyncColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    scene.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: CoreSyncColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scene.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                  if (scene.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      scene.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CoreSyncColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (scene.tracks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Music',
                          style: TextStyle(
                            fontSize: 15,
                            color: CoreSyncColors.textPrimary,
                          ),
                        ),
                        Switch.adaptive(
                          value: musicEnabled,
                          activeTrackColor: CoreSyncColors.accent,
                          onChanged: (val) {
                            setSheetState(() => musicEnabled = val);
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: isActive
                        ? OutlinedButton(
                            onPressed: () => _deactivateScene(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Deactivate'),
                          )
                        : ElevatedButton(
                            onPressed: () => _activateScene(
                              ctx,
                              scene.id,
                              musicEnabled,
                            ),
                            child: const Text('Activate'),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _activateScene(
    BuildContext ctx,
    int sceneId,
    bool musicEnabled,
  ) async {
    Navigator.of(ctx).pop();
    try {
      await ref.read(sceneServiceProvider).activateScene(
            sceneId,
            musicEnabled: musicEnabled,
          );
      await _loadScenes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to activate scene')),
      );
    }
  }

  Future<void> _deactivateScene(BuildContext ctx) async {
    Navigator.of(ctx).pop();
    try {
      await ref.read(sceneServiceProvider).deactivateScene();
      await _loadScenes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to deactivate scene')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: CoreSyncColors.accent,
          strokeWidth: 1.5,
        ),
      );
    }

    if (_scenes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.landscape_outlined,
              size: 48,
              color: CoreSyncColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No scenes available',
              style: TextStyle(
                fontSize: 16,
                color: CoreSyncColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadScenes,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: CoreSyncColors.accent,
      backgroundColor: CoreSyncColors.surface,
      onRefresh: _loadScenes,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemCount: _scenes.length,
        itemBuilder: (context, index) {
          final scene = _scenes[index];
          final isActive = _activeScene?.scene.id == scene.id;
          return _SceneCard(
            scene: scene,
            isActive: isActive,
            onTap: () => _showSceneSheet(scene),
          );
        },
      ),
    );
  }
}

class _SceneCard extends StatelessWidget {
  final Scene scene;
  final bool isActive;
  final VoidCallback onTap;

  const _SceneCard({
    required this.scene,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: CoreSyncColors.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? CoreSyncColors.accent
                : CoreSyncColors.glassBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: scene.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        scene.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: CoreSyncColors.surface,
                          child: const Icon(
                            Icons.landscape_outlined,
                            size: 36,
                            color: CoreSyncColors.textMuted,
                          ),
                        ),
                      )
                    : Container(
                        color: CoreSyncColors.surface,
                        child: const Icon(
                          Icons.landscape_outlined,
                          size: 36,
                          color: CoreSyncColors.textMuted,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CoreSyncColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CoreSyncColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          scene.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: CoreSyncColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const Spacer(),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCENT TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ScentTab extends ConsumerStatefulWidget {
  const _ScentTab();

  @override
  ConsumerState<_ScentTab> createState() => _ScentTabState();
}

class _ScentTabState extends ConsumerState<_ScentTab> {
  List<ScentProfile> _profiles = [];
  ActiveScent? _activeScent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScents();
  }

  Future<void> _loadScents() async {
    setState(() => _isLoading = true);
    final scentService = ref.read(scentServiceProvider);
    final results = await Future.wait([
      scentService.getScentProfiles(),
      scentService.getActiveScent(),
    ]);
    if (!mounted) return;
    setState(() {
      _profiles = results[0] as List<ScentProfile>;
      _activeScent = results[1] as ActiveScent?;
      _isLoading = false;
    });
  }

  void _showScentSheet(ScentProfile profile) {
    final isActive = _activeScent?.scentProfile.id == profile.id;
    double intensity = isActive
        ? _activeScent!.intensity.toDouble()
        : profile.intensityDefault.toDouble();

    showModalBottomSheet(
      context: context,
      backgroundColor: CoreSyncColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CoreSyncColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: CoreSyncColors.glass,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: CoreSyncColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.air_outlined,
                      size: 28,
                      color: CoreSyncColors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: CoreSyncColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                  if (profile.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      profile.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CoreSyncColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Intensity',
                        style: TextStyle(
                          fontSize: 14,
                          color: CoreSyncColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        intensity.round().toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CoreSyncColors.accent,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: intensity,
                    min: profile.intensityMin.toDouble(),
                    max: profile.intensityMax.toDouble(),
                    divisions: profile.intensityMax - profile.intensityMin,
                    activeColor: CoreSyncColors.accent,
                    inactiveColor: CoreSyncColors.glassBorder,
                    onChanged: (val) {
                      setSheetState(() => intensity = val);
                    },
                    onChangeEnd: isActive
                        ? (val) => _updateIntensity(val.round())
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: isActive
                        ? OutlinedButton(
                            onPressed: () => _deactivateScent(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                  color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Deactivate'),
                          )
                        : ElevatedButton(
                            onPressed: () => _activateScent(
                              ctx,
                              profile.id,
                              intensity.round(),
                            ),
                            child: const Text('Activate'),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _activateScent(
    BuildContext ctx,
    int profileId,
    int intensity,
  ) async {
    Navigator.of(ctx).pop();
    try {
      await ref.read(scentServiceProvider).activateScent(
            profileId,
            intensity,
          );
      await _loadScents();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to activate scent')),
      );
    }
  }

  Future<void> _deactivateScent(BuildContext ctx) async {
    Navigator.of(ctx).pop();
    try {
      await ref.read(scentServiceProvider).deactivateScent();
      await _loadScents();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to deactivate scent')),
      );
    }
  }

  Future<void> _updateIntensity(int intensity) async {
    try {
      final result =
          await ref.read(scentServiceProvider).updateIntensity(intensity);
      if (result != null && mounted) {
        setState(() => _activeScent = result);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: CoreSyncColors.accent,
          strokeWidth: 1.5,
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.air_outlined,
              size: 48,
              color: CoreSyncColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No scent profiles available',
              style: TextStyle(
                fontSize: 16,
                color: CoreSyncColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadScents,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: CoreSyncColors.accent,
      backgroundColor: CoreSyncColors.surface,
      onRefresh: _loadScents,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _profiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final profile = _profiles[index];
          final isActive =
              _activeScent?.scentProfile.id == profile.id;
          return _ScentCard(
            profile: profile,
            isActive: isActive,
            activeIntensity: isActive ? _activeScent!.intensity : null,
            onTap: () => _showScentSheet(profile),
          );
        },
      ),
    );
  }
}

class _ScentCard extends StatelessWidget {
  final ScentProfile profile;
  final bool isActive;
  final int? activeIntensity;
  final VoidCallback onTap;

  const _ScentCard({
    required this.profile,
    required this.isActive,
    this.activeIntensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? CoreSyncColors.accent.withAlpha(20)
                    : CoreSyncColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? CoreSyncColors.accent
                      : CoreSyncColors.glassBorder,
                ),
              ),
              child: Icon(
                Icons.air_outlined,
                size: 22,
                color: isActive
                    ? CoreSyncColors.accent
                    : CoreSyncColors.textMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CoreSyncColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        profile.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CoreSyncColors.textSecondary,
                        ),
                      ),
                      if (isActive && activeIntensity != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: CoreSyncColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Intensity $activeIntensity',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CoreSyncColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: CoreSyncColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONTROLS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ControlsTab extends ConsumerStatefulWidget {
  const _ControlsTab();

  @override
  ConsumerState<_ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends ConsumerState<_ControlsTab> {
  List<Device> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final devices =
        await ref.read(spaControlServiceProvider).getDevices();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _isLoading = false;
    });
  }

  Future<void> _controlDevice(
    int deviceId,
    Map<String, dynamic> state,
  ) async {
    try {
      await ref.read(spaControlServiceProvider).controlDevice(
            deviceId,
            state,
          );
      await _loadDevices();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device control failed')),
      );
    }
  }

  IconData _deviceIcon(String typeName) {
    final lower = typeName.toLowerCase();
    if (lower.contains('light')) return Icons.lightbulb_outline;
    if (lower.contains('thermo')) return Icons.thermostat_outlined;
    if (lower.contains('audio') || lower.contains('speaker')) {
      return Icons.speaker_outlined;
    }
    if (lower.contains('fan') || lower.contains('hvac')) {
      return Icons.air_outlined;
    }
    return Icons.devices_other_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: CoreSyncColors.accent,
          strokeWidth: 1.5,
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.devices_other_outlined,
              size: 48,
              color: CoreSyncColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No devices found',
              style: TextStyle(
                fontSize: 16,
                color: CoreSyncColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadDevices,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: CoreSyncColors.accent,
      backgroundColor: CoreSyncColors.surface,
      onRefresh: _loadDevices,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = _devices[index];
          return _DeviceCard(
            device: device,
            icon: _deviceIcon(device.deviceType.name),
            onControl: (state) => _controlDevice(device.id, state),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatefulWidget {
  final Device device;
  final IconData icon;
  final void Function(Map<String, dynamic> state) onControl;

  const _DeviceCard({
    required this.device,
    required this.icon,
    required this.onControl,
  });

  @override
  State<_DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<_DeviceCard> {
  late bool _power;
  late double _brightness;
  late double _temperature;

  @override
  void initState() {
    super.initState();
    _power = (widget.device.currentState['power'] as bool?) ?? false;
    _brightness =
        ((widget.device.currentState['brightness'] as num?) ?? 50)
            .toDouble();
    _temperature =
        ((widget.device.currentState['temperature'] as num?) ?? 22)
            .toDouble();
  }

  @override
  void didUpdateWidget(covariant _DeviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.id != widget.device.id) {
      _power =
          (widget.device.currentState['power'] as bool?) ?? false;
      _brightness =
          ((widget.device.currentState['brightness'] as num?) ?? 50)
              .toDouble();
      _temperature =
          ((widget.device.currentState['temperature'] as num?) ?? 22)
              .toDouble();
    }
  }

  String get _typeName => widget.device.deviceType.name.toLowerCase();

  bool get _isLight => _typeName.contains('light');
  bool get _isThermostat => _typeName.contains('thermo');

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 22, color: CoreSyncColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: CoreSyncColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          widget.device.room,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CoreSyncColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.device.isOnline
                                ? Colors.greenAccent.withAlpha(25)
                                : Colors.redAccent.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.device.isOnline
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.device.isOnline
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _power,
                activeTrackColor: CoreSyncColors.accent,
                onChanged: widget.device.isOnline
                    ? (val) {
                        setState(() => _power = val);
                        widget.onControl({'power': val});
                      }
                    : null,
              ),
            ],
          ),
          if (_power && _isLight) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.brightness_6_outlined,
                  size: 16,
                  color: CoreSyncColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _brightness,
                    min: 0,
                    max: 100,
                    activeColor: CoreSyncColors.accent,
                    inactiveColor: CoreSyncColors.glassBorder,
                    onChanged: (val) {
                      setState(() => _brightness = val);
                    },
                    onChangeEnd: (val) {
                      widget.onControl({
                        'power': _power,
                        'brightness': val.round(),
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${_brightness.round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_power && _isThermostat) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.thermostat_outlined,
                  size: 16,
                  color: CoreSyncColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _temperature,
                    min: 16,
                    max: 30,
                    divisions: 28,
                    activeColor: CoreSyncColors.accent,
                    inactiveColor: CoreSyncColors.glassBorder,
                    onChanged: (val) {
                      setState(() => _temperature = val);
                    },
                    onChangeEnd: (val) {
                      widget.onControl({
                        'power': _power,
                        'temperature': val.round(),
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${_temperature.round()}°C',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CoreSyncColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

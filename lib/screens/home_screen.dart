import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/permission_helper.dart';
import '../providers/broadcast_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/broadcast_card.dart';
import '../widgets/device_tile.dart';
import '../widgets/error_dialog.dart';
import '../widgets/how_it_works.dart';
import '../widgets/permission_sheet.dart';
import '../widgets/status_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh devices when app comes back (user might have changed BT settings)
      context.read<DeviceProvider>().loadDevices();
    }
  }

  Future<void> _initialize() async {
    // Show permission sheet on first launch
    final perms = await PermissionHelper.requestAllPermissions();
    _permissionsGranted = perms.values.every((v) => v);

    if (!_permissionsGranted && mounted) {
      PermissionSheet.show(context, () async {
        final results = await PermissionHelper.requestAllPermissions();
        _permissionsGranted = results.values.every((v) => v);
        if (mounted) {
          context.read<DeviceProvider>().loadDevices();
        }
      });
    } else {
      if (mounted) {
        context.read<DeviceProvider>().loadDevices();
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<DeviceProvider>().loadDevices();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  Future<void> _startBroadcast() async {
    final deviceProvider = context.read<DeviceProvider>();
    final broadcastProvider = context.read<BroadcastProvider>();

    final success = await broadcastProvider.startBroadcast(
      deviceProvider.connectedCount,
    );

    if (success) {
      _startAutoRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Now play audio in ANY app!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else if (broadcastProvider.state.hasError && mounted) {
      final error = AppException(
        message: broadcastProvider.state.errorMessage ?? 'Failed',
        severity: broadcastProvider.state.errorSeverity!,
      );
      ErrorDialog.show(
        context,
        exception: error,
        onRetry: _startBroadcast,
      );
    }
  }

  Future<void> _stopBroadcast() async {
    _stopAutoRefresh();
    await context.read<BroadcastProvider>().stopBroadcast();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_audio, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Multi BT Audio'),
          ],
        ),
        centerTitle: true,
        actions: [
          Consumer<DeviceProvider>(
            builder: (_, provider, __) => IconButton(
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed:
                  provider.isLoading ? null : () => provider.loadDevices(),
              tooltip: 'Refresh devices',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DeviceProvider>().loadDevices(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Banner
              Consumer<DeviceProvider>(
                builder: (_, provider, __) => StatusBanner(
                  error: provider.lastError,
                  onDismiss: provider.clearError,
                  actionLabel: provider.lastError is PermissionException
                      ? 'Open Settings'
                      : null,
                  onAction: () => PermissionHelper.openSettings(),
                ),
              ),

              // Broadcast Control
              Consumer2<BroadcastProvider, DeviceProvider>(
                builder: (_, broadcast, device, __) => BroadcastCard(
                  state: broadcast.state,
                  connectedCount: device.connectedCount,
                  onStart: _startBroadcast,
                  onStop: _stopBroadcast,
                ),
              ),
              const SizedBox(height: 20),

              // How it works (only when idle)
              Consumer<BroadcastProvider>(
                builder: (_, broadcast, __) => broadcast.state.isIdle
                    ? const HowItWorks()
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Connected Devices
              _buildSectionHeader(
                'Connected Devices',
                Icons.bluetooth_connected,
                context.watch<DeviceProvider>().connectedCount,
              ),
              const SizedBox(height: 8),
              _buildConnectedDevices(),
              const SizedBox(height: 20),

              // Available Devices
              _buildSectionHeader(
                'Available Devices',
                Icons.bluetooth_searching,
                context.watch<DeviceProvider>().disconnectedDevices.length,
              ),
              const SizedBox(height: 8),
              _buildAvailableDevices(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDevices() {
    return Consumer<DeviceProvider>(
      builder: (_, provider, __) {
        if (provider.connectedDevices.isEmpty) {
          return Card(
            color: AppColors.surfaceLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.bluetooth_disabled,
                      size: 48, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  const Text(
                    'No audio devices connected',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Connect devices from the list below',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: provider.connectedDevices
              .map((device) => DeviceTile(
                    device: device,
                    onDisconnect: () => provider.disconnectDevice(device),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildAvailableDevices() {
    return Consumer<DeviceProvider>(
      builder: (_, provider, __) {
        final devices = provider.disconnectedDevices;

        if (provider.isLoading && devices.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (devices.isEmpty) {
          return Card(
            color: AppColors.surfaceLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No available devices.\n'
                'Pair your Bluetooth earphones in device Settings first.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: devices
              .map((device) => DeviceTile(
                    device: device,
                    onConnect: () => provider.connectDevice(device),
                  ))
              .toList(),
        );
      },
    );
  }
}

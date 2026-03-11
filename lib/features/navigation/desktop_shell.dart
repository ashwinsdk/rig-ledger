import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/app_colors.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/side_ledger_provider.dart';
import '../../core/providers/agent_provider.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/models/vehicle.dart';
import '../home/combined_home_screen.dart';
import '../stats/stats_screen.dart';
import '../agents/agents_screen.dart';
import '../settings/settings_screen.dart';
import '../ledger_form/ledger_form_screen.dart';
import '../ledger_form/side_bore_form_screen.dart';
import '../side_ledger/diesel/diesel_form_screen.dart';
import '../side_ledger/pvc/pvc_form_screen.dart';
import '../side_ledger/bit/bit_form_screen.dart';
import '../side_ledger/hammer/hammer_form_screen.dart';
import 'main_navigation.dart';

/// Desktop navigation index provider (separate from mobile)
final desktopNavIndexProvider = StateProvider<int>((ref) => 0);

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // Start periodic sync on desktop
    Future.microtask(() {
      ref.read(syncProvider.notifier).startPeriodicSync();
      // Do an initial sync
      ref.read(syncProvider.notifier).syncNow();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.destroy();
  }

  final List<_NavItem> _navItems = const [
    _NavItem(
        icon: Icons.book_outlined, activeIcon: Icons.book, label: 'Ledger'),
    _NavItem(
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart,
        label: 'Stats'),
    _NavItem(
        icon: Icons.people_outlined, activeIcon: Icons.people, label: 'Agents'),
    _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(desktopNavIndexProvider);
    final homeTabIndex = ref.watch(homeTabIndexProvider);
    final currentVehicle = ref.watch(currentVehicleProvider);
    final vehicles = ref.watch(vehiclesProvider);

    return PlatformMenuBar(
      menus: _buildMacOSMenus(context, ref),
      child: CallbackShortcuts(
        bindings: _buildKeyboardShortcuts(context, ref),
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                // Custom title bar with drag area
                _DesktopTitleBar(
                  currentVehicle: currentVehicle,
                  vehicles: vehicles,
                  onVehicleSelected: (vehicle) {
                    ref
                        .read(currentVehicleProvider.notifier)
                        .setCurrentVehicle(vehicle);
                    // Refresh all providers
                    ref.read(ledgerEntriesProvider.notifier).refresh();
                    ref.read(agentsProvider.notifier).refresh();
                    ref.read(dieselEntriesProvider.notifier).refresh();
                    ref.read(pvcEntriesProvider.notifier).refresh();
                    ref.read(bitEntriesProvider.notifier).refresh();
                    ref.read(hammerEntriesProvider.notifier).refresh();
                    ref.read(vehiclesProvider.notifier).refresh();
                  },
                ),
                // Main content area
                Expanded(
                  child: Row(
                    children: [
                      // Sidebar navigation
                      _DesktopSidebar(
                        items: _navItems,
                        selectedIndex: currentIndex,
                        onItemSelected: (index) {
                          ref.read(desktopNavIndexProvider.notifier).state =
                              index;
                          // Refresh providers when switching to Stats
                          if (index == 1) {
                            ref.read(ledgerEntriesProvider.notifier).refresh();
                            ref.read(dieselEntriesProvider.notifier).refresh();
                            ref.read(pvcEntriesProvider.notifier).refresh();
                            ref.read(bitEntriesProvider.notifier).refresh();
                            ref.read(hammerEntriesProvider.notifier).refresh();
                          }
                        },
                        onAddPressed: () => _handleAdd(context, ref,
                            currentIndex, homeTabIndex, currentVehicle),
                      ),
                      // Vertical divider
                      const VerticalDivider(
                          width: 1, thickness: 1, color: AppColors.border),
                      // Page content
                      Expanded(
                        child: _DesktopPageContent(index: currentIndex),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PlatformMenu> _buildMacOSMenus(BuildContext context, WidgetRef ref) {
    return [
      PlatformMenu(
        label: 'RigLedger',
        menus: [
          const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.about),
          const PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.servicesSubmenu),
          ]),
          const PlatformMenuItemGroup(members: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hideOtherApplications),
            PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.showAllApplications),
          ]),
          const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit),
        ],
      ),
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItem(
            label: 'New Entry',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
            onSelected: () {
              final idx = ref.read(desktopNavIndexProvider);
              final tab = ref.read(homeTabIndexProvider);
              final v = ref.read(currentVehicleProvider);
              _handleAdd(context, ref, idx, tab, v);
            },
          ),
          PlatformMenuItem(
            label: 'Sync Now',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
            onSelected: () => ref.read(syncProvider.notifier).syncNow(),
          ),
        ],
      ),
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItem(
            label: 'Ledger',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.digit1, meta: true),
            onSelected: () =>
                ref.read(desktopNavIndexProvider.notifier).state = 0,
          ),
          PlatformMenuItem(
            label: 'Stats',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.digit2, meta: true),
            onSelected: () =>
                ref.read(desktopNavIndexProvider.notifier).state = 1,
          ),
          PlatformMenuItem(
            label: 'Agents',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.digit3, meta: true),
            onSelected: () =>
                ref.read(desktopNavIndexProvider.notifier).state = 2,
          ),
          PlatformMenuItem(
            label: 'Settings',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.digit4, meta: true),
            onSelected: () =>
                ref.read(desktopNavIndexProvider.notifier).state = 3,
          ),
        ],
      ),
      PlatformMenu(
        label: 'Window',
        menus: [
          const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.minimizeWindow),
          const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.zoomWindow),
        ],
      ),
    ];
  }

  void _handleAdd(BuildContext context, WidgetRef ref, int currentIndex,
      int homeTabIndex, Vehicle? currentVehicle) {
    if (currentIndex == 0) {
      if (homeTabIndex == 0) {
        // Ledger tab
        final isSideBore = currentVehicle?.vehicleType == VehicleType.sideBore;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => isSideBore
                ? const SideBoreFormScreen()
                : const LedgerFormScreen(),
          ),
        );
      } else {
        // Side Ledger tab
        _showAddSideLedgerDialog(context);
      }
    } else if (currentIndex == 2) {
      // Agents tab - trigger add agent
      // The agents screen has its own add button
    }
  }

  void _showAddSideLedgerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Entry'),
        content: SizedBox(
          width: 360,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAddOption(
                  context, 'Diesel', Icons.local_gas_station, AppColors.warning,
                  () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DieselFormScreen()));
              }),
              _buildAddOption(context, 'PVC', Icons.plumbing, AppColors.info,
                  () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PvcFormScreen()));
              }),
              _buildAddOption(context, 'Bit', Icons.settings, AppColors.success,
                  () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const BitFormScreen()));
              }),
              _buildAddOption(
                  context, 'Hammer', Icons.hardware, AppColors.error, () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const HammerFormScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts(
      BuildContext context, WidgetRef ref) {
    return {
      // Cmd+1..4 to switch tabs
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
          ref.read(desktopNavIndexProvider.notifier).state = 0,
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () =>
          ref.read(desktopNavIndexProvider.notifier).state = 1,
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () =>
          ref.read(desktopNavIndexProvider.notifier).state = 2,
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () =>
          ref.read(desktopNavIndexProvider.notifier).state = 3,
      // Cmd+N to add new entry
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
        final currentIndex = ref.read(desktopNavIndexProvider);
        final homeTab = ref.read(homeTabIndexProvider);
        final vehicle = ref.read(currentVehicleProvider);
        _handleAdd(context, ref, currentIndex, homeTab, vehicle);
      },
      // Cmd+F to search (when on ledger)
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
        // Focus the search if on ledger tab
        if (ref.read(desktopNavIndexProvider) == 0) {
          // Trigger search state - the home screen watches searchQueryProvider
        }
      },
      // Cmd+S to sync
      const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
        ref.read(syncProvider.notifier).syncNow();
      },
    };
  }
}

// ─── Desktop Title Bar ──────────────────────────────────────────────────────

class _DesktopTitleBar extends ConsumerWidget {
  final Vehicle? currentVehicle;
  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle> onVehicleSelected;

  const _DesktopTitleBar({
    required this.currentVehicle,
    required this.vehicles,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          gradient: AppColors.appBarGradient,
        ),
        child: Row(
          children: [
            // macOS traffic light spacing
            const SizedBox(width: 78),
            // App title
            const Text(
              'RigLedger',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            // Sync status indicator
            _SyncIndicator(
              syncState: syncState,
              onTap: () => ref.read(syncProvider.notifier).syncNow(),
            ),
            const Spacer(),
            // Vehicle switcher
            if (vehicles.length > 1)
              PopupMenuButton<Vehicle>(
                tooltip: 'Switch vehicle',
                offset: const Offset(0, 42),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        currentVehicle?.name ?? 'Select Vehicle',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
                itemBuilder: (context) => vehicles.map((v) {
                  return PopupMenuItem<Vehicle>(
                    value: v,
                    child: Row(
                      children: [
                        Icon(
                          v.id == currentVehicle?.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: v.id == currentVehicle?.id
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(v.name),
                        const SizedBox(width: 8),
                        Text(
                          v.vehicleType == VehicleType.mainBore
                              ? 'Main Bore'
                              : 'Side Bore',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onSelected: onVehicleSelected,
              )
            else if (currentVehicle != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  currentVehicle!.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Sync Indicator ─────────────────────────────────────────────────────────

class _SyncIndicator extends StatelessWidget {
  final SyncState syncState;
  final VoidCallback onTap;

  const _SyncIndicator({required this.syncState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip;
    Color color = Colors.white;

    switch (syncState.status) {
      case SyncStatus.idle:
        icon = Icons.cloud_done_outlined;
        tooltip = syncState.lastSyncTime != null
            ? 'Last synced: ${_formatTime(syncState.lastSyncTime!)}'
            : 'Tap to sync';
      case SyncStatus.syncing:
        icon = Icons.sync;
        tooltip = 'Syncing...';
      case SyncStatus.success:
        icon = Icons.cloud_done;
        tooltip = 'Synced successfully';
        color = Colors.greenAccent;
      case SyncStatus.error:
        icon = Icons.cloud_off;
        tooltip = syncState.errorMessage ?? 'Sync error';
        color = Colors.redAccent;
      case SyncStatus.offline:
        icon = Icons.cloud_off_outlined;
        tooltip = 'Sign in to sync';
        color = Colors.white54;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: syncState.status == SyncStatus.syncing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Desktop Sidebar ────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(
      {required this.icon, required this.activeIcon, required this.label});
}

class _DesktopSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onAddPressed;

  const _DesktopSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Navigation items
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == selectedIndex;
            return _SidebarItem(
              icon: isSelected ? item.activeIcon : item.icon,
              label: item.label,
              isSelected: isSelected,
              onTap: () => onItemSelected(index),
            );
          }),
          const Spacer(),
          // Add button at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          // Keyboard shortcut hints
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShortcutHint(keys: '\u2318 1-4', label: 'Switch tabs'),
                _ShortcutHint(keys: '\u2318 N', label: 'New entry'),
                _ShortcutHint(keys: '\u2318 S', label: 'Sync now'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : _isHovered
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: widget.isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutHint extends StatelessWidget {
  final String keys;
  final String label;

  const _ShortcutHint({required this.keys, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─── Desktop Page Content ───────────────────────────────────────────────────

class _DesktopPageContent extends StatelessWidget {
  final int index;

  const _DesktopPageContent({required this.index});

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      children: const [
        // Wrap each screen in a desktop-adapted container
        _DesktopContentWrapper(child: CombinedHomeScreen()),
        _DesktopContentWrapper(child: StatsScreen()),
        _DesktopContentWrapper(child: AgentsScreen()),
        _DesktopContentWrapper(child: SettingsScreen()),
      ],
    );
  }
}

/// Wraps mobile screens to adapt their layout for desktop
/// Constrains max width, removes SafeArea padding issues, etc.
class _DesktopContentWrapper extends StatelessWidget {
  final Widget child;

  const _DesktopContentWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: child,
    );
  }
}

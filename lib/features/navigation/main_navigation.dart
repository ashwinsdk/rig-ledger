import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/combined_home_screen.dart';
import '../stats/stats_screen.dart';
import '../agents/agents_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/side_ledger_provider.dart';
import '../../core/models/vehicle.dart';
import '../ledger_form/ledger_form_screen.dart';
import '../ledger_form/side_bore_form_screen.dart';
import '../side_ledger/diesel/diesel_form_screen.dart';
import '../side_ledger/pvc/pvc_form_screen.dart';
import '../side_ledger/bit/bit_form_screen.dart';
import '../side_ledger/hammer/hammer_form_screen.dart';

// Provider to track which tab is selected in CombinedHomeScreen (0=Ledger, 1=Side Ledger)
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CombinedHomeScreen(),
    StatsScreen(),
    AgentsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final homeTabIndex = ref.watch(homeTabIndexProvider);
    final currentVehicle = ref.watch(currentVehicleProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                if (homeTabIndex == 0) {
                  // Ledger tab - add ledger entry
                  final isSideBore =
                      currentVehicle?.vehicleType == VehicleType.sideBore;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => isSideBore
                          ? const SideBoreFormScreen()
                          : const LedgerFormScreen(),
                    ),
                  );
                } else {
                  // Side Ledger tab - show add options
                  _showAddSideLedgerSheet(context);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Refresh providers when switching to Stats tab
              if (index == 1) {
                ref.read(ledgerEntriesProvider.notifier).refresh();
                ref.read(dieselEntriesProvider.notifier).refresh();
                ref.read(pvcEntriesProvider.notifier).refresh();
                ref.read(bitEntriesProvider.notifier).refresh();
                ref.read(hammerEntriesProvider.notifier).refresh();
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Ledger',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline),
                activeIcon: Icon(Icons.pie_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outlined),
                activeIcon: Icon(Icons.people),
                label: 'Agents',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSideLedgerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Entry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAddOption(
                  context,
                  'Diesel',
                  Icons.local_gas_station,
                  AppColors.warning,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const DieselFormScreen()),
                  ),
                ),
                _buildAddOption(
                  context,
                  'PVC',
                  Icons.plumbing,
                  AppColors.info,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const PvcFormScreen()),
                  ),
                ),
                _buildAddOption(
                  context,
                  'Bit',
                  Icons.settings,
                  AppColors.success,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const BitFormScreen()),
                  ),
                ),
                _buildAddOption(
                  context,
                  'Hammer',
                  Icons.hardware,
                  AppColors.error,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const HammerFormScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

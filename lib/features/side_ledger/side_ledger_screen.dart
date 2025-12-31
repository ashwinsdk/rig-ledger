import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/vehicle_provider.dart';
import 'diesel/diesel_list_screen.dart';
import 'pvc/pvc_list_screen.dart';
import 'bit/bit_list_screen.dart';
import 'hammer/hammer_list_screen.dart';

class SideLedgerScreen extends ConsumerWidget {
  const SideLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVehicle = ref.watch(currentVehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient App Bar
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Side Ledger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentVehicle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentVehicle.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Manage Diesel, PVC, Bit & Hammer entries',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          'Diesel',
                          Icons.local_gas_station,
                          AppColors.warning,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DieselListScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          'PVC',
                          Icons.plumbing,
                          AppColors.primary,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PvcListScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          'Bit',
                          Icons.hardware,
                          AppColors.success,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BitListScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          'Hammer',
                          Icons.gavel,
                          AppColors.accent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HammerListScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

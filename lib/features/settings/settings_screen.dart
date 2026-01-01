import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/providers/ledger_provider.dart';
import '../../core/providers/agent_provider.dart';
import '../../core/providers/vehicle_provider.dart';
import '../../core/providers/side_ledger_provider.dart';
import '../../core/services/file_save_service.dart';
import '../../core/services/google_drive_service.dart';
import '../export/csv_export_screen.dart';
import '../export/csv_import_screen.dart';
import '../export/pdf_export_screen.dart';
import 'vehicle_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
            ),
            child: const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Vehicle Section
                _buildSectionTitle('Vehicle'),
                _SettingsCard(
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final currentVehicle =
                            ref.watch(currentVehicleProvider);
                        return _SettingsTile(
                          icon: Icons.directions_car_outlined,
                          title: 'Manage Vehicles',
                          subtitle: currentVehicle != null
                              ? 'Current: ${currentVehicle.name}'
                              : 'Add, edit, or switch vehicles',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const VehicleManagementScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Export/Import Section
                _buildSectionTitle('Export & Import'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.file_download_outlined,
                      title: 'Export to CSV',
                      subtitle: 'Export ledger entries as CSV file',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CsvExportScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.file_upload_outlined,
                      title: 'Import from CSV',
                      subtitle: 'Import ledger entries from CSV file',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CsvImportScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Export to PDF',
                      subtitle: 'Generate PDF report',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PdfExportScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Backup Section
                _buildSectionTitle('Backup & Restore'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.backup_outlined,
                      title: 'Create Backup',
                      subtitle: 'Backup all data to a file',
                      onTap: () => _createBackup(context),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.restore_outlined,
                      title: 'Restore Backup',
                      subtitle: 'Restore data from backup file',
                      onTap: () => _restoreBackup(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Drive Backup Section
                _buildSectionTitle('Google Drive Backup'),
                const _GoogleDriveBackupCard(),
                const SizedBox(height: 24),

                // Data Section
                _buildSectionTitle('Data'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Clear All Data',
                      subtitle: 'Delete all ledger entries and agents',
                      titleColor: AppColors.error,
                      onTap: () => _showClearDataDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSectionTitle('About'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outlined,
                      title: 'RigLedger',
                      subtitle: 'Version 1.0.5',
                      trailing: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                      ),
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      final backup = await DatabaseService.createBackup();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'rigledger_backup_$timestamp.json';

      final saved = await FileSaveService.saveStringFile(
        context: context,
        content: jsonString,
        fileName: fileName,
        shareSubject: 'RigLedger Backup',
        dialogTitle: 'Save Backup File',
      );

      if (context.mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all current data with the backup data. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      await DatabaseService.restoreBackup(backup);
      ref.read(ledgerEntriesProvider.notifier).refresh();
      ref.read(agentsProvider.notifier).refresh();
      ref.read(vehiclesProvider.notifier).refresh();
      ref.read(dieselEntriesProvider.notifier).refresh();
      ref.read(pvcEntriesProvider.notifier).refresh();
      ref.read(bitEntriesProvider.notifier).refresh();
      ref.read(hammerEntriesProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showClearDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Clear All Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text('• All ledger entries'),
            Text('• All agents'),
            Text('• All side-ledger entries'),
            Text('• All vehicles (except default)'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.clearAllData();
      ref.read(ledgerEntriesProvider.notifier).refresh();
      ref.read(agentsProvider.notifier).refresh();
      ref.read(vehiclesProvider.notifier).refresh();
      ref.read(dieselEntriesProvider.notifier).refresh();
      ref.read(pvcEntriesProvider.notifier).refresh();
      ref.read(bitEntriesProvider.notifier).refresh();
      ref.read(hammerEntriesProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            const Text('RigLedger'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 1.0.5'),
            const SizedBox(height: 8),
            const Text(
              'A fast, lightweight ledger for borewell drilling entries, income and expenses, and agent management.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text('- Multi-vehicle support'),
            const Text('- Side-ledger (Diesel, PVC, Bit, Hammer)'),
            const Text('- Offline-first operation'),
            const Text('- CSV import/export'),
            const Text('- PDF report generation'),
            const Text('- Agent management'),
            const Text('- Statistics and charts'),
            const SizedBox(height: 16),
            const Text(
              'Developer:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                // Could add URL launcher here if needed
              },
              child: const Text(
                'github.com/ashwinsdk',
                style: TextStyle(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _GoogleDriveBackupCard extends StatefulWidget {
  const _GoogleDriveBackupCard();

  @override
  State<_GoogleDriveBackupCard> createState() => _GoogleDriveBackupCardState();
}

class _GoogleDriveBackupCardState extends State<_GoogleDriveBackupCard> {
  bool _isLoading = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleDrive();
  }

  Future<void> _initializeGoogleDrive() async {
    setState(() => _isLoading = true);
    await GoogleDriveService.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final (success, errorMessage) = await GoogleDriveService.signIn();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to Google Drive'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Failed to connect to Google Drive'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Drive'),
        content: const Text(
          'Are you sure you want to disconnect from Google Drive? Auto-backup will be disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await GoogleDriveService.signOut();
      setState(() {});
    }
  }

  Future<void> _backupNow() async {
    setState(() => _isBackingUp = true);
    final success = await GoogleDriveService.backup();
    if (mounted) {
      setState(() => _isBackingUp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Backup successful' : 'Backup failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _restoreFromDrive(WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Google Drive'),
        content: const Text(
          'This will replace all current data with the backup from Google Drive. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isRestoring = true);

    try {
      final backupData = await GoogleDriveService.restore();
      if (backupData != null) {
        await DatabaseService.restoreBackup(backupData);

        // Refresh all providers to reflect restored data
        ref.read(vehiclesProvider.notifier).refresh();
        ref.read(ledgerEntriesProvider.notifier).refresh();
        ref.read(agentsProvider.notifier).refresh();
        ref.read(dieselEntriesProvider.notifier).refresh();
        ref.read(pvcEntriesProvider.notifier).refresh();
        ref.read(bitEntriesProvider.notifier).refresh();
        ref.read(hammerEntriesProvider.notifier).refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data restored successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backup found on Google Drive'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String _formatLastBackup() {
    final lastBackup = GoogleDriveService.lastBackupTime;
    if (lastBackup == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(lastBackup);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return DateFormat('MMM d, yyyy').format(lastBackup);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final isSignedIn = GoogleDriveService.isSignedIn;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!isSignedIn) ...[
            // Not signed in - show connect button
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined,
                  color: AppColors.textSecondary),
              title: const Text('Google Drive not connected'),
              subtitle: const Text('Connect for automatic cloud backup'),
              trailing: ElevatedButton(
                onPressed: _signIn,
                child: const Text('Connect'),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ] else ...[
            // Signed in - show account info and options
            ListTile(
              leading: const Icon(Icons.cloud_done_outlined,
                  color: AppColors.success),
              title: Text(GoogleDriveService.userEmail ?? 'Connected'),
              subtitle: Text('Last backup: ${_formatLastBackup()}'),
              trailing: IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                onPressed: _signOut,
                tooltip: 'Disconnect',
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            const Divider(height: 1),
            // Auto-backup toggle
            ListTile(
              leading: const Icon(Icons.sync, color: AppColors.primary),
              title: const Text('Auto Backup'),
              subtitle: const Text('Backup automatically every 6 hours'),
              trailing: Switch(
                value: GoogleDriveService.isAutoBackupEnabled,
                onChanged: (value) async {
                  await GoogleDriveService.setAutoBackupEnabled(value);
                  setState(() {});
                },
                activeColor: AppColors.primary,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            const Divider(height: 1),
            // Backup now button
            ListTile(
              leading: _isBackingUp
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.backup_outlined, color: AppColors.primary),
              title: const Text('Backup Now'),
              subtitle: const Text('Upload backup to Google Drive'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
              onTap: _isBackingUp ? null : _backupNow,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            const Divider(height: 1),
            // Restore from Drive
            Consumer(
              builder: (context, ref, child) {
                return ListTile(
                  leading: _isRestoring
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined,
                          color: AppColors.primary),
                  title: const Text('Restore from Drive'),
                  subtitle: const Text('Download and restore backup'),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: _isRestoring ? null : () => _restoreFromDrive(ref),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

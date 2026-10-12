import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_info.dart';

/// Installed app version, read from the platform (pubspec is the source).
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Settings > About: version, what the app stores, license and notices.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider);
    final version = info.maybeWhen(
        data: (i) => '${i.version} (build ${i.buildNumber})', orElse: () => '');
    final packageName =
        info.maybeWhen(data: (i) => i.packageName, orElse: () => '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About'),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.appBarGradient)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/images/logo.png',
                          width: 72, height: 72),
                    ),
                    const SizedBox(height: 12),
                    const Text(AppInfo.name,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    if (version.isNotEmpty)
                      Text('Version $version',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    if (packageName.isNotEmpty)
                      Text(packageName,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _Section('What it is', [
                'A ledger for borewell drilling businesses: bills with payment '
                    'logs and commission, agents, side ledger purchases, '
                    'portfolio statistics, and an Account Ledger cash book with '
                    'receiver books.',
                'Available for Android and macOS.',
              ]),
              const _Section('Your data', [
                'All records are stored on this device and the app works without '
                    'an internet connection.',
                'Optional Google Drive backup and sync: after you sign in with '
                    'Google, the app requests Google Drive access to create, read '
                    'and update one file, ${AppInfo.driveFile}, in a folder named '
                    '"${AppInfo.driveFolder}" in your own Drive.',
                'The app does not include advertising or usage analytics libraries.',
                'Deleted Account Ledger transactions are removed permanently '
                    '30 days after deletion.',
              ]),
              _Section('Permissions (Android)', const [
                'Internet: Google Drive backup and sync.',
                'Storage access: saving and reading backup and report files.',
              ]),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.gavel_outlined,
                          color: AppColors.primary),
                      title: const Text('License'),
                      subtitle: const Text('RigLedger Proprietary License'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const _LicenseTextScreen())),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined,
                          color: AppColors.primary),
                      title: const Text('Open source licenses'),
                      subtitle:
                          const Text('Flutter, packages and bundled fonts'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: AppInfo.name,
                        applicationVersion: version.isEmpty ? null : version,
                        applicationLegalese: '(c) ${AppInfo.copyright}',
                      ),
                    ),
                    ...[
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.code, color: AppColors.primary),
                        title: const Text('Developer'),
                        subtitle: const Text(AppInfo.developerLink),
                        onTap: () => launchUrl(Uri.parse(AppInfo.developerUrl),
                            mode: LaunchMode.externalApplication),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('(c) ${AppInfo.copyright}. All rights reserved.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _Section(this.title, this.lines);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  Text(l, style: const TextStyle(fontSize: 14, height: 1.35)),
            ),
        ],
      ),
    );
  }
}

class _LicenseTextScreen extends StatelessWidget {
  const _LicenseTextScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License'),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.appBarGradient)),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(AppInfo.licenseAsset),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
                child: snap.hasError
                    ? const Text('License text is not available')
                    : const CircularProgressIndicator());
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(snap.data!,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            ),
          );
        },
      ),
    );
  }
}

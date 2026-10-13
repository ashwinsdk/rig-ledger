import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/app_theme.dart';
import 'core/database/database_service.dart';
import 'core/services/google_drive_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/payment_link_service.dart';
import 'core/providers/sync_provider.dart';
import 'core/utils/platform_helper.dart';
import 'core/utils/app_info.dart';
import 'features/navigation/main_navigation.dart';
import 'features/navigation/desktop_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformHelper.isMobile) {
    // Mobile-only: orientation lock and immersive mode
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  if (PlatformHelper.isDesktop) {
    // Desktop: window manager setup
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 820),
      minimumSize: Size(900, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'RigLedger',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize database
  registerAppLicenses();
  await DatabaseService.initialize();
  await PaymentLinkService.reconcileAll();

  // No storage permission is requested: exports go through the system file
  // picker (Storage Access Framework) or Share, which need none.

  // Initialize sync state (load last sync time from storage)
  SyncService.initialize();

  // Initialize Google Drive (try silent sign-in)
  await GoogleDriveService.initialize();

  runApp(
    const ProviderScope(
      child: RigLedgerApp(),
    ),
  );
}

class RigLedgerApp extends ConsumerStatefulWidget {
  const RigLedgerApp({super.key});

  @override
  ConsumerState<RigLedgerApp> createState() => _RigLedgerAppState();
}

class _RigLedgerAppState extends ConsumerState<RigLedgerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sync immediately on launch, then every 5 minutes
    _triggerSync();
    ref.read(syncProvider.notifier).startPeriodicSync(
          interval: const Duration(minutes: 5),
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(syncProvider.notifier).stopPeriodicSync();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sync whenever the app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _triggerSync();
    }
  }

  void _triggerSync() {
    if (!GoogleDriveService.isSignedIn) return;
    ref.read(syncProvider.notifier).syncNow();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RigLedger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: PlatformHelper.isDesktop
          ? const DesktopShell()
          : const MainNavigation(),
    );
  }
}

# RigLedger - Coding Conventions

## Language and style

- Dart only. English only. No emojis. No em-dashes.
- File names: snake_case.dart
- Class names: PascalCase
- Methods, variables, providers: camelCase
- Private members: _prefixed
- Constants: camelCase (Dart convention)
- Use `withValues(alpha: x)` not `.withOpacity(x)` (the latter is deprecated in this codebase)

## File and class naming

- One top-level class per file (private helpers are fine in the same file)
- Form screens: `xxx_form_screen.dart`
- List screens: `xxx_list_screen.dart`
- Full-page screens: `xxx_screen.dart`
- Providers: `xxx_provider.dart`
- Models: `xxx.dart` + `xxx.g.dart` (generated, never edit)
- Services: `xxx_service.dart`
- Widgets: `xxx_widget.dart` or `xxx.dart` inside a `widgets/` subfolder

## State management patterns

- Mutable lists: `StateNotifierProvider<XxxNotifier, List<Xxx>>`
- Every `StateNotifier` must have: `loadXxx()`, `addXxx()`, `updateXxx()`, `deleteXxx()`, `refresh()`
- Derived state: `Provider<T>` watching the base StateNotifierProvider
- UI-only state: `StateProvider<T>`
- Never call `DatabaseService` from a screen widget -- always go through a provider

## Model patterns

- All Hive models: extend HiveObject, have `copyWith()`, and have serialization methods
- LedgerEntry and Agent use `toMap()`/`fromMap()` for serialization
- All other models (Vehicle, side ledger) use `toJson()`/`fromJson()`
- Do not change serialization method names without updating `DatabaseService` and `SyncService`
- When adding a new HiveField to an existing model: add it with a new field index (never reuse indices), give it a default value in `fromMap`/`fromJson`, and regenerate the adapter

## Error handling

- Service methods return `(bool, String?)` record tuples: `(success, errorMessage)`
- Use `debugPrint` for logging. No structured logging library.
- Wrap async calls in try/catch at the service layer. Do not propagate exceptions to the UI unhandled.
- Show errors to users via SnackBar or AlertDialog -- do not silently swallow errors.

## Currency and numbers

- All monetary values stored as `double`.
- Currency: Indian Rupees (INR). Use Rs. prefix where needed or follow existing UI patterns.
- Format numbers with `intl` package in UI. Do not hardcode number formatting.
- Dates stored as `DateTime` (local time), serialised as ISO 8601 strings.
- No timezone handling anywhere in the codebase.

## Platform-adaptive UI

- Check `PlatformHelper.isDesktop` / `PlatformHelper.isMobile` for platform splits
- Use `AdaptiveHeader` widget (`lib/core/widgets/adaptive_header.dart`) for screen headers
- Mobile headers: full gradient with SafeArea. Desktop headers: slim with border-bottom.
- Desktop forms: max width 700px centered. Mobile forms: full width.
- App theme: light only. No dark mode.
- Brand gradient: #252B49 -> #315D9A -> #618DCE (linear, horizontal)
- Primary colour: AppColors.primary (#315D9A)
- Category colours: Diesel = Amber/Orange, PVC = Blue, Bit = Green, Hammer = Brown (#8B4513)

## After editing a Hive model

Always run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

## After any Dart file edit

Always run:
```bash
flutter analyze
```
Fix all errors and relevant warnings before continuing.

## Riverpod provider refresh pattern

After vehicle switch or full sync, refresh all 8 providers:
```dart
ref.read(ledgerEntriesProvider.notifier).refresh();
ref.read(agentsProvider.notifier).refresh();
ref.read(vehiclesProvider.notifier).refresh();
ref.read(currentVehicleProvider.notifier).refresh();
ref.read(dieselEntriesProvider.notifier).refresh();
ref.read(pvcEntriesProvider.notifier).refresh();
ref.read(bitEntriesProvider.notifier).refresh();
ref.read(hammerEntriesProvider.notifier).refresh();
```

## Tombstone pattern on delete

Whenever deleting any entity, call `DatabaseService.recordTombstone(id, boxName)` BEFORE deleting from the box. `DatabaseService.deleteLedgerEntry()`, `deleteAgent()`, etc. already do this -- do not bypass them with direct box operations.

## Agent name denormalisation

`agentName` is stored directly in every `LedgerEntry` and `MiniLedgerEntry`. When an agent is renamed:
1. Call `DatabaseService.updateAgentInLedgerEntries(agentId, newName)` to update all linked entries.
2. Then save the agent with the new name.
Both steps must happen or data will diverge.

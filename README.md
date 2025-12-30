# RigLedger

A fast, lightweight, production-ready native Android Flutter application for borewell drilling entries, income and expenses, and agent management. **100% offline operation** - no backend, no cloud sync, all data stored locally.

![RigLedger](assets/images/logo.png)

## Features

### Core Features
- **Ledger Management**: Track drilling entries with comprehensive details including depth, PVC, MS pipe, rates, and more
- **Agent Management**: Full CRUD operations for agents with bill count tracking
- **Statistics**: Visual pie charts and aggregated data by agent with customizable date ranges
- **Search & Filter**: Full-text search across bill numbers, addresses, agent names, and notes
- **Calendar & Daily Views**: Toggle between daily grouped list and calendar month view

### Data Operations
- **CSV Export**: Export ledger entries with customizable date ranges
- **CSV Import**: Import entries with column mapping, validation, and error preview
- **PDF Export**: Generate professional PDF reports with summary statistics
- **Backup & Restore**: Full data backup and restore functionality
- **Clear All Data**: Complete data wipe with confirmation

### UI/UX
- **Light Theme Only**: Clean, professional light theme using gradient aesthetic
- **Gradient Colors**: `linear-gradient(90deg, #252B49, #315D9A, #618DCE, #0490B6, #B7CDED)`
- **Responsive Design**: Optimized for all Android screen sizes and densities
- **Icons Only**: No emojis - Material Icons throughout
- **Smooth Animations**: Subtle Material animations for a polished experience

## Tech Stack

- **Flutter**: 3.38.3 (stable channel)
- **Dart**: 3.10.1
- **State Management**: Riverpod
- **Local Database**: Hive
- **Charts**: fl_chart
- **PDF Generation**: pdf/printing packages
- **File Operations**: file_picker, share_plus, path_provider

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0.0
- Android SDK >= 21 (Android 5.0)
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd rig-ledger
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Build for Production

```bash
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── core/
│   ├── database/
│   │   └── database_service.dart       # Hive database operations
│   ├── models/
│   │   ├── agent.dart                  # Agent data model
│   │   ├── agent.g.dart                # Hive adapter (generated)
│   │   ├── ledger_entry.dart           # Ledger entry data model
│   │   └── ledger_entry.g.dart         # Hive adapter (generated)
│   ├── providers/
│   │   ├── agent_provider.dart         # Agent state management
│   │   └── ledger_provider.dart        # Ledger state management
│   ├── theme/
│   │   ├── app_colors.dart             # Color definitions
│   │   └── app_theme.dart              # Theme configuration
│   └── widgets/
│       └── gradient_widgets.dart       # Reusable gradient widgets
├── features/
│   ├── agents/
│   │   └── agents_screen.dart          # Agent management
│   ├── export/
│   │   ├── csv_export_screen.dart      # CSV export
│   │   ├── csv_import_screen.dart      # CSV import with mapping
│   │   └── pdf_export_screen.dart      # PDF generation
│   ├── home/
│   │   ├── home_screen.dart            # Main ledger screen
│   │   └── widgets/
│   │       ├── calendar_view.dart      # Calendar month view
│   │       ├── filter_sheet.dart       # Filter bottom sheet
│   │       ├── ledger_list.dart        # Daily grouped list
│   │       ├── search_sheet.dart       # Search bottom sheet
│   │       └── summary_row.dart        # Monthly summary
│   ├── ledger_form/
│   │   └── ledger_form_screen.dart     # Add/Edit ledger entry
│   ├── navigation/
│   │   └── main_navigation.dart        # Bottom navigation
│   ├── settings/
│   │   └── settings_screen.dart        # Settings & utilities
│   └── stats/
│       └── stats_screen.dart           # Statistics & charts
```

## Database Schema

### LedgerEntry
| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID primary key |
| date | DateTime | Entry date |
| billNumber | String | Bill/Invoice number |
| agentId | String | Reference to agent |
| agentName | String | Agent name (denormalized) |
| address | String | City/Location |
| depth | String | Depth type (7inch/8inch) |
| depthInFeet | double | Actual depth measurement |
| depthPerFeetRate | double | Rate per foot |
| pvc | String | PVC type (7inch/8inch) |
| pvcRate | double | PVC rate |
| msPipe | String | MS Pipe details |
| msPipeRate | double | MS Pipe rate |
| extraCharges | double | Additional charges |
| total | double | Total amount |
| isTotalManuallyEdited | bool | Manual override flag |
| received | double | Amount received |
| balance | double | Outstanding balance |
| less | double | Discounts/Deductions |
| notes | String? | Optional notes |
| createdAt | DateTime | Creation timestamp |
| updatedAt | DateTime | Last update timestamp |

### Agent
| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID primary key |
| name | String | Agent name (unique) |
| phone | String? | Phone number (optional) |
| notes | String? | Notes (optional) |
| createdAt | DateTime | Creation timestamp |
| updatedAt | DateTime | Last update timestamp |

## CSV Import/Export

### Export Format
CSV files are exported with the following columns:
```
Date, Bill number, Agent name, Address, Depth, Depth in feet, Depth per feet rate, PVC, PVC rate, MS pipe, MS pipe rate, Extra-chargers, TOTAL, Received, Balance, Less
```

- Dates are formatted as `YYYY-MM-DD`
- UTF-8 encoding
- Comma-separated values

### Import Process
1. **Select File**: Choose a CSV file from device storage
2. **Map Columns**: Map CSV headers to expected fields (auto-detected when possible)
3. **Validate**: Review valid entries and errors
4. **Import**: Commit valid entries to database

Options:
- **Auto-create missing agents**: Automatically create agents that don't exist

## Acceptance Tests

### Test Checklist

1. **Opening App**
   - [ ] App launches without errors
   - [ ] Shows empty state on first run
   - [ ] Bottom navigation works correctly

2. **Adding Entry**
   - [ ] Tap FAB opens add form
   - [ ] All fields accept input
   - [ ] Date picker works
   - [ ] Agent dropdown allows adding new agent
   - [ ] Total calculation updates in real-time
   - [ ] Manual total override works
   - [ ] Entry saves successfully

3. **Editing Entry**
   - [ ] Tap entry opens detail view
   - [ ] All fields are editable
   - [ ] Changes save correctly
   - [ ] Delete with confirmation works
   - [ ] Undo delete works

4. **Search & Filter**
   - [ ] Search finds entries by bill number
   - [ ] Search finds entries by agent name
   - [ ] Search finds entries by address
   - [ ] Filter by agent works
   - [ ] Filter by bill number works
   - [ ] Clear filters works

5. **CSV Export**
   - [ ] Select date range
   - [ ] Export all entries option
   - [ ] File shares correctly
   - [ ] CSV format is valid

6. **CSV Import**
   - [ ] File picker opens
   - [ ] Column mapping works
   - [ ] Validation shows errors
   - [ ] Auto-create agents option
   - [ ] Entries import correctly

7. **PDF Export**
   - [ ] Select date range
   - [ ] Preview shows correctly
   - [ ] PDF generates without errors
   - [ ] File shares correctly

8. **Agent Management**
   - [ ] Add agent works
   - [ ] Edit agent works
   - [ ] Delete agent shows options
   - [ ] Reassign entries works
   - [ ] Delete entries works

9. **Statistics**
   - [ ] Pie chart renders correctly
   - [ ] Date range selector works
   - [ ] Summary cards show correct values
   - [ ] Chart updates when data changes

10. **Backup/Restore**
    - [ ] Create backup works
    - [ ] Restore backup works
    - [ ] Clear all data works with confirmation

## Developer Environment

Verified environment:
```
Flutter 3.38.3 (stable)
Dart 3.10.1
Android SDK 36.1.0
```

## Migrations

The database uses schema versioning. Current version: **1**

Migration path is handled in `DatabaseService._performMigrations()`. Add version checks for future schema changes.

## License

MIT License

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

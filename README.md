# RigLedger

A fast, lightweight, production-ready native Android Flutter application for borewell drilling business management. Supports multiple vehicles (rigs), ledger entries, agent management, side ledger tracking (diesel, PVC, bit, hammer), and comprehensive reporting. 100% offline operation - all data stored locally on device.

## Version

Current: 1.0.5

### Changelog

v1.0.5
- Fixed UI being hidden by mobile navigation bars with edge-to-edge display
- Fixed Google Drive error
- Updated About section with developer GitHub contact

v1.0.4
- Added multi-type selection for PVC, Bit, and Hammer in Side Ledger
- Updated PDF export to show each type as separate columns with counts and a single total column
- Updated forms and lists to input and display per-type details across PVC, Bit, and Hammer
- Minor fixes and performance improvements

v1.0.3
- Added multi-vehicle support with complete data isolation
- Added Side Bore vehicle type with simplified form
- Added Side Ledger module (Diesel, PVC, Bit, Hammer tracking)
- Added time period filters for Side Ledger (Month, 3 Months, 6 Months, Year, All)
- Added Google Drive backup and restore
- Added 5 PDF export types (Full, Summary, Pending, Agent-wise, Date Range)
- Fixed vehicle-specific agent and entry management
- Improved gradient UI across all form screens

v1.0.1
- Initial release with core ledger functionality

## Features

### Ledger Management
- Track drilling entries with comprehensive details
- Main Bore entries: Depth, PVC, MS Pipe, rates, step rate calculation, extra charges
- Side Bore entries: Simplified form with depth, rate, total, received, balance
- Bill number tracking with auto-increment
- Date picker with calendar view
- Notes and additional details

### Multi-Vehicle Support
- Add multiple vehicles (rigs) with unique names
- Vehicle types: Main Bore, Side Bore
- Complete data isolation between vehicles
- Switch vehicles from home screen dropdown
- Each vehicle has its own agents, entries, and side ledger data

### Agent Management
- Full CRUD operations for agents
- Bill count tracking per agent
- Vehicle-specific agent lists
- Quick agent creation from entry forms
- Agent-wise statistics and reports

### Side Ledger Module
- Track operational expenses separate from main ledger
- Four categories: Diesel, PVC, Bit, Hammer
- Time period filters: Month, 3 Months, 6 Months, Year, All
- Month/Year navigation
- Category totals with amounts
- Diesel: Track litres and total cost
- PVC/Bit/Hammer: Track quantity and amount

### Statistics
- Visual pie charts by agent
- Customizable date range filters
- Aggregated totals (depth, PVC, MS, amounts)
- Pending balance tracking
- Feet totals: 7inch depth, 8inch depth, 7inch PVC, 8inch PVC, MS Pipe

### Search and Filter
- Full-text search across bill numbers, addresses, agent names, notes
- Date range filtering
- Agent filtering
- Balance status filtering (All, Pending, Cleared)

### Calendar View
- Toggle between list and calendar month view
- Daily grouped entries
- Quick date navigation

## Data Operations

### CSV Export
- Export ledger entries with customizable date ranges
- UTF-8 encoding
- Columns: Date, Bill Number, Agent Name, Address, Depth Type, Depth, Depth Rate, Step Rate, PVC Type, PVC, PVC Rate, MS Pipe Type, MS Pipe, MS Pipe Rate, Extra Charges, Total, Received, Balance, Less

### CSV Import
- Select CSV file from device storage
- Automatic column mapping with manual override
- Validation with error preview
- Option to auto-create missing agents
- Skip invalid rows

### PDF Export (5 Types)
1. Full Report: All entries with complete details
2. Summary Report: Aggregated totals and statistics
3. Pending Report: Only entries with outstanding balance
4. Agent Report: Entries grouped by agent
5. Date Range Report: Custom date range selection

All PDFs include:
- Column selection (choose which columns to include)
- Summary section with totals
- Feet totals section
- Landscape A4 format
- Preview with zoom and share

### Backup and Restore

Local Backup:
- Full data backup to device storage
- JSON format with all entries, agents, vehicles, side ledger
- Restore with confirmation dialog

Google Drive Backup:
- Sign in with Google account
- Backup to Google Drive app folder
- Restore from Google Drive
- Automatic file naming with timestamp
- **Note**: Physical Android devices require proper Firebase configuration with SHA-1/SHA-256 fingerprints. See [GOOGLE_DRIVE_SETUP.md](GOOGLE_DRIVE_SETUP.md) for detailed setup instructions.

### Clear Data
- Complete data wipe with confirmation
- Clears all vehicles, entries, agents, side ledger data

## Data Models

### LedgerEntry
- id: Unique identifier
- date: Entry date
- billNumber: Bill number string
- agentId: Reference to agent
- address: Location/address
- depthType: 7inch or 8inch
- depthFeet: Depth in feet
- depthRate: Rate per foot
- stepRate: Calculated step rate
- pvcType: 7inch or 8inch
- pvcFeet: PVC pipe feet
- pvcRate: PVC rate per foot
- msPipeType: 4.5inch, 5inch, or 6inch
- msPipeFeet: MS pipe feet
- msPipeRate: MS pipe rate per foot
- extraCharges: Additional charges
- total: Calculated total
- received: Amount received
- balance: Remaining balance
- less: Discount/adjustment
- notes: Additional notes
- vehicleId: Associated vehicle

### Agent
- id: Unique identifier
- name: Agent name
- vehicleId: Associated vehicle

### Vehicle
- id: Unique identifier
- name: Vehicle/rig name
- type: mainBore or sideBore

### DieselEntry
- id: Unique identifier
- date: Entry date
- litres: Diesel quantity
- amount: Total cost
- vehicleId: Associated vehicle

### PvcEntry
- id: Unique identifier
- date: Entry date
- quantity: PVC quantity
- amount: Total cost
- vehicleId: Associated vehicle

### BitEntry
- id: Unique identifier
- date: Entry date
- quantity: Bit quantity
- amount: Total cost
- vehicleId: Associated vehicle

### HammerEntry
- id: Unique identifier
- date: Entry date
- quantity: Hammer quantity
- amount: Total cost
- vehicleId: Associated vehicle

## Calculations

### Main Bore Total
```
Total = (Depth x Depth Rate) + Step Rate + (PVC x PVC Rate) + (MS Pipe x MS Rate) + Extra Charges
```

### Side Bore Total
```
Total = Depth x Rate per foot
```

### Step Rate Calculation

Automatically calculated based on depth type and feet:

7inch:
- 0-300 ft: Base rate (no step rate)
- 300-400 ft: +10 per foot above 300
- 400-500 ft: +10 per foot above 400
- 500-600 ft: +10 per foot above 500
- 600-700 ft: +20 per foot above 600
- 700-800 ft: +20 per foot above 700
- 800+ ft: +20 per foot above 800

8inch:
- Same as 7inch except 500-600 ft is +20 per foot instead of +10

### Balance Calculation
```
Balance = Total - Received - Less
```

## Tech Stack

- Flutter: 3.38.3 (stable channel)
- Dart: 3.10.1
- State Management: Riverpod
- Local Database: Hive
- Charts: fl_chart
- PDF Generation: pdf, printing packages
- File Operations: file_picker, share_plus, path_provider
- Google Sign-In: google_sign_in, googleapis
- CSV Handling: csv package

## UI Theme

- Light theme only
- Gradient colors: linear-gradient(90deg, #252B49, #315D9A, #618DCE)
- Category colors:
  - Diesel: Amber/Orange
  - PVC: Blue
  - Bit: Green
  - Hammer: Brown (#8B4513)
- Material Design 3 components
- Responsive design for all Android screen sizes

## Project Structure

```
lib/
  core/
    models/           # Data models (LedgerEntry, Agent, Vehicle, etc.)
    providers/        # Riverpod providers for state management
    services/         # Database service, backup service
    theme/            # App theme and colors
  features/
    home/             # Home screen with vehicle selection
      widgets/        # Ledger list, stats cards
    ledger_form/      # Main bore and side bore entry forms
    agents/           # Agent management screens
    statistics/       # Charts and statistics
    side_ledger/      # Diesel, PVC, Bit, Hammer modules
    settings/         # Settings and data operations
    import/           # CSV import functionality
    export/           # CSV and PDF export
    backup/           # Backup and restore
```

## Build

Requirements:
- Flutter 3.38.3 or higher
- Dart 3.10.1 or higher
- Android SDK 36.1.0
- Java 17 (for Gradle)

Build commands:
```bash
# Set Java 17 for Gradle
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# Get dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## Development

```bash
# Run in debug mode
flutter run

# Run with specific device
flutter run -d <device_id>

# Analyze code
flutter analyze

# Run tests
flutter test
```

## License

MIT License

## Contributing

1. Fork the repository
2. Create your feature branch (git checkout -b feature/NewFeature)
3. Commit your changes (git commit -m 'Add NewFeature')
4. Push to the branch (git push origin feature/NewFeature)
5. Open a Pull Request

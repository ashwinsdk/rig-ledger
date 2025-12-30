# RigLedger

A fast, lightweight, production-ready native Android Flutter application for borewell drilling entries, income and expenses, and agent management. 100% offline operation - no backend, no cloud sync, all data stored locally.

## Features

### Core Features
- Ledger Management: Track drilling entries with comprehensive details including depth, PVC, MS pipe, rates, step rate calculation, and more
- Agent Management: Full CRUD operations for agents with bill count tracking
- Statistics: Visual pie charts and aggregated data by agent with customizable date ranges
- Search and Filter: Full-text search across bill numbers, addresses, agent names, and notes
- Calendar and Daily Views: Toggle between daily grouped list and calendar month view
- Feet Totals: Track totals for 7inch/8inch depth, PVC, and MS pipe

### Data Operations
- CSV Export: Export ledger entries with customizable date ranges
- CSV Import: Import entries with column mapping, validation, and error preview
- PDF Export: Generate professional PDF reports with summary statistics and column selection
- Backup and Restore: Full data backup and restore functionality
- Clear All Data: Complete data wipe with confirmation

### UI/UX
- Light Theme Only: Clean, professional light theme using gradient aesthetic
- Gradient Colors: linear-gradient(90deg, #252B49, #315D9A, #618DCE, #0490B6, #B7CDED)
- Responsive Design: Optimized for all Android screen sizes and densities
- Material Icons: Clean iconography throughout
- Smooth Animations: Subtle Material animations for a polished experience

## Tech Stack

- Flutter: 3.38.3 (stable channel)
- Dart: 3.10.1
- State Management: Riverpod
- Local Database: Hive
- Charts: fl_chart
- PDF Generation: pdf/printing packages
- File Operations: file_picker, share_plus, path_provider


## Total Calculation

The total is calculated using the following formula:

```
Total = (Depth x Depth per feet rate) + Step Rate + (PVC x PVC per feet rate) + (MS Pipe x MS Pipe per feet rate) + Extra Charges
```

### Step Rate Calculation

Step rate is automatically calculated based on depth type and feet:

- 7inch: 0-300ft same rate, 300-400 +10/ft, 400-500 +10/ft, 500-600 +10/ft, 600-700 +20/ft, 700-800 +20/ft, 800+ +20/ft
- 8inch: Same as 7inch except 500-600 is +20/ft instead of +10/ft

## CSV Import/Export

### Export Format
CSV files are exported with the following columns:
```
Date, Bill Number, Agent Name, Address, Depth Type, Depth (feet), Depth Rate/ft, Step Rate, PVC Type, PVC (feet), PVC Rate/ft, MS Pipe Type, MS Pipe (feet), MS Pipe Rate/ft, Extra Charges, Total, Received, Balance, Less
```

- Dates are formatted as YYYY-MM-DD
- UTF-8 encoding
- Comma-separated values

### Import Process
1. Select File: Choose a CSV file from device storage
2. Map Columns: Map CSV headers to expected fields (auto-detected when possible)
3. Validate: Review valid entries and errors
4. Import: Commit valid entries to database

Options:
- Auto-create missing agents: Automatically create agents that do not exist

## PDF Export

PDF export includes:
- Column selection (choose which columns to include)
- Date range selection
- Summary section with totals
- Feet totals section (7inch depth, 8inch depth, 7inch PVC, 8inch PVC, MS Pipe)
- Landscape A4 format
- Preview with zoom support

## Developer Environment

Verified environment:
```
Flutter 3.38.3 (stable)
Dart 3.10.1
Android SDK 36.1.0
```

## License

MIT License

## Contributing

1. Fork the repository
2. Create your feature branch (git checkout -b feature/AmazingFeature)
3. Commit your changes (git commit -m 'Add some AmazingFeature')
4. Push to the branch (git push origin feature/AmazingFeature)
5. Open a Pull Request

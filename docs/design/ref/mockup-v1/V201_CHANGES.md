# Mockup changes for RigLedger 2.0.1

File: rigledger_android_mockup.html (dummy data, click-through). Source of truth: the Flutter code in rig-ledger.

- Version text is 2.0.1 (build 6) in the page title, sidebar, Settings About tile and About screen.
- Ledger: smaller header (34 dp pills), month or year arrows (or custom range) and a small Daily/Calendar toggle in one row, one slim sideways-scrolling card (Total, Received, Balance, Commission; side bore adds a Total Depth tile), collapsible "Feet: Depth | PVC | MS" bar with by-type chips (7", 8", 9", 6").
- Bill cards: commission strip with "(manual)" and per-kind parts. Bill form: breakdown box with Total commission and a "manual" tag, Calculation Preview has a "Commission (not in total)" block, type dropdowns use Settings > Ledger Types, rates follow the agent price for the chosen type.
- Settings > Ledger Types (add, rename, delete with the in-use and last-type errors, step rate table choice for depth types).
- Agents tab removed (tabs: Ledger, Portfolio, Accounts, Settings). Portfolio Overview has an Agents section, agent detail sheet and Add/Edit agent dialogs with per-type prices.
- Portfolio: rig pill opens the Switch Vehicle sheet, two large This rig / All rigs pills with a hint line, agent filter resets on scope change, expenses include Other expenses.
- Other expenses: Side Ledger mini stat and category card, list screen, Add/Edit form, Add Entry sheet option, Portfolio side-ledger pie and detail card, CSV and PDF export type.
- Account Ledger home restyled (header pills, white date navigator, summary card on top, floating entry cards, Income/Expense buttons only, rupee sign). Entry form: Save and add another plus Save, inline "Enter an amount" error, 1 second "Saved" snack.
- New dummy data: agent Ramesh (no bills), bill 1043 (9inch depth and PVC), bill 1041 with a manual commission of 4000, three Other expenses, per-type agent prices. Step rate, total and commission rates are fixed on each bill when the page loads (like the stored values in the app).
- Sidebar index has entries for every new screen.

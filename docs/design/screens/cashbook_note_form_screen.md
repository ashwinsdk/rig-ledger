> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_note_form_screen.dart (Add / Edit note)

Group g2. Source: lib/features/cashbook/cashbook_note_form_screen.dart (151 lines).

## 1. Purpose and primary user task

Add a dated note, or edit or delete an existing one. Parity: PARITY-066.

## 2. Current structure

`CashbookNoteFormScreen` (param `note`). State: `_date` (note date or now), `_text` controller (disposed, note_form:25-29). Tree: `Scaffold(cashAppBar(_isEdit ? 'Edit' : 'Notes'))` > `CashPageBody(600)` > `Column[Expanded SingleChildScrollView(16, Column[Row[CashDateField (flex 3), time InkWell+InputDecorator (flex 2)], multi-line TextField 4 to 8 lines, label 'Notes']), Padding(SafeArea Row[Delete (edit only, OutlinedButton red), ElevatedButton Save])]`.
`_save`: edit with empty text shows 'Enter a note' (error snackbar); edit calls `updateNote(note.copyWith(date, text trimmed))`; add calls `addNote(date, text)` and shows the provider error if any; then pops. `_delete`: `confirmCashDialog('Delete', 'Delete this note?')` then `deleteNote(id)` and pops.
Providers: `cashSettingsProvider` (watch), `cashNotesProvider.notifier` (`addNote`, `updateNote`, `deleteNote`).

## 3. Problems found

1. No busy flag: double tap Save creates two notes in add mode (note_form:40-57, 139-140) (G2-B06).
2. App bar title 'Notes' for add and 'Edit' for edit (note_form:71): inconsistent with the field label 'Notes' and with "Add Income"/"Edit Transaction" naming elsewhere.
3. Time picker ignores the 12/24 hour setting (note_form:31-38) (G2-B15).
4. Date and time use two different widgets (`CashDateField`, `InputDecorator`) without labels.
5. The edit path ignores the result of `updateNote` (note_form:47-48); add path pops even when nothing visible changed.
6. Add with empty text relies on the provider error (note_form:50-54); edit validates locally; two paths, one snackbar style.
7. Delete is an equal-width red outlined button next to Save (note_form:127-135): destructive as prominent as the primary action; uses `CashColors.expense`.
8. No `textInputAction`, the multi-line field cannot submit from the keyboard; the Save button is outside the scroll area but is not lifted above the keyboard guaranteed (the `Column` above is not in `resizeToAvoidBottomInset: false`; default is true, so it moves up; acceptable).
9. Back discards silently (same as the reference; PARITY-050 equivalent for notes, unspecified).
10. Field label "Notes" is plural for one note.

## 4. Redesign

- `RigScaffold(appBar: RigAppBar(title: _isEdit ? 'Edit Note' : 'Add Note', actions: [], Delete stays in the bottom action bar as today), maxContentWidth 640)`.
  Title copy: "Add Note" and "Edit Note" replace "Notes" and "Edit" (copy change, Q6).
- Body: one `RigCard` (padding `s4`, gap `s3`): date and time Row (`RigDateField` label "Date", flex 3; `RigTimeField` label "Time" with `use24Hour`, flex 2; stacked below 400 dp), then `RigTextField` label "Note" (hint "Write a note"), 4 to 8 lines, `TextCapitalization.sentences`, autofocus in add mode, `textInputAction: newline`.
- `FormActionBar`: edit = text button "Delete" (`negative`, `Icons.delete_rounded`) + filled "Save"; add = filled "Save" full width. Save shows a 24 dp indicator and disables while `_saving` (new local flag). Delete uses `ConfirmDialog(destructive)` with the same texts ('Delete', 'Delete this note?').
- Validation: both modes show the same inline error "Enter a note" under the field for an empty text; the add path still goes through the provider (message from provider if any is shown as an error snackbar, unchanged).
- Desktop: Cmd+Enter saves, Esc leaves, max width 640.

Tokens: `s4`, `s3`; `md` fields, `lg` card; `bodyLarge` field; colors `negative` for delete.

State table: Default; Loading (saving); Empty text error; Error (snackbar); Disabled (Save while saving).

Motion: error helper fade `fast`.

## 5. Logic touchpoints that must stay untouched

- `addNote(date:, text:)` returns `(_, error)`; `updateNote(note.copyWith(date:, text: trimmed))`; `deleteNote(id)`.
- Edit with empty trimmed text refuses with the snackbar 'Enter a note' (text unchanged) and does not pop.
- Add path trims inside the provider (text passed untrimmed, note_form:50).
- `_date` keeps time of day on date pick; time pick keeps the date.
- Pop after success; delete requires confirmation.
- `_text` controller State-owned and disposed.

## 6. Acceptance criteria

1. Add: type text, Save creates one note dated as chosen; screen closes.
2. Double activation of Save creates one note.
3. Edit: changed text and date persist; empty text shows "Enter a note" and stays.
4. Delete asks "Delete this note?" and removes it.
5. Time picker follows the 12/24 hour setting.
6. Date and time fields are labeled for screen readers.
7. No overflow at 200 percent text, 360 dp.
8. Cmd+Enter saves on macOS.

## 7. Performance notes

- Tiny screen. `ref.watch(cashSettingsProvider)` at the top rebuilds all fields on any setting change; use `select` for the formatters.
- Controller State-owned, disposed; one `setState` per date/time change.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Note form | `SC.cbNote` | lib/features/cashbook/cashbook_note_form_screen.dart | LargeTitleScaffold (pushed, title "New Note" or "Edit Note"), RigGroup (Date, Time rows), RigGroup (multi-line Notes row), pinned buttons (Delete tonal, Save filled), UnsavedChangesGuard | Titles in the mockup are "New Note" and "Edit Note"; the old design proposed "Add Note". |

### R2. What changes in the redesign (supersedes section 4)

Note form (pushed from the Notebook):
1. LargeTitleScaffold, title "New Note" or "Edit Note", back chevron.
2. RigGroup: Date row (`dFull`, opens the DatePickerSheet) and Time row (`fT`, opens the time picker).
3. RigGroup: Notes row, multi-line (six lines visible), hint "Write a note".
4. Pinned bottom bar: add mode a single filled "Save" pill; edit mode a tonal destructive "Delete" pill and a filled "Save" pill (50 dp, gap 12). Delete shows RigAlertDialog "Delete" with "Delete this note?" and the action in `moneyOutText`.
5. Discard prompt (LR-25): dirty when the text, date or time differ from the opening values; back and Android back show "Discard changes?" with Keep Editing and Discard. A clean form closes at once. Save closes without a prompt.
6. Validation: empty text on edit shows the inline error "Enter a note" under the row (the old behaviour used a snackbar with the same text; the add path stays guarded by the provider).


Old section 4 items:

- Old 4 title copy "Add Note" and "Edit Note": CHANGED to "New Note" and "Edit Note" (mockup).
- Old body RigCard with date and time Row: CHANGED to two RigGroups (rows).
- Old FormActionBar with a text Delete: CHANGED to a tonal destructive pill.
- Old Save spinner (`_saving`): KEPT, and it is the LR-32 guard.
- Old inline "Enter a note" for both modes: KEPT as a row error text.
- Old desktop paragraph: DROPPED.


States:

| State | Rule in the new look |
|---|---|
| Default | rows plus pinned pills |
| Loading | Save pill shows a 20 dp spinner while saving |
| Empty | empty text: row error "Enter a note" |
| Error | provider error message in RigSnack |
| Disabled | Save pill disabled while saving |
| Dirty | back raises the discard alert |


Motion: ink press; error text fades 150 ms; sheets and alerts as the shared components; reduced motion removes durations.


### R3. Logic touchpoints and LR items

Untouched: `addNote(date:, text:)` returning `(_, error)`, `updateNote(note.copyWith(...))`, `deleteNote(id)`, empty trimmed text refusing on edit, the add path trimming in the provider, date and time keeping each other, delete needs confirmation, State-owned `_text` controller.


- LR-25 (approved): discard prompt on the note form (named in the LR).
- LR-32 (approved, Phase 1): double-tap Save creates one note.
- LR-24 (approved): `dFull` date.
- No new logic item.


### R4. Acceptance criteria delta

1. Opening a new note and pressing back closes without a prompt; typing then back shows "Discard changes?"; Discard closes, Keep Editing stays.
2. Double tap on Save creates one note; the spinner shows while saving.
3. Edit with empty text shows "Enter a note" and stays; Delete asks "Delete this note?" and removes it.
4. The pinned pills sit above the keyboard at 360 dp; the Notes row scrolls into view.
5. Time picker follows the 12 or 24 hour setting; labels are announced; text scale 200 percent has no overflow.


### R5. Parity delta

Change on purpose:

- PARITY-066: back with unsaved text now prompts (LR-25); previously it closed silently.
- Title text "New Note" in place of "Notes" or "Add Note".


Must stay identical:

- PARITY-066 add, edit, delete with the confirmation "Delete this note?", empty text on edit shows "Enter a note".


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- PopScope with `UnsavedChangesGuard`; dirty via a `ValueNotifier<bool>` fed by `_text` and the date and time fields.
- Controller: `_text` is State-owned and disposed (verified, note form 21-28).


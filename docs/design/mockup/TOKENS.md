# TOKENS (Apple look, Android platform)

Platform: the app is Android only. The Apple look (large titles, inset groups, glass bars) is kept, the behaviour is Android (insets, system back, ripple, 48 dp targets, keyboard). macOS was dropped on 2026-10-13 (see `archive/`).

Source of truth: the `:root` blocks at the top of `rigledger_apple_mockup.html`. Every color in the file is a CSS custom property; `qa/token-audit.mjs` fails if a raw hex or rgb value appears anywhere else (CSS rules or inline styles in the screen templates). This file lists every token, both themes, the WCAG check, the Flutter mapping and the formatter rules.

Reference measurements of the Apple screenshots (3x, PIL, in points, used for proportions only): screen side margin 20, gap between cards about 10.7 (mockup uses 11, Flutter should use 12 on the 4 pt grid), card corner radius about 18 to 20 with a continuous curve (mockup 20), card surface about #1C1C1D (dark), floating tab bar about 61 pt tall with about 22 pt side inset and a 21 pt bottom inset, 20 pt large-title row centred about 69 pt from the top. Brief estimates that measurement corrected: card radius 26 became 20, nav bar 62 pt.

Brand status: the logo and brand colour are not ready, so the default accent is the system blue. The Dev panel can preview lime, green and the provisional brand blue #315D9A (`data-accent` on the root element). Only five tokens change per accent: `--acc`, `--acc-tx`, `--acc-btn`, `--onacc`, `--acc-tint`.

## 1. Naming and roles

| Group | Tokens | Rule |
|---|---|---|
| Surfaces | `--canvas`, `--s1`, `--s2`, `--s3`, `--s1e`, `--sheet` | canvas is the page, `--s1` is a card or inset group, `--s1e` is a card inside a sheet (sheets use a lighter elevated surface), `--s2` and `--s3` are fills for keys and chips |
| Labels | `--lb`, `--lb2`, `--lb3` | primary, secondary, tertiary. `--lb3` is for chevrons and decoration only, never for text that carries meaning |
| Separators and fills | `--sep`, `--fill`, `--fill2` | hairline 0.5 px, unselected pill, switch off track |
| Accent | `--acc` (graphics), `--acc-tx` (text), `--acc-btn` (fill behind a white label), `--onacc`, `--acc-tint` | text and filled-button variants are darker (light) or lighter (dark) than the graphic colour so that they pass AA |
| Money | `--in*`, `--out*`, `--bal*`, `--com*` | each has a graphic colour, a text colour `-tx`, and for in and out a button fill `-btn`. income green, expense and destructive red, balance (pending) orange, commission purple |
| Side ledger categories | `--c-diesel`, `--c-pvc`, `--c-bit`, `--c-ham`, `--c-oth` and their `-tx` | Diesel orange, PVC teal, Bit purple, Hammer pink, Other expenses (v2.0.1) Apple brown. Tile labels are `--on-tile` (black) so the saturated gradients keep contrast |
| Glass | `--glass`, `--glass-bar`, `--glass-bd`, `--glass-sel`, `--bar`, `--alert`, `--scrim` | translucent surfaces; blur is applied only to `#nav` and the collapsed header (see MOCKUP_NOTES.md) |
| Chrome of the mockup page | `--bezel`, `--page`, `--panel*`, `--tl-*`, `--sh-*` | not part of the app, never ship |

Deviations from the brief colours (needed for WCAG AA 4.5:1, measured with the matrix below):
- Light mode text colours are darker than Apple's system colours: Apple #34C759 on white is 2.2:1, so text uses `--in-tx` #1E7434. The system colours stay for graphics (ring, bars, dots, switch).
- Light `--lb2` is rgba(60,60,67,.8) instead of Apple's .6, because .6 gives only 3.4:1.
- Dark `--acc-tx`, `--out-tx`, `--com-tx` are slightly lighter than Apple's dark system colours so that they pass on elevated surfaces and on pill fills.
- Filled buttons use `--acc-btn`, `--in-btn`, `--out-btn` (darker) because white on Apple's #007AFF is 4.0:1.

## 2. Resolved values

| Token | Light | Dark |
|---|---|---|
| `--white` | `#FFFFFF` | same |
| `--black` | `#000000` | same |
| `--canvas` | `#F2F2F7` | `#000000` |
| `--s1` | `#FFFFFF` | `#1C1C1E` |
| `--s2` | `#F2F2F7` | `#2C2C2E` |
| `--s3` | `#E5E5EA` | `#3A3A3C` |
| `--s1e` | `#FFFFFF` | `#2C2C2E` |
| `--sheet` | `#F2F2F7` | `#1C1C1E` |
| `--sep` | `rgba(60,60,67,.29)` | `rgba(84,84,88,.65)` |
| `--lb` | `#000000` | `#FFFFFF` |
| `--lb2` | `rgba(60,60,67,.8)` | `rgba(235,235,245,.6)` |
| `--lb3` | `rgba(60,60,67,.3)` | `rgba(235,235,245,.3)` |
| `--fill` | `rgba(120,120,128,.16)` | `rgba(120,120,128,.24)` |
| `--fill2` | `rgba(120,120,128,.24)` | `rgba(120,120,128,.36)` |
| `--inv-bg` | `#000000` | `#FFFFFF` |
| `--inv-tx` | `#FFFFFF` | `#000000` |
| `--acc` | `#007AFF` | `#0A84FF` |
| `--acc-tx` | `#0059B8` | `#4FA3FF` |
| `--acc-btn` | `#0062CC` | `#0072E5` |
| `--onacc` | `#FFFFFF` | same |
| `--acc-tint` | `rgba(0,122,255,.1)` | `rgba(10,132,255,.2)` |
| `--in` | `#34C759` | `#30D158` |
| `--in-tx` | `#1E7434` | `#30D158` |
| `--in-btn` | `#1E7434` | `#1E8537` |
| `--out` | `#FF3B30` | `#FF453A` |
| `--out-tx` | `#BE0A00` | `#FF6B63` |
| `--out-btn` | `#CC0B00` | `#EA0D00` |
| `--bal` | `#FF9500` | `#FF9F0A` |
| `--bal-tx` | `#945600` | `#FF9F0A` |
| `--com` | `#AF52DE` | `#BF5AF2` |
| `--com-tx` | `#9928D2` | `#D17FF6` |
| `--dng` | `var(--out)` | same |
| `--dng-tx` | `var(--out-tx)` | same |
| `--wrn` | `var(--bal)` | same |
| `--wrn-tx` | `var(--bal-tx)` | same |
| `--c-diesel` | `#FF9500` | `#FF9F0A` |
| `--c-diesel-tx` | `#945600` | `#FF9F0A` |
| `--c-pvc` | `#30B0C7` | `#40C8E0` |
| `--c-pvc-tx` | `#1E6F7D` | `#40C8E0` |
| `--c-bit` | `#AF52DE` | `#BF5AF2` |
| `--c-bit-tx` | `#9928D2` | `#D17FF6` |
| `--c-ham` | `#FF2D55` | `#FF375F` |
| `--c-ham-tx` | `#CB0027` | `#FF6F8D` |
| `--c-oth` | `#A2845E` | `#AC8E68` |
| `--c-oth-tx` | `#7A5B38` | `#C4A57C` |
| `--on-tile` | `#000000` | same |
| `--glass` | `rgba(255,255,255,.72)` | `rgba(58,58,60,.7)` |
| `--glass-bar` | `rgba(250,250,252,.78)` | `rgba(44,44,46,.66)` |
| `--glass-bd` | `rgba(255,255,255,.9)` | `rgba(255,255,255,.16)` |
| `--glass-sel` | `rgba(120,120,128,.12)` | `rgba(10,10,12,.62)` |
| `--bar` | `rgba(242,242,247,.82)` | `rgba(0,0,0,.72)` |
| `--alert` | `rgba(255,255,255,.96)` | `rgba(44,44,46,.97)` |
| `--scrim` | `rgba(0,0,0,.35)` | `rgba(0,0,0,.55)` |
| `--sh` | `0 1px 2px rgba(0,0,0,.04),0 6px 18px rgba(0,0,0,.05)` | `none` |
| `--sh-bar` | `0 8px 28px rgba(0,0,0,.14)` | `0 8px 28px rgba(0,0,0,.5)` |



## 3. Accents (Dev panel preview)

| Accent | Light `--acc` / `--acc-tx` / `--acc-btn` | Dark `--acc` / `--acc-tx` / `--acc-btn` | `--onacc` |
|---|---|---|---|
| System blue (default) | #007AFF / #0059B8 / #0062CC | #0A84FF / #4FA3FF / #0072E5 | white |
| Lime | #8FD100 / #4D7000 / #8FD100 | #C6F73A / #C6F73A / #C6F73A | black |
| Green | #34C759 / #1E7434 / #34C759 | #30D158 / #30D158 / #30D158 | black |
| Brand #315D9A (provisional) | #315D9A / #315D9A / #315D9A | #6D97D1 / #6D97D1 / #315D9A | white |

## 4. Type, spacing, radius, motion

| Token | Value | Notes |
|---|---|---|
| Font stack | `Inter, Roboto, system-ui, sans-serif` | Inter is vendored (`fonts/InterVariable.woff2`, SIL OFL 1.1, license in `fonts/Inter-OFL.txt`) and loaded with `@font-face` so it is always first. Flutter bundles the same Inter (T-U03): weights 400, 500, 600, 700 and `FontFeature.tabularFigures()` on every amount (the mockup uses `font-feature-settings: 'tnum'`) |
| Numbers | `font-variant-numeric: tabular-nums` on the page | |
| Scale (class) | `.t34` 34/1.2 bold, `.t28`, `.t22` 22/1.25 bold, `.t20`, `.t17` 17/1.3, `.t15`, `.t13`, `.t12`, `.t11` (minimum), `.hero` 44 bold | all sizes are `calc(Npx * var(--ts))`; `--ts` is the text scale (Dev panel 100, 130, 200) |
| Margin / gap | 20 / 12 (`--mx`, `--gap`) | gap was 11 (measured 10.7), set to 12 on the 4 pt grid by decision |
| Radius | card and inset group 20, sheet top 28, alert 14, tile 28, chip and pill 22, form row 0 inside a group | |
| Row height and targets | 48 dp minimum (`--tap`) | Android rule, was 44. Chips and segments are 48 dp boxes with a visible pill inside (transparent border trick); the QA script fails any target under 48 |
| Motion | 200 to 350 ms ease-out, press scale .98, ring and bars reveal, sheet rise | all off under `prefers-reduced-motion` |

## 4b. Android platform

| Token | Value | Notes |
|---|---|---|
| Device (Dev panel) | 412 x 892 dp, or 360 x 800 dp (small phone) | `--dw`, `--dh`; the bezel is 8 px with a 30 px radius, no notch |
| Status bar `--sbh` | 28 dp, edge to edge, transparent over the content | time left, signal, wifi, battery right (Material icons). Flutter: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` and `MediaQuery.viewPaddingOf` |
| App bar row `--abh` | 56 dp | holds the pinned glass buttons and the collapsed title; large title sits below on pushed screens |
| Bottom inset `--inset` | 24 dp with gesture navigation (a 108 x 4 pill is drawn); 0 dp with 3-button navigation | `--sysb` is 48 dp for the 3-button bar, which is opaque and back, home, recents. Flutter: `MediaQuery.viewPaddingOf(context).bottom` |
| Tab bar | 62 dp, floats `--inset` + 8 dp above the bottom, 16 dp side margin | lists end at `--navh` = 62 + inset + 8 + 24. Sticky bottom buttons (`.bot`, `.shbot`) use inset + 12 and sit above the inset |
| Keyboard `--kb` | 300 dp panel while a text field is focused | the screen, sheets and the tab bar give way (tab bar hidden); the focused field is scrolled to the centre; the inset becomes 0 while the keyboard is open |
| Pressed feedback | `--press` (light rgba(0,0,0,.08), dark rgba(255,255,255,.12)); `--press-on` (rgba black .2 or .22) on filled controls | CSS only: an inset overlay on :active for rows, cards, chips, segments, buttons, keys, tab items. No scale feedback. Flutter: `InkWell`/`Material` with `splashColor` = these colours and `ThemeData.splashFactory: InkSparkle.splashFactory` (Android 12 and up) |
| Glass blur (Dev toggle) | default OFF | off: solid surface at 94 percent (`--bar-s`, `--glass-bar-s`) with a hairline border. On: translucent `--bar`, `--glass-bar` with `backdrop-filter` (header and tab bar, plus the sheet scrim). Blur must be profiled on the reference Android device before it is switched on in the app |
| Theme | follows the system (Android 10 and up): `prefers-color-scheme` here, `ThemeMode.system` in Flutter | no dynamic colour (Material You) |
| System back | Dev button "System back" and the Escape key | order: keyboard, popover, top dialog or sheet, top screen, then the app is left on a root tab (Android default). No edge swipe is used anywhere in the app |

Switch and checkbox: they keep the Apple look but are Flutter's `Switch` and `Checkbox` with a custom theme, not custom widgets. `SwitchThemeData`: track 51 x 31 as close as Material allows (set `trackOutlineColor` transparent, `thumbColor` white, `trackColor` on = `moneyIn`, off = `fillStrong`), `materialTapTargetSize: padded` for the 48 dp target. `CheckboxThemeData`: `shape: CircleBorder()`, `side` 2 dp `outline`, `fillColor` accent when selected, `checkColor` onAccent.

## 5. Contrast matrix

Computed from the resolved values above (WCAG 2.x relative luminance, translucent labels composited over each surface). Fills such as `--fill` are composited over `--s1`.

### Contrast matrix (WCAG 2.x, text tokens)

#### Light

| Text token | on canvas | on surface-1 | on elevated (sheet cards) | on fill chip | Verdict (>= 4.5) |
|---|---|---|---|---|---|
| `--lb` | 18.82 | 21.00 | 21.00 | 17.38 | PASS |
| `--lb2` | 5.56 | 5.97 | 5.97 | 5.27 | PASS |
| `--acc-tx` | 6.03 | 6.73 | 6.73 | 5.57 | PASS |
| `--in-tx` | 5.22 | 5.83 | 5.83 | 4.82 | PASS |
| `--out-tx` | 5.82 | 6.50 | 6.50 | 5.37 | PASS |
| `--bal-tx` | 5.24 | 5.85 | 5.85 | 4.84 | PASS |
| `--com-tx` | 5.24 | 5.85 | 5.85 | 4.84 | PASS |
| `--c-diesel-tx` | 5.24 | 5.85 | 5.85 | 4.84 | PASS |
| `--c-pvc-tx` | 5.19 | 5.79 | 5.79 | 4.79 | PASS |
| `--c-bit-tx` | 5.24 | 5.85 | 5.85 | 4.84 | PASS |
| `--c-ham-tx` | 5.27 | 5.88 | 5.88 | 4.87 | PASS |
| `--c-oth-tx` | 5.57 | 6.21 | 6.21 | 5.14 | PASS |

#### Dark

| Text token | on canvas | on surface-1 | on elevated (sheet cards) | on fill chip | Verdict (>= 4.5) |
|---|---|---|---|---|---|
| `--lb` | 21.00 | 17.01 | 13.94 | 12.76 | PASS |
| `--lb2` | 6.36 | 5.95 | 5.27 | 4.97 | PASS |
| `--acc-tx` | 8.02 | 6.49 | 5.32 | 4.87 | PASS |
| `--in-tx` | 10.39 | 8.42 | 6.89 | 6.31 | PASS |
| `--out-tx` | 7.54 | 6.11 | 5.00 | 4.58 | PASS |
| `--bal-tx` | 10.22 | 8.28 | 6.78 | 6.21 | PASS |
| `--com-tx` | 8.08 | 6.54 | 5.36 | 4.91 | PASS |
| `--c-diesel-tx` | 10.22 | 8.28 | 6.78 | 6.21 | PASS |
| `--c-pvc-tx` | 10.56 | 8.55 | 7.01 | 6.41 | PASS |
| `--c-bit-tx` | 8.08 | 6.54 | 5.36 | 4.91 | PASS |
| `--c-ham-tx` | 7.91 | 6.41 | 5.25 | 4.81 | PASS |
| `--c-oth-tx` | 9.02 | 7.31 | 5.99 | 5.48 | PASS |

#### Filled controls (label on fill)

| Pair | Light | Dark |
|---|---|---|
| white on `--acc-btn` (primary pill) | 5.80 | 4.63 |
| `--onacc` on `--acc-btn` | 5.80 | 4.63 |
| white on `--in-btn` (Income button) | 5.83 | 4.70 |
| white on `--out-btn` (Expense and destructive) | 5.81 | 4.61 |
| `--inv-tx` on `--inv-bg` (selected chip) | 21.00 | 21.00 |
| `--on-tile` on `--c-diesel` | 9.55 | 10.22 |
| `--on-tile` on `--c-pvc` | 8.16 | 10.56 |
| `--on-tile` on `--c-bit` | 5.08 | 5.96 |
| `--on-tile` on `--c-ham` | 5.76 | 5.96 |
| `--on-tile` on `--c-oth` | 6.00 | 6.82 |

Gradient tiles lighten toward white, so the black label only gains contrast along the gradient.


The same rule is checked on the live DOM by `qa/shoot.mjs` (every text node against its real composited background, gradient tiles against every gradient stop): 0 failures (see MOCKUP_PROGRESS.md for the matrix of modes) in light and dark.

## 6. Flutter mapping

`ColorScheme` (Material roles) and one `ThemeExtension<RigColors>` for the money and category roles. Build two schemes by hand (not `ColorScheme.fromSeed`) so that Apple-style neutrals are exact.

| Mockup token | ColorScheme role | RigColors field |
|---|---|---|
| `--canvas` | `surface` (scaffold background) | |
| `--s1` | `surfaceContainerLow` (cards, inset groups) | |
| `--s1e` / `--sheet` | `surfaceContainerHigh` / `surfaceContainer` (sheets and their cards) | |
| `--s2`, `--s3` | `surfaceContainerHighest` | `fillStrong` |
| `--lb` / `--lb2` / `--lb3` | `onSurface` / `onSurfaceVariant` / `outline` | |
| `--sep` | `outlineVariant` | |
| `--fill` | | `fill` (unselected pill, inactive switch track) |
| `--inv-bg` / `--inv-tx` | | `inverseChip`, `onInverseChip` (selected period chip) |
| `--acc-btn` / `--onacc` | `primary` / `onPrimary` | |
| `--acc-tx` | | `accentText` (text buttons, links); also `primary` when used as text |
| `--acc-tint` | `primaryContainer` (tinted secondary pill) with `onPrimaryContainer` = `--acc-tx` | |
| `--in`, `--in-tx`, `--in-btn` | | `moneyIn`, `moneyInText`, `moneyInButton` |
| `--out`, `--out-tx`, `--out-btn` | `error`, (text), `errorContainer` | `moneyOut`, `moneyOutText`, `moneyOutButton` |
| `--bal`, `--bal-tx` | | `outstanding`, `outstandingText` |
| `--com`, `--com-tx` | | `commission`, `commissionText` |
| `--c-diesel` ... `--c-ham` and `-tx` | | `catDiesel`, `catPvc`, `catBit`, `catHammer` (+ text) |
| `--glass*`, `--bar`, `--alert`, `--scrim` | | `glass`, `glassBar`, `glassBorder`, `glassSelected`, `bar`, `scrim` |
| `--sh`, `--sh-bar` | | `RigElevation.card` (light only), `RigElevation.bar` |
| `--bar-s`, `--glass-bar-s` | | `barSolid`, `glassBarSolid` (default); `bar`, `glassBar` only when the blur flag is on |
| `--press`, `--press-on` | | `pressOverlay`, `pressOverlayOnFill` (ink splash and highlight colours) |

Theme: `ThemeMode.system` by default, a persisted setting (LR-23 in LOGIC_REQUESTS.md) with System, Light, Dark. The accent is one `Color` seed in `RigColors.accent*`; changing it recolours buttons, selected states and the ring. Text scale uses `MediaQuery.textScalerOf` and the stress rules in HIGHLIGHTS_AND_COLLAPSE.md section B.

## 7. Formatter rules (the only logic-block change)

One money formatter replaces `inr`, `inrS`, `rs`, `grp` (number form) and `num`:

| Function | Rule | Example |
|---|---|---|
| `money(n)` | rupee sign, en-IN grouping (lakh, crore), two decimals only when the value has paise, minus before the sign, never negative zero, `--` for non-finite | `₹59,000`, `₹1,25,000.50`, `-₹4,50,000` |
| `money(n, {compact:true})` | `L` from 1,00,000, `Cr` from 1,00,00,000 and `L Cr` (lakh crore) from 1e12; up to 2 decimals, none once the number is 1,000 or more; never used on its own | `₹2.28 L`, `₹22.7 Cr`, `₹1.28 L Cr` |
| `qty(n)` | en-IN grouping, up to 2 decimals, no symbol | `1,25,000` |
| `ftq(n)` | `qty` plus ` ft` | `630 ft` |
| `mfit(n)` / `mf(n)` | the fit pipeline for highlight tiles and list cells: full value; scale down to 75 percent; then compact; last guard shrinks to 11 px. Tap shows the full value in a popover | |

Dates (one documented set; time stays `fT`, 12 hour `hh:mm AM`):

| Function | Pattern | Example | Use |
|---|---|---|---|
| `dRow(s)` | `d MMM` | `12 Oct` | compact row meta (Account Ledger when "show date" is on, calendar chips, summary rows) |
| `dGroup(s)` | `EEE, d MMM yyyy` | `Mon, 12 Oct 2026` | sticky day group headers |
| `dFull(s)` | `d MMM yyyy` | `12 Oct 2026` | forms, ranges, period labels |
| `dMonth(d)` | `MMMM yyyy` | `October 2026` | month navigator |

Kept on their own formats, on purpose: the Export to PDF screen (summary lines `Rs. 282,910.00` and the range rows `01 Oct 2026`) and the Export to CSV column list, because export content is frozen (UX_FLOWS.md F-6). The Account Ledger "Format Date" setting stays a user choice; its six sample patterns in the mockup are illustrative.

Open decision shown in the mockup, not decided here: the Account Ledger now shows the rupee sign everywhere instead of `Rs.` (v2.0.0 review question, LR-16).

### Call sites changed (baseline v1 function: formatter used before, now)

Counts are the number of calls in the v1 file. Totals: `inr` 32, `grp` 26, `rs` 12, `fCb` 10, `num` 8, `fCbDay` 5, `fDM` 4, `fEEE` 3, `fSl` 2, `inrS` 1, `cmp` 1.

| v1 function | Used | Now |
|---|---|---|
| `ledgerTab` | `fDM` x2, `grp` x3 | `dFull`, `qfit`, `mfit` |
| `billList` | `fEEE`, `grp` x5 | `dGroup`, `mf`, `money` |
| `calView` | `cmp` | `qty` (calendar cells show a plain grouped number) |
| `sideLedger` | `grp` x4, `inr` | `money`, `mfit`, `qty` |
| `slList` | `grp` x3, `inr` x6, `fSl` | `money`, `mf`, `dFull`, `qty` |
| `slForm`, `slTot` | `fSl`, `inr` x2 each | `dFull`, `money`, `setFit` |
| `billForm` | `fEEE`, `inr` | `dFull`, `money`, `mfid` |
| `sideBoreForm` | `fEEE`, `inrS`, `inr` | `dFull`, `money`, `mfid` (lakh grouping now everywhere) |
| `previewHtml`, `onFi`, `commissionBox` | `inr` x2, `inr` x3, `grp` | `money`, `mf`, `setFit` |
| `payLog`, `payDlgRender` | `grp` x2, `fDM` x2, `inr` | `money`, `mf`, `dFull` |
| `portfolioTab` | `inr` x12, `grp` x7 | `money`, `mf`, `mfit`, `qty` |
| `agentsTab` | `inr` | `mf` |
| `strip` (Account Ledger) | `rs` x5 | `cbStrip` with `mfit` |
| `cbRows` | `rs` x3, `num`, `fCbDay`, `fCb` | `mf`, `money`, `dGroup`, `dRow` |
| `cbLabel` | `fCb` x2 | `dFull` (`to` instead of an arrow) |
| `cbDaySheet`, `SC.cbAllTx`, `SC.cbTrash`, `SC.cbBooks` | `rs`, `fCbDay` | `mf`, `dGroup` |
| `SC.cbAcctSummary`, `SC.cbCalendar`, `cbItemsDlg` | `num` x3, `num` x2, `num` x2 | `mf`, `qty`, `money` |
| `SC.cbEntry`, `SC.cbNote`, `SC.cbSettings`, `SC.cbTransfer`, `cbBookDlg`, `cbOpenBal`, `SC.cbNotebook` | `fCb`, `fCbDay` | `dFull`, `dGroup` |
| `calcRender` | `grp` | `qty` |

## 8. How to check

```
node qa/token-audit.mjs                 # no raw colours outside tokens
node qa/logic-diff.mjs                  # logic block identical to qa/logic-baseline-v2.0.4.txt, plus hand-computed numbers
node qa/smoke.mjs                       # every J screen renders, no script errors
node qa/flows.mjs                       # click-through: bill lines, agent choice, agent filter, agent edit and delete
node qa/shoot.mjs                       # screenshots plus overflow, text size, touch target (48), contrast and keyboard checks
node qa/shoot.mjs --stress --ts 2       # very large amounts and 200 percent text
node qa/shoot.mjs --width 360           # small phone
node qa/shoot.mjs --nav3                # 3-button navigation
node qa/shoot.mjs --blur                # glass blur on
python3 qa/contact.py docs/design/ref/qa phone dark   # contact sheets
```

## 7. v2.0.1 additions (no raw colours: every colour below is an existing token or a `color-mix` of tokens)

New token: `--c-oth` / `--c-oth-tx` (Other expenses, Apple brown; light #A2845E and #7A5B38, dark #AC8E68 and #C4A57C). Chosen because indigo and the other system colours either failed black-on-tile contrast (indigo 3.7:1) or collided with Bit and Commission purple. Flutter: add `otherExpense` and `otherExpenseText` to `RigColors`; the screens use `Colors.purple` today.

| Component (CSS class) | Where | Spec |
|---|---|---|
| Slim summary card (`.sumstrip`, `.hscroll`) | Ledger home | one card (radius 20, `--sh`), items 112 dp minimum (scaled by text size), 0.5 px dividers, scrolls sideways, no scrollbar; label 12 sp `lb2` with a 14 dp icon, value 17 sp bold in the money colour; Total, Received, Balance, Commission, and "Total Depth" at the end for a side bore rig. Flutter: horizontal `SingleChildScrollView` of fixed width items |
| Feet bar (`.feetbar`, `.tch`) | Ledger home, main bore only | collapsible card, header 48 dp row "Feet: Depth X \| PVC Y \| MS Z" and an expand arrow; expanded: three groups, a chip per type (fill, label `lb2`, value 13 sp semibold in `acc-tx`, `c-pvc-tx`, `c-diesel-tx`), zero shows `0 ft` |
| View toggle (`.segs`) | Ledger home | two 48 dp icon buttons (agenda, calendar) in a fill capsule next to the month arrows; aria labels Daily and Calendar |
| Commission strip (`.cmstrip`) | bill card | 10 dp radius, `com` at 12 percent, handshake icon, "Commission" (+ " (manual)"), amount in `com-tx`, per-kind amounts right in 11 sp `lb2` |
| Commission breakdown (`.cbk`, `.mantag`) | bill form | card with Depth, PVC and MS pipe commission rows, hairline, "Total commission" bold; the amber manual tag is `bal` at 20 percent with `bal-tx` text |
| Scope pills (`.scope`, `.hint`) | Portfolio Overview | capsule in `acc-tint`, two 48 dp pills with icons, selected = `acc-btn` fill with `onacc` text; a 12 sp `lb2` hint line below |
| Agents section (`.plink`) | Portfolio Overview | card with a title row and "Add agent" text button; each agent a 48 dp minimum row, hairline separated: name, bill count or "no bills", chevron, then four labelled amounts |
| Category tile and card for Other expenses (`.g-other`) | Side Ledger, Other Expenses list, Add Entry sheet | same gradient rule as the other categories, `--on-tile` label |

## 9. v2.0.2 additions (no new raw colours and no new tokens: every colour below is an existing token or a `color-mix` of tokens)

| Component (CSS class) | Where | Spec |
|---|---|---|
| Line card (`.grp` plus `.fr.lnh`) | bill forms | one inset grouped card per bill line (radius `--r`, `--sh`, gap `--gap` between cards). Rows: Type (dropdown, main bore only), feet, rate per foot (48 dp rows). With more than one line in a category the first row is a header (`.fr.lnh`): "Depth line 2" in 13 sp semibold `lb2`, uppercase, and a 48 dp remove button (close icon in `out-tx`, aria label "Remove Depth line 2"). Flutter: `LinesSection` card (`AppColors.surface`, radius 12) |
| Add line button (`.btx.addln`) | bill forms, under the last line card of a category | text button, add icon 18 dp plus "Add Depth line" / "Add PVC line" / "Add MS Pipe line", `acc-tx`, 48 dp tall, left aligned with the card margin (negative 4 px top margin pulls it under the card). Flutter: `TextButton.icon` |
| Card chip (`.ichip`) | bill card, second info row | 16 dp icon in `lb2`, label 13 sp `lb2`, value 13 sp medium `lb` (Depth value "200ft (7inch) + 150ft (8inch)", PVC value "7inch + 8inch"); the row wraps (`.entry .r2` is `flex-wrap`), so long values go to a second line. Flutter: `_InfoChip` in a `Wrap` |
| Agent filter pill (`.pillb.afp`, `.on`) | Portfolio Overview, under the scope pills | the rig pill shape (48 dp tall, radius 24, `--fill`): person icon, "Agent:" in `lb2`, the name (ellipsis), drop-down arrow. Selected agent: background `acc-tint`, 1 px inset `acc` outline, icon and "Agent:" in `acc-tx`. Flutter: `_AgentFilterPill` (primary at 10 percent, primary border) |
| Agent filter sheet (`sheet()` with `#afq`, `#aflist`) | Portfolio Overview | standard sheet with grabber, title "Filter by agent", a search row (search icon, placeholder "Search agents") in a `.grp`, then a `.grp` of two line rows (name 17 sp, subtitle 13 sp `lb2`). Chosen row: name in `acc-tx` and a check mark. Empty search result: centred 15 sp `lb2` "No agent matches". Flutter: `_AgentFilterSheet` (`ListTile`s) |

## 10. v2.0.3 additions (no new raw colours and no new tokens: every colour below is an existing token or a `color-mix` of tokens)

| Component (CSS class) | Where | Spec |
|---|---|---|
| Agent view header (`.agh`) | Portfolio Overview with an agent chosen | card radius `--r`, margin `--mx`, padding 12 / 8 / 12 / 16, background `linear-gradient(135deg, acc-btn, mix(acc-btn 70 percent, black))`, text `onacc` (white on the blue; the lime and green accents use black text). Row 1 (48 dp): person icon 20 dp, name 20 sp semibold with ellipsis, tune icon button. Then the period (13 sp), "Commission earned" (13 sp), the amount 34 sp bold (`mfit`, scales down inside the card), and the outlined back button (`.ahb`: 48 dp tall pill, 1 px `onacc` outline, arrow_back 20 dp, "All agents" 15 sp semibold). Flutter: `AgentView._header` (`AppColors.cardGradient`, white text) |
| Agent profit card (`.agp`, `.neg`) | under the header | radius `--r`, `in` at 10 percent over `s1` with a 1 px inset `in` at 35 percent outline (good); `.neg` uses `out` the same way. Label 13 sp `lb2`, amount 28 sp bold `in-tx` or `out-tx`, "Expected when all pending is collected: X" 13 sp (amount bold), "All agents, after expenses: X" 13 sp `lb2`, the note 12 sp `lb2`. Flutter: `_profitCard` |
| Agent month table (`.card.mtb`, `.mr`, `.th`) | under the Bills / Total cards, only when the period spans more than one calendar month | card with the title "By month" (17 sp semibold), a header row (12 sp semibold `lb2`: Month, Bills, Total, Commission) and one row per month newest first; grid columns 1.25 / 0.6 / 1.2 / 1.2 fr, 8 px gap, hairline between rows; month 15 sp semibold, bills 13 sp, total 13 sp semibold, commission 13 sp semibold `com-tx`; numbers right aligned and shrink with `fitAll`. At text scale above 150 percent the table stacks (`.stk`): month on its own line, then one labelled line per figure. Flutter: `_monthTable` (`Row`s with `Expanded` flex 3, 2, 3, 3) |
| Agent bill card (`.agb`, `.stk`) | the Bills list of the agent view | one `.card`-like button (radius `--r`, `--sh`, margin `--mx`, gap `--gap`), min 48 dp: row 1 date 13 sp `lb2`, #number 15 sp bold, address 15 sp with ellipsis, chevron; row 2 three columns Total (`acc-tx`), Received (`in-tx`), Balance (`bal-tx`, `in-tx` when settled), label 12 sp `lb2`, value 14 sp semibold (`mfit`); row 3 the existing commission strip (`.cmstrip`, "Commission" or "Commission (manual)", split Depth / PVC / MS right when more than one kind and not manual). At text scale above 150 percent the three amounts stack (`.agb.stk`). Flutter: `_BillRow` |
| Agent totals row (`.agt`) | end of the Bills list | `acc-tint` card, radius `--r`, wrapping row 14 sp: "N bills" bold, Total, Received, Pending, Commission (amounts bold in their money colours). Flutter: `_totalRow` (primary at 8 percent, radius 12) |
| Info icon button (`.agi`) | Agents section rows, agent view header (tune) | 48 x 48 dp round target, `info_outline` 22 dp in `lb2` (the header uses the `tune` icon in `onacc`), pressed overlay `--press`, tooltip and aria label "Prices and details". Flutter: `IconButton(Icons.info_outline)` / `IconButton(Icons.tune)` with `tooltip: 'Prices and details'` |

## 11. v2.0.4 additions (no new raw colours and no new tokens: every colour below is an existing token or a `color-mix` of tokens)

| Component (CSS class) | Where | Spec |
|---|---|---|
| Info box (`.infob`) | Step Rates, under the Rig row | `acc-tint` background, radius 16, margin `--mx`, padding 14, an info icon (`acc-tx`, 20 dp) and 13 sp text in `lb`. Flutter: `Container` with the info colour at 8 percent and radius 12 |
| Step table editor card (`sec()` title plus `.grp`) | Step Rates, one per table | a 22 sp section title ("7 inch table") over one inset group of 48 dp form rows: "Step rate starts after" (number, `ft` suffix), the bracket rows, an "Add bracket" row (add_circle 22 dp, `acc-tx` label), "After the last bracket, extra per ft grows by" (rupee prefix, `per 100 ft` suffix); the group footnote (`.fh`, 13 sp `lb2`) is the live example line. Labels wrap at 200 percent text. Flutter: `_TableEditor` (a `Container`, radius 16, border) |
| Bracket row (`.fr` with a rupee prefix and a `.nbtn` suffix) | Step Rates | label "300 to 400 ft, extra per ft" (follows the typed start), rupee sign, number input, a 48 x 48 dp close icon button in `acc-tx` (disabled at 35 percent when it is the only row). Flutter: `TextField` with `IconButton(Icons.close)` |
| Rig dropdown row (`.fr.sel`) | Account Ledger entry form | 48 dp row: precision_manufacturing icon 20 dp and "Rig (optional)" on the left, the chosen name ("No rig" by default, ellipsis) on the right with an expand_more icon. Tap opens a sheet of rows (No rig, then each rig with its type, check mark in `acc` on the chosen one). Disabled (55 percent opacity, no arrow) with the helper "Set from the bill" under the group for income linked from a bill payment. Flutter: `DropdownButtonFormField<String?>` (the mockup shows the menu as a sheet) |
| Rig chip on the row (`.entry .r2.rg`) | Account Ledger rows | third line under the time line: precision_manufacturing 14 dp in `lb2` and the rig name 13 sp `lb2` with ellipsis; absent without a rig. Flutter: `Row` with `Icon(size: 13)` and `Text(fontSize: 12)` |
| Feet and commission card (`.card.fcard`, `.fch`, `.fcc`, `.fcx`) | agent view, between the metric cards and By month | card with a 17 sp semibold title; per group a header row (12 sp semibold `lb2` title on the left, "Total 1,910 ft  |  ₹20,070" 12 sp bold in the group colour on the right, wraps) and a wrapping row of chips (`--fill`, radius 10, padding 6 / 10): line 1 `7"` in `lb2` then the feet 13 sp semibold in the group colour (`acc-tx` depth, `c-pvc-tx` PVC, `c-diesel-tx` MS pipe), line 2 "Commission ₹13,500" (the commission chip text) 11 sp `lb2`; an optional 12 sp `lb2` note. Flutter: `_feetByType` (chips are `Container`s with a `Column`) |

# Archive

`macos_css_block.css` holds every CSS rule that was removed when macOS was dropped (the 1280 px window, sidebar, grids, hover rules, traffic lights). The JavaScript parts that went with it:
- `applyUI` toggled the class `mac` on `#phone` when `UI.dw >= 1000`
- the Dev panel had a `Device width` option `macOS 1280`
- `render()` kept `#nav` visible on pushed screens when wide, and each nav button carried a shortcut label (`Cmd+1` to `Cmd+5`)
- Escape, `Cmd+1..5` and `Cmd+N` keyboard handlers
- wrapper elements kept in the markup (`.dgrid`, `.hrow`, `.grp2`) are still there and are plain blocks on a phone
If macOS comes back, restore from these notes and re-run `node qa/shoot.mjs --width 1280` (the 28 px pointer target rule was used there).

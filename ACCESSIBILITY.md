# Accessibility

This bootstrap changes how a Mac looks and behaves, so it treats accessibility settings with extra
care. Contrast, cursor size and predictable layouts are practical needs for many people. A setup
script that quietly reset them would make a new Mac harder to use from the first minute.

> [!NOTE]
> The published settings are one person's choices. Make them yours by setting them in System
> Settings and running `--capture-settings`, which records them in your fork of system-defaults.
> If a change would help other people too, open an issue or a pull request so I can consider it
> for everyone.

## Settings carried over exactly

| Setting | Why it matters |
| --- | --- |
| Pointer size (`mouseDriverCursorSize`) | A larger pointer is easier to find without depth cues. Captured as 2, about twice the default |
| Increase contrast and reduce transparency | Captured as they are set, on or off, rather than assumed |
| Reduce motion and differentiate without colour | Carried over whenever they are set on the source Mac |
| Keyboard navigation (`AppleKeyboardUIMode`) | Captured as it is set (currently off), so a Mac that relies on Tab moving through every control keeps it |
| Dock size and position | A predictable place for every app, set to the size that reads comfortably |

Nothing in this list is written unless it differs from what the Mac already has, so running the
bootstrap on a Mac never resets a setting that was changed by hand since the last capture.

> [!WARNING]
> macOS can refuse writes to accessibility settings from a script. The bootstrap then lists each
> refused setting at the end of the run instead of failing. Set those in System Settings,
> Accessibility, straight after the run.

## Terminal colours

The configs stage runs terminal-config's installer, so Terminal.app and iTerm2 get the High Contrast
palette straight away: vivid colours on black in dark mode, every colour at 7:1 or more on white in
light mode. Both switch with macOS's light and dark setting; Terminal.app through a small login
agent the installer builds. Bold text keeps its colour rather than switching to the softer bright
row.

## Output

The bootstrap prints every line with a word label as well as a colour (`[INFO]`, `[ OK ]`, `[WARN]`,
`[ERROR]`), so the state of a run reads correctly without colour.

## Known gaps

- The zoom shortcuts and scroll-to-zoom are captured when they are set. VoiceOver keeps its
  settings in its own utility, so a new Mac imports them from VoiceOver Utility's export rather
  than through the bootstrap.

## Feedback wanted

If something here gets in the way, open an [issue](https://github.com/zaccesss/mac-bootstrap/issues/new/choose)
describing what happened and what would work better.

## The shared statement

> [!NOTE]
> I keep one shared accessibility statement for all my projects: [zaccesss/accessibility](https://github.com/zaccesss/accessibility) or on [my site](https://isaacadjei.me/accessibility). This file takes precedence where the two differ.

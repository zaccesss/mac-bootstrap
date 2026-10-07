# Settings

macOS settings live in [system-defaults](https://github.com/zaccesss/system-defaults), not here. It holds three
files under `mac/`:

| File | What it holds |
| --- | --- |
| `tracked.txt` | The keys worth carrying from one Mac to the next, grouped by area |
| `defaults.tsv` | The values captured from a real Mac, with their types |
| `defaults.sh` | The script that captures (`--capture`) and applies them |

The bootstrap's settings stage clones that repository into `~/.dotfiles/system-defaults` and runs
the script. Keeping the data and the script together means one source of truth that works with or
without this bootstrap, alongside the Linux settings in the same repository.

## Capturing

```bash
./bootstrap/bootstrap.sh --capture-settings
```

Records this Mac's values for every tracked key into the system defaults repository's
`defaults.tsv`. Keys left at the system default are not recorded. Commit the file in your own fork
afterwards, so your next Mac gets your settings rather than the published ones.

## Applying

```bash
./bootstrap/bootstrap.sh --settings-only
```

Only values that differ are written, so a Mac that already matches is not touched. The Dock, Finder
and menu bar restart only when one of their own settings changed. A path stored with `~` and the
same path spelt out count as equal.

## Accessibility settings

> [!IMPORTANT]
> Accessibility choices such as pointer size, contrast and the zoom shortcuts are carried over
> exactly as captured. macOS sometimes refuses writes to accessibility settings from a script. When
> it does, the run does not fail: each one is listed at the end so it can be set in System Settings,
> Accessibility.

## Settings outside the scope

Display arrangement, Wi-Fi, notifications per app, login items, privacy permissions and VoiceOver
(which exports from VoiceOver Utility) are set by hand. See the [new Mac checklist](new-mac.md).

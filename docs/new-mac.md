# New Mac checklist

The bootstrap does most of the work. These are the steps around it, in order.

## Before the bootstrap

1. Finish macOS setup, sign in to the Apple Account and let macOS update fully (System Settings,
   General, Software Update).
2. Sign in to any cloud storage you use and let it sync the folders needed straight away.
3. Run the [Quickstart](../README.md#quickstart).

## During the bootstrap

- Click **Install** when Apple's window offers the command line tools.
- Confirm the GitHub sign-in in the browser when the CLI opens it.
- Enter the Mac's password once if a step asks for it.

## After the bootstrap

1. Open a new terminal so the shell profile loads.
2. **Git and SSH:** edit the starting `~/.gitconfig` for your own name and email, then create SSH
   and signing keys on this Mac (or restore them from a secure backup), add them to GitHub and to
   `~/.ssh/config`. Keys are never stored in any repository.
3. **VS Code:** sign in to Settings Sync if used, then run
   `./bootstrap/bootstrap.sh --extras-only --with vscode-extensions`.
4. **Linux:** `./bootstrap/bootstrap.sh --extras-only --with linux` creates the OrbStack Ubuntu
   machine and sets it up. Then run `gh auth login` inside it.
5. **System Settings the bootstrap cannot set:** displays, notifications, login items, privacy
   permissions (Full Disk Access, Screen Recording, Accessibility for Raycast and Rectangle) and
   anything listed at the end of the bootstrap run.
6. **Apps that need a sign-in:** office suites, JetBrains Toolbox, chat and music apps and the
   like.

## Keeping a Mac in line

| When | Run |
| --- | --- |
| After installing a new app with Homebrew | `bdump` to add it to the Brewfile in your dotfiles fork |
| After changing a tracked setting on purpose | `./bootstrap/bootstrap.sh --capture-settings`, then commit it in your system-defaults fork |
| Every so often | `./bootstrap/bootstrap.sh` to catch anything that drifted |

# dotfiles

One repo for both machines. `install.sh` checks the system and hands off:

- **Codespaces (Linux)** → `codespaces/install.sh`. GitHub runs it automatically when a codespace is created.
- **Mac** → `mac/install.sh`. Run by hand.

Both scripts are safe to rerun.

## New Mac

1. On github.com, download this repo as ZIP (Code → Download ZIP) and unzip it.
2. In the built-in Terminal app:

   ```sh
   bash ~/Downloads/dotfiles-main/install.sh
   ```

   It installs Homebrew, everything in `mac/Brewfile`, copies the configs and signs in to gh. The few steps left to do by hand are printed at the end.
3. Delete the downloaded folder. The configs are copies, so the Mac doesn't need it.

## Working in a codespace: `dev`

In Ghostty on the Mac, run `dev` (or `dev <part of the name or repo>`). It asks which codespace when there are several, and attaches to that codespace's tmux session, building it first if needed:

```
┌─────────────────────────────┬──────────────────────┐
│                             │ Codespace            │
│  Claude Code agent view     │                      │
│  in the codespace's repo    ├──────────────────────┤
│                             │ Mac shell            │
└─────────────────────────────┴──────────────────────┘
```

- **Claude Code** runs as background sessions in the codespace (agent view, `claude agents`), so they keep working when the connection drops. The pane just shows them again.
- **The Codespace shell** runs in tmux in the codespace so it survives disconnects. That tmux has no status bar and uses **Ctrl-q** as prefix; **Ctrl-b** is the Mac tmux.
- Both Codespace panes share one SSH connection. `dev` refreshes the SSH config from `gh codespace ssh --config` (in `~/.ssh/config.d/codespaces/`) when it builds a layout, and starts a stopped codespace.
- Running `dev` again reconnects whatever needs it before attaching: panes whose connection dropped, and both Codespace panes if the codespace was stopped (it gets started, with progress shown). So in the morning: open Ghostty, run `dev`.
- A dropped pane also says so itself: press **Enter** to reconnect. **Ctrl-b R** restarts the current pane. A hung connection is detected within ~45 s, or end it at once with Enter, `~`, `.`.
- Closing the Ghostty window doesn't drop the panes; the tmux session keeps running, and `dev` attaches to it again.
- Mouse: click to switch panes, drag borders to resize, wheel to scroll. Copying in any pane (also remote) lands on the Mac clipboard.
- First time in a new codespace: Claude Code asks to log in (`/login`) and to trust the repo folder.

### Undoing it

`uninstall.sh` removes the `dev` setup again, on the Mac or in a codespace (`bash ~/Downloads/dotfiles-main/uninstall.sh` on the Mac): `dev`'s tmux sessions and SSH connections, its files, the lines it added to `~/.zshrc` and `~/.ssh/config`, and tmux with the dependencies nothing else needs. Everything else from `install.sh` stays. Files you changed are kept as `*.backup-<date-time>`, and tmux stays installed while other tmux sessions run. Safe to rerun.

## Changing the Mac config later

Edit the file in `mac/` here (on github.com or in a codespace), then download the ZIP again and rerun the script. Changed files on the Mac are backed up before being replaced.

## Changing the Codespaces setup

Edit `codespaces/install.sh`. To test in a running codespace:

```sh
cd /workspaces/.codespaces/.persistedshare/dotfiles && git pull && ./install.sh
```

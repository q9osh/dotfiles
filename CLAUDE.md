# CLAUDE.md

Dotfiles for one Mac and GitHub Codespaces. README.md explains how to use them;
this file holds what isn't obvious from the code: conventions, facts that were
verified by testing, and how to test.

## Layout
- `install.sh` checks `uname` and hands off to `mac/install.sh` or
  `codespaces/install.sh`. `uninstall-dev.sh` does the same for the
  `*/uninstall-dev.sh` scripts, which remove only the `dev` setup.
- Mac: run by hand from a downloaded ZIP of `main`; the folder is deleted
  afterwards, so the Mac only has copies. Uninstalling needs a fresh ZIP.
- Codespaces: GitHub clones the default branch (`main`) to
  `/workspaces/.codespaces/.persistedshare/dotfiles` and runs `install.sh`
  when a codespace is created. Existing codespaces don't update by themselves:
  `git pull && ./install.sh` in that folder.
- The `dev` setup: `mac/bin/dev` (with `mac/tmux.conf`, `mac/ssh/codespaces.conf`)
  on the Mac, `codespaces/dev-remote` and `codespaces/tmux.conf` in codespaces.

## Conventions
- Install scripts stay safe to rerun: append lines only behind a `grep -qxF`
  check; on the Mac `install_file` backs up a changed file as
  `*.backup-<date-time>` before replacing it. Uninstall deletes only files
  identical to the repo's copy and backs up the rest.
- Codespace steps that can fail (network) must not stop the rest: `|| log "⚠️ ..."`.
- Mac scripts run under macOS bash 3.2 and BSD tools: no `mapfile`, associative
  arrays, `${x,,}`; no `sed -i`; use awk with a temp file.
- Ghostty must not start `dev` automatically (user's decision).
- Comments say why; log lines follow the existing emoji style.

## Verified facts (don't regress these)
- **Shift+Enter:** Claude Code turns on extended keys only when it knows it's
  inside tmux (`TMUX` or `TERM_PROGRAM=tmux`). ssh passes neither, and the
  codespace's sshd accepts only `LANG`/`LC_*` (`SetEnv`), so `dev` puts
  `TERM_PROGRAM` on the ssh command line.
- **`gh codespace ssh --config`:** without `-c` it skips codespaces that aren't
  Available and exits non-zero; with `-c <name>` it starts the codespace. Its
  host names contain the branch, so `dev` rewrites them to `cs.<name>`. It sets
  `ControlMaster` but no `ControlPath`. ssh refuses included config files that
  are group-writable (write them with mode 600).
- **The shared connection:** gh's `--stdio` tunnel doesn't exit when its input
  closes; ssh ends it with SIGHUP when the connection closes. So the
  ControlMaster is opened through `tmux run-shell` (the tmux server runs
  detached): opened from a terminal or pane, closing that kills the tunnel for
  all panes; with `nohup`, tunnels pile up after every closed connection.
- **Pane state:** the pane wrapper exits on HUP/TERM without marking
  `@dev_state waiting`, else a restarted pane's old wrapper overwrites the new one's state.
- **Claude login in codespaces:** Codespaces secrets (`CLAUDE_CODE_OAUTH_TOKEN`)
  are exported only for SSH *login* shells, by `/etc/profile.d/codespaces.sh`;
  commands over ssh run in a non-login shell, so `dev-remote` sources that script.
- **Claude's background supervisor** keeps the credentials it started with. If it
  started without the token: `claude daemon stop --any --keep-workers`, start
  `claude agents` again within a minute, then `claude respawn <id>` per session.
  Background sessions survive an SSH drop and stop when the codespace stops
  (conversations are kept).
- macOS 14+ ships the `tmux-256color` terminfo that `mac/tmux.conf` uses.
- **Open question:** GitHub counts terminal input/output as activity for the idle
  timeout; unknown whether a connected `dev` layout keeps a codespace running.

## Testing
- Codespace side: test for real in the codespace. Run `install.sh` twice and
  check the second run changes nothing; check that `uninstall-dev.sh` then
  `install.sh` restores everything.
- Mac side can't run here; simulate it in the codespace:
  - "Mac" tmux on its own socket (`TMUX_TMPDIR` with a short path) using
    `mac/tmux.conf`, inside an outer tmux standing in for Ghostty (`set-clipboard on`
    captures OSC 52, `send-keys -H` sends raw key bytes).
  - Real connection to the codespace itself through gh, with the Mac's SSH
    files installed temporarily in `~/.ssh`.
  - For `mac/(un)install`: a fake `HOME` and stub `uname`/`brew` in `PATH`.
  - Clean up afterwards: the `~/.ssh` files and the key gh adds to `authorized_keys`.
- Never stop the codespace you're running in, and don't touch the user's live
  tmux `shell` session or Claude supervisor without asking.
- `shellcheck -s bash`; SC2016 notes on strings meant literally are expected.
- Say plainly which Mac parts couldn't be tested.

## Workflow
- Work on a branch, show the diff before committing, open a pull request; the
  user merges on GitHub.
- Tag `before-dev-tmux-layout` marks `main` before the `dev` setup.

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

## Changing the Mac config later

Edit the file in `mac/` here (on github.com or in a codespace), then download the ZIP again and rerun the script. Changed files on the Mac are backed up before being replaced.

## Changing the Codespaces setup

Edit `codespaces/install.sh`. To test in a running codespace:

```sh
cd /workspaces/.codespaces/.persistedshare/dotfiles && git pull && ./install.sh
```

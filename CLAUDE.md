# Dotfiles

Personal dotfiles repo that lives at `~/.dotfiles` (i.e. `/Users/<username>/.dotfiles`).

## How installation works

Run `rake install` from the repo root. This:

1. **Symlinks dotfiles into `$HOME`** -- every top-level file not in the `DOTFILE_SKIPLIST` (see `Rakefile`) gets linked as `~/.dotfiles/<file>` -> `~/<dot><file>`. For example `zshrc` becomes `~/.zshrc`. The interactive prompt asks before overwriting existing files (answer `a` to replace all, `y`/`n` per file).
2. **Installs git hooks** from `hooks/` into `.git/hooks/` (currently a `pre-commit` that auto-exports Velja prefs).
3. **Initializes git submodules** (powerlevel10k, fzf-tab, git-when-merged, FiraCode, etc. -- see `.gitmodules`).
4. **On macOS**, runs `mac/setup.sh`, symlinks `~/.config` → `config/` (XDG), sets up Velja, and configures ZSH with oh-my-zsh + powerlevel10k.
5. **Sets up asdf language versions** from `tool-versions` (ruby, python, golang, nodejs).

### XDG Base Directory

The repo follows the XDG Base Directory Specification. The `config/` directory in the repo is symlinked as `~/.config`. It uses an ignore-all `.gitignore` with explicit opt-in for tracked configs — apps that write to `~/.config/` are silently ignored by git unless explicitly added.

XDG-native configs tracked in the repo:
- `config/git/config` and `config/git/ignore` — Git reads these automatically from `~/.config/git/`
- `config/starship.toml` — Starship reads from `~/.config/starship.toml` by default
- `config/ghostty/` — Ghostty reads from `~/.config/ghostty/`
- `config/karabiner/` — Karabiner reads from `~/.config/karabiner/`

### Homebrew packages

`Brewfile` is the manifest for `brew bundle`. It is in the skiplist so it is not symlinked. Run `brew bundle --file=~/.dotfiles/Brewfile` to install everything. The `brewdump` shell function (in `functions_osx.sh`) exports current brew state to `Brewfile_new` for comparison.

## Repo structure

```
~/.dotfiles/
  Rakefile            # Main installer -- `rake install`
  Brewfile            # Homebrew bundle manifest
  tool-versions       # asdf language versions

  # Shell configs (symlinked as dotfiles into ~/)
  zshrc               # Main ZSH config -> ~/.zshrc
  bashrc              # Bash completions and env -> ~/.bashrc
  bash_profile        # Bash login shell -> ~/.bash_profile
  ackrc, agignore, ctags, gemrc, irbrc, asdfrc, ...

  # Function libraries (sourced directly from repo by zshrc/bash_profile)
  functions_shell.sh  # Navigation, file finding, extraction, aliases
  functions_dev.sh    # Git aliases/helpers, dev tooling, compiler config
  functions_osx.sh    # Brew helpers, macOS utilities, spotlight/network
  functions_colors.sh # Color definitions
  functions_colors_shell.zsh
  functions_graphics.sh
  prompt.sh           # Starship prompt init

  # XDG configs (symlinked as ~/.config → this directory)
  config/
    .gitignore        # Ignore-all, opt-in tracked configs
    git/config        # Git config (read from ~/.config/git/config)
    git/ignore        # Global gitignore (read from ~/.config/git/ignore)
    starship.toml     # Starship prompt config
    ghostty/          # Ghostty terminal config
    karabiner/        # Karabiner-Elements config

  # Directories (NOT symlinked -- in DOTFILE_SKIPLIST)
  bin/                # Utility scripts added to PATH
  hooks/              # Git hooks installed into .git/hooks/
  utils/              # Git submodules and standalone utilities
  mac/                # macOS-specific configs and scripts
    velja/            # Velja URL-routing prefs (imported via `defaults`)
    launchctl/        # LaunchAgent plists
    Saved Searches/   # Finder saved searches
  var/                # Miscellaneous templates (PR template, etc.)
  lib/                # Vendored libs (git-completion, osx-shell-battery)
  zsh/                # ZSH plugins and themes (submodules: fzf-tab, powerlevel10k)
```

## How the shell finds this repo

`zshrc` and `bash_profile` set `DOTFILES_REPO="$HOME/.dotfiles"` at the top of shell init. `functions_shell.sh` defaults it with `DOTFILES_REPO="${DOTFILES_REPO:-$HOME/.dotfiles}"`. The `cddot` alias navigates to it. Homebrew prefix is resolved dynamically via `BREW_PREFIX="$(brew --prefix)"`.

## Adding custom local/private configuration

The repo supports a **local override file** that is never committed:

- **`~/.zshrc_local.sh`** -- sourced by `zshrc` if it exists. Put machine-specific PATH additions, secrets, employer-specific aliases, or anything private here.

This file is not tracked by git. Create it manually:

```sh
touch ~/.zshrc_local.sh
```

For **private Velja URL-routing rules** (e.g. containing sensitive internal URLs):

- Create `~/.config/velja/private-rules.json` with an array of rule JSON strings.
- `rake mac:install_configs` merges them into the Velja preferences at import time.
- `rake mac:velja_backup` strips them back out before committing, so private rules never enter the repo.

The `config/.gitignore` excludes sensitive dirs like `gh/` and `velja/` from tracking. The repo `.gitignore` also excludes `ssh_config` and `.profile.local`.

## Key rake tasks

| Task | Description |
|------|-------------|
| `rake install` | Full install: symlink dotfiles, hooks, submodules, mac setup, asdf |
| `rake mac:setup` | macOS-specific setup (setup.sh + configs + ZSH) |
| `rake mac:install_configs` | Symlink ~/.config, set up gh credentials, import Velja prefs |
| `rake mac:velja_backup` | Export Velja prefs back to repo (strips private rules) |
| `rake mac:customize` | Apply macOS system preference tweaks |
| `rake mac:app_handlers` | Set default apps for file types (duti) |
| `rake mac:saved_search_restore` | Restore Finder saved searches |
| `rake utils:asdf` | Install asdf plugins and language versions from `tool-versions` |
| `rake utils:install` | Run utility install scripts from `utils/` |
| `rake hooks:install` | Copy hooks into `.git/hooks/` |

## Conventions

- Top-level files not in the skiplist get symlinked into `$HOME` with a `.` prefix.
- Function files and `prompt.sh` are in the skiplist — they are sourced directly from `$DOTFILES_REPO`, not symlinked.
- XDG-compatible configs live under `config/` (symlinked as `~/.config`). To track a new app's config, add a `!pattern` to `config/.gitignore`.
- Shell function files are organized by domain (`_shell`, `_dev`, `_osx`, `_colors`, `_graphics`).
- macOS app configs that require `defaults import` live under `mac/` and are installed via rake tasks.
- Git submodules are used for vendored tools -- run `git submodule update --init` after cloning.
- The `bin/` directory contains standalone scripts; it is not auto-added to PATH by the installer (add it via `~/.zshrc_local.sh` if desired).
- Use `$HOME` (not `~`) in scripts. Use `$DOTFILES_REPO` and `$BREW_PREFIX` instead of hardcoded paths.

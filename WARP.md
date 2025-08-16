# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that manages shell configuration, development tools, and macOS system settings. The setup is based on Ryan Bates' dotfiles architecture with symlink-based installation and comprehensive development environment automation.

## Core Commands

### Installation & Setup
```bash
# Fresh installation
git clone git://github.com/newalexandria/dotfiles ~/dotfiles
cd ~/dotfiles
rake install

# Install without Git (using curl)
cd $HOME && mkdir -p dotfiles
curl -# -L -k https://github.com/newalexandria/dotfiles/tarball/master | tar xz --strip 1 -C dotfiles
cd dotfiles && rake install
```

### Package Management
```bash
# Install/update Homebrew packages
brew bundle --file=Brewfile

# Install development tool versions via asdf
rake utils:asdf

# macOS-specific setup (only run on macOS)
rake mac:setup
```

### Development Workflow
```bash
# Source shell configuration changes
source ~/.zshrc

# Update git submodules
git submodule update --init --recursive

# Update all repositories in current directory
update_repos  # Custom function from functions_dev.sh
```

## Architecture & Structure

### Configuration Management
- **Symlink-based**: All dotfiles are symlinked from repository to `$HOME/.filename`
- **Modular functions**: Shell functionality split across multiple `functions_*.sh` files
- **Platform-specific**: macOS configurations in `/mac/` directory
- **Version-controlled**: Tools and language versions managed via asdf with `tool-versions`

### Key Components

#### Shell Environment
- **ZSH + Oh-My-Zsh**: Primary shell with Powerlevel10k theme
- **Custom ZSH config**: Located in `zsh/` directory with custom functions and themes
- **Bash compatibility**: Maintains bash configurations for legacy systems

#### Development Tools Stack
- **asdf**: Version manager for Ruby, Python, Go, Node.js
- **Homebrew**: Package management with comprehensive Brewfile (500+ packages)
- **Git tooling**: Enhanced git workflow with custom aliases and functions
- **Docker/Kubernetes**: Full containerization and orchestration stack
- **AWS CLI**: Cloud development tooling with custom helper functions

#### Custom Utilities
- **bin/**: Custom scripts for git operations, AWS, graphics processing
- **Development functions**: Git workflow automation, branch management, repository operations
- **macOS integration**: System preferences, app handlers, keyboard customization

### Git Workflow Integration
The repository implements a sophisticated git workflow with branch management:
- **Environment branches**: `development`, `main`, `staging`, `main-release`
- **Custom git functions**: `gfb()`, `gmr()`, `parent_branch()`, `default_branch()`
- **Pull request helpers**: GitHub CLI integration with `ghpr()`, `ghbo()`

### Language Support
Current tool versions (from `tool-versions`):
- Ruby 3.1.2
- Python 3.11.0  
- Go 1.18

Additional language support configured via asdf plugins and Homebrew packages.

### macOS System Integration
- **Karabiner Elements**: Keyboard customization configs in `mac/karabiner/`
- **System preferences**: Automated via `mac/customize.sh`
- **App handlers**: File association management with duti
- **Launch agents**: Automated background tasks

### VS Code Integration
Extensive VS Code extension configuration (140+ extensions) covering:
- Language support (Ruby, Python, Go, TypeScript, etc.)
- Development tools (Docker, Kubernetes, AWS, Git)
- Code quality (ESLint, Prettier, Rubocop)
- Productivity tools (Copilot, GitLens, etc.)

## Important Notes

### Environment Variables
The repository uses several environment variables for branch management:
- `DEV_BRANCH="development"`
- `PROD_BRANCH="main"`
- `RELEASE_BR="main-release-2nd-pipe"`
- `STAGING_BR="staging"`

### Path Management
Multiple PATH additions are managed across files:
- Custom bin directory: `~/.dotfiles/bin`
- Homebrew tools, language version managers
- Platform-specific tool paths (macOS, Linux compatibility)

### Customization Points
- `~/.zshrc_local.sh`: Local overrides not tracked in git
- Platform detection in Rakefile for macOS vs Linux differences
- Skip lists in Rakefile (`DOTFILE_SKIPLIST`) control what gets symlinked

### Security Considerations
The repository includes configurations for:
- GPG key management (reminder to setup keys post-install)
- SSH completion and known hosts integration
- API token management for GitHub operations

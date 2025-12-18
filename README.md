<p align="center">
  <h1 align="center">wtp.fish</h1>
  <p align="center">
    <strong>Worktree Plus for Fish Shell</strong>
    <br />
    <em>Streamlined Git worktree management with native Fish shell integration</em>
    <br /><br />
    A Fish shell port of <a href="https://github.com/satococoa/wtp"><strong>satococoa/wtp</strong></a>
  </p>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> •
  <a href="#features">Features</a> •
  <a href="#usage">Usage</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#why-wtp">Why wtp?</a>
</p>

`wtp` simplifies Git worktree management by abstracting filesystem paths. It allows users to create, list, and switch between branch-based worktrees without manually managing directory locations.

---

## Quick Start

```fish
# Install via Fisher
fisher install shuntksh/wtp.fish

# Create a worktree
wtp add -b feature/my-feature

# Switch worktrees
wtp cd feature/my-feature
```

## Features

| Command | Description |
|---------|-------------|
| `wtp add` | Create worktrees from existing or new branches |
| `wtp list` / `wtp ls` | List all worktrees with status information |
| `wtp remove` / `wtp rm` | Remove worktrees with optional branch cleanup |
| `wtp cd` | Change directory to worktree root |
| `wtp init` | Initialize `.wtp.yml` configuration |

### Key Features

- **Pure Fish shell** — No external dependencies.
- **Native navigation** — Changes working directory within the current shell session.
- **Fisher compatible** — Install and update via Fisher.
- **Hooks** — Supports post-creation file copying and command execution.
- **Completions** — Tab completion for branches and worktrees.

## Installation

### Fisher

```fish
fisher install shuntksh/wtp.fish
```

### Manual Installation

```fish
# Clone and copy files to your Fish config
cp functions/wtp.fish ~/.config/fish/functions/
cp completions/wtp.fish ~/.config/fish/completions/
cp conf.d/wtp.fish ~/.config/fish/conf.d/
```

## Usage

### Creating Worktrees

```fish
# From an existing branch
wtp add feature/auth

# Create a new branch and worktree
wtp add -b feature/my-feature

# Create new branch from specific commit/tag
wtp add -b hotfix/urgent v1.2.0

# Force create (overwrite existing)
wtp add -f -b feature/retry
```

### Listing Worktrees

```fish
# Show all worktrees with details
wtp list

# Compact output (names only)
wtp ls --quiet
```

Example output:
```
PATH                           BRANCH                    STATUS     HEAD
----                           ------                    ------     ----
@                              main                      managed    a1b2c3d4
feature/auth                   feature/auth              managed    e5f6g7h8*
feature/new-ui                 feature/new-ui            managed    i9j0k1l2
```

### Navigating Between Worktrees

```fish
# Jump to a specific worktree
wtp cd feature/auth

# Return to main worktree
wtp cd @
# or
wtp cd
```

### Removing Worktrees

```fish
# Remove worktree only
wtp remove feature/old

# Remove worktree AND delete the branch
wtp remove --with-branch feature/done

# Force remove dirty worktree and unmerged branch
wtp remove -f --with-branch --force-branch feature/abandoned
```

## Configuration

Initialize a configuration file in your repository:

```fish
wtp init
```

This creates `.wtp.yml` in your repository root:

```yaml
version: "1.0"

defaults:
  # Where worktrees are created (relative to repo root)
  base_dir: ../worktrees

hooks:
  post_create:
    # Copy environment files from main worktree
    - type: copy
      from: .env
      to: .env
    
    # Copy IDE/AI context (often gitignored)
    - type: copy
      from: .cursor/
      to: .cursor/
    
    # Run setup commands in new worktree
    - type: command
      command: npm install
```

### Hook Types

| Type | Description | Options |
|------|-------------|---------|
| `copy` | Copy files from main worktree to new worktree | `from`, `to` |
| `command` | Execute shell command in new worktree | `command` |

## Completions

Tab completion is provided for commands, branches, and worktrees:

```fish
wtp <TAB>           # add, list, remove, cd, init, help, version
wtp add <TAB>       # Available branches (local and remote)
wtp cd <TAB>        # Available worktrees
wtp remove <TAB>    # Removable worktrees (excludes main)
```

## Why wtp?

### The Problem with Git Worktrees

Git worktrees allow multiple branches to be checked out simultaneously. However, the native command requires manual directory path management:

```fish
# Standard git worktree usage
git worktree add ../my-repo-feature-auth feature/auth
cd ../my-repo-feature-auth
```

Users must manually define destination paths and remember their locations to switch contexts.

### The wtp Solution

`wtp` manages worktree paths automatically, allowing interaction by branch name rather than filesystem path:

```fish
# wtp usage
wtp add feature/auth
wtp cd feature/auth
```

This abstracts the underlying directory structure and simplifies navigation between worktrees.

## Requirements

- **Fish shell** 3.0+
- **Git** 2.17+
- Standard POSIX utilities (`sed`, `grep`, `realpath`)

## Testing

Tests are written using [fishtape](https://github.com/jorgebucaran/fishtape):

```fish
# Install fishtape
fisher install jorgebucaran/fishtape

# Run tests
fishtape tests/*
```

## Credits

This project is a Fish shell port of **[wtp](https://github.com/satococoa/wtp)** created by **[@satococoa](https://github.com/satococoa)**.

This port enables native directory switching (`wtp cd`) without external shell hooks and offers a shell-native alternative to the original Go implementation.

### Implementation Differences

| Aspect | Go Binary | Fish Implementation |
|--------|-----------|---------------------|
| `wtp cd` | Requires shell hook | Works natively |
| Installation | Build from source | Single Fisher command |
| Dependencies | Go runtime (build) | None |
| YAML parsing | Full support | Basic support |

## License

[MIT](LICENSE) © 2025 Shun Takahashi

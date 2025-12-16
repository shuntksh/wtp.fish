# wtp (Worktree Plus) - Fish Shell Implementation

A pure fish shell implementation of the wtp worktree management tool. Porting the original amazing [Go implementation](https://github.com/satococoa/wtp) to fish shell.

## Installation

### Using Fisher (Recommended)

```fish
fisher install shuntksh/wtp.fish
```

### Manual Installation

Copy the files to your fish configuration:

```fish
cp functions/wtp.fish ~/.config/fish/functions/
cp completions/wtp.fish ~/.config/fish/completions/
cp conf.d/wtp.fish ~/.config/fish/conf.d/
```

## Features

This fish implementation provides all core wtp functionality:

- **`wtp add`** - Create worktrees from existing or new branches
- **`wtp list`** (or `wtp ls`) - List all worktrees with status
- **`wtp remove`** (or `wtp rm`) - Remove worktrees with optional branch deletion
- **`wtp cd`** - Navigate between worktrees (directly changes directory in fish!)
- **`wtp init`** - Initialize `.wtp.yml` configuration

### Key Advantages Over Go Binary

1. **Native `wtp cd`** - Unlike the Go binary which requires shell hooks, fish's `wtp cd` directly changes your directory
2. **No compilation needed** - Pure fish script, works immediately
3. **Tab completion** - Full completion support for worktrees, branches, and flags

## Usage

```fish
# Create worktree from existing branch
wtp add feature/auth

# Create worktree with new branch
wtp add -b feature/new-feature

# Create new branch from specific commit
wtp add -b hotfix/urgent main

# List all worktrees
wtp list
wtp ls --quiet  # Only names

# Navigate to worktree
wtp cd feature/auth
wtp cd  # Go to main worktree
wtp cd @  # Also goes to main worktree

# Remove worktree
wtp remove feature/old
wtp remove --with-branch feature/done  # Also delete branch
wtp remove -f --with-branch --force-branch feature/dirty  # Force everything

# Initialize configuration
wtp init
```

## Configuration

The fish implementation reads the same `.wtp.yml` configuration file as the Go version:

```yaml
version: "1.0"

defaults:
  base_dir: ../worktrees  # Worktree location relative to repo root

hooks:
  post_create:
    # Copy files from main worktree
    - type: copy
      from: .env
      to: .env
    
    # Run commands in new worktree
    - type: command
      command: npm install
```

## Differences from Go Version

| Feature | Go Binary | Fish Implementation |
|---------|-----------|---------------------|
| `wtp cd` | Requires shell hook | Works directly |
| Compilation | Required | Not needed |
| Performance | Faster for complex operations | Slight overhead for git calls |
| YAML parsing | Full support | Basic support |
| Error messages | Rich formatting | Simpler formatting |

## Requirements

- Fish shell 3.0+
- Git 2.17+
- Standard POSIX utilities (sed, grep, realpath)

## Completion

Tab completion works out of the box:

```fish
wtp <TAB>           # Shows: add, list, remove, cd, init, help, version
wtp add <TAB>       # Shows available branches
wtp cd <TAB>        # Shows available worktrees
wtp remove <TAB>    # Shows removable worktrees (excludes main)
```

## Testing

The project is tested using [fishtape](https://github.com/jorgebucaran/fishtape). Run the tests with:

```fish
fishtape tests/*
```

To install fishtape, run:

```fish
fisher install jorgebucaran/fishtape
```

## License

[MIT](/LICENSE) - Same as the main wtp project

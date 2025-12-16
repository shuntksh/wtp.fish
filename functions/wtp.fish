# wtp - Worktree Plus for Fish Shell
# A powerful Git worktree management tool
# Fisher compatible: https://github.com/jorgebucaran/fisher

# Main wtp function
function wtp --description "Enhanced Git worktree management"
    if test (count $argv) -eq 0
        __wtp_help
        return 0
    end

    set -l cmd $argv[1]
    set -l args $argv[2..-1]

    switch $cmd
        case add
            __wtp_add $args
        case list ls
            __wtp_list $args
        case remove rm
            __wtp_remove $args
        case cd
            __wtp_cd $args
        case init
            __wtp_init
        case help -h --help
            __wtp_help
        case version -v --version
            __wtp_version
        case '*'
            echo "Error: Unknown command '$cmd'" >&2
            echo "Run 'wtp help' for usage." >&2
            return 1
    end
end

# Print help message
function __wtp_help
    echo "wtp (Worktree Plus) - Enhanced Git worktree management"
    echo ""
    echo "Usage: wtp <command> [options] [arguments]"
    echo ""
    echo "Commands:"
    echo "  add <branch>          Create worktree from existing branch"
    echo "  add -b <new-branch>   Create worktree with new branch"
    echo "  list, ls              List all worktrees"
    echo "  remove, rm <name>     Remove a worktree"
    echo "  cd [name]             Change to worktree directory (@ for main)"
    echo "  init                  Initialize .wtp.yml configuration"
    echo "  help                  Show this help message"
    echo "  version               Show version information"
    echo ""
    echo "Examples:"
    echo "  wtp add feature/auth             # Create worktree from branch"
    echo "  wtp add -b feature/new           # Create new branch and worktree"
    echo "  wtp list                         # Show all worktrees"
    echo "  wtp cd feature/auth              # Navigate to worktree"
    echo "  wtp cd                           # Navigate to main worktree"
    echo "  wtp remove feature/old           # Remove a worktree"
    echo "  wtp remove --with-branch feature # Also delete the branch"
end

# Print version
function __wtp_version
    echo "wtp (fish) 0.0.2"
end

# Resolve worktree path from branch name
function __wtp_resolve_worktree_path --argument-names branch_name
    set -l main_path (__wtp_get_main_worktree_path)
    set -l base_dir (__wtp_load_config)

    # Make base_dir absolute if relative
    if not string match -q "/*" $base_dir
        set base_dir "$main_path/$base_dir"
    end

    # Clean up the path
    echo (realpath -m "$base_dir/$branch_name" 2>/dev/null; or echo "$base_dir/$branch_name")
end

# wtp add command
function __wtp_add
    set -l branch ""
    set -l new_branch ""
    set -l commitish ""
    set -l force false

    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        switch $arg
            case -b --branch
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set new_branch $argv[$i]
                else
                    echo "Error: -b requires a branch name" >&2
                    return 1
                end
            case -f --force
                set force true
            case '-*'
                echo "Error: Unknown option '$arg'" >&2
                return 1
            case '*'
                if test -z "$branch"
                    set branch $arg
                else if test -z "$commitish"
                    set commitish $arg
                end
        end
        set i (math $i + 1)
    end

    # Validate input
    if test -z "$branch" -a -z "$new_branch"
        echo "Error: Branch name required" >&2
        echo "Usage: wtp add <existing-branch> | wtp add -b <new-branch> [commit]" >&2
        return 1
    end

    # Determine actual branch name for path
    set -l path_branch $branch
    if test -n "$new_branch"
        set path_branch $new_branch
    end

    # Resolve worktree path
    set -l wt_path (__wtp_resolve_worktree_path $path_branch)

    # Build git command
    set -l git_args "worktree" "add"
    if test "$force" = "true"
        set git_args $git_args "--force"
    end
    if test -n "$new_branch"
        set git_args $git_args "-b" $new_branch
    end
    set git_args $git_args $wt_path

    # Add commitish or branch
    if test -n "$new_branch"
        if test -n "$commitish"
            set git_args $git_args $commitish
        else if test -n "$branch"
            set git_args $git_args $branch
        end
    else if test -n "$branch"
        # Check if branch exists locally, if not check remote
        set -l resolved (__wtp_resolve_branch $branch)
        if test $status -ne 0
            echo "Error: Branch '$branch' not found in local or remote branches" >&2
            return 1
        end
        set git_args $git_args $resolved
    end

    # Execute git worktree add
    if not git $git_args
        return 1
    end

    # Execute post-create hooks
    __wtp_run_hooks $wt_path

    # Success message
    echo ""
    echo "✅ Worktree created successfully!"
    echo ""
    echo "📁 Location: $wt_path"
    echo "🌿 Branch: $path_branch"
    echo ""
    echo "💡 To switch to the new worktree, run:"
    echo "   wtp cd $path_branch"
end

# Resolve branch (check local then remote)
function __wtp_resolve_branch --argument-names branch
    # Check if exists locally
    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null
        echo $branch
        return 0
    end

    # Check remotes
    set -l remote_branches (git for-each-ref --format='%(refname:short)' "refs/remotes/*/$branch" 2>/dev/null)
    set -l count (count $remote_branches)

    if test $count -eq 0
        return 1
    else if test $count -eq 1
        echo $remote_branches[1]
        return 0
    else
        # Multiple remotes have this branch
        set -l remotes
        for rb in $remote_branches
            set -l parts (string split "/" $rb)
            set remotes $remotes $parts[1]
        end
        echo "Error: Branch '$branch' exists in multiple remotes: "(string join ", " $remotes) >&2
        echo "Please specify the remote explicitly (e.g., wtp add -b $branch origin/$branch)" >&2
        return 1
    end
end

# Run post-create hooks
function __wtp_run_hooks --argument-names wt_path
    set -l main_path (__wtp_get_main_worktree_path)
    set -l config_file "$main_path/.wtp.yml"

    if not test -f "$config_file"
        return 0
    end

    # Simple YAML parsing for hooks
    # This is a basic implementation - complex YAML needs proper parsing
    set -l in_post_create false
    set -l current_type ""
    set -l current_from ""
    set -l current_to ""
    set -l current_command ""

    echo ""
    echo "Executing post-create hooks..."

    while read -l line
        # Skip empty lines and comments
        if test -z "$line"; or string match -q -- "#*" (string trim -- "$line")
            continue
        end

        # Check for post_create section
        if string match -q -- "*post_create:*" "$line"
            set in_post_create true
            continue
        end

        if test "$in_post_create" = "true"
            # Check if we've left hooks section
            if string match -q -r -- "^[a-z]" "$line"
                set in_post_create false
                continue
            end

            # Parse hook entries
            if string match -q -- "*- type:*" "$line"
                # Process previous hook if exists
                __wtp_execute_hook "$current_type" "$current_from" "$current_to" "$current_command" "$main_path" "$wt_path"
                
                set current_type (string replace -r -- ".*type:\s*" "" "$line" | string trim | string replace -a '"' '' | string replace -a "'" '')
                set current_from ""
                set current_to ""
                set current_command ""
            else if string match -q -- "*from:*" "$line"
                set current_from (string replace -r -- ".*from:\s*" "" "$line" | string trim | string replace -a '"' '' | string replace -a "'" '')
            else if string match -q -- "*to:*" "$line"
                set current_to (string replace -r -- ".*to:\s*" "" "$line" | string trim | string replace -a '"' '' | string replace -a "'" '')
            else if string match -q -- "*command:*" "$line"
                set current_command (string replace -r -- ".*command:\s*" "" "$line" | string trim | string replace -a '"' '' | string replace -a "'" '')
            end
        end
    end < "$config_file"

    # Execute last hook
    __wtp_execute_hook "$current_type" "$current_from" "$current_to" "$current_command" "$main_path" "$wt_path"

    echo "✓ All hooks executed successfully"
end

# Execute a single hook
function __wtp_execute_hook --argument-names type from to cmd main_path wt_path
    if test -z "$type"
        return
    end

    switch $type
        case copy
            if test -n "$from" -a -n "$to"
                set -l src "$main_path/$from"
                set -l dst "$wt_path/$to"
                if test -e "$src"
                    echo "  → Copying $from to $to"
                    if test -d "$src"
                        cp -r "$src" "$dst"
                    else
                        mkdir -p (dirname "$dst")
                        cp "$src" "$dst"
                    end
                else
                    echo "  ⚠ Warning: Source '$from' not found, skipping copy" >&2
                end
            end
        case command
            if test -n "$cmd"
                echo "  → Running: $cmd"
                pushd "$wt_path" >/dev/null
                eval $cmd
                popd >/dev/null
            end
    end
end

# wtp list command
function __wtp_list
    set -l quiet false
    set -l compact false

    # Parse arguments
    for arg in $argv
        switch $arg
            case -q --quiet
                set quiet true
            case -c --compact
                set compact true
        end
    end

    # Check if in git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git repository" >&2
        return 1
    end

    set -l worktrees (__wtp_parse_worktrees)
    if test (count $worktrees) -eq 0
        if test "$quiet" != "true"
            echo "No worktrees found"
        end
        return 0
    end

    set -l cwd (pwd)
    set -l main_path (__wtp_get_main_worktree_path)

    if test "$quiet" = "true"
        # Only output worktree names
        for wt in $worktrees
            set -l parts (string split "|" $wt)
            set -l wt_path $parts[1]
            set -l is_main $parts[4]
            set -l name (__wtp_get_worktree_name "$wt_path" "$is_main")
            echo $name
        end
    else
        # Table format
        printf "%-30s %-25s %-10s %s\n" "PATH" "BRANCH" "STATUS" "HEAD"
        printf "%-30s %-25s %-10s %s\n" "----" "------" "------" "----"

        for wt in $worktrees
            set -l parts (string split "|" $wt)
            set -l wt_path $parts[1]
            set -l branch $parts[2]
            set -l head $parts[3]
            set -l is_main $parts[4]

            set -l name (__wtp_get_worktree_name "$wt_path" "$is_main")

            # Add current marker
            if test "$wt_path" = "$cwd"
                set name "$name*"
            end

            # Status
            set -l wt_status "unmanaged"
            if __wtp_is_managed "$wt_path" "$is_main"
                set wt_status "managed"
            end

            # Format branch display
            if test -z "$branch"
                set branch "(no branch)"
            else if test "$branch" = "detached"
                set branch "(detached HEAD)"
            end

            # Truncate head
            set head (string sub -l 8 $head)

            printf "%-30s %-25s %-10s %s\n" $name $branch $wt_status $head
        end
    end
end

# wtp remove command
function __wtp_remove
    set -l wt_name ""
    set -l force false
    set -l with_branch false
    set -l force_branch false

    # Parse arguments
    for arg in $argv
        switch $arg
            case -f --force
                set force true
            case --with-branch
                set with_branch true
            case --force-branch
                set force_branch true
            case '-*'
                echo "Error: Unknown option '$arg'" >&2
                return 1
            case '*'
                if test -z "$wt_name"
                    set wt_name $arg
                end
        end
    end

    if test -z "$wt_name"
        echo "Error: Worktree name required" >&2
        echo "Usage: wtp remove <worktree-name>" >&2
        return 1
    end

    if test "$force_branch" = "true" -a "$with_branch" != "true"
        echo "Error: --force-branch requires --with-branch" >&2
        return 1
    end

    # Check if in git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git repository" >&2
        return 1
    end

    # Find target worktree
    set -l worktrees (__wtp_parse_worktrees)
    set -l target_path ""
    set -l target_branch ""

    for wt in $worktrees
        set -l parts (string split "|" $wt)
        set -l wt_path $parts[1]
        set -l branch $parts[2]
        set -l is_main $parts[4]

        # Skip main worktree
        if test "$is_main" = "true"
            continue
        end

        # Skip unmanaged
        if not __wtp_is_managed "$wt_path" "$is_main"
            continue
        end

        set -l name (__wtp_get_worktree_name "$wt_path" "$is_main")

        # Match by various methods
        if test "$name" = "$wt_name"; or test "$branch" = "$wt_name"; or test (basename "$wt_path") = "$wt_name"
            set target_path $wt_path
            set target_branch $branch
            break
        end
    end

    if test -z "$target_path"
        echo "Error: Worktree '$wt_name' not found" >&2
        return 1
    end

    # Check if we're inside the worktree
    set -l cwd (pwd)
    if test "$cwd" = "$target_path"; or string match -q "$target_path/*" "$cwd"
        echo "Error: Cannot remove worktree you are currently in" >&2
        echo "Please change to a different directory first." >&2
        return 1
    end

    # Remove worktree
    set -l git_args "worktree" "remove"
    if test "$force" = "true"
        set git_args $git_args "--force"
    end
    set git_args $git_args $target_path

    if not git $git_args
        return 1
    end

    echo "Removed worktree '$wt_name' at $target_path"

    # Remove branch if requested
    if test "$with_branch" = "true" -a -n "$target_branch" -a "$target_branch" != "detached"
        set -l branch_args "branch"
        if test "$force_branch" = "true"
            set branch_args $branch_args "-D"
        else
            set branch_args $branch_args "-d"
        end
        set branch_args $branch_args $target_branch

        if git $branch_args 2>/dev/null
            echo "Removed branch '$target_branch'"
        else
            echo "Warning: Could not remove branch '$target_branch'. It may not be fully merged." >&2
            echo "Use --force-branch to force deletion." >&2
        end
    end
end

# wtp cd command
function __wtp_cd
    set -l wt_name "@"  # Default to main worktree

    if test (count $argv) -gt 0
        set wt_name $argv[1]
    end

    # Remove trailing asterisk (from completion)
    set wt_name (string replace -r '\*$' '' $wt_name)

    # Check if in git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git repository" >&2
        return 1
    end

    set -l worktrees (__wtp_parse_worktrees)
    set -l target_path ""

    for wt in $worktrees
        set -l parts (string split "|" $wt)
        set -l wt_path $parts[1]
        set -l branch $parts[2]
        set -l is_main $parts[4]

        set -l name (__wtp_get_worktree_name "$wt_path" "$is_main")

        # Match by various methods
        if test "$name" = "$wt_name"
            set target_path $wt_path
            break
        else if test "$branch" = "$wt_name"
            set target_path $wt_path
            break
        else if test (basename "$wt_path") = "$wt_name"
            set target_path $wt_path
            break
        else if test "$wt_name" = "root" -a "$is_main" = "true"
            set target_path $wt_path
            break
        end
    end

    if test -z "$target_path"
        echo "Error: Worktree '$wt_name' not found" >&2

        # Show available worktrees
        echo "Available worktrees:"
        for wt in $worktrees
            set -l parts (string split "|" $wt)
            set -l wt_path $parts[1]
            set -l is_main $parts[4]
            if __wtp_is_managed "$wt_path" "$is_main"
                echo "  - "(__wtp_get_worktree_name "$wt_path" "$is_main")
            end
        end
        return 1
    end

    # Change to the directory
    cd "$target_path"
end

# wtp init command
function __wtp_init
    # Check if in git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git repository" >&2
        return 1
    end

    set -l repo_path (git rev-parse --show-toplevel 2>/dev/null)
    set -l config_path "$repo_path/.wtp.yml"

    if test -f "$config_path"
        echo "Error: Configuration file already exists: $config_path" >&2
        return 1
    end

    # Create configuration file
    echo '# Worktree Plus Configuration
version: "1.0"

# Default settings for worktrees
defaults:
  # Base directory for worktrees (relative to repository root)
  base_dir: ../worktrees

# Hooks that run after creating a worktree
hooks:
  post_create:
    # Example: Copy gitignored files from MAIN worktree to new worktree
    # Note: '"'"'from'"'"' is relative to main worktree, '"'"'to'"'"' is relative to new worktree
    # - type: copy
    #   from: .env        # Copy actual .env file (gitignored)
    #   to: .env

    # Example: Run a command to show all worktrees
    - type: command
      command: wtp list

    # More examples (commented out):
    
    # Copy AI context files (typically gitignored):
    # - type: copy
    #   from: .claude     # Claude AI context
    #   to: .claude
    # - type: copy
    #   from: .cursor/    # Cursor IDE settings
    #   to: .cursor/
    
    # Run setup commands:
    # - type: command
    #   command: npm install
    # - type: command
    #   command: echo "Created new worktree!"
' > "$config_path"

    echo "Configuration file created: $config_path"
    echo "Edit this file to customize your worktree setup."
end

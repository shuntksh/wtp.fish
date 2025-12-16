# wtp - Worktree Plus fish shell completions
# Fisher compatible: https://github.com/jorgebucaran/fisher

# Disable file completion for wtp
complete -c wtp -f

# Helper function to get worktrees for completion
function __wtp_complete_worktrees
    # Check if in git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        return
    end

    set -l worktrees (__wtp_parse_worktrees)
    set -l cwd (pwd)

    for wt in $worktrees
        set -l parts (string split "|" $wt)
        set -l wt_path $parts[1]
        set -l is_main $parts[4]

        set -l name (__wtp_get_worktree_name "$wt_path" "$is_main")

        if test -n "$name"
            # Add marker if current
            if test "$wt_path" = "$cwd"
                echo "$name*"
            else
                echo $name
            end
        end
    end
end

# Helper function to get removable worktrees (excludes main)
function __wtp_complete_removable_worktrees
    __wtp_complete_worktrees | string match -v '@' | string match -v '@*'
end

# Helper function to get branches for completion
function __wtp_complete_branches
    # Check if in git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        return
    end

    # Get local and remote branches
    set -l seen

    for branch in (git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null)
        if test -z "$branch"
            continue
        end

        # Skip HEAD references
        if test "$branch" = "origin/HEAD" -o "$branch" = "origin"
            continue
        end

        # Remove origin/ prefix for display
        set -l display_name $branch
        if string match -q "origin/*" $branch
            set display_name (string replace "origin/" "" $branch)
        end

        # Skip duplicates
        if contains $display_name $seen
            continue
        end

        set seen $seen $display_name
        echo $display_name
    end
end

# Subcommand completions
complete -c wtp -n "__fish_use_subcommand" -a "add" -d "Create a new worktree"
complete -c wtp -n "__fish_use_subcommand" -a "list" -d "List all worktrees"
complete -c wtp -n "__fish_use_subcommand" -a "ls" -d "List all worktrees (alias)"
complete -c wtp -n "__fish_use_subcommand" -a "remove" -d "Remove a worktree"
complete -c wtp -n "__fish_use_subcommand" -a "rm" -d "Remove a worktree (alias)"
complete -c wtp -n "__fish_use_subcommand" -a "cd" -d "Change to worktree directory"
complete -c wtp -n "__fish_use_subcommand" -a "init" -d "Initialize configuration file"
complete -c wtp -n "__fish_use_subcommand" -a "help" -d "Show help message"
complete -c wtp -n "__fish_use_subcommand" -a "version" -d "Show version information"

# wtp add completions
complete -c wtp -n "__fish_seen_subcommand_from add" -s b -l branch -d "Create new branch"
complete -c wtp -n "__fish_seen_subcommand_from add" -s f -l force -d "Force creation"
complete -c wtp -n "__fish_seen_subcommand_from add" -a "(__wtp_complete_branches)" -d "Branch"

# wtp list completions
complete -c wtp -n "__fish_seen_subcommand_from list ls" -s q -l quiet -d "Only display worktree paths"
complete -c wtp -n "__fish_seen_subcommand_from list ls" -s c -l compact -d "Minimize column widths"

# wtp remove completions
complete -c wtp -n "__fish_seen_subcommand_from remove rm" -s f -l force -d "Force removal even if dirty"
complete -c wtp -n "__fish_seen_subcommand_from remove rm" -l with-branch -d "Also remove the branch"
complete -c wtp -n "__fish_seen_subcommand_from remove rm" -l force-branch -d "Force branch deletion"
complete -c wtp -n "__fish_seen_subcommand_from remove rm" -a "(__wtp_complete_removable_worktrees)" -d "Worktree"

# wtp cd completions
complete -c wtp -n "__fish_seen_subcommand_from cd" -a "(__wtp_complete_worktrees)" -d "Worktree"

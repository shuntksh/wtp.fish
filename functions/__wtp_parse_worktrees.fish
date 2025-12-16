function __wtp_parse_worktrees
    set -l output (git worktree list --porcelain 2>/dev/null)
    if test $status -ne 0
        return 1
    end

    set -l current_path ""
    set -l current_branch ""
    set -l current_head ""
    set -l is_first true

    for line in $output
        if test -z "$line"
            # End of worktree entry
            if test -n "$current_path"
                set -l is_main false
                if test "$is_first" = "true"
                    set is_main true
                    set is_first false
                end
                echo "$current_path|$current_branch|$current_head|$is_main"
            end
            set current_path ""
            set current_branch ""
            set current_head ""
        else if string match -q "worktree *" $line
            set current_path (string replace "worktree " "" $line)
        else if string match -q "HEAD *" $line
            set current_head (string replace "HEAD " "" $line)
        else if string match -q "branch refs/heads/*" $line
            set current_branch (string replace "branch refs/heads/" "" $line)
        else if test "$line" = "detached"
            set current_branch "detached"
        end
    end

    # Handle last entry (if no trailing newline)
    if test -n "$current_path"
        set -l is_main false
        if test "$is_first" = "true"
            set is_main true
        end
        echo "$current_path|$current_branch|$current_head|$is_main"
    end
end

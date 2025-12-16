function __wtp_get_main_worktree_path
    set -l git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
    if test $status -ne 0
        return 1
    end

    # If ends with .git, get parent directory
    if string match -q "*/.git" $git_common_dir; or test "$git_common_dir" = ".git"
        set -l parent (dirname $git_common_dir)
        if test "$parent" = "."
            pwd
        else if string match -q "/*" $parent
            echo $parent
        else
            echo (pwd)/$parent | string replace -r '/[^/]+/\.\.' ''
        end
    else
        echo $git_common_dir
    end
end

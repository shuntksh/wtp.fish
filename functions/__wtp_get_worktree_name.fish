function __wtp_get_worktree_name --argument-names wt_path is_main
    if test "$is_main" = "true"
        echo "@"
        return
    end

    set -l main_path (__wtp_get_main_worktree_path)
    set -l base_dir (__wtp_load_config)

    # Make base_dir absolute
    if not string match -q "/*" $base_dir
        set base_dir "$main_path/$base_dir"
    end
    set base_dir (realpath -m "$base_dir" 2>/dev/null; or echo "$base_dir")

    # Get relative path from base_dir
    set -l abs_wt_path (realpath -m "$wt_path" 2>/dev/null; or echo "$wt_path")

    # Try to compute relative path
    if string match -q "$base_dir/*" "$abs_wt_path"
        string replace "$base_dir/" "" "$abs_wt_path"
    else
        basename "$wt_path"
    end
end

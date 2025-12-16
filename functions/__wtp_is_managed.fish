function __wtp_is_managed --argument-names wt_path is_main
    if test "$is_main" = "true"
        return 0
    end

    set -l main_path (__wtp_get_main_worktree_path)
    set -l base_dir (__wtp_load_config)

    # Make base_dir absolute
    if not string match -q "/*" $base_dir
        set base_dir "$main_path/$base_dir"
    end
    set base_dir (realpath -m "$base_dir" 2>/dev/null; or echo "$base_dir")

    set -l abs_wt_path (realpath -m "$wt_path" 2>/dev/null; or echo "$wt_path")

    # Check if worktree is under base_dir
    if string match -q "$base_dir/*" "$abs_wt_path"
        return 0
    end

    return 1
end

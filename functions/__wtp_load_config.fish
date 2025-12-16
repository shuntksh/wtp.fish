function __wtp_load_config
    set -l main_path (__wtp_get_main_worktree_path)
    if test -z "$main_path"
        return 1
    end

    set -l config_file "$main_path/.wtp.yml"
    set -l default_base_dir "../worktrees"

    if test -f "$config_file"
        # Parse base_dir from YAML (simple parsing)
        set -l base_dir (grep -E "^\s*base_dir:" "$config_file" 2>/dev/null | head -1 | sed 's/.*base_dir:\s*//' | sed 's/[\"'"'"']//g' | string trim)
        if test -n "$base_dir"
            echo $base_dir
            return 0
        end
    end

    echo $default_base_dir
end

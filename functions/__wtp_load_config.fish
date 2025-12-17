function __wtp_load_config
    set -l default_base_dir "../worktrees"

    # Find config file from multiple paths
    set -l config_file (__wtp_find_config)
    if test $status -ne 0; or test -z "$config_file"
        echo $default_base_dir
        return 0
    end

    # Parse base_dir from YAML (simple parsing)
    set -l base_dir (grep -E "^\s*base_dir:" "$config_file" 2>/dev/null | head -1 | sed 's/.*base_dir:\s*//' | sed 's/[\"'"'"']//g' | string trim)
    if test -n "$base_dir"
        echo $base_dir
        return 0
    end

    echo $default_base_dir
end

# Find the config file path, checking multiple locations
# Priority: {GIT_ROOT}/.wtp.yml > {GIT_ROOT}/.config/.wtp.yml
# Returns: The path to the config file if found, empty string otherwise
function __wtp_find_config
    set -l main_path (__wtp_get_main_worktree_path)
    if test -z "$main_path"
        return 1
    end

    # Check primary path first: {GIT_ROOT}/.wtp.yml
    set -l primary_path "$main_path/.wtp.yml"
    if test -f "$primary_path"
        echo "$primary_path"
        return 0
    end

    # Check secondary path: {GIT_ROOT}/.config/.wtp.yml
    set -l secondary_path "$main_path/.config/.wtp.yml"
    if test -f "$secondary_path"
        echo "$secondary_path"
        return 0
    end

    # No config file found
    return 1
end

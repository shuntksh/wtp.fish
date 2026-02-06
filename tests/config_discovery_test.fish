# Tests for config discovery paths
# .wtp.yml (primary) and .config/.wtp.yml (secondary)

# Setup
set fish_function_path $PWD/functions $fish_function_path
source functions/wtp.fish

set -g tmp (mktemp -d)
set -g tmp (realpath $tmp)
cd $tmp

# Git Setup
git init -q
git config user.email "ci@wtp.fish"
git config user.name "CI"
git commit --allow-empty -m "root" -q

# Test 1: Init with --config-dir creates config in .config/
wtp init --config-dir >/dev/null
@test "init --config-dir creates .config directory" -d .config
@test "init --config-dir creates config file" -f .config/.wtp.yml

# Test 2: Config discovery finds .config/.wtp.yml
echo "version: '1.0'
defaults:
  base_dir: alt-worktrees" > .config/.wtp.yml

wtp add -b config-dir-test --no-cd >/dev/null
@test "config discovery uses .config/.wtp.yml" -d alt-worktrees/config-dir-test

# Test 3: Primary path takes precedence over secondary
echo "version: '1.0'
defaults:
  base_dir: primary-wts" > .wtp.yml

wtp add -b priority-test --no-cd >/dev/null
@test "primary config path takes precedence" -d primary-wts/priority-test
@test "secondary path not used when primary exists" ! -d alt-worktrees/priority-test

# Test 4: Init fails when config exists in .config/
rm .wtp.yml
wtp init 2>/dev/null
set init_status $status
@test "init fails when .config/.wtp.yml exists" (test $init_status -ne 0) $status -eq 0

# Test 5: Init fails when config exists at root
rm .config/.wtp.yml
echo "version: '1.0'" > .wtp.yml
wtp init --config-dir 2>/dev/null
set init_status $status
@test "init --config-dir fails when .wtp.yml exists" (test $init_status -ne 0) $status -eq 0

# Cleanup
cd ..
rm -rf $tmp

# Setup
# Ensure we are testing the local functions
set fish_function_path $PWD/functions $fish_function_path
source functions/wtp.fish

set -g tmp (mktemp -d)
# Resolve physical path to match wtp's realpath behavior
set -g tmp (realpath $tmp)
cd $tmp

# Git Setup
git init -q
git config user.email "ci@wtp.fish"
git config user.name "CI"
git commit --allow-empty -m "root" -q

# Test 1: Init
wtp init >/dev/null
@test "wtp init creates config" -f .wtp.yml

# Configuration
echo "version: '1.0'
defaults:
  base_dir: wts" > .wtp.yml

# Test 2: Add
wtp add -b feat-1 >/dev/null
@test "worktree directory created" -d wts/feat-1

# Test 3: CD to worktree
wtp cd feat-1 >/dev/null
@test "changed directory to worktree" (pwd) = "$tmp/wts/feat-1"

# Test 4: CD back to root
wtp cd @ >/dev/null
@test "changed directory back to root" (pwd) = "$tmp"

# Test 5: Custom nested config
echo "version: '1.0'
defaults:
  base_dir: nested/path" > .wtp.yml

wtp add -b feat-nested >/dev/null
@test "nested worktree directory created" -d nested/path/feat-nested

# Test 6: CD to nested
wtp cd feat-nested >/dev/null
@test "changed directory to nested worktree" (pwd) = "$tmp/nested/path/feat-nested"

# Test 7: Hooks
cd $tmp
# Create a dummy file to copy
echo "secret data" > .env.example

# Update config with hooks
echo "version: '1.0'
defaults:
  base_dir: wts
hooks:
  post_create:
    - type: copy
      from: .env.example
      to: .env
    - type: command
      command: touch hooks_ran.txt" > .wtp.yml

wtp add -b hook-feature >/dev/null
@test "copy hook worked" -f wts/hook-feature/.env
@test "command hook worked" -f wts/hook-feature/hooks_ran.txt

# Cleanup
cd ..
rm -rf $tmp
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

# Test 2: Add (should cd by default)
wtp add -b feat-1 >/dev/null
@test "worktree directory created" -d $tmp/wts/feat-1
@test "run wtp add changes directory" (pwd) = "$tmp/wts/feat-1"

# Go back to root
cd $tmp

# Test 2b: Add with --no-cd
wtp add -b feat-no-cd --no-cd >/dev/null
@test "worktree directory created (no-cd)" -d $tmp/wts/feat-no-cd
@test "run wtp add --no-cd stays in root" (pwd) = "$tmp"

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

wtp add -b feat-nested --no-cd >/dev/null
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

wtp add -b hook-feature --no-cd >/dev/null
@test "copy hook worked" -f wts/hook-feature/.env
@test "command hook worked" -f wts/hook-feature/hooks_ran.txt

# Test 8: Remove managed worktree
cd $tmp
wtp rm -f hook-feature >/dev/null 2>&1
@test "managed worktree removed" ! -d wts/hook-feature

# Test 9: Create and remove unmanaged worktree (not in base_dir)
git worktree add -b unmanaged-test unmanaged-wt >/dev/null 2>&1
@test "unmanaged worktree created" -d unmanaged-wt

wtp rm unmanaged-test >/dev/null 2>&1
@test "unmanaged worktree removed" ! -d unmanaged-wt

# Cleanup
cd ..
rm -rf $tmp
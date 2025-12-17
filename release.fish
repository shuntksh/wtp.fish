#!/usr/bin/env fish

# Helper script to release a new version of wtp.fish
# Usage: ./scripts/release.fish <version>

if test (count $argv) -ne 1
    echo "Usage: ./scripts/release.fish <version>"
    echo "Example: ./scripts/release.fish 0.1.0"
    exit 1
end

set -l new_version $argv[1]
set -l file "functions/wtp.fish"

# Verify file exists
if not test -f "$file"
    echo "Error: $file not found!"
    exit 1
end

# Update version using sed
# This is generally safer than reading into variable and echoing back in fish
if test (uname) = "Darwin"
    sed -i '' -E "s/echo \"wtp \(fish\) [0-9.]+\"/echo \"wtp (fish) $new_version\"/" $file
else
    sed -i -E "s/echo \"wtp \(fish\) [0-9.]+\"/echo \"wtp (fish) $new_version\"/" $file
end

echo "Updated $file to version $new_version"

# Git operations
echo "Creating git commit and tag..."
git add $file
git commit -m "chore: release v$new_version"
git tag -f "v$new_version"

echo ""
echo "✅ Release v$new_version prepared!"
echo "Run 'git push && git push --tags' to publish."

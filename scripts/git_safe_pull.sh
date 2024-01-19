if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "$PWD is not a Git repository. Skipping."
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Uncommitted changes found in $PWD. Skipping."
    exit 0
fi

# Fetch the latest changes
git fetch

# Check for potential merge conflicts
if ! git merge-base --is-ancestor HEAD origin/master; then
    echo "Potential merge conflicts detected in $PWD. Skipping."
    exit 0
fi

# Perform the pull
git pull
echo "Git pull executed successfully in $PWD."

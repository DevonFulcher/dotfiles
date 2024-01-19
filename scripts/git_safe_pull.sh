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

if git rev-parse --verify main >/dev/null 2>&1; then
    # If 'main' exists, checkout to 'main'
    default_branch="main"
elif git rev-parse --verify master >/dev/null 2>&1; then
    # If 'master' exists but 'main' does not, checkout to 'master'
    default_branch="master"
else
    echo "Neither 'main' nor 'master' branch exists."
    exit 1
fi

# Check for potential merge conflicts
if ! git merge-base --is-ancestor HEAD origin/$default_branch; then
    echo "Potential merge conflicts detected in $PWD. Skipping."
    exit 0
fi

# Perform the pull
git pull
echo "Git pull executed successfully in $PWD."

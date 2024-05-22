# Function to check for potential merge conflicts
check_for_conflicts() {
    local base_branch=$1
    local current_branch=$2

    # Check for potential merge conflicts
    if ! git merge-tree `git merge-base $base_branch $current_branch` $base_branch $current_branch | grep '<<<<<<<'; then
        return 0  # No conflicts
    else
        return 1  # Conflicts exist
    fi
}

# Get the name of the current branch
current_branch=$(git branch --show-current)

# Define the base branch (main or master)
base_branch="main"
if ! git show-ref --verify --quiet refs/heads/$base_branch; then
    base_branch="master"
    if ! git show-ref --verify --quiet refs/heads/$base_branch; then
        echo "Neither main nor master branches found."
        exit 1
    fi
fi

# Check if the current branch is main or master
if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
    echo "Current branch is $current_branch. No action needed."
    exit 0
fi

# Fetch the latest changes
git fetch

# Check for potential merge conflicts
if check_for_conflicts $base_branch $current_branch; then
    # Perform the merge
    git merge $base_branch --no-edit
    echo "Merged $base_branch into $current_branch successfully."

    # Push the changes to the remote
    git push origin $current_branch
    echo "Pushed changes to remote."
else
    echo "Potential merge conflicts detected. Aborting merge."
    exit 1
fi

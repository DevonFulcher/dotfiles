if [ ! -d "$GIT_PROJECTS_WORKDIR" ]; then
    echo "Directory $GIT_PROJECTS_WORKDIR does not exist."
    exit 1
fi

# Function to check and pull each repository
check_and_pull() {
    local repo_dir=$1
    cd "$repo_dir"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "Uncommitted changes found in $repo_dir. Skipping."
        return
    fi

    # Fetch the latest changes
    git fetch

    # Check for potential merge conflicts
    if ! git merge-base --is-ancestor HEAD origin/master; then
        echo "Potential merge conflicts detected in $repo_dir. Skipping."
        return
    fi

    # Perform the pull
    git pull
    echo "Git pull executed successfully in $repo_dir."
}

# Iterate over each subdirectory in GIT_PROJECTS_WORKDIR
for dir in "$GIT_PROJECTS_WORKDIR"/*/; do
    if [ -d "$dir" ]; then
        echo "Checking repository: $dir"
        check_and_pull "$dir"
    fi
done

REPO_DIR="${GIT_PROJECTS_WORKDIR}"

if [ -z "$REPO_DIR" ]; then
    echo "The GIT_PROJECTS_WORKDIR environment variable is not set. Exiting..."
    exit 1
fi

for dir in "$REPO_DIR"/*; do
    if [ -d "$dir" ]; then
        cd "$dir"
        # Check if directory is a git repository
        if git rev-parse --git-dir > /dev/null 2>&1; then
            # Get the current branch and a short summary of the status, remove hashes
            status=$(git status -sb 2>/dev/null | sed 's/^## //g' | head -n 1)
            if [ -z "$status" ]; then
                echo "$(basename "$dir") - clean"
            else
                echo "$(basename "$dir") - $status"
            fi
        else
            echo "$(basename "$dir") - not a git repository"
        fi
    fi
done

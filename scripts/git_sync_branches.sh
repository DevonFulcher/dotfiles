if [ -z "$GIT_PROJECTS_WORKDIR" ]; then
    echo "GIT_PROJECTS_WORKDIR is not set. Exiting."
    exit 1
fi

for repo_dir in "$GIT_PROJECTS_WORKDIR"/*; do
    if [ -d "$repo_dir" ]; then
        echo "Processing repository: $repo_dir"
        cd "$repo_dir"

        # Check if directory is a git repository
        if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            # Fetch and prune remote-tracking branches
            if ! git fetch --prune origin; then
                echo "Fetch failed for $repo_dir. Skipping."
                continue
            fi

            # List and delete local branches where the corresponding remote-tracking branch is gone
            git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d

            echo "Local branches corresponding to deleted remote branches have been removed for $repo_dir."
        else
            echo "$repo_dir is not a Git repository. Skipping."
        fi

        # Go back to the original directory
        cd - > /dev/null
    fi
done

echo "Script completed."
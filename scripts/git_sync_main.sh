if [ -z "$GIT_PROJECTS_WORKDIR" ]; then
    echo "GIT_PROJECTS_WORKDIR is not set. Exiting."
    exit 1
fi

# Iterate over each subdirectory in GIT_PROJECTS_WORKDIR
for repo_dir in "$GIT_PROJECTS_WORKDIR"/*; do
    if [ -d "$repo_dir" ]; then
        echo "Syncing repository: $repo_dir"
        cd "$repo_dir"

        # Check if directory is a git repository
        if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            # Run gh repo sync
            if ! gh repo sync; then
                echo "Failed to sync $repo_dir. Skipping."
                continue
            fi

            echo "Repository synced: $repo_dir."
        else
            echo "$repo_dir is not a Git repository. Skipping."
        fi

        # Go back to the original directory
        cd - > /dev/null
    fi
done

echo "Script completed."

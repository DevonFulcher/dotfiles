if [ -z "$GIT_PROJECTS_WORKDIR" ]; then
    echo "The GIT_PROJECTS_WORKDIR environment variable is not set. Exiting..."
    exit 1
fi

list_repos() {
    for dir in "$GIT_PROJECTS_WORKDIR"/*; do
        if [ -d "$dir" ]; then
            cd "$dir"
            # Check if directory is a git repository
            if git rev-parse --git-dir > /dev/null 2>&1; then
                # Get the last commit date authored by Devon Fulcher
                # commit_date=$(git log -1 --format="%cd" --date=format:"%Y-%m-%d %H:%M:%S" --author="Devon Fulcher")
                status=$(git status -sb 2>/dev/null | sed 's/^## //g' | head -n 1 | cut -d '/' -f 2)

                # Check if there are any commits at all
                if [[ -n "$(git log --all)" ]]; then
                    # If there are commits, check if there's one authored by you
                    if [[ -n "$commit_date" ]]; then
                        # Construct output string with commit date
                        printf "%-30.25s %-15s \n" "$(basename "$dir")" "$status"
                    else
                        # Indicate no commits by you
                        printf "%-30.25s %-15s \n" "$(basename "$dir")" "$status"
                    fi
                else
                    # Indicate no commits in the repo at all
                    printf "%-30.25s %-15s \n" "$(basename "$dir")" "$status"
                fi
            else
                printf "%-30.25s %-15s \n" "$(basename "$dir")" "not a git repository"
            fi
        fi
    done
}
list_repos | less
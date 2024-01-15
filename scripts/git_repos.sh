if [ -z "$GIT_PROJECTS_WORKDIR" ]; then
    echo "The GIT_PROJECTS_WORKDIR environment variable is not set. Exiting..."
    exit 1
fi

# Store output temporarily in an array for sorting later
output=()

for dir in "$GIT_PROJECTS_WORKDIR"/*; do
    if [ -d "$dir" ]; then
        cd "$dir"
        # Check if directory is a git repository
        if git rev-parse --git-dir > /dev/null 2>&1; then
            # Get the last commit date authored by Devon Fulcher
            commit_date=$(git log -1 --format="%cd" --date=format:"%Y-%m-%d %H:%M:%S" --author="Devon Fulcher")

            # Check if there is actually a commit authored by you (empty string otherwise)
            if [[ -n "$commit_date" ]]; then
                # Get the current branch and a short summary of the status, remove hashes
                status=$(git status -sb 2>/dev/null | sed 's/^## //g' | head -n 1)

                # Construct the output string with the last commit date
                output_line="$(basename "$dir") - $status - $commit_date"

                # Add the output line to the array
                output+=("$output_line")
            fi
        else
            output+=("$(basename "$dir") - not a git repository")
        fi
    fi
done

# Sort the output array in descending order by the last commit date
IFS=$'\n' sorted_output=($(sort -r <<< "${output[*]}"))
unset IFS

# Print the sorted output
for line in "${sorted_output[@]}"; do
    echo "$line"
done

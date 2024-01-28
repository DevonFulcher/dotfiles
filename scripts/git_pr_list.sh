pr_table() {
  remote_name="origin"
  if ! git remote | grep -q "^${remote_name}$"; then
    echo "Remote '${remote_name}' does not exist."
    return 0
  fi

  # Fetch PRs and filter them based on author or review requests
  json_output=$(gh pr list --json number,title,author,reviewDecision,reviewRequests --jq 'map(select(.author.login == "DevonFulcher" or any(.reviewRequests[]; .login == "DevonFulcher")))')

  # Check if there is any output to avoid errors with jq
  if [ -z "$json_output" ]; then
    echo "No matching PRs found."
    exit 0
  fi

  # Format the JSON output into a table
  header="Number\tTitle\tAuthor\tReview Decision\tReviewers\n"
  echo "$json_output" | jq -r '.[] | [.number, .title, .author.login, .reviewDecision, ([.reviewRequests[].login] | join(", "))] | @tsv' | sed "1s/^/$header/" | column -t -s $'\t'
}

if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "$(pr_table $@)"
else
  for dir in "$GIT_PROJECTS_WORKDIR"/*; do
    if [ -d "$dir" ]; then
      cd "$dir"
      if git rev-parse --git-dir > /dev/null 2>&1; then
        repo_name=$(basename "$dir")
        echo $repo_name
        echo "$(pr_table $@)\n"
      fi
    fi
  done
fi



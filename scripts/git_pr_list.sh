# Fetch PRs and filter them based on author or review requests
json_output=$(gh pr list --json number,title,author,reviewDecision,reviewRequests --jq 'map(select(.author.login == "DevonFulcher" or any(.reviewRequests[]; .login == "DevonFulcher")))')

# Check if there is any output to avoid errors with jq
if [ -z "$json_output" ]; then
  echo "No matching PRs found."
  exit 0
fi

header="Number\tTitle\tAuthor\tReview Decision\tReviewers\n"

# Format the JSON output into a table without the -n option
echo "$json_output" | jq -r '.[] | [.number, .title, .author.login, .reviewDecision, ([.reviewRequests[].login] | join(", "))] | @tsv' | sed "1s/^/$header/" | column -t -s $'\t'

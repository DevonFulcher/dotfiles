message=$1

if [ -z "$message" ]; then
  echo "Please provide a message as the first argument."
  exit 1
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
  # Create a new branch with spaces replaced by hyphens
  branch_name="${message// /-}"
  git checkout -b $branch_name
else
  echo "You are not on a default branch. Current branch is $current_branch"
fi

git save "$message"
git pr
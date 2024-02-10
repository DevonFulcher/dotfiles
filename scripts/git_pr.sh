if [ "$#" -eq 1 ]; then
  gh pr view --web || gh pr create --web
elif [ $2 = "list" ]; then
  sh $GIT_PROJECTS_WORKDIR/dotfiles/scripts/git_pr_list.sh
else
  echo "Unrecognized command."
  return 1
fi
git add -A;
if [ -n "$1" ]; then
  verify=true;
  echo "$@"
  for arg in "$@"; do
    if [ "$arg" = "--no-verify" ]; then
      verify=false;
    fi
  done
  if [ $verify ]; then
    git commit -m "$1" --quiet && echo "code committed" || { echo "commit failed"; exit 1; }
  else
    git commit -m "$1" --quiet --no-verify && echo "code committed" || { echo "commit failed"; exit 1; }
  fi
else
  aicommits || { echo "aicommits failed"; exit 1; }
fi
git push --quiet && echo "commit pushed" || echo "push failed";

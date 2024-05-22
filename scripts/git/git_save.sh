git add -A;
if [ -n "$1" ]; then
  git commit -m "$1" --quiet && echo "code committed" || { echo "commit failed"; exit 1; }
else
  aicommits || { echo "aicommits failed"; exit 1; }
fi
git push --quiet && echo "commit pushed" || echo "push failed";

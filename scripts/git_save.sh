git add -A;
if [ -n "$1" ]; then
  git commit -m "$1" --quiet && echo "code committed";
else
  aicommits;
fi
git push --quiet && echo "code pushed";

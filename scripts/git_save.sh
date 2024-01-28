git add -A;
if [ -n "$1" ]; then
  git commit -m "$1";
else
  aicommits;
fi

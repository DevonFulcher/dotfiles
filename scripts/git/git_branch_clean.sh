git fetch -p
git branch -vv | grep ': gone]' | awk '{print $1}' | while read branch; do
  git branch -D "$branch"
done

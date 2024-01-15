git fetch --prune origin && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d

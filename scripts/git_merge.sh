merge_branch() {
    branch=$1
    shift
    git merge $branch "$@"
}

if [ "$1" = "main" ] || [ "$1" = "master" ]; then
    if git rev-parse --verify main >/dev/null 2>&1; then
        # If 'main' exists, merge 'main'
        merge_branch main "$@"
    elif git rev-parse --verify master >/dev/null 2>&1; then
        # If 'master' exists but 'main' does not, merge 'master'
        merge_branch master "$@"
    else
        echo "Neither 'main' nor 'master' branch exists."
        exit 1
    fi
else
    # If not 'main' or 'master', pass all arguments to git merge
    git merge "$@"
fi

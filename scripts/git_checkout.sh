checkout_branch() {
    branch=$1
    shift
    git checkout $branch "$@"
}

if [ "$1" = "main" ] || [ "$1" = "master" ]; then
    if git rev-parse --verify main >/dev/null 2>&1; then
        # If 'main' exists, checkout to 'main'
        checkout_branch main "$@"
    elif git rev-parse --verify master >/dev/null 2>&1; then
        # If 'master' exists but 'main' does not, checkout to 'master'
        checkout_branch master "$@"
    else
        echo "Neither 'main' nor 'master' branch exists."
        exit 1
    fi
else
    # If not 'main' or 'master', pass all arguments to git checkout
    git checkout "$@"
fi

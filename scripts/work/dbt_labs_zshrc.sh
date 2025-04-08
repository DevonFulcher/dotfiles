export AFS_DATASOURCES_PATH="$GIT_PROJECTS_WORKDIR/afs-cli/datasources.yaml"
alias afs='python3.12 $GIT_PROJECTS_WORKDIR/afs-cli/afs.py $@'

alias core="$GIT_PROJECTS_WORKDIR/dbt-core/env/bin/dbt"

alias charts="$GIT_PROJECTS_WORKDIR/helm-charts"
alias cloud="$GIT_PROJECTS_WORKDIR/dbt-cloud"
alias codegen="$GIT_PROJECTS_WORKDIR/ai-codegen-api"
alias dsi="$GIT_PROJECTS_WORKDIR/dbt-semantic-interfaces"
alias excel="$GIT_PROJECTS_WORKDIR/semantic-layer-spreadsheet-integrations/apps/excel"
alias gsheets="$GIT_PROJECTS_WORKDIR/semantic-layer-spreadsheet-integrations/apps/gsheets"
alias mantle="$GIT_PROJECTS_WORKDIR/dbt-mantle"
alias mf="$GIT_PROJECTS_WORKDIR/metricflow"
alias mfs="$GIT_PROJECTS_WORKDIR/metricflow-server"
alias releases="$GIT_PROJECTS_WORKDIR/helm-releases"
alias sheet="$GIT_PROJECTS_WORKDIR/semantic-layer-spreadsheet-integrations"
alias slg="$GIT_PROJECTS_WORKDIR/semantic-layer-gateway"
alias ui="$GIT_PROJECTS_WORKDIR/cloud-ui"
alias infra="$DOTFILES/workspaces/infra.code-workspace"

export APPLE_SSH_ADD_BEHAVIOR="macos"
export GITHUB_TOKEN="$HOMEBREW_GITHUB_API_TOKEN"

# Hatch: https://hatch.pypa.io/1.12/cli/about/#tab-completion
. ~/.hatch-complete.zsh

# Java
export JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home

# bun completions
[ -s "/Users/devonfulcher/.bun/_bun" ] && source "/Users/devonfulcher/.bun/_bun"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Rust & Cargo
. "$HOME/.cargo/env"

export AWS_USER="devon.fulcher"
export AFS_JDBC_DRIVER=/Users/devonfulcher/drivers/flight-sql-jdbc-driver-12.0.0.jar
alias tableau="/Applications/Tableau\ Desktop\ 2023.2.app/Contents/MacOS/Tableau -DDisableVerifyConnectorPluginSignature=true -DConnectPluginsPath=$GIT_PROJECTS_WORKDIR/semantic-layer-gateway/integrations/tableau"
export DEVSPACE_NAMESPACE="dev-devonfulcher"

kubectl config set-context --current --namespace=$DEVSPACE_NAMESPACE > /dev/null 2>&1

source ~/.devspace-completion

function ensure-k8s-context() {
    local expected_context="dbt-labs-devspace"
    local expected_namespace="$DEVSPACE_NAMESPACE"
    local current_context=$(kubectl config current-context)

    if [ "$current_context" != "$expected_context" ]; then
        echo "Switching kubectl context from '$current_context' to '$expected_context'..."
        kubectl config use-context "$expected_context" || return 1
    fi

    local current_namespace=$(kubectl config view --minify -o jsonpath='{..namespace}')
    if [ "$current_namespace" != "$expected_namespace" ]; then
        echo "Switching kubectl namespace from '$current_namespace' to '$expected_namespace'..."
        kubectl config set-context --current --namespace="$expected_namespace" || return 1
    fi

    echo "Using context: $expected_context"
    echo "Using namespace: $expected_namespace"
}

function ds() {
  local force=false
  local args=()

  # Parse arguments to check for --force flag
  for arg in "$@"; do
    if [ "$arg" = "--force" ]; then
      force=true
    else
      args+=("$arg")
    fi
  done

  if ! $force; then
    ensure-k8s-context || return 1

    if [ "$(git -C "$GIT_PROJECTS_WORKDIR/helm-releases" rev-parse --abbrev-ref HEAD)" != "main" ]; then
      echo "helm-releases is not on the 'main' branch. Use --force to run anyway."
      return 1
    elif [ "$(git -C "$GIT_PROJECTS_WORKDIR/helm-charts" rev-parse --abbrev-ref HEAD)" != "main" ]; then
      echo "helm-charts is not on the 'main' branch. Use --force to run anyway."
      return 1
    fi
  fi

  command devspace "${args[@]}"
}

function refresh-devspace() {
  echo "==============================================="
  echo "(cd helm-charts && git checkout main && git pull)"
  echo "==============================================="
  (cd $GIT_PROJECTS_WORKDIR/helm-charts && git checkout main && git pull)

  echo "==============================================="
  echo "(cd helm-releases && git checkout main && git pull)"
  echo "==============================================="
  (cd $GIT_PROJECTS_WORKDIR/helm-releases && git checkout main && git pull)

  echo "==============================================="
  echo "(cd devspace-tools && git checkout main && git pull)"
  echo "==============================================="
  (cd $GIT_PROJECTS_WORKDIR/devspace-tools && git checkout main && git pull)

  echo "==============================================="
  echo "(cd dbt-cloud && git checkout master && git pull)"
  echo "==============================================="
  (cd $GIT_PROJECTS_WORKDIR/dbt-cloud && git checkout master && git pull)

  echo "==============================================="
  echo "rip $HOME/.devspace"
  echo "==============================================="
  rip $HOME/.devspace

  echo "==============================================="
  echo "find $GIT_PROJECTS_WORKDIR -maxdepth 2 -name '.devspace' -exec rip {} +"
  echo "==============================================="
  find $GIT_PROJECTS_WORKDIR -maxdepth 2 -name ".devspace" -exec rip {} +
}

function nuke-devspace() {
  refresh-devspace || return 1
  ensure-k8s-context || return 1

  if [[ ! -f "devspace.yaml" && ! -f "devspace.yml" ]]; then
    echo "Error: No devspace.yaml or devspace.yml found in current directory"
    return 1
  fi

  echo "==============================================="
  echo "aws sso login"
  echo "==============================================="
  aws sso login

  echo "==============================================="
  echo "devspace use namespace $DEVSPACE_NAMESPACE"
  echo "==============================================="
  devspace use namespace $DEVSPACE_NAMESPACE

  echo "==============================================="
  echo "devspace purge --force-purge"
  echo "==============================================="
  devspace purge --force-purge

  echo "==============================================="
  echo "kubectl delete namespace $DEVSPACE_NAMESPACE"
  echo "==============================================="
  kubectl delete namespace $DEVSPACE_NAMESPACE

  echo "==============================================="
  echo "devspace use namespace $DEVSPACE_NAMESPACE"
  echo "==============================================="
  devspace use namespace $DEVSPACE_NAMESPACE
}

function connect-devspace-codex-database() {
  kubectl exec -it $(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep ^codex-database) -- psql -U root -d codex
}

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm end

# pnpm
export PNPM_HOME="/Users/devonfulcher/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

fpath+=~/.zfunc
autoload -Uz compinit && compinit

# From fsh setup
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export ASDF_HASHICORP_OVERWRITE_ARCH=amd64
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export AWS_PROFILE=staging-admin

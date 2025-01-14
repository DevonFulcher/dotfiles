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
export NAMESPACE="dev-devonfulcher"

source ~/.devspace-completion

function devspace() {
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

function nuke-devspace() {
  if [[ ! -f "devspace.yaml" && ! -f "devspace.yml" ]]; then
    echo "Error: No devspace.yaml or devspace.yml found in current directory"
    return 1
  fi

  echo "==============================================="
  echo "aws sso login"
  echo "==============================================="
  aws sso login

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
  echo "devspace use namespace $NAMESPACE"
  echo "==============================================="
  devspace use namespace $NAMESPACE

  echo "==============================================="
  echo "devspace purge --force-purge"
  echo "==============================================="
  devspace purge --force-purge

  echo "==============================================="
  echo "rip $HOME/.devspace"
  echo "==============================================="
  rip $HOME/.devspace

  echo "==============================================="
  echo "kubectl delete namespace $NAMESPACE"
  echo "==============================================="
  kubectl delete namespace $NAMESPACE

  echo "==============================================="
  echo "find $GIT_PROJECTS_WORKDIR -maxdepth 2 -name '.devspace' -exec rip {} +"
  echo "==============================================="
  find $GIT_PROJECTS_WORKDIR -maxdepth 2 -name ".devspace" -exec rip {} +


  echo "==============================================="
  echo "devspace use namespace $NAMESPACE"
  echo "==============================================="
  devspace use namespace $NAMESPACE
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

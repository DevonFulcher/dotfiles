export AFS_DATASOURCES_PATH="$GIT_PROJECTS_WORKDIR/afs-cli/datasources.yaml"
alias afs='python3.12 $GIT_PROJECTS_WORKDIR/afs-cli/afs.py $@'

export APPLE_SSH_ADD_BEHAVIOR="macos"
export GITHUB_TOKEN="$HOMEBREW_GITHUB_API_TOKEN"

# Go
export GOPATH=/usr/local/go/bin
export PATH="$PATH:${GOPATH}/bin"

# Java
export JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home

# bun completions
[ -s "/Users/devonfulcher/.bun/_bun" ] && source "/Users/devonfulcher/.bun/_bun"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export AWS_USER="devon.fulcher"
export AFS_JDBC_DRIVER=/Users/devonfulcher/drivers/flight-sql-jdbc-driver-12.0.0.jar
alias tableau="/Applications/Tableau\ Desktop\ 2023.2.app/Contents/MacOS/Tableau -DDisableVerifyConnectorPluginSignature=true -DConnectPluginsPath=$GIT_PROJECTS_WORKDIR/semantic-layer-gateway/integrations/tableau"
export NAMESPACE="dev-devonfulcher"

# devspace completions, doesn't seem to work actually
source ~/.devspace-completion

function devspace() {
  if [ "$(git -C "$GIT_PROJECTS_WORKDIR/helm-releases" rev-parse --abbrev-ref HEAD)" != "main" ]; then
    echo "helm-releases is not on the 'main' branch."
  elif [ "$(git -C "$GIT_PROJECTS_WORKDIR/helm-charts" rev-parse --abbrev-ref HEAD)" != "main" ]; then
    echo "helm-charts is not on the 'main' branch."
  else
    command devspace "$@"
  fi
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

alias dbti=~/cli/dbt
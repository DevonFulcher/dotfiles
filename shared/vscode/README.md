list extensions:
`code --list-extensions > extensions.txt`

locations:
Windows %APPDATA%\Code\User\settings.json
macOS $HOME/Library/Application\ Support/Code/User/settings.json
Linux $HOME/.config/Code/User/settings.json

install an extension:
code --install-extension (<extension-id> | <extension-vsix-path>)
    Installs an extension.
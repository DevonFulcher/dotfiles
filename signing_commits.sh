ssh-keygen -t ed25519 -C $GITHUB_PERSONAL_EMAIL -f ~/.ssh/personal_email_id_ed25519
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/personal_email_id_ed25519
pbcopy < ~/.ssh/personal_email_id_ed25519.pub

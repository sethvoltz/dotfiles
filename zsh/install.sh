#!/bin/sh

echo "  Ensuring compaudit is clear... you may be asked for your system password"
zsh -c 'autoload -Uz compaudit; for f in $(compaudit); do sudo chmod -R 755 $f; done'

if [ ! -f ~/.iterm2_shell_integration.zsh ]; then
  echo "  Installing iTerm shell integrations"
  curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
fi

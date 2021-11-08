if command -v vim > /dev/null 2>&1; then
  pushd $ZSH > /dev/null

  echo "» Installing Vim plugins"
  vim +PlugInstall +PlugClean +PlugUpgrade +qa

  popd > /dev/null
fi

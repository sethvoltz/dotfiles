if command -v borders > /dev/null 2>&1; then
  echo "» Starting or restarting borders service"
  brew services restart borders
fi

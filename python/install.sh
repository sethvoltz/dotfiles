if ! command -v uv > /dev/null 2>&1; then
  echo "» Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

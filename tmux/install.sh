#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

target_dir="${HOME}/.tmux/plugins"

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

mkdir -p "${target_dir}"

if [[ -d "${target_dir}/tpm" ]]; then
  echo "» TMUX Plugin Manager (TPM) already exists, updating..."
  git -C "${target_dir}/tpm" pull
else
  echo "» Installing TMUX Plugin Manager (TPM)"
  git clone https://github.com/tmux-plugins/tpm "${target_dir}/tpm"
fi

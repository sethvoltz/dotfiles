return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          prepend_args = {
            "--config",
            vim.fn.expand("~/.dotfiles/nvim/markdownlint-cli2.jsonc"),
          },
        },
      },
    },
  },
}

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    -- config = function()
    --   require("catppuccin").setup({
    --     transparent_background = true,
    --   })
    -- end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}

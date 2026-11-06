-- lua/plugins/terminal.lua — terminal nhanh trong Neovim (toggleterm)

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermSelect" },
    keys = {
      { "<C-\\>", "<cmd>ToggleTerm<CR>", desc = "Bật/tắt terminal" },
      { "<leader>tt", "<cmd>ToggleTerm direction=float<CR>", desc = "Terminal nổi" },
      { "<leader>tT", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Terminal bên dưới" },
    },
    opts = {
      open_mapping = [[<c-\>]],
      direction = "float",
      float_opts = { border = "curved" },
      persist_mode = true,
      start_in_insert = true,
      auto_scroll = true,
    },
  },
}

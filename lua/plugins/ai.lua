-- lua/plugins/ai.lua — terminal thường trong Neovim (toggleterm)
-- AI CLI giờ chạy dạng tmux pane (xem lua/util/ai.lua + keymap <leader>a trong
-- lua/config/keymaps.lua). toggleterm ở đây chỉ dùng cho terminal scratch nhanh.

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermSelect" },
    keys = {
      { "<leader>at", "<cmd>ToggleTerm direction=float<CR>", desc = "Terminal scratch (float)" },
      { "<leader>aT", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Terminal scratch (dưới)" },
    },
    opts = {
      open_mapping = [[<c-\>]], -- Ctrl-\ bật/tắt terminal scratch nhanh
      direction = "float",
      float_opts = { border = "curved" },
      persist_mode = true,
      start_in_insert = true,
      auto_scroll = true,
    },
  },
}

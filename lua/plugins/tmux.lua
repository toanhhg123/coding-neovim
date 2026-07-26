-- lua/plugins/tmux.lua — tích hợp tmux
-- vim-tmux-navigator: Ctrl-h/j/k/l nhảy liền mạch giữa Neovim split và tmux pane.
-- Cần config phía tmux (tmux/tmux.conf) có đoạn is_vim tương ứng.

return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Sang trái (split/tmux pane)" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Xuống dưới (split/tmux pane)" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Lên trên (split/tmux pane)" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Sang phải (split/tmux pane)" },
    },
  },
}

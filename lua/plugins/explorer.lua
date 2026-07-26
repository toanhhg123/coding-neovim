-- lua/plugins/explorer.lua — file explorer (neo-tree)
-- Cây thư mục bên trái, tích hợp git status, theo dõi file đang mở.

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle reveal<CR>", desc = "Explorer (bật/tắt)" },
      { "<leader>E", "<cmd>Neotree reveal<CR>", desc = "Explorer: hiện file hiện tại" },
      { "<leader>ge", "<cmd>Neotree float git_status<CR>", desc = "Explorer: git status" },
    },
    opts = {
      close_if_last_window = true, -- đóng nvim gọn nếu chỉ còn cây
      popup_border_style = "rounded",
      enable_git_status = true,
      enable_diagnostics = true,
      sources = { "filesystem", "buffers", "git_status" },
      default_component_configs = {
        indent = { with_expanders = true },
        git_status = {
          symbols = {
            added = "", -- dùng màu, khỏi ký hiệu cho gọn
            modified = "",
            deleted = "✖",
            renamed = "󰁕",
            untracked = "",
            ignored = "",
            unstaged = "󰄱",
            staged = "",
            conflict = "",
          },
        },
      },
      window = {
        width = 32,
        mappings = {
          ["<space>"] = "none", -- nhả <space> để leader hoạt động bình thường
          ["l"] = "open",
          ["h"] = "close_node",
          ["<CR>"] = "open",
          ["P"] = { "toggle_preview", config = { use_float = true } },
        },
      },
      filesystem = {
        bind_to_cwd = true,
        follow_current_file = { enabled = true }, -- tự highlight file đang mở
        use_libuv_file_watcher = true, -- tự cập nhật khi file đổi (AI CLI sửa)
        hijack_netrw_behavior = "open_default", -- mở thư mục = mở neo-tree
        filtered_items = {
          hide_dotfiles = false, -- vẫn thấy dotfiles (.env, .config...)
          hide_gitignored = false,
          never_show = { ".DS_Store", ".git" },
        },
      },
    },
  },
}

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
      -- Tạo file xong thì mở luôn ở cửa sổ code. Sự kiện này cũng phát khi tạo thư mục và
      -- khi copy, nên chỉ mở file trống (file mới tạo luôn trống)
      event_handlers = {
        {
          event = "file_added",
          handler = function(path)
            if vim.fn.getfsize(path) ~= 0 then return end
            vim.schedule(function()
              for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype ~= "neo-tree" and vim.api.nvim_win_get_config(win).relative == "" then
                  vim.api.nvim_set_current_win(win)
                  vim.cmd.edit(vim.fn.fnameescape(path))
                  return
                end
              end
            end)
          end,
        },
      },
      filesystem = {
        bind_to_cwd = true,
        follow_current_file = { enabled = true }, -- tự highlight file đang mở
        use_libuv_file_watcher = true, -- tự cập nhật khi file đổi
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

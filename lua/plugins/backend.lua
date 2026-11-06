-- lua/plugins/backend.lua — công cụ backend: database (dadbod) + gọi API (curl.nvim)
-- Thông tin kết nối DB lưu trong thư mục data của Neovim, KHÔNG nằm trong repo này.

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>Dd", "<cmd>DBUIToggle<CR>", desc = "Bật/tắt giao diện database" },
      { "<leader>Da", "<cmd>DBUIAddConnection<CR>", desc = "Thêm kết nối" },
      { "<leader>Df", "<cmd>DBUIFindBuffer<CR>", desc = "Gắn file SQL này vào kết nối" },
    },
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
    end,
  },

  -- Gọi API bằng lệnh curl: viết lệnh ở khung trái, Enter để chạy, kết quả (jq) ở khung phải
  {
    "oysandvik94/curl.nvim",
    cmd = { "CurlOpen", "CurlClose", "CurlCollection" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>hh", "<cmd>CurlOpen<CR>", desc = "Mở bảng curl của project" },
      { "<leader>hg", "<cmd>CurlOpen global<CR>", desc = "Mở bảng curl dùng chung" },
      { "<leader>hc", "<cmd>CurlCollection scoped<CR>", desc = "Chọn bộ request đã lưu" },
      { "<leader>hq", "<cmd>CurlClose<CR>", desc = "Đóng bảng curl" },
    },
    opts = {},
  },
}

-- lua/plugins/outline.lua — Outline cấu trúc file (aerial)
-- Xem nhanh danh sách class / function / method để navigate trong file dài.
-- Backend treesitter -> CHẠY ĐƯỢC KHI LSP TẮT (đúng gu: LSP mặc định off).

return {
  {
    "stevearc/aerial.nvim",
    version = "v3.1.0", -- bản cuối hỗ trợ Neovim < 0.12 (bạn đang 0.11.x); master yêu cầu 0.12
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
    keys = {
      { "<leader>co", "<cmd>AerialToggle<CR>", desc = "Outline: bật/tắt cấu trúc file" },
      { "<leader>cO", "<cmd>AerialNavToggle<CR>", desc = "Outline: popup điều hướng nhanh" },
      { "{", "<cmd>AerialPrev<CR>", desc = "Symbol trước" },
      { "}", "<cmd>AerialNext<CR>", desc = "Symbol kế tiếp" },
    },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Ưu tiên treesitter (không phụ thuộc LSP), fallback LSP/markdown nếu có
      backends = { "treesitter", "lsp", "markdown", "man" },
      layout = {
        max_width = { 40, 0.25 },
        min_width = 24,
        default_direction = "right",
      },
      attach_mode = "global",     -- 1 aerial theo dõi window đang active
      show_guides = true,         -- đường nối cây cho dễ đọc
      filter_kind = false,        -- hiện mọi loại symbol
      highlight_on_hover = true,
    },
  },
}

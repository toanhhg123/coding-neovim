-- lua/plugins/ui.lua — UI nền tảng: which-key (gợi ý phím) + lualine (statusline)

return {
  -- ============================================================
  -- which-key: bấm <leader> là hiện bảng gợi ý phím -> khỏi phải nhớ
  -- ============================================================
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix", -- layout gọn, hiện bên phải màn hình
      delay = 300,      -- ms chờ trước khi bật popup (đồng bộ với timeoutlen)
      icons = {
        mappings = true,
        rules = false, -- không auto gán icon để nhẹ & khỏi phụ thuộc nhiều
      },
      -- Đặt TÊN cho các namespace -> bảng gợi ý gọn gàng, phân nhóm rõ
      spec = {
        { "<leader>f", group = "Find / Search" },
        { "<leader>g", group = "Git" },
        { "<leader>a", group = "AI CLI" },
        { "<leader>b", group = "Buffer" },
        { "<leader>e", group = "Explorer" },
        { "<leader>L", desc = "Lazy (quản lý plugin)" },
        { "<leader>w", desc = "Lưu file" },
        { "<leader>/", desc = "Tìm trong file hiện tại" },
        { "<leader><leader>", desc = "Tìm file" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Phím tắt của buffer hiện tại",
      },
    },
  },

  -- ============================================================
  -- lualine: statusline nhẹ, hiện mode / git / diagnostic / vị trí
  -- ============================================================
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- icon (cần Nerd Font)
    opts = {
      options = {
        theme = "auto",             -- tự khớp với colorscheme đang dùng
        globalstatus = true,        -- 1 statusline chung cho mọi split -> gọn
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          statusline = { "alpha", "neo-tree", "oil" },
        },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },   -- nhánh git hiện tại
        lualine_c = {
          { "diff", symbols = { added = " ", modified = " ", removed = " " } },
          { "diagnostics", sources = { "nvim_lsp" } },
          { "filename", path = 1 }, -- path tương đối -> biết mình đang ở file nào trong project
        },
        lualine_x = {
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
        lualine_y = { "progress" },
        lualine_z = { "location" }, -- dòng:cột
      },
      extensions = { "lazy", "quickfix" },
    },
  },
}

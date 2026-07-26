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

  -- ============================================================
  -- bufferline: thanh tab các file đang mở (trên cùng)
  -- ============================================================
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<S-h>", "<cmd>BufferLineCyclePrev<CR>", desc = "Tab trước" },
      { "<S-l>", "<cmd>BufferLineCycleNext<CR>", desc = "Tab sau" },
      { "<leader>bp", "<cmd>BufferLineTogglePin<CR>", desc = "Ghim/bỏ ghim tab" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Đóng các tab khác" },
      { "<leader>bl", "<cmd>BufferLineCloseRight<CR>", desc = "Đóng tab bên phải" },
      { "<leader>bh", "<cmd>BufferLineCloseLeft<CR>", desc = "Đóng tab bên trái" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<CR>", desc = "Đóng tab chưa ghim" },
      -- Nhảy nhanh tới tab theo số thứ tự
      { "<leader>1", "<cmd>BufferLineGoToBuffer 1<CR>", desc = "Tab 1" },
      { "<leader>2", "<cmd>BufferLineGoToBuffer 2<CR>", desc = "Tab 2" },
      { "<leader>3", "<cmd>BufferLineGoToBuffer 3<CR>", desc = "Tab 3" },
      { "<leader>4", "<cmd>BufferLineGoToBuffer 4<CR>", desc = "Tab 4" },
      { "<leader>5", "<cmd>BufferLineGoToBuffer 5<CR>", desc = "Tab 5" },
    },
    opts = {
      options = {
        mode = "buffers",              -- mỗi file mở = 1 tab
        diagnostics = "nvim_lsp",       -- hiện dấu lỗi/cảnh báo trên tab
        separator_style = "slant",
        show_buffer_close_icons = true,
        show_close_icon = false,
        always_show_bufferline = false, -- ẩn khi chỉ có 1 file cho gọn
        offsets = {
          {
            filetype = "neo-tree",
            text = "Explorer",
            highlight = "Directory",
            separator = true,
          },
        },
        hover = { enabled = true, delay = 200, reveal = { "close" } },
      },
    },
  },
}

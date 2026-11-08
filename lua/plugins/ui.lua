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
        { "<leader>s", group = "Search / Replace" },
        { "<leader>g", group = "Git" },
        { "<leader>t", group = "Terminal" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code / LSP" },
        { "<leader>e", group = "Explorer" },
        { "<leader>m", group = "Markdown" },
        { "<leader>j", group = "Java / Spring" },
        { "<leader>d", group = "Debug" },
        { "<leader>D", group = "Database" },
        { "<leader>h", group = "HTTP (curl)" },
        { "<leader>r", group = "Rename/Refactor" },
        { "<leader>L", desc = "Lazy (quản lý plugin)" },
        { "<leader>w", desc = "Lưu file" },
        { "<leader>/", desc = "Tìm trong file hiện tại" },
        { "<leader><leader>", desc = "Tìm file" },
      },
    },
    keys = {
      {
        "<leader>f?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Phím tắt của buffer hiện tại",
      },
    },
  },

  -- Icon một màu để cùng tông với giao diện
  { "nvim-tree/nvim-web-devicons", lazy = true, opts = { color_icons = false } },

  -- ============================================================
  -- lualine: statusline chỉ có chữ, không khối màu, không nền
  -- ============================================================
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local gray = "#686868"
      local function mode(color)
        return {
          a = { fg = color, bg = "NONE", gui = "bold" },
          b = { fg = gray, bg = "NONE" },
          c = { fg = gray, bg = "NONE" },
        }
      end
      return {
        options = {
          theme = {
            normal = mode("#00c5c7"),
            insert = mode("#58e790"),
            visual = mode("#e17ee1"),
            replace = mode("#dd7975"),
            command = mode("#c7c400"),
            inactive = mode(gray),
          },
          globalstatus = true,
          component_separators = "",
          section_separators = "",
          disabled_filetypes = { statusline = { "alpha", "oil" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { { "branch", icon = "" } },
          lualine_c = { { "filename", path = 1, symbols = { modified = "●", readonly = "", unnamed = "" } } },
          lualine_x = { { "diagnostics", sources = { "nvim_diagnostic" } } },
          lualine_y = { { "filetype", colored = false, icon_only = false } },
          lualine_z = { "location" },
        },
        extensions = { "lazy", "quickfix" },
      }
    end,
  },

  -- ============================================================
  -- bufferline: tab các file đang mở, chỉ phân biệt bằng màu chữ
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
        mode = "buffers",
        separator_style = { "", "" },
        indicator = { style = "none" },
        show_buffer_close_icons = false,
        show_close_icon = false,
        color_icons = false,
        always_show_bufferline = false,
        -- Ẩn buffer trống [No Name]
        custom_filter = function(buf)
          return vim.api.nvim_buf_get_name(buf) ~= ""
        end,
        offsets = { { filetype = "neo-tree", text = "", separator = true } },
      },
      highlights = function(defaults)
        local gray, fg = "#686868", "#dcdcdc"
        local result = {}
        for name in pairs(defaults.highlights) do
          -- Mọi thành phần: không nền, không in nghiêng; mặc định chữ xám
          result[name] = { fg = gray, bg = "NONE", italic = false, bold = false, sp = "NONE" }
        end
        for _, name in ipairs({ "buffer_selected", "numbers_selected", "duplicate_selected", "pick_selected" }) do
          result[name] = { fg = fg, bg = "NONE", bold = true, italic = false }
        end
        result.modified_selected = { fg = "#00c5c7", bg = "NONE" }
        result.offset_separator = { fg = "#3a4048", bg = "NONE" }
        return result
      end,
    },
  },
}

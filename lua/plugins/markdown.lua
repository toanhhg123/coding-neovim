-- lua/plugins/markdown.lua — đọc & preview markdown
-- 1) render-markdown: render đẹp NGAY trong editor (nhẹ, dùng treesitter)
-- 2) markdown-preview: mở bản render đầy đủ trên trình duyệt (live sync)
-- 3) img-clip: dán ảnh từ clipboard / kéo-thả ảnh vào file markdown

return {
  -- ============================================================
  -- Render markdown trong buffer (heading, bảng, code, checkbox...)
  -- ============================================================
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "md" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", ft = "markdown", desc = "Render markdown (bật/tắt)" },
    },
    opts = {
      code = { sign = false, width = "block", right_pad = 1 },
      heading = { sign = false, icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " } },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
    },
  },

  -- ============================================================
  -- Preview trên trình duyệt (live, cuộn đồng bộ).
  -- Chạy bằng node (yarn install) thay vì binary prebuilt — binary macOS
  -- hay lỗi E903 "-88". Cần node + npx (yarn).
  -- ============================================================
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = "cd app && npx --yes yarn install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", ft = "markdown", desc = "Preview markdown (trình duyệt)" },
    },
    config = function()
      vim.g.mkdp_auto_close = 1 -- tự đóng tab khi rời buffer markdown
      vim.g.mkdp_theme = "dark"
    end,
  },

  -- ============================================================
  -- Dán ảnh: lưu ảnh vào thư mục assets/ cạnh file .md và chèn ![](...)
  -- Cần công cụ đọc ảnh trong clipboard: pngpaste (macOS), xclip hoặc wl-clipboard (Linux)
  -- ============================================================
  {
    "HakonHarnes/img-clip.nvim",
    ft = { "markdown" }, -- nạp cùng file .md để kéo-thả ảnh vào terminal cũng chạy
    cmd = "PasteImage",
    keys = {
      { "<leader>mi", "<cmd>PasteImage<CR>", ft = "markdown", desc = "Dán ảnh từ clipboard" },
    },
    opts = {
      default = {
        dir_path = "assets",
        relative_to_current_file = true, -- assets/ nằm cạnh file .md, không phải ở thư mục gốc
        prompt_for_file_name = true, -- hỏi tên file ảnh, đặt tên dễ hiểu cho ghi chú
        show_dir_path_in_prompt = true,
        copy_images = true, -- kéo-thả ảnh có sẵn trên máy: chép vào assets/ thay vì trỏ ra ngoài
      },
    },
  },
}

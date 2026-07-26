-- lua/plugins/markdown.lua — đọc & preview markdown
-- 1) render-markdown: render đẹp NGAY trong editor (nhẹ, dùng treesitter)
-- 2) markdown-preview: mở bản render đầy đủ trên trình duyệt (live sync)

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
  -- Preview trên trình duyệt (live, cuộn đồng bộ). Binary tự tải khi build.
  -- ============================================================
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", ft = "markdown", desc = "Preview markdown (trình duyệt)" },
    },
    config = function()
      vim.g.mkdp_auto_close = 1 -- tự đóng tab khi rời buffer markdown
      vim.g.mkdp_theme = "dark"
    end,
  },
}

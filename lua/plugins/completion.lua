-- lua/plugins/completion.lua — gợi ý code (blink.cmp), chỉ nạp khi vào Insert
-- LSP tắt thì vẫn có gợi ý từ path/snippet/buffer. Snippet Java, Spring: friendly-snippets.

return {
  {
    "saghen/blink.cmp",
    version = "1.*", -- bản release có sẵn binary fuzzy matcher, không cần Rust
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "enter", -- Enter nhận gợi ý như IntelliJ, Tab đi qua các ô của snippet
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
      },
      completion = {
        list = { selection = { preselect = true, auto_insert = false } },
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
        menu = { border = "rounded" },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      cmdline = { enabled = false }, -- giữ dòng lệnh mặc định cho nhẹ
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          sql = { "snippets", "dadbod", "buffer" },
          mysql = { "snippets", "dadbod", "buffer" },
          plsql = { "snippets", "dadbod", "buffer" },
        },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
}

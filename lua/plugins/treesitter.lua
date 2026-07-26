-- lua/plugins/treesitter.lua — highlight code theo cây cú pháp + textobjects
-- Cần C compiler (clang/gcc) để build parser. Chạy :TSUpdate khi cài.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- nhánh ổn định (API cổ điển)
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdate", "TSInstall", "TSInstallInfo" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
      -- Parser cho stack chính (JS/TS + Frontend, Java/Spring) + thông dụng
      ensure_installed = {
        "lua", "vim", "vimdoc", "bash", "regex",
        -- JS/TS + Frontend
        "javascript", "typescript", "tsx", "html", "css", "scss",
        "json", "jsonc", "yaml", "toml",
        -- Java / Spring Boot
        "java", "xml", "properties", "sql",
        -- Hạ tầng & tài liệu
        "dockerfile", "gitignore", "gitcommit", "diff", "markdown", "markdown_inline",
      },
      auto_install = true, -- gặp filetype lạ tự cài parser (nếu có mạng)
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
        disable = { "yaml" }, -- indent yaml của treesitter hay lệch
      },
      -- Chọn vùng tăng dần theo cú pháp (rất tiện đọc/refactor)
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-Space>",
          node_incremental = "<C-Space>",
          node_decremental = "<BS>",
          scope_incremental = false,
        },
      },
      textobjects = {
        -- Chọn theo cú pháp: af/if = hàm, ac/ic = class, aa/ia = tham số
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "Chọn cả hàm" },
            ["if"] = { query = "@function.inner", desc = "Chọn thân hàm" },
            ["ac"] = { query = "@class.outer", desc = "Chọn cả class" },
            ["ic"] = { query = "@class.inner", desc = "Chọn thân class" },
            ["aa"] = { query = "@parameter.outer", desc = "Chọn tham số" },
            ["ia"] = { query = "@parameter.inner", desc = "Chọn nội dung tham số" },
          },
        },
        -- Nhảy tới hàm/class kế tiếp (tránh ]c/[c vì gitsigns đang dùng cho hunk)
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = { query = "@function.outer", desc = "Hàm kế tiếp" },
            ["]t"] = { query = "@class.outer", desc = "Class kế tiếp" },
          },
          goto_previous_start = {
            ["[f"] = { query = "@function.outer", desc = "Hàm trước" },
            ["[t"] = { query = "@class.outer", desc = "Class trước" },
          },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}

-- lua/plugins/lsp.lua — LSP tối giản (điều hướng/hiểu code)
-- Triết lý: tập trung go-to-definition / references / hover / diagnostics.
-- KHÔNG format-on-save, KHÔNG ép lint (IDE chính lo phần đó).

return {
  -- Trình cài đặt language server
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
    },
    config = function()
      require("mason").setup({ ui = { border = "rounded" } })

      -- Danh sách server + tùy chỉnh. Thêm ở đây là tự cài + bật.
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } }, -- khỏi báo "vim" undefined
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        ts_ls = {}, -- JavaScript / TypeScript
        html = {},
        cssls = {},
        tailwindcss = {},
        jsonls = {},
        yamlls = {},
        bashls = {},
        -- Java: KHÔNG setup ở đây (jdtls cần plugin riêng nvim-jdtls).
        -- Xem lua/plugins/java.lua.
      }

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_installation = true,
        automatic_enable = false, -- tự setup thủ công bên dưới (tránh bật 2 lần)
      })

      -- ===== Diagnostics: gọn, dễ đọc =====
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = "rounded", source = true },
        virtual_text = { prefix = "●", spacing = 2 },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
          },
        },
      })

      -- ===== Keymap khi LSP gắn vào buffer =====
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
          end
          local ok, tb = pcall(require, "telescope.builtin")

          -- Điều hướng (dùng Telescope nếu có, đẹp hơn)
          map("gd", ok and tb.lsp_definitions or vim.lsp.buf.definition, "Nhảy tới định nghĩa")
          map("gr", ok and tb.lsp_references or vim.lsp.buf.references, "References")
          map("gi", ok and tb.lsp_implementations or vim.lsp.buf.implementation, "Implementations")
          map("gy", ok and tb.lsp_type_definitions or vim.lsp.buf.type_definition, "Type definition")
          map("gD", vim.lsp.buf.declaration, "Khai báo")
          -- Đọc thông tin
          map("K", vim.lsp.buf.hover, "Hover (xem doc/type)")
          -- Sửa nhanh
          map("<leader>rn", vim.lsp.buf.rename, "Đổi tên (rename)")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format (thủ công)")
          -- Diagnostics
          map("gl", vim.diagnostic.open_float, "Xem diagnostic dòng này")
          map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Diagnostic kế tiếp")
          map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Diagnostic trước")
          map("<leader>cd", ok and tb.diagnostics or vim.diagnostic.setqflist, "Danh sách diagnostic")
        end,
      })

      -- ===== Setup từng server (API native nvim 0.11) =====
      -- capabilities chung cho mọi server
      vim.lsp.config("*", { capabilities = vim.lsp.protocol.make_client_capabilities() })
      -- override riêng từng server (nvim-lspconfig cung cấp config nền lsp/<name>.lua)
      for name, opts in pairs(servers) do
        if next(opts) ~= nil then
          vim.lsp.config(name, opts)
        end
      end
      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },
}

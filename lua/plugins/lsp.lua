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
    lazy = true, -- nạp từ util/lsp.lua
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
        -- Backend: pom.xml/XML, Dockerfile, docker-compose
        lemminx = {},
        dockerls = {},
        docker_compose_language_service = {},
        -- Java: KHÔNG setup ở đây (jdtls cần plugin riêng nvim-jdtls).
        -- Xem lua/plugins/java.lua.
      }

      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
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
          map("gS", function() require("util.editor").super() end, "Method cha (Java) / class cha")
          -- Luồng gọi & kế thừa (đọc code Spring: ai gọi service này, class nào implement)
          map("<leader>ci", ok and tb.lsp_incoming_calls or vim.lsp.buf.incoming_calls, "Ai gọi hàm này")
          map("<leader>cI", ok and tb.lsp_outgoing_calls or vim.lsp.buf.outgoing_calls, "Hàm này gọi những gì")
          map("<leader>ch", function() vim.lsp.buf.typehierarchy("subtypes") end, "Class con / implement")
          map("<leader>cH", function() vim.lsp.buf.typehierarchy("supertypes") end, "Class cha / interface")
          -- Đọc thông tin
          map("K", vim.lsp.buf.hover, "Hover (xem doc/type)")
          map("<leader>cp", vim.lsp.buf.signature_help, "Thông tin tham số")
          -- Sửa nhanh
          map("<leader>rn", vim.lsp.buf.rename, "Đổi tên (rename)")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format (thủ công)")
          map("<leader>cg", function()
            vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
          end, "Sinh code (getter, constructor...)")
          -- Diagnostics
          map("gl", vim.diagnostic.open_float, "Xem diagnostic dòng này")
          map("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Diagnostic kế tiếp")
          map("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Diagnostic trước")
          map("<leader>cd", ok and tb.diagnostics or vim.diagnostic.setqflist, "Danh sách diagnostic")
        end,
      })

      -- ===== Setup từng server (API native nvim 0.11) =====
      -- capabilities chung được đặt lúc bật LSP (xem util/lsp.lua)
      -- override riêng từng server (nvim-lspconfig cung cấp config nền lsp/<name>.lua)
      for name, opts in pairs(servers) do
        if next(opts) ~= nil then
          vim.lsp.config(name, opts)
        end
      end
      -- Bật/tắt toàn bộ LSP: :LspToggle/:LspEnable/:LspDisable + <leader>cl
      local toggle = require("util.lsp")
      -- register bật server nếu LSP đang bật, đang tắt thì chỉ ghi nhận
      toggle.register(vim.tbl_keys(servers))
    end,
  },
}

-- lua/plugins/java.lua — Java / Spring Boot qua nvim-jdtls
-- jdtls KHÔNG chạy được qua lspconfig chung -> phải dùng plugin chuyên dụng.
-- Chạy jdtls bằng Java 21 (project target 21). Workspace tách theo từng project.

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      -- Java runtime để CHẠY jdtls (cần 17/21; tránh 25 chưa hỗ trợ tốt).
      -- Ưu tiên bản 21 của sdkman; fallback về java trên PATH.
      local java_bin = vim.fn.expand("~/.sdkman/candidates/java/21.0.5-tem/bin/java")
      if vim.fn.executable(java_bin) == 0 then
        java_bin = "java"
      end

      local mason = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
      local launcher = vim.fn.glob(mason .. "/plugins/org.eclipse.equinox.launcher_*.jar")
      local config_dir = mason .. "/config_mac_arm" -- macOS Apple Silicon

      -- Các JDK để jdtls biên dịch project (khai báo theo tên JavaSE-*)
      local runtimes = {}
      local candidates = {
        { name = "JavaSE-17", path = vim.fn.expand("~/.sdkman/candidates/java/17.0.13-tem") },
        { name = "JavaSE-21", path = vim.fn.expand("~/.sdkman/candidates/java/21.0.5-tem") },
      }
      for _, c in ipairs(candidates) do
        if vim.fn.isdirectory(c.path) == 1 then
          table.insert(runtimes, c)
        end
      end

      local function start()
        local root = vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" })
        if not root then
          return
        end
        -- Workspace riêng cho mỗi project (tránh lẫn dữ liệu)
        local ws = vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. vim.fn.fnamemodify(root, ":p:h:t")

        require("jdtls").start_or_attach({
          cmd = {
            java_bin,
            "-Declipse.application=org.eclipse.jdt.ls.core.id1",
            "-Dosgi.bundles.defaultStartLevel=4",
            "-Declipse.product=org.eclipse.jdt.ls.core.product",
            "-Dlog.protocol=true",
            "-Dlog.level=ALL",
            "-Xmx1g",
            "--add-modules=ALL-SYSTEM",
            "--add-opens", "java.base/java.util=ALL-UNNAMED",
            "--add-opens", "java.base/java.lang=ALL-UNNAMED",
            "-jar", launcher,
            "-configuration", config_dir,
            "-data", ws,
          },
          root_dir = root,
          settings = {
            java = {
              eclipse = { downloadSources = true },
              maven = { downloadSources = true },
              signatureHelp = { enabled = true },
              contentProvider = { preferred = "fernflower" }, -- xem source thư viện
              configuration = { runtimes = runtimes },
            },
          },
          init_options = { bundles = {} },
          -- keymap gd/gr/K... đã có sẵn qua LspAttach trong lua/plugins/lsp.lua
        })
      end

      local grp = vim.api.nvim_create_augroup("jdtls_start", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        group = grp,
        callback = start,
      })
      -- Buffer java đang mở khi plugin vừa nạp (lazy ft) -> khởi động luôn
      if vim.bo.filetype == "java" then
        start()
      end
    end,
  },
}

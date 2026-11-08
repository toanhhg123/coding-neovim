-- lua/plugins/java.lua — Java / Spring Boot
-- nvim-jdtls: LSP Java + Lombok + debug + test (tắt/bật bằng <leader>cl)
-- spring-boot.nvim: gợi ý application.yml/properties, tra bean/endpoint qua LSP
-- Lệnh chạy app/test không cần LSP nằm trong lua/util/spring.lua (<leader>j).

local TOOLS = require("util.java").TOOLS

local function spring(fn)
  return function() require("util.spring")[fn]() end
end

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = { "williamboman/mason.nvim" },
    keys = {
      { "<leader>jr", spring("run"), desc = "Chạy app (nhớ profile đã chọn)" },
      { "<leader>jR", spring("run_pick_profile"), desc = "Chạy app: chọn profile" },
      { "<leader>jD", function() require("util.debug").start() end, desc = "Chạy app và attach debugger (cổng 5005)" },
      { "<leader>jq", function() require("util.debug").stop() end, desc = "Dừng app / debugger" },
      { "<leader>jt", spring("test_class"), desc = "Test: class hiện tại" },
      { "<leader>jn", spring("test_method"), desc = "Test: method dưới con trỏ" },
      { "<leader>jT", spring("test_all"), desc = "Test: toàn bộ" },
      { "<leader>jm", spring("goals"), desc = "Lệnh Maven/Gradle" },
      { "<leader>ja", spring("toggle_test"), desc = "Nhảy class <-> test" },
      { "<leader>je", spring("endpoints"), desc = "Tìm endpoint" },
      { "<leader>jb", spring("beans"), desc = "Tìm bean" },
      { "<leader>jy", spring("resources"), desc = "Mở file resources" },
      { "<leader>jk", spring("docker"), desc = "Docker (lazydocker)" },
    },
    config = function()
      local java = require("util.java")

      local function jars(pattern)
        return vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/" .. pattern, true, true)
      end

      -- Extension cho jdtls: debug + test + spring boot
      local function bundles()
        local list = jars("java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
        for _, jar in ipairs(jars("java-test/extension/server/*.jar")) do
          local name = vim.fs.basename(jar)
          -- 2 jar này là công cụ chạy test, không phải OSGi bundle (theo tài liệu nvim-jdtls)
          if not name:match("^com%.microsoft%.java%.test%.runner%-jar%-with%-dependencies") and not name:match("^jacocoagent") then
            table.insert(list, jar)
          end
        end
        local ok, spring_boot = pcall(require, "spring_boot")
        if ok then vim.list_extend(list, spring_boot.java_extensions()) end
        return list
      end

      local function on_attach(_, buf)
        local jdtls = require("jdtls")
        pcall(jdtls.setup_dap, { hotcodereplace = "auto" })

        local function map(mode, keys, fn, desc)
          vim.keymap.set(mode, keys, fn, { buffer = buf, desc = "Java: " .. desc })
        end
        map("n", "<leader>jo", jdtls.organize_imports, "Sắp xếp import")
        map({ "n", "x" }, "<leader>jv", function() jdtls.extract_variable(vim.fn.mode() ~= "n") end, "Tách biến")
        map({ "n", "x" }, "<leader>jC", function() jdtls.extract_constant(vim.fn.mode() ~= "n") end, "Tách hằng số")
        map("x", "<leader>jx", function() jdtls.extract_method(true) end, "Tách method")
        map("n", "<leader>jU", jdtls.update_project_config, "Cập nhật project (sau khi sửa pom)")
        map("n", "<leader>dT", function() require("jdtls.dap").test_class() end, "Debug test class")
        map("n", "<leader>dN", function() require("jdtls.dap").test_nearest_method() end, "Debug test method")
        map("n", "<leader>js", "<cmd>SpringBoot<CR>", "Spring: bean/endpoint qua LSP")
      end

      local function start()
        -- Tôn trọng trạng thái bật/tắt toàn bộ LSP
        local toggle = require("util.lsp")
        if not toggle.enabled then return end

        local mason = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
        local launcher = vim.fn.glob(mason .. "/plugins/org.eclipse.equinox.launcher_*.jar")
        if launcher == "" then
          java.ensure_mason(TOOLS, function()
            vim.notify("Đã cài xong, bật lại LSP bằng <leader>cl", vim.log.levels.INFO, { title = "Java" })
          end)
          return
        end

        -- Thư mục có wrapper/.git ưu tiên hơn pom con, để multi-module gom về một workspace
        local root = vim.fs.root(0, { { "mvnw", "gradlew", ".git" }, { "pom.xml", "build.gradle", "build.gradle.kts" } })
        if not root then return end

        -- Hash đường dẫn: hai project trùng tên không dùng chung workspace
        local workspace = vim.fs.joinpath(
          vim.fn.stdpath("cache"),
          "jdtls-workspace",
          vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
        )

        local cmd = {
          java.jdtls_java(),
          "-Declipse.application=org.eclipse.jdt.ls.core.id1",
          "-Dosgi.bundles.defaultStartLevel=4",
          "-Declipse.product=org.eclipse.jdt.ls.core.product",
          "-Xmx2g",
          "--add-modules=ALL-SYSTEM",
          "--add-opens", "java.base/java.util=ALL-UNNAMED",
          "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        }
        -- Lombok: mason đóng gói sẵn trong jdtls, jar tự đặt là phương án dự phòng
        for _, lombok in ipairs({ mason .. "/lombok.jar", vim.fn.stdpath("data") .. "/lombok.jar" }) do
          if vim.fn.filereadable(lombok) == 1 then
            table.insert(cmd, "-javaagent:" .. lombok) -- phải trước -jar
            break
          end
        end
        vim.list_extend(cmd, { "-jar", launcher, "-configuration", java.jdtls_config_dir(mason), "-data", workspace })

        local extended = vim.deepcopy(require("jdtls").extendedClientCapabilities)
        extended.resolveAdditionalTextEditsSupport = true

        require("jdtls").start_or_attach({
          cmd = cmd,
          root_dir = root,
          capabilities = toggle.capabilities(),
          on_attach = on_attach,
          settings = {
            java = {
              eclipse = { downloadSources = true },
              maven = { downloadSources = true },
              signatureHelp = { enabled = true },
              contentProvider = { preferred = "fernflower" }, -- xem source thư viện
              configuration = {
                runtimes = java.runtimes(root),
                updateBuildConfiguration = "interactive",
              },
              references = { includeDecompiledSources = true },
              completion = {
                favoriteStaticMembers = {
                  "org.junit.jupiter.api.Assertions.*",
                  "org.assertj.core.api.Assertions.*",
                  "org.mockito.Mockito.*",
                  "org.mockito.ArgumentMatchers.*",
                  "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
                  "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
                },
                filteredTypes = { "com.sun.*", "sun.*", "jdk.*", "org.graalvm.*", "io.micrometer.shaded.*" },
                importOrder = { "java", "javax", "jakarta", "org", "com", "" },
              },
              sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
              codeGeneration = {
                useBlocks = true,
                toString = { template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}" },
              },
            },
          },
          init_options = { bundles = bundles(), extendedClientCapabilities = extended },
          -- gd/gr/K... đã có sẵn qua LspAttach trong lua/plugins/lsp.lua
        })
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        group = vim.api.nvim_create_augroup("jdtls_start", { clear = true }),
        callback = start,
      })
      -- Buffer java đang mở khi plugin vừa nạp (lazy ft) -> khởi động luôn
      if vim.bo.filetype == "java" then start() end
    end,
  },

  -- Gợi ý application.yml/properties + tra bean/endpoint (chạy cùng LSP, chỉ với project Spring Boot)
  {
    "JavaHello/spring-boot.nvim",
    lazy = true, -- nạp từ util/lsp.lua
    config = function()
      require("spring_boot").setup({
        auto_enable = false, -- bật/tắt theo util/lsp.lua
        java_cmd = require("util.java").tool_java(),
        project_filter = function(root)
          return require("spring_boot.util").has_spring_boot_dependency(root)
        end,
      })
      require("util.lsp").register("spring-boot")
    end,
  },
}

-- scripts/setup.lua — cài parser treesitter + package Mason, rồi thoát
-- install.sh gọi: nvim --headless -c "luafile scripts/setup.lua"
-- Danh sách lấy từ chính config (util/parsers.lua, util/lsp.lua, util/java.lua), không viết lại.

local failed = {}

local function step(name, fn)
  io.write("  - " .. name .. "\n")
  local ok, err = pcall(fn)
  if not ok then
    table.insert(failed, name .. ": " .. tostring(err))
  end
end

step("Parser treesitter", function()
  require("nvim-treesitter").install(require("util.parsers")):wait(15 * 60 * 1000)
end)

step("Package Mason (LSP, Java, Spring)", function()
  -- Nạp lspconfig để có danh sách server mà config đang dùng
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  local to_package = require("mason-lspconfig").get_mappings().lspconfig_to_package
  local names = vim.deepcopy(require("util.java").TOOLS)
  for _, server in ipairs(require("util.lsp").servers) do
    if to_package[server] then table.insert(names, to_package[server]) end
  end

  local registry = require("mason-registry")
  local refreshed = false
  registry.refresh(function() refreshed = true end)
  vim.wait(120000, function() return refreshed end, 200)

  local pending = 0
  for _, name in ipairs(names) do
    local pkg = registry.get_package(name)
    if not pkg:is_installed() then
      pending = pending + 1
      io.write("    cài " .. name .. "\n")
      pkg:install({}, function(success, err)
        if not success then table.insert(failed, name .. ": " .. tostring(err)) end
        pending = pending - 1
      end)
    end
  end
  if not vim.wait(20 * 60 * 1000, function() return pending == 0 end, 500) then
    error("hết thời gian chờ Mason")
  end
end)

if #failed > 0 then
  io.write("\nLỗi:\n  " .. table.concat(failed, "\n  ") .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("quitall!")

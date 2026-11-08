-- Chạy setup thật với các biên plugin được giả lập; giữ nguyên exit code của Neovim.
vim.opt.rtp:prepend(vim.fn.getcwd())
local case = assert(arg[1])
package.loaded["nvim-treesitter"] = {
  install = function()
    return { wait = function()
      if case == "parser-exception" then error("parser task timeout") end
      return case ~= "parser-failure"
    end }
  end,
}
package.loaded.lazy = { load = function() end }
package.loaded["util.java"] = { TOOLS = { "jdtls" } }
package.loaded["util.lsp"] = { servers = { "lua_ls" } }
local refreshed = false
package.loaded["mason-lspconfig"] = { get_mappings = function()
  -- Registry chưa refresh thì máy mới chưa có mapping server -> package.
  return { lspconfig_to_package = refreshed and { lua_ls = "lua-language-server" } or {} }
end }
package.loaded["mason-registry"] = {
  refresh = function(callback)
    if case == "registry-timeout" then return end
    vim.schedule(function()
      refreshed = true
      callback(case ~= "registry-failure")
    end)
  end,
  get_package = function(name)
    return {
      is_installed = function() return case == "already-installed" end,
      install = function(_, _, callback)
        print("INSTALL: " .. name)
        if case == "mason-timeout" then return end
        vim.schedule(function() callback(case ~= "mason-failure", "mock installation failure") end)
      end,
    }
  end,
}
local wait = vim.wait
vim.wait = function(timeout, predicate, interval)
  if (case == "registry-timeout" and timeout == 120000)
    or (case == "mason-timeout" and timeout == 20 * 60 * 1000) then return false end
  return wait(timeout, predicate, interval)
end
dofile("scripts/setup.lua")

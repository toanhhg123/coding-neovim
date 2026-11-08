-- Default startup and leader mappings, without plugins or an iTerm keyboard profile.
vim.opt.rtp:prepend(vim.fn.getcwd())
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
temp = vim.uv.fs_realpath(temp)
local original_clients = vim.lsp.get_clients
local cases = {}
local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
end
local function startup(local_config)
  package.loaded["config.lazy"] = true
  package.loaded.lazy = { load = function() end }
  package.preload["config.local"] = local_config or function() return true end
  dofile("init.lua")
end
local function install_keys(spec)
  for _, key in ipairs(spec.keys or {}) do
    vim.keymap.set(key.mode or "n", key[1], key[2], { desc = key.desc })
  end
end

function cases.startup()
  startup()
  assert(not package.loaded["config.intellij"], "default startup loads Cmd mappings")
  for _, mode in ipairs({ "n", "i", "x", "c" }) do
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
      assert(not mapping.lhs:match("^<[MAD]%-"), "terminal modifier dependency: " .. mapping.lhs)
    end
  end
  feed("ihello world<Esc>")
  equal({ "hello world" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  equal("<C-g>w", require("plugins.coding")[1].opts.fast_wrap.map)
end

function cases.editing()
  startup()
  vim.o.clipboard = ""
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "abcdef" })
  feed("gg0vll<Space>cy<Esc>")
  equal({ "abcabcdef" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  feed("<Space>cy")
  equal({ "abcabcdef", "abcabcdef" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "cat one cat", "cat" })
  feed("gg0/cat<CR>n")
  equal({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
  feed("N")
  equal({ 1, 8 }, vim.api.nvim_win_get_cursor(0))
  feed("ggVG")
  equal("V", vim.fn.mode())
  feed("<Esc>")
end

function cases.navigation()
  startup()
  install_keys(require("plugins.navigation")[1])
  local action, opts
  vim.api.nvim_create_user_command("Telescope", function(args) action = args.args end, { nargs = "*" })
  package.loaded["telescope.builtin"] = {
    find_files = function() action = "files" end,
    lsp_dynamic_workspace_symbols = function(args) action, opts = "classes", args end,
  }
  vim.lsp.get_clients = function() return {} end
  feed("<Space>ft")
  equal("files", action)
  vim.lsp.get_clients = function() return { {} } end
  feed("<Space>ft")
  equal("classes", action)
  equal({ "class", "interface", "enum", "struct" }, opts.symbols)
  feed("<Space>fc")
  equal("commands", action)
  feed("<Space>fS")
  equal("lsp_dynamic_workspace_symbols", action)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "é中z" })
  vim.ui.input = function(_, callback) callback("2:2") end
  feed("<Space>fl")
  equal({ 2, 2 }, vim.api.nvim_win_get_cursor(0))
  assert(not package.loaded["config.intellij"])
end

function cases.recent()
  startup()
  install_keys(require("plugins.navigation")[1])
  for _, file in ipairs({ "first.txt", "closed.txt" }) do
    local path = temp .. "/" .. file
    vim.fn.writefile({ file }, path)
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
  local closed = vim.api.nvim_buf_get_name(0)
  vim.cmd.bdelete()
  assert(vim.tbl_contains(require("util.editor").recent_files(), closed))
  local called = false
  require("util.editor").recent_picker = function() called = true end
  feed("<Space>fo")
  assert(called and not package.loaded["config.intellij"])
end

function cases.lsp()
  startup()
  package.loaded.mason = { setup = function() end }
  package.loaded["mason-lspconfig"] = { setup = function() end }
  require("util.lsp").register = function() end
  local action, opts
  vim.lsp.buf.signature_help = function() action = "parameters" end
  vim.lsp.buf.code_action = function(args) action, opts = "generate", args end
  package.loaded["telescope.builtin"] = setmetatable({}, { __index = function(_, name)
    return function() action = name end
  end })
  package.loaded.jdtls = { super_implementation = function() action = "super-method" end }
  require("plugins.lsp")[2].config()
  vim.bo.filetype = "java"
  vim.api.nvim_exec_autocmds("LspAttach", { group = "lsp_attach_keymaps", buffer = 0 })
  feed("gS")
  equal("super-method", action)
  feed("gy")
  equal("lsp_type_definitions", action)
  feed("<Space>cp")
  equal("parameters", action)
  feed("<Space>cg")
  equal("generate", action)
  equal({ "source" }, opts.context.only)
  assert(not package.loaded["config.intellij"])
end

function cases.workflow()
  startup()
  install_keys(require("plugins.java")[1])
  install_keys(require("plugins.debug")[1])
  local actions = {}
  local function action(name) return function() table.insert(actions, name) end end
  package.loaded["util.spring"] = { run = action("run"), test_class = action("test-class"), test_method = action("test-method") }
  package.loaded["util.debug"] = { start = action("debug"), stop = action("stop") }
  package.loaded.dap = { toggle_breakpoint = action("breakpoint"), step_over = action("over"), step_into = action("into"), step_out = action("out") }
  feed("<Space>jr<Space>jt<Space>jn<Space>jD<Space>db<Space>dn<Space>di<Space>do<Space>jq")
  equal({ "run", "test-class", "test-method", "debug", "breakpoint", "over", "into", "out", "stop" }, actions)
  assert(not package.loaded["config.intellij"])
end

function cases.optional_cmd()
  startup(function() require("config.intellij") end)
  assert(package.loaded["config.intellij"])
  assert(next(vim.fn.maparg("<M-o>", "n", false, true)))
  assert(next(vim.fn.maparg("<Space>cy", "x", false, true)))
end

function cases.conflicts()
  local native = {}
  for _, mode in ipairs({ "n", "i", "x", "s", "t" }) do
    native[mode] = {}
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do native[mode][mapping.lhs] = mapping end
  end
  startup()
  local seen = {}
  local function add(mode, lhs)
    lhs = lhs:gsub("<leader>", vim.g.mapleader)
    lhs = vim.api.nvim_replace_termcodes(lhs, true, true, true)
    if mode == "v" then add("x", lhs); add("s", lhs); return end
    local key = mode .. ":" .. lhs
    assert(not seen[key], "duplicate keymap: " .. mode .. " " .. vim.fn.keytrans(lhs))
    seen[key] = true
  end
  for _, mode in ipairs({ "n", "i", "x", "s", "t" }) do
    for _, mapping in ipairs(vim.api.nvim_get_keymap(mode)) do
      -- Plugin có thể cố ý thay mặc định Neovim (vd Ctrl-l để đi giữa pane).
      if not vim.deep_equal(native[mode][mapping.lhs], mapping) then add(mode, mapping.lhs) end
    end
  end
  for _, file in ipairs(vim.fn.glob("lua/plugins/*.lua", false, true)) do
    for _, spec in ipairs(dofile(file)) do
      for _, key in ipairs(spec.keys or {}) do
        local modes = type(key.mode) == "table" and key.mode or { key.mode or "n" }
        for _, mode in ipairs(modes) do add(mode, key[1]) end
      end
    end
  end
end

local ok, err = xpcall(assert(cases[arg[1]], "unknown case"), debug.traceback)
vim.lsp.get_clients = original_clients
vim.fn.delete(temp, "rf")
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
print("PASS: " .. arg[1])

vim.opt.rtp:prepend(vim.fn.getcwd())
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
temp = vim.uv.fs_realpath(temp)
local original_clients = vim.lsp.get_clients
local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
  vim.wait(10, function() return false end) -- flush scheduled Insert -> Normal actions
end
local function lines(text)
  feed("<Esc>")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end
local function write(path)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ path }, path)
end
local cases = {}

function cases.modes()
  require("config.intellij")
  for _, key in ipairs({ "<M-f>", "<M-o>", "<M-e>", "<M-a>", "<M-A>", "<M-B>", "<M-g>", "<M-G>", "<M-l>", "<M-1>", "<M-L>", "<S-F6>", "<S-F10>", "<S-F9>", "<M-q>" }) do
    for _, mode in ipairs({ "n", "i" }) do
      assert(next(vim.fn.maparg(key, mode, false, true)), mode .. " mapping missing: " .. key)
    end
  end
  local called = false
  package.loaded["telescope.builtin"] = { find_files = function()
    called = true
    equal("n", vim.fn.mode())
  end }
  feed("i<M-O>")
  assert(called, "Insert Cmd+Shift+O did not open file picker")
  lines({ "one", "two" })
  feed("i<M-a>")
  equal("V", vim.fn.mode())
  equal({ "one", "two" }, vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = "V" }))
  local coding = require("plugins.coding")[1].opts
  assert(coding.fast_wrap.map and coding.fast_wrap.map ~= "<M-e>", "fast-wrap steals Cmd+E")
  called = false
  require("util.intellij").recent_picker = function() called = true end
  -- Reload config so the mapping points at the spy; plugin config keeps its own key.
  package.loaded["config.intellij"] = nil
  require("config.intellij")
  feed("<Esc>i<M-e>")
  assert(called, "Insert Cmd+E did not open recent files")
end

function cases.duplicate()
  require("config.intellij")
  vim.o.clipboard = ""
  vim.fn.setreg("a", "clipboard sentinel")
  vim.fn.setreg("z", "temporary register sentinel")
  vim.fn.setreg('"', { points_to = "a" })
  local unnamed, saved = vim.fn.getreginfo('"'), vim.fn.getreginfo("z")
  local scenarios = {
    { { "abcdef" }, "gg0vll", { "abcabcdef" } },
    { { "abcdef" }, "gg0llvhh", { "abcabcdef" } },
    { { "aé中z" }, "gg0lvl", { "aé中é中z" } },
    { { "abcd", "efgh" }, "gg0lvjl", { "abcd", "efgbcd", "efgh" } },
    { { "abcd", "efgh" }, "ggVj", { "abcd", "efgh", "abcd", "efgh" } },
    { { "abcd", "efgh" }, "gg0l<C-v>jl", { "abcbcd", "efgfgh" } },
  }
  for _, scenario in ipairs(scenarios) do
    lines(scenario[1])
    feed(scenario[2] .. "<M-d><Esc>")
    equal(scenario[3], vim.api.nvim_buf_get_lines(0, 0, -1, false))
    equal(unnamed, vim.fn.getreginfo('"'))
    equal(saved, vim.fn.getreginfo("z"))
  end
  vim.o.selection = "exclusive"
  lines({ "abcdef" })
  feed("gg0vlll<M-d><Esc>")
  equal({ "abcabcdef" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

function cases.recent()
  require("config.intellij")
  local root = temp .. "/project"
  vim.fn.mkdir(root .. "/.git", "p")
  local current, closed, open, historical = root .. "/current", root .. "/closed", root .. "/open", root .. "/historical"
  local outside = temp .. "/other/file"
  for _, path in ipairs({ current, closed, open, historical, outside }) do write(path) end
  for _, path in ipairs({ current, open, closed }) do vim.cmd.edit(vim.fn.fnameescape(path)) end
  vim.cmd.bdelete()
  vim.cmd.edit(vim.fn.fnameescape(outside))
  vim.cmd.edit(vim.fn.fnameescape(current))
  vim.v.oldfiles = { closed, historical, outside, root .. "/missing", "term://ignore" }
  local files = require("util.intellij").recent_files()
  equal(4, #files)
  equal(open, files[1]) -- bdelete quay về buffer open, nên open vừa được dùng sau closed
  assert(vim.tbl_contains(files, closed), "recently closed file disappeared")
  equal(outside, files[#files])
  assert(vim.tbl_contains(files, open) and vim.tbl_contains(files, historical))
  local captured
  package.loaded["telescope.config"] = { values = { generic_sorter = function() end, file_previewer = function() end } }
  package.loaded["telescope.finders"] = { new_table = function(opts) captured = opts.results end }
  package.loaded["telescope.make_entry"] = { gen_from_file = function() end }
  package.loaded["telescope.pickers"] = { new = function() return { find = function() end } end }
  vim.fn.maparg("<M-e>", "n", false, true).callback()
  equal(files, captured)
end

function cases.search_and_line()
  require("config.intellij")
  lines({ "cat one cat", "cat", "é中z" })
  feed("gg0<M-f>cat<CR><M-g>")
  equal({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
  feed("<M-G>")
  equal({ 1, 8 }, vim.api.nvim_win_get_cursor(0))
  vim.ui.input = function(_, callback) callback("3:2") end
  feed("i<M-l>")
  equal({ 3, 2 }, vim.api.nvim_win_get_cursor(0)) -- column 2 is 中 (byte offset 2)
  vim.ui.input = function(_, callback) callback("999:1") end
  vim.notify = function() end
  feed("<M-l>")
  equal({ 3, 2 }, vim.api.nvim_win_get_cursor(0))
end

function cases.lsp_and_actions()
  require("config.intellij")
  local action
  vim.lsp.get_clients = function() return { {} } end
  package.loaded.jdtls = { super_implementation = function() action = "super-method" end }
  package.loaded["telescope.builtin"] = {
    commands = function() action = "commands" end,
    lsp_type_definitions = function() action = "type-definition" end,
  }
  vim.bo.filetype = "java"
  feed("<M-u>")
  equal("super-method", action)
  feed("i<M-B>")
  equal("type-definition", action)
  feed("i<M-A>")
  equal("commands", action)
  local warned = false
  vim.lsp.get_clients = function() return {} end
  vim.notify = function() warned = true end
  action = nil
  feed("i<M-B>")
  assert(warned and action == nil, "missing-LSP guard was bypassed")
end

function cases.workflow_shortcuts()
  require("config.intellij")
  local actions = {}
  package.loaded["util.debug"] = {
    start = function() table.insert(actions, "debug") end,
    stop = function() table.insert(actions, "stop") end,
  }
  package.loaded["util.spring"] = { run = function() table.insert(actions, "run") end }
  feed("<S-F9><M-q><S-F10>")
  feed("i<S-F9>")
  feed("i<M-q>")
  equal({ "debug", "stop", "run", "debug", "stop" }, actions)
  -- Các entry point Space phải dùng cùng bộ điều phối với phím IntelliJ.
  for _, spec in ipairs({ require("plugins.java")[1], require("plugins.debug")[1] }) do
    for _, key in ipairs(spec.keys) do
      if key[1] == "<leader>jD" or key[1] == "<leader>jq" or key[1] == "<leader>dq" then key[2]() end
    end
  end
  equal({ "debug", "stop", "run", "debug", "stop", "debug", "stop", "stop" }, actions)
end

function cases.profile()
  require("config.intellij")
  local profile = vim.json.decode(table.concat(vim.fn.readfile("iterm/coding-neovim.json"), "\n"))
  local routes = {
    ["0x61-0x120000"] = "A", ["0x41-0x120000"] = "A",
    ["0x62-0x120000"] = "B", ["0x42-0x120000"] = "B",
    ["0x67-0x100000"] = "g", ["0x67-0x120000"] = "G", ["0x47-0x120000"] = "G",
    ["0x6c-0x100000"] = "l",
  }
  for key, char in pairs(routes) do
    local mapping = assert(profile.Profiles[1]["Keyboard Map"][key], "iTerm route missing: " .. key)
    equal(11, mapping.Action)
    local bytes = {}
    for hex in mapping.Text:gmatch("0x(%x+)") do table.insert(bytes, string.char(tonumber(hex, 16))) end
    equal("\27" .. char, table.concat(bytes))
    for _, mode in ipairs({ "n", "i" }) do
      assert(next(vim.fn.maparg("<M-" .. char .. ">", mode, false, true)), "unmapped iTerm output: " .. char)
    end
  end
  local wrap = profile.Profiles[1]["Keyboard Map"]["0x76-0x80000"]
  equal({ Action = 11, Text = "0x07 0x77" }, wrap)
  equal("<C-g>w", require("plugins.coding")[1].opts.fast_wrap.map)
end

local ok, err = xpcall(assert(cases[arg[1]], "unknown case"), debug.traceback)
vim.lsp.get_clients = original_clients
vim.fn.delete(temp, "rf")
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
print("PASS: " .. arg[1])

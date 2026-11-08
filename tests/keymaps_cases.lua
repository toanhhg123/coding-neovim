vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local cases = {}
local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local function canonical(lhs) return vim.api.nvim_replace_termcodes(lhs, true, true, true) end
local function feed(keys) vim.api.nvim_feedkeys(canonical(keys), "xt", false) end
local function flush()
  vim.wait(20, function() return false end)
  feed("")
end
local function origin() return { win = vim.api.nvim_get_current_win(), buf = vim.api.nvim_get_current_buf() } end
local function lookup(entries, mode, lhs)
  local result, count
  count = 0
  for _, entry in ipairs(entries) do
    if entry.mode == mode and canonical(entry.lhs) == canonical(lhs) then result, count = entry, count + 1 end
  end
  equal(1, count)
  return result
end

function cases.entries()
  local help = require("util.keymaps")
  vim.keymap.set("n", "<leader>jn", function() end, { desc = "Test: method dưới con trỏ" })
  vim.keymap.set("n", "<leader>db", function() end, { desc = "Breakpoint" })
  vim.keymap.set("n", "<leader>rn", function() end, { desc = "Đổi tên symbol" })
  vim.keymap.set("n", "<Plug>(private)", function() end, { desc = "Internal action" })
  local entries = help.collect()
  local method = help.entry(lookup(entries, "n", "<leader>jn"))
  assert(method.display:find("Space j n", 1, true), method.display)
  assert(method.display:find("[Java / Spring]", 1, true))
  assert(method.display:find("[Normal]", 1, true))
  assert(help.entry(lookup(entries, "n", "<leader>db")).ordinal:find("debug", 1, true))
  assert(help.entry(lookup(entries, "n", "<leader>rn")).ordinal:find("doi ten", 1, true))
  for _, entry in ipairs(entries) do assert(not entry.lhs:match("^<Plug>")) end
end

function cases.reference()
  local help = require("util.keymaps")
  local entries = help.collect()
  local wanted = {
    { "n", "<C-w>v", "split" }, { "n", "<C-w>s", "split" },
    { "n", "<C-w>h", "chuyen o" }, { "n", "<C-w>j", "chuyen o" },
    { "n", "<C-w>k", "chuyen o" }, { "n", "<C-w>l", "chuyen o" },
    { "n", "<C-w>q", "dong o" }, { "n", "<C-w>c", "dong o" },
    { "n", "<C-w>=", "resize" }, { "n", "<C-w>+", "resize" },
    { "n", "yyp", "duplicate" }, { "n", "ggVG", "select all" },
    { "n", "gg", "file" }, { "n", "u", "undo" }, { "n", ":wa<CR>", "save all" },
    { "n", "gt", "tab" }, { "n", "za", "fold" }, { "n", ":cnext<CR>", "quickfix" },
    { "i", "<C-x><C-f>", "completion" }, { "x", "iw", "word" },
    { "o", "i{", "braces" }, { "c", "<C-b>", "beginning" },
    { "t", "<C-\\><C-n>", "terminal" },
  }
  for _, item in ipairs(wanted) do
    local row = help.entry(lookup(entries, item[1], item[2]))
    assert(row.ordinal:lower():find(item[3], 1, true), row.ordinal)
  end
  local seen = {}
  for _, entry in ipairs(require("config.keymap_reference")) do
    local key = entry.mode .. ":" .. canonical(entry.lhs)
    assert(not seen[key], "duplicate reference: " .. key)
    seen[key] = true
  end
end

function cases.buffer_override()
  local help = require("util.keymaps")
  vim.keymap.set("n", "K", function() end, { desc = "Global hover" })
  vim.keymap.set("n", "K", function() end, { buffer = 0, desc = "Java hover" })
  local called = false
  vim.keymap.set("n", "u", function() called = true end) -- override sans desc must still hide native undo
  local entries = help.collect()
  equal("Java hover", lookup(entries, "n", "K").desc)
  equal("Buffer", lookup(entries, "n", "K").source)
  local override = lookup(entries, "n", "u")
  equal("Config", override.source)
  assert(override.desc ~= "Hoàn tác")
  assert(help.execute(override, origin()))
  feed("")
  assert(called)
end

function cases.modes()
  local help = require("util.keymaps")
  local mappings = {
    { "i", "<C-g>w" }, { "x", "<leader>cy" }, { "o", "af" },
    { "c", "<C-r>" }, { "t", "<Esc><Esc>" }, { "s", "<F6>" }, { "l", "ñ" },
  }
  local called, messages = false, {}
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unchanged" })
  for _, mapping in ipairs(mappings) do
    vim.keymap.set(mapping[1], mapping[2], function() called = true end, { desc = "Mode regression " .. mapping[1] })
  end
  vim.notify = function(message) table.insert(messages, message) end
  local entries = help.collect()
  for _, mapping in ipairs(mappings) do
    local entry = lookup(entries, mapping[1], mapping[2])
    assert(help.entry(entry).display:find("Mode regression", 1, true))
    equal(false, help.execute(entry, origin()))
    feed("")
  end
  equal(#mappings, #messages)
  assert(not called, "non-Normal mapping was executed as Normal keys")
  equal({ "unchanged" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  equal(false, help.execute(lookup(entries, "n", "f"), origin())) -- incomplete command needs an argument
end

function cases.windows()
  local help = require("util.keymaps")
  local function run(lhs)
    assert(help.execute(lookup(help.collect(), "n", lhs), origin()))
    feed("")
  end
  run("<C-w>v")
  equal(2, #vim.api.nvim_list_wins())
  local wins = vim.api.nvim_list_wins()
  assert(vim.api.nvim_win_get_position(wins[1])[2] ~= vim.api.nvim_win_get_position(wins[2])[2])
  run("<C-w>h")
  local left = vim.api.nvim_get_current_win()
  run("<C-w>l")
  assert(left ~= vim.api.nvim_get_current_win())
  run("<C-w>s")
  equal(3, #vim.api.nvim_list_wins())
  run("<C-w>j")
  local bottom = vim.api.nvim_get_current_win()
  run("<C-w>k")
  assert(bottom ~= vim.api.nvim_get_current_win())
  run("<C-w>=")
  local height = vim.api.nvim_win_get_height(0)
  run("<C-w>+")
  assert(vim.api.nvim_win_get_height(0) > height)
  run("<C-w>c")
  equal(2, #vim.api.nvim_list_wins())
  run("<C-w>q")
  equal(1, #vim.api.nvim_list_wins())
  run("<C-w>v")
  run("<C-w>o")
  equal(1, #vim.api.nvim_list_wins())
end

function cases.stale_origin()
  local help = require("util.keymaps")
  vim.cmd.vsplit()
  local closed = origin()
  vim.api.nvim_win_close(closed.win, true)
  local warned = false
  vim.notify = function() warned = true end
  equal(false, help.execute(lookup(help.collect(), "n", "<C-w>v"), closed))
  feed("")
  assert(warned)
  equal(1, #vim.api.nvim_list_wins())
  local changed = origin()
  vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(true, false))
  equal(false, help.execute(lookup(help.collect(), "n", "<C-w>v"), changed))
  feed("")
  equal(1, #vim.api.nvim_list_wins())
end

function cases.entry_points()
  local calls = {}
  local help = require("util.keymaps")
  help.show = function(query) table.insert(calls, query or "") end
  local navigation = require("plugins.navigation")[1]
  local keys = {}
  for _, key in ipairs(navigation.keys) do
    keys[key[1]] = true
    vim.keymap.set(key.mode or "n", key[1], key[2], { desc = key.desc })
  end
  assert(keys["<leader>?"] and keys["<leader>fk"])
  feed("<Space>?<Space>fk")
  equal({ "", "" }, calls)
  local buffer_help
  package.loaded["which-key"] = { show = function(opts) buffer_help = opts end }
  for _, key in ipairs(require("plugins.ui")[1].keys) do
    assert(key[1] ~= "<leader>?", "which-key steals the searchable help shortcut")
    if key[1] == "<leader>f?" then key[2]() end
  end
  equal({ global = false }, buffer_help)
  package.loaded.telescope = { setup = function() end, load_extension = function() end }
  navigation.config(nil, {})
  vim.cmd("Keymaps split")
  equal("split", calls[#calls])
  vim.cmd("Keymaps")
  equal("", calls[#calls])
  assert(vim.tbl_contains(navigation.cmd, "Keymaps"))
end

local function real_picker(query)
  local lazy = vim.fn.stdpath("data") .. "/lazy/"
  for _, plugin in ipairs({ "plenary.nvim", "telescope.nvim" }) do
    assert(vim.uv.fs_stat(lazy .. plugin), "missing integration dependency: " .. plugin)
    vim.opt.rtp:prepend(lazy .. plugin)
  end
  require("telescope").setup({ defaults = { initial_mode = "insert", sorting_strategy = "ascending" } })
  require("util.keymaps").show(query)
  local picker = require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
  assert(vim.wait(2000, function()
    return picker.manager and picker.manager:num_results() > 0
      and require("telescope.actions.state").get_selected_entry() ~= nil
  end, 10), "picker did not produce a selection")
  return require("telescope.actions.state").get_selected_entry()
end

function cases.picker()
  local global, local_action = false, false
  local original = origin()
  vim.keymap.set("n", "<leader>zz", function() global = true end, { desc = "Global regression action" })
  vim.keymap.set("n", "<leader>zz", function()
    equal(original.buf, vim.api.nvim_get_current_buf())
    equal("n", vim.fn.mode())
    local_action = true
  end, { buffer = original.buf, desc = "keymap-regression-spy" })
  local selected = real_picker("keymap-regression-spy")
  assert(selected.display:find("Space z z", 1, true))
  feed("<CR>")
  flush()
  assert(local_action and not global)
end

function cases.picker_split()
  local selected = real_picker("vertical vsplit")
  equal(canonical("<C-w>v"), canonical(selected.value.lhs))
  feed("<CR>")
  flush()
  equal(2, #vim.api.nvim_list_wins())
end

function cases.picker_guide()
  local called, message = false, nil
  vim.keymap.set("x", "<leader>zx", function() called = true end, { desc = "visual-regression-spy" })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unchanged" })
  local selected = real_picker("visual-regression-spy")
  assert(selected.display:find("[Visual]", 1, true))
  vim.notify = function(text) message = text end
  feed("<CR>")
  flush()
  assert(not called and message:find("Chọn vùng", 1, true))
  equal({ "unchanged" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
end

local ok, err = xpcall(assert(cases[arg[1]], "unknown case"), debug.traceback)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
print("PASS: " .. arg[1])

vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local cases = {}
local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
end

function cases.entries()
  local opts
  package.loaded["telescope.builtin"] = { keymaps = function(args) opts = args end }
  vim.keymap.set("n", "<leader>jn", function() end, { desc = "Test: method dưới con trỏ" })
  vim.keymap.set("n", "<leader>db", function() end, { desc = "Breakpoint" })
  vim.keymap.set("n", "<leader>rn", function() end, { desc = "Đổi tên symbol" })
  require("util.keymaps").show("test")
  equal({ "n" }, opts.modes)
  equal(false, opts.show_plug)
  equal("test", opts.default_text)
  local method = opts.entry_maker(vim.fn.maparg("<leader>jn", "n", false, true))
  assert(method.display:find("Space j n", 1, true), method.display)
  assert(method.display:find("[Java / Spring]", 1, true), method.display)
  -- get_keymap dùng Space thật, maparg có thể trả ký hiệu <Space>.
  for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do
    if mapping.desc == "Test: method dưới con trỏ" then
      assert(opts.entry_maker(mapping).display:find("Space j n", 1, true))
      assert(opts.entry_maker(mapping).display:find("[Java / Spring]", 1, true))
    end
  end
  local breakpoint = opts.entry_maker(vim.fn.maparg("<leader>db", "n", false, true))
  assert(breakpoint.ordinal:find("debug", 1, true))
  local rename = opts.entry_maker(vim.fn.maparg("<leader>rn", "n", false, true))
  assert(rename.ordinal:find("doi ten", 1, true), rename.ordinal)
  assert(not opts.filter({ lhs = "x", buffer = 0 }))
  assert(not opts.filter({ lhs = "x", buffer = 0, desc = "" }))
end

function cases.buffer_override()
  local opts
  package.loaded["telescope.builtin"] = { keymaps = function(args) opts = args end }
  vim.keymap.set("n", "K", function() end, { desc = "Global hover" })
  vim.keymap.set("n", "K", function() end, { buffer = 0, desc = "Java hover" })
  require("util.keymaps").show()
  equal("", opts.default_text)
  local matches = {}
  for _, source in ipairs({ vim.api.nvim_get_keymap("n"), vim.api.nvim_buf_get_keymap(0, "n") }) do
    for _, mapping in ipairs(source) do
      if mapping.lhs == "K" and opts.filter(mapping) then table.insert(matches, opts.entry_maker(mapping).display) end
    end
  end
  equal(1, #matches)
  assert(matches[1]:find("Java hover", 1, true))
end

function cases.entry_points()
  local calls = {}
  package.loaded["util.keymaps"] = {
    show = function(query) table.insert(calls, query or "") end,
    setup = function() error("spy must be replaced before plugin config") end,
  }
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
  package.loaded["util.keymaps"] = nil
  package.loaded.telescope = { setup = function() end, load_extension = function() end }
  package.loaded["telescope.builtin"] = { keymaps = function(opts) table.insert(calls, opts.default_text) end }
  navigation.config(nil, {})
  vim.cmd("Keymaps import")
  equal("import", calls[#calls])
  vim.cmd("Keymaps")
  equal("", calls[#calls])
  assert(vim.tbl_contains(navigation.cmd, "Keymaps"), "command does not lazy-load Telescope")
end

function cases.picker()
  -- Integration with installed Telescope: no user config, network or plugin installation.
  local lazy = vim.fn.stdpath("data") .. "/lazy/"
  for _, plugin in ipairs({ "plenary.nvim", "telescope.nvim" }) do
    assert(vim.uv.fs_stat(lazy .. plugin), "missing integration dependency: " .. plugin)
    vim.opt.rtp:prepend(lazy .. plugin)
  end
  require("telescope").setup({ defaults = { initial_mode = "insert", sorting_strategy = "ascending" } })
  local global, local_action = false, false
  local origin = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "<leader>zz", function() global = true end, { desc = "Global regression action" })
  vim.keymap.set("n", "<leader>zz", function()
    equal(origin, vim.api.nvim_get_current_buf())
    equal("n", vim.fn.mode())
    local_action = true
  end, { buffer = origin, desc = "keymap-regression-spy" })
  require("util.keymaps").show("keymap-regression-spy")
  local prompt = vim.api.nvim_get_current_buf()
  local picker = require("telescope.actions.state").get_current_picker(prompt)
  assert(vim.wait(2000, function() return picker.manager and picker.manager:num_results() == 1 end, 10), "picker did not filter the entry")
  assert(require("telescope.actions.state").get_selected_entry().display:find("Space z z", 1, true))
  feed("<CR>") -- đi qua Insert mode của prompt như người dùng bấm Enter thật
  assert(local_action and not global, "Enter did not execute the effective buffer-local mapping")
end

local ok, err = xpcall(assert(cases[arg[1]], "unknown case"), debug.traceback)
if not ok then io.stderr:write(err .. "\n"); vim.cmd("cquit 1") end
print("PASS: " .. arg[1])

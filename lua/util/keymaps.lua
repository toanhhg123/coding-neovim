-- Ghép lệnh Vim gốc với mapping hiệu lực trong buffer ở mọi mode.
local M = {}

local modes = { "n", "i", "x", "s", "o", "c", "t", "l" }
local mode_names = { n = "Normal", i = "Insert", x = "Visual", s = "Select", o = "Operator", c = "Command", t = "Terminal", l = "Language" }
local instructions = {
  i = "Vào Insert bằng i rồi bấm", x = "Chọn vùng bằng v/V/Ctrl-v rồi bấm",
  s = "Trong Select mode, bấm", o = "Sau toán tử d/c/y, bấm",
  c = "Trong dòng lệnh : hoặc tìm kiếm /, bấm", t = "Trong terminal đang nhập, bấm",
  l = "Trong ngữ cảnh nhập ký tự của language mapping, bấm",
}

local groups = {
  f = "Find / Search", s = "Search / Replace", j = "Java / Spring", d = "Debug",
  c = "Code / LSP", r = "Rename / Refactor", g = "Git", b = "Buffer",
  t = "Terminal", D = "Database", h = "HTTP", m = "Markdown",
}

local accents = {}
for plain, letters in pairs({
  a = "àáảãạăằắẳẵặâầấẩẫậ", e = "èéẻẽẹêềếểễệ", i = "ìíỉĩị",
  o = "òóỏõọôồốổỗộơờớởỡợ", u = "ùúủũụưừứửữự", y = "ỳýỷỹỵ", d = "đ",
}) do
  for _, letter in ipairs(vim.fn.split(letters, "\\zs")) do accents[letter] = plain end
end

local function searchable(text)
  return vim.fn.tolower(text):gsub("[\194-\244][\128-\191]*", function(char) return accents[char] or char end)
end

local function canonical(lhs)
  return vim.api.nvim_replace_termcodes(lhs, true, true, true)
end

local function readable(text)
  return vim.trim((text:gsub("<C%-([^>]+)>", function(key)
    return "Ctrl-" .. (#key == 1 and key:lower() or key) .. " "
  end):gsub("<CR>", "Enter"):gsub("<Esc>", "Esc"):gsub("<Space>", "Space")))
end

local function label(lhs, mode)
  local leader = canonical(vim.g.mapleader or "\\")
  local prefix = lhs:sub(1, #leader) == leader and leader or vim.fn.keytrans(leader)
  if lhs:sub(1, #prefix) ~= prefix then
    local group = ({ i = "Insert / Completion", x = "Visual / Selection", s = "Visual / Selection", o = "Text Objects", c = "Command Line", t = "Terminal" })[mode] or "Editor"
    local raw = canonical(lhs)
    if mode == "n" and (raw:sub(1, 1) == canonical("<C-w>") or vim.tbl_contains({ canonical("<C-h>"), canonical("<C-j>"), canonical("<C-k>"), canonical("<C-l>") }, raw)) then
      group = "Window / Split"
    end
    return readable(lhs), group
  end
  local suffix, tokens = lhs:sub(#prefix + 1), { leader == " " and "Space" or vim.fn.keytrans(leader) }
  local group = groups[suffix:sub(1, 1)] or "Editor"
  while suffix ~= "" do
    local token = suffix:match("^<[^>]+>") or vim.fn.strcharpart(suffix, 0, 1)
    table.insert(tokens, (token == "<Space>" or token == " ") and "Space" or token)
    suffix = suffix:sub(#token + 1)
  end
  return readable(table.concat(tokens, " ")), group
end

function M.collect(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local effective = {}
  local function id(mode, lhs) return mode .. ":" .. canonical(lhs) end
  -- Không bỏ mapping thiếu desc: chúng vẫn che lệnh Vim gốc bên dưới.
  for _, mode in ipairs(modes) do
    for _, source in ipairs({ vim.api.nvim_get_keymap(mode), vim.api.nvim_buf_get_keymap(buf, mode) }) do
      for _, mapping in ipairs(source) do
        local desc = mapping.desc
        if not desc or desc == "" then desc = "Phím cấu hình chưa có mô tả" end
        local _, group = label(mapping.lhs, mode)
        effective[id(mode, mapping.lhs)] = {
          mode = mode, lhs = mapping.lhs, desc = desc, group = group,
          source = mapping.buffer ~= 0 and "Buffer" or "Config",
        }
      end
    end
  end
  for _, entry in ipairs(require("config.keymap_reference")) do
    local key = id(entry.mode, entry.lhs)
    if not effective[key] then effective[key] = vim.tbl_extend("force", entry, { source = "Vim" }) end
  end
  local result = {}
  for _, entry in pairs(effective) do
    if not entry.lhs:match("^<Plug>") and not entry.lhs:match("^<SNR>") then result[#result + 1] = entry end
  end
  local rank = {}
  for i, mode in ipairs(modes) do rank[mode] = i end
  table.sort(result, function(a, b)
    if a.mode ~= b.mode then return rank[a.mode] < rank[b.mode] end
    if a.group ~= b.group then return a.group < b.group end
    return a.lhs < b.lhs
  end)
  return result
end

function M.entry(entry)
  local keys = label(entry.lhs, entry.mode)
  local description = entry.desc:gsub("[\r\n]", " ")
  if entry.mode ~= "n" or entry.guide then description = description .. " (hướng dẫn)" end
  local text = string.format("[%s] %s  [%s] %s", mode_names[entry.mode], keys, entry.group, description)
  local search = text .. " " .. (entry.keywords or "") .. " " .. (entry.guide or "")
  return { value = entry, display = text, ordinal = search .. " " .. searchable(search) }
end

function M.execute(entry, origin)
  if not vim.api.nvim_win_is_valid(origin.win) or vim.api.nvim_win_get_buf(origin.win) ~= origin.buf then
    vim.notify("Ô hoặc buffer gốc đã đổi; mở lại bảng tra keymap", vim.log.levels.WARN)
    return false
  end
  vim.api.nvim_set_current_win(origin.win)
  if entry.mode ~= "n" or entry.guide then
    local keys = label(entry.lhs, entry.mode)
    vim.notify(entry.guide or (instructions[entry.mode] .. ": " .. keys), vim.log.levels.INFO, { title = mode_names[entry.mode] })
    return false
  end
  -- Phát lại lhs thay vì gọi callback: tôn trọng lazy-load và mapping hiện tại.
  vim.api.nvim_feedkeys(canonical(entry.lhs), "mt", false)
  return true
end

function M.show(query)
  local origin = { win = vim.api.nvim_get_current_win(), buf = vim.api.nvim_get_current_buf() }
  local entries = M.collect(origin.buf)
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local opts = { default_text = query or "" }
  require("telescope.pickers").new(opts, {
    prompt_title = "Keymaps — split / visual / test / import",
    results_title = "Enter: chạy / hướng dẫn theo mode · Esc: đóng",
    finder = require("telescope.finders").new_table({ results = entries, entry_maker = M.entry }),
    sorter = require("telescope.config").values.generic_sorter(opts),
    attach_mappings = function(prompt)
      actions.select_default:replace(function()
        local selection = state.get_selected_entry()
        if not selection then return end
        actions.close(prompt)
        vim.cmd.stopinsert()
        vim.schedule(function() M.execute(selection.value, origin) end)
      end)
      return true
    end,
  }):find()
end

function M.setup()
  vim.api.nvim_create_user_command("Keymaps", function(opts) M.show(opts.args) end, {
    nargs = "*", desc = "Tra phím Vim + cấu hình mọi mode, vd :Keymaps split",
  })
end

return M

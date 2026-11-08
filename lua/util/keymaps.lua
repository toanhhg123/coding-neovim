-- Tra các phím Normal đang có hiệu lực, dùng luôn picker và hành động của Telescope.
local M = {}

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

local function label(lhs)
  local leader = canonical(vim.g.mapleader or "\\")
  local prefix = lhs:sub(1, #leader) == leader and leader or vim.fn.keytrans(leader)
  if lhs:sub(1, #prefix) ~= prefix then return lhs, "Editor" end
  local suffix, tokens = lhs:sub(#prefix + 1), { leader == " " and "Space" or vim.fn.keytrans(leader) }
  local group = groups[suffix:sub(1, 1)] or "Editor"
  while suffix ~= "" do
    local token = suffix:match("^<[^>]+>") or vim.fn.strcharpart(suffix, 0, 1)
    table.insert(tokens, (token == "<Space>" or token == " ") and "Space" or token)
    suffix = suffix:sub(#token + 1)
  end
  return table.concat(tokens, " "), group
end

function M.show(query)
  -- Buffer-local thắng global: bảng tra phải trùng hành động thực sự khi bấm phím.
  local local_keys = {}
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do local_keys[canonical(mapping.lhs)] = true end
  require("telescope.builtin").keymaps({
    modes = { "n" },
    show_plug = false,
    default_text = query or "",
    prompt_title = "Keymaps — gõ debug / test / import",
    results_title = "Normal mode · Enter chạy · Esc đóng",
    filter = function(mapping)
      return type(mapping.desc) == "string" and mapping.desc ~= ""
        and (mapping.buffer ~= 0 or not local_keys[canonical(mapping.lhs)])
    end,
    entry_maker = function(mapping)
      local keys, group = label(mapping.lhs)
      local description = mapping.desc:gsub("[\r\n]", " ")
      local text = keys .. "  [" .. group .. "]  " .. description
      return {
        value = mapping, -- Telescope phát lại lhs để lazy-load và buffer-local hoạt động đúng.
        display = text,
        ordinal = text .. " " .. searchable(text), -- tìm được cả "doi ten" lẫn "đổi tên"
      }
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("Keymaps", function(opts) M.show(opts.args) end, {
    nargs = "*", desc = "Tra keymap theo phím hoặc hành động, vd :Keymaps debug",
  })
end

return M

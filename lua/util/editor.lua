-- Hành vi editor dùng chung cho phím Vim và bộ IntelliJ tùy chọn.
local M = {}
local recent, clock = {}, 0

local function file_path(path)
  if path == "" or path:match("^%a+://") then return nil end
  return vim.uv.fs_realpath(path) or vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function remember(buf)
  if vim.bo[buf].buftype ~= "" then return end
  local path = file_path(vim.api.nvim_buf_get_name(buf))
  if path then
    clock = clock + 1
    recent[path] = clock
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
    group = vim.api.nvim_create_augroup("editor_recent_files", { clear = true }),
    callback = function(ev) remember(ev.buf) end,
  })
  remember(vim.api.nvim_get_current_buf())
end

function M.recent_files()
  local current = file_path(vim.api.nvim_buf_get_name(0))
  local root = vim.fs.root(0, { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", "package.json" })
    or vim.fn.getcwd()
  root = file_path(root)
  local candidates, seen = {}, {}
  local function add(path, rank, loaded)
    path = file_path(path)
    if not path or path == current or seen[path] or (not loaded and vim.fn.filereadable(path) == 0) then return end
    seen[path] = true
    table.insert(candidates, { path = path, rank = rank, project = path:sub(1, #root + 1) == root .. "/" })
  end
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(buffers, function(a, b) return a.lastused > b.lastused end)
  for _, buf in ipairs(buffers) do
    if vim.bo[buf.bufnr].buftype == "" then add(buf.name, recent[file_path(buf.name)] or -1, true) end
  end
  for path, rank in pairs(recent) do add(path, rank) end
  for i, path in ipairs(vim.v.oldfiles) do add(path, -i - 1) end
  table.sort(candidates, function(a, b)
    if a.project ~= b.project then return a.project end
    if a.rank ~= b.rank then return a.rank > b.rank end
    return a.path < b.path
  end)
  return vim.tbl_map(function(item) return item.path end, candidates), root
end

function M.recent_picker()
  local paths, root = M.recent_files()
  local opts = { cwd = root }
  local conf = require("telescope.config").values
  require("telescope.pickers").new(opts, {
    prompt_title = "Recent Files",
    finder = require("telescope.finders").new_table({
      results = paths,
      entry_maker = require("telescope.make_entry").gen_from_file(opts),
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
  }):find()
end

function M.class_picker()
  local telescope = require("telescope.builtin")
  if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then return telescope.find_files() end
  telescope.lsp_dynamic_workspace_symbols({ symbols = { "class", "interface", "enum", "struct" } })
end

-- Native yank/put giữ đúng charwise, linewise, blockwise và ký tự UTF-8.
-- Dùng register tạm rồi khôi phục, không làm đổi clipboard của người dùng.
function M.duplicate_selection()
  local mode = vim.fn.mode()
  local saved, unnamed = vim.fn.getreginfo("z"), vim.fn.getreginfo('"')
  vim.cmd.normal({ '"zy', bang = true })
  if mode == "\22" then
    local first, last = vim.fn.getpos("'["), vim.fn.getpos("']")
    vim.api.nvim_win_set_cursor(0, { first[2], math.max(0, last[3] - 1) })
  else
    vim.cmd.normal({ "`]", bang = true })
  end
  vim.cmd.normal({ '"zp', bang = true })
  local select = mode == "V" and "'[V']" or (mode == "\22" and "`[\22`]" or "`[v`]")
  vim.cmd.normal({ select, bang = true })
  vim.fn.setreg("z", saved)
  vim.fn.setreg('"', unnamed)
end

function M.go_to_line()
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  vim.ui.input({ prompt = "Line[:column]: " }, function(value)
    if not value then return end
    local row, col = value:match("^%s*(%d+):?(%d*)%s*$")
    row, col = tonumber(row), tonumber(col) or 1
    if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then return end
    if not row or row < 1 or row > vim.api.nvim_buf_line_count(buf) or col < 1 then
      return vim.notify("Dòng/cột không hợp lệ", vim.log.levels.WARN)
    end
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
    local byte = vim.str_byteindex(line, "utf-32", col - 1, false)
    vim.api.nvim_win_set_cursor(win, { row, math.min(byte, #line) })
    vim.api.nvim_win_call(win, function() vim.cmd.normal({ "zvzz", bang = true }) end)
  end)
end

function M.search_next(backward)
  local ok, err = pcall(vim.cmd.normal, { backward and "Nzzzv" or "nzzzv", bang = true })
  if not ok then vim.notify(tostring(err), vim.log.levels.WARN) end
end

function M.super()
  if vim.bo.filetype == "java" then return require("jdtls").super_implementation() end
  vim.lsp.buf.typehierarchy("supertypes")
end

return M

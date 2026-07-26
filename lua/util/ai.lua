-- lua/util/ai.lua — mở AI CLI dạng TMUX PANE bên phải (nhiều session)
-- Mỗi lần gọi mở 1 pane mới: pane đầu tạo cột phải, các pane sau xếp chồng
-- trong cột đó. Điều hướng bằng Ctrl-hjkl (vim-tmux-navigator).
-- Yêu cầu: Neovim chạy BÊN TRONG tmux.

local M = {}

-- Bề rộng cột AI (theo % cửa sổ tmux). Đổi tại đây.
M.width_ratio = 0.40
-- Danh sách pane AI đang mở: { {id=, label=}, ... }
M._panes = {}
-- Pane AI mở/nhắm gần nhất (để gửi context)
M._last_pane = nil

-- Các AI đã biết. Thêm ở đây là có keymap tương ứng.
M.named = {
  claude = { cmd = "claude", label = "Claude" },
  codex = { cmd = "codex", label = "Codex" },
  gemini = { cmd = "gemini", label = "Gemini" },
}

local function in_tmux()
  return os.getenv("TMUX") ~= nil
end

local function executable(cmd)
  return vim.fn.executable(cmd:match("^%S+")) == 1
end

local function width_pct()
  return tostring(math.floor(M.width_ratio * 100)) .. "%"
end

-- Tập pane còn sống (id kiểu %3) trong toàn server tmux
local function live_set()
  local out = vim.fn.system({ "tmux", "list-panes", "-a", "-F", "#{pane_id}" })
  local set = {}
  for id in out:gmatch("%%%d+") do
    set[id] = true
  end
  return set
end

-- Bỏ khỏi danh sách những pane đã đóng
local function prune()
  local live = live_set()
  local kept = {}
  for _, p in ipairs(M._panes) do
    if live[p.id] then
      kept[#kept + 1] = p
    end
  end
  M._panes = kept
  if M._last_pane and not live[M._last_pane] then
    M._last_pane = M._panes[#M._panes] and M._panes[#M._panes].id or nil
  end
end

local function guard()
  if not in_tmux() then
    vim.notify(
      "Chưa ở trong tmux — mở nvim bên trong tmux để dùng AI pane.\n(Terminal thường: <C-\\>)",
      vim.log.levels.WARN,
      { title = "AI" }
    )
    return false
  end
  return true
end

-- Mở 1 AI CLI ở tmux pane bên phải. Mỗi lần gọi = 1 pane mới (không cướp focus).
function M.open(cmd, label)
  if not guard() then
    return
  end
  if not executable(cmd) then
    vim.notify("AI CLI chưa cài: " .. cmd, vim.log.levels.WARN, { title = "AI" })
    return
  end
  prune()
  local cwd = vim.fn.getcwd()
  local anchor = M._panes[#M._panes]
  local args
  if anchor then
    -- Đã có cột AI -> thêm CỘT MỚI bên phải (side by side, full-height)
    args = { "tmux", "split-window", "-h", "-d", "-t", anchor.id, "-c", cwd, "-P", "-F", "#{pane_id}", cmd }
  else
    -- Chưa có -> tạo cột AI full-height bên phải
    args = { "tmux", "split-window", "-h", "-f", "-d", "-l", width_pct(), "-c", cwd, "-P", "-F", "#{pane_id}", cmd }
  end
  local out = vim.fn.system(args)
  if vim.v.shell_error ~= 0 then
    vim.notify("tmux split lỗi:\n" .. out, vim.log.levels.ERROR, { title = "AI" })
    return
  end
  local id = vim.trim(out)
  table.insert(M._panes, { id = id, label = label or cmd })
  M._last_pane = id
  vim.notify((label or cmd) .. " → pane " .. id .. "  (tổng " .. #M._panes .. " session)", vim.log.levels.INFO, { title = "AI" })
end

-- Mở AI theo tên (giữ tên toggle cho tương thích keymap cũ)
function M.toggle(name)
  local spec = M.named[name]
  if not spec then
    vim.notify("AI chưa cấu hình: " .. tostring(name), vim.log.levels.ERROR)
    return
  end
  M.open(spec.cmd, spec.label)
end

-- Claude: tiếp tục session hội thoại trước
function M.claude_continue()
  M.open("claude --continue", "Claude ↺")
end

-- === Xem toàn bộ session AI đang mở, chọn để nhảy tới ===
function M.sessions()
  if not guard() then
    return
  end
  prune()
  if #M._panes == 0 then
    vim.notify("Chưa có session AI. Mở bằng <leader>ac / <leader>ax", vim.log.levels.INFO, { title = "AI" })
    return
  end
  vim.ui.select(M._panes, {
    prompt = "Session AI (" .. #M._panes .. "):",
    format_item = function(p)
      local mark = (p.id == M._last_pane) and "● " or "○ "
      return mark .. p.label .. "  [" .. p.id .. "]"
    end,
  }, function(choice)
    if not choice then
      return
    end
    vim.fn.system({ "tmux", "select-pane", "-t", choice.id })
    M._last_pane = choice.id
  end)
end

-- Đóng tất cả pane AI đang mở
function M.close_all()
  if not guard() then
    return
  end
  prune()
  local n = #M._panes
  for _, p in ipairs(M._panes) do
    vim.fn.system({ "tmux", "kill-pane", "-t", p.id })
  end
  M._panes = {}
  M._last_pane = nil
  vim.notify("Đã đóng " .. n .. " session AI", vim.log.levels.INFO, { title = "AI" })
end

-- === Gửi context vào pane AI gần nhất (send-keys -l: literal, KHÔNG tự Enter) ===
local function send_literal(text)
  if not guard() then
    return
  end
  prune()
  if not M._last_pane then
    vim.notify("Chưa có AI pane. Mở bằng <leader>ac trước.", vim.log.levels.INFO, { title = "AI" })
    return
  end
  vim.fn.system({ "tmux", "send-keys", "-t", M._last_pane, "-l", text })
  if vim.v.shell_error ~= 0 then
    vim.notify("AI pane đã đóng. Mở lại bằng <leader>ac.", vim.log.levels.WARN, { title = "AI" })
    M._last_pane = nil
    return
  end
  vim.fn.system({ "tmux", "select-pane", "-t", M._last_pane }) -- nhảy sang pane AI
end

function M.send_file()
  local abs = vim.fn.expand("%:p")
  if abs == "" then
    vim.notify("Buffer chưa gắn file", vim.log.levels.WARN)
    return
  end
  send_literal("@" .. vim.fn.fnamemodify(abs, ":.") .. " ")
end

function M.send_file_line()
  send_literal("@" .. vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.") .. ":" .. vim.fn.line(".") .. " ")
end

function M.send_selection()
  local s, e = vim.fn.line("v"), vim.fn.line(".")
  if s > e then
    s, e = e, s
  end
  send_literal("@" .. vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.") .. ":" .. s .. "-" .. e .. " ")
end

-- Xem AI vừa update gì: mở diff các thay đổi chưa commit
function M.review_changes()
  if vim.fn.exists(":DiffviewOpen") == 2 then
    vim.cmd("DiffviewOpen")
  else
    vim.notify("Cần diffview (đã cài ở plugins/git.lua)", vim.log.levels.WARN)
  end
end

-- Xem nhanh các phím thao tác AI (which-key)
function M.show_keys()
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.show({ keys = "<leader>a", loop = true })
  else
    vim.notify("which-key chưa sẵn sàng", vim.log.levels.WARN)
  end
end

return M

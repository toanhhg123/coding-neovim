-- lua/util/ai.lua — helper quản lý các session AI CLI (dựa trên toggleterm)
-- Tính năng: nhiều session, session bền (giữ tiến trình khi ẩn), gửi context,
-- chọn/chuyển session, review thay đổi AI.

local M = {}

-- Cache các Terminal theo key -> giữ session (tiến trình vẫn chạy khi ẩn đi)
M._terms = {}
-- Terminal AI được focus gần nhất (để gửi context vào đúng session)
M._last = nil
-- Bộ đếm cho session tạo thêm (ad-hoc)
M._counter = 300

-- Cấu hình các AI đã biết. Thêm ở đây là có ngay keymap tương ứng.
-- count: id cố định của toggleterm -> mỗi AI 1 cửa sổ riêng.
M.named = {
  claude = { cmd = "claude", count = 191, label = "Claude" },
  codex = { cmd = "codex", count = 192, label = "Codex" },
  gemini = { cmd = "gemini", count = 193, label = "Gemini" },
}

local function float_opts()
  return {
    border = "curved",
    width = math.floor(vim.o.columns * 0.85),
    height = math.floor(vim.o.lines * 0.85),
  }
end

-- CLI đã cài chưa? (báo nhẹ nếu thiếu, không làm vỡ config)
local function ensure(cmd)
  local bin = cmd:match("^%S+")
  if vim.fn.executable(bin) == 0 then
    vim.notify("AI CLI chưa cài: " .. bin, vim.log.levels.WARN, { title = "AI" })
    return false
  end
  return true
end

-- Tạo (hoặc lấy từ cache) một Terminal AI theo key
function M.get(key, cmd, count, label)
  if M._terms[key] then
    return M._terms[key]
  end
  local Terminal = require("toggleterm.terminal").Terminal
  local term = Terminal:new({
    cmd = cmd,
    count = count,
    direction = "float",
    float_opts = float_opts(),
    close_on_exit = false, -- giữ cửa sổ khi CLI thoát -> đọc được output cuối
    hidden = true,
    display_name = label or key,
    on_open = function(t)
      M._last = t
      vim.cmd("startinsert")
      -- Trong terminal AI: <C-q> để ẩn nhanh (giữ session)
      vim.keymap.set("t", "<C-q>", function()
        t:toggle()
      end, { buffer = t.bufnr, desc = "Ẩn AI (giữ session)" })
    end,
    on_focus = function(t)
      M._last = t
    end,
  })
  M._terms[key] = term
  return term
end

-- Bật/tắt một AI đã đặt tên (claude/codex/gemini). Giữ session giữa các lần bật.
function M.toggle(name)
  local spec = M.named[name]
  if not spec then
    vim.notify("AI chưa cấu hình: " .. tostring(name), vim.log.levels.ERROR)
    return
  end
  if not ensure(spec.cmd) then
    return
  end
  M.get(name, spec.cmd, spec.count, spec.label):toggle()
end

-- Claude: tiếp tục session trước đó (persist qua các lần khởi động nvim)
function M.claude_continue()
  if not ensure("claude") then
    return
  end
  M.get("claude_continue", "claude --continue", 190, "Claude ↺"):toggle()
end

-- Mở THÊM một session AI mới (độc lập với session chính) -> chạy nhiều song song
function M.new_session()
  local names = vim.tbl_keys(M.named)
  table.sort(names)
  vim.ui.select(names, {
    prompt = "Mở session AI mới:",
    format_item = function(n)
      return M.named[n].label
    end,
  }, function(choice)
    if not choice then
      return
    end
    local spec = M.named[choice]
    if not ensure(spec.cmd) then
      return
    end
    M._counter = M._counter + 1
    local key = choice .. "#" .. M._counter
    M.get(key, spec.cmd, M._counter, spec.label .. " #" .. (M._counter - 300)):toggle()
  end)
end

-- Chọn/chuyển giữa các session terminal đang mở
function M.select()
  vim.cmd("TermSelect")
end

-- === Gửi context vào session AI đang focus (không tự submit -> bạn tự sửa & Enter) ===
local function insert_into_ai(text)
  local term = M._last
  if not (term and term:is_open()) then
    -- Chưa có AI mở -> mở Claude mặc định rồi chèn
    term = M.get("claude", "claude", 191, "Claude")
    term:open()
    M._last = term
    vim.defer_fn(function()
      pcall(vim.api.nvim_chan_send, term.job_id, text)
    end, 400)
    return
  end
  term:open()
  pcall(vim.api.nvim_chan_send, term.job_id, text)
end

-- Gửi đường dẫn file hiện tại (dạng @path tương đối)
function M.send_file()
  local abs = vim.fn.expand("%:p")
  if abs == "" then
    vim.notify("Buffer chưa gắn file", vim.log.levels.WARN)
    return
  end
  insert_into_ai("@" .. vim.fn.fnamemodify(abs, ":.") .. " ")
end

-- Gửi @path:line của dòng hiện tại
function M.send_file_line()
  local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
  insert_into_ai("@" .. rel .. ":" .. vim.fn.line(".") .. " ")
end

-- Gửi @path:start-end của vùng đang chọn (visual)
function M.send_selection()
  local rel = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
  local s = vim.fn.line("v")
  local e = vim.fn.line(".")
  if s > e then
    s, e = e, s
  end
  insert_into_ai("@" .. rel .. ":" .. s .. "-" .. e .. " ")
end

-- Xem AI vừa update gì: mở diff các thay đổi (chưa commit) qua diffview
function M.review_changes()
  if vim.fn.exists(":DiffviewOpen") == 2 then
    vim.cmd("DiffviewOpen")
  else
    vim.cmd("Git diff")
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

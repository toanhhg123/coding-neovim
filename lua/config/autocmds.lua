-- lua/config/autocmds.lua — autocommands cơ bản

local function augroup(name)
  return vim.api.nvim_create_augroup("coding_nvim_" .. name, { clear = true })
end

-- === Highlight vùng vừa yank (phản hồi trực quan khi copy) ===
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- === Auto-reload file khi bị đổi bên ngoài (git pull, đổi nhánh...) ===
-- autoread đã bật trong options; cần kích checktime khi focus/enter buffer.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = augroup("auto_reload"),
  callback = function()
    if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})
-- Báo khi file được nạp lại
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = augroup("auto_reload_notify"),
  callback = function()
    vim.notify("File đã đổi bên ngoài — đã nạp lại.", vim.log.levels.INFO)
  end,
})

-- === Về đúng vị trí con trỏ cũ khi mở lại file ===
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- === Đóng buffer phụ bằng phím q (help, quickfix, man...) ===
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "notify" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- === File .java trống: tự điền package + class ===
-- Dùng BufReadPost vì neo-tree tạo file trên đĩa trước rồi mới mở (không phát BufNewFile).
vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  group = augroup("java_skeleton"),
  pattern = "*.java",
  callback = function(event)
    local buf = event.buf
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if vim.bo[buf].buftype ~= "" or #lines > 1 or lines[1] ~= "" then return end

    local path = vim.api.nvim_buf_get_name(buf)
    if path:match("^%a+://") then return end -- source thư viện qua jdt://
    local name = vim.fn.fnamemodify(path, ":t:r")
    local body = { "public class " .. name .. " {", "", "}" }
    local package = path:match("/src/[^/]+/java/(.+)/[^/]+$")
    if package then
      table.insert(body, 1, "")
      table.insert(body, 1, "package " .. package:gsub("/", ".") .. ";")
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, body)
    if vim.api.nvim_get_current_buf() == buf then
      vim.api.nvim_win_set_cursor(0, { #body - 1, 0 }) -- con trỏ ở thân class
    end
  end,
})

-- === Bỏ auto-comment khi xuống dòng mới sau dòng comment ===
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("no_auto_comment"),
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

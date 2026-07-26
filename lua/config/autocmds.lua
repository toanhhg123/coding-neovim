-- lua/config/autocmds.lua — autocommands cơ bản

local function augroup(name)
  return vim.api.nvim_create_augroup("coding_nvim_" .. name, { clear = true })
end

-- === Highlight vùng vừa yank (phản hồi trực quan khi copy) ===
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

-- === Auto-reload file khi bị đổi bên ngoài (AI CLI sửa file trên đĩa) ===
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

-- === Bỏ auto-comment khi xuống dòng mới sau dòng comment ===
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("no_auto_comment"),
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

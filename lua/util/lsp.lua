-- lua/util/lsp.lua — bật/tắt TOÀN BỘ LSP bằng 1 lệnh
-- Tắt: dừng mọi client + chặn tự attach. Bật: cho phép lại + attach lại buffer.

local M = {}

M.enabled = true      -- trạng thái hiện tại
M.servers = {}        -- danh sách server generic (lsp.lua điền vào)

local function notify(on)
  vim.notify("LSP: " .. (on and "BẬT ●" or "TẮT ○"), vim.log.levels.INFO, { title = "LSP" })
end

function M.set(on)
  M.enabled = on

  -- Bật/tắt auto-attach của các server generic (API native nvim 0.11)
  if #M.servers > 0 then
    pcall(vim.lsp.enable, M.servers, on)
  end

  if on then
    -- Attach lại: fire FileType trên các buffer đang mở -> server + jdtls gắn lại
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" then
        vim.api.nvim_exec_autocmds("FileType", { buffer = b })
      end
    end
  else
    -- Dừng mọi client đang chạy (gồm cả jdtls)
    for _, c in ipairs(vim.lsp.get_clients()) do
      vim.lsp.stop_client(c.id, true)
    end
  end

  notify(on)
end

function M.toggle()
  M.set(not M.enabled)
end

-- Đăng ký lệnh :LspToggle / :LspEnable / :LspDisable (gọi 1 lần từ lsp.lua)
function M.setup_commands()
  vim.api.nvim_create_user_command("LspToggle", function() M.toggle() end, { desc = "Bật/tắt toàn bộ LSP" })
  vim.api.nvim_create_user_command("LspEnable", function() M.set(true) end, { desc = "Bật toàn bộ LSP" })
  vim.api.nvim_create_user_command("LspDisable", function() M.set(false) end, { desc = "Tắt toàn bộ LSP" })
end

return M

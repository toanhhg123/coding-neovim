-- lua/util/lsp.lua — bật/tắt TOÀN BỘ LSP bằng 1 lệnh
-- Tắt: dừng mọi client + chặn tự attach. Bật: cho phép lại + attach lại buffer.

local M = {}

M.enabled = false     -- trạng thái mặc định: TẮT (bật bằng <leader>cl / :LspEnable)
M.servers = {}        -- danh sách server generic

local function notify(on)
  vim.notify("LSP: " .. (on and "BẬT ●" or "TẮT ○"), vim.log.levels.INFO, { title = "LSP" })
end

--- Capabilities cho mọi client. Chỉ gọi lúc bật LSP nên không kéo blink.cmp vào startup.
function M.capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  return ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()
end

--- Thêm server vào danh sách quản lý; đang bật thì bật luôn server đó.
function M.register(names)
  names = type(names) == "table" and names or { names }
  vim.list_extend(M.servers, names)
  if M.enabled then
    vim.lsp.config("*", { capabilities = M.capabilities() })
    vim.lsp.enable(names)
  end
end

function M.set(on)
  M.enabled = on

  if on then
    -- LSP mặc định tắt nên chỉ nạp lspconfig/mason/spring khi thật sự bật, startup không tốn gì
    require("lazy").load({ plugins = { "nvim-lspconfig", "spring-boot.nvim" } })
    vim.lsp.config("*", { capabilities = M.capabilities() })
  end

  -- Bật/tắt auto-attach của các server generic (API native nvim 0.11+)
  if #M.servers > 0 then
    pcall(vim.lsp.enable, M.servers, on)
  end

  if on then
    -- Attach lại: fire FileType trên các buffer đang mở -> server + jdtls gắn lại
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "" then
        -- Phải truyền pattern = filetype: dùng { buffer = b } thì autocmd so khớp theo tên file
        -- nên autocmd pattern "java" (jdtls) sẽ không chạy
        vim.api.nvim_buf_call(b, function()
          vim.api.nvim_exec_autocmds("FileType", { pattern = vim.bo[b].filetype })
        end)
      end
    end
  else
    -- Dừng mọi client đang chạy (gồm cả jdtls)
    for _, c in ipairs(vim.lsp.get_clients()) do
      c:stop() -- dừng êm: force sẽ làm hiện thông báo "exit code 143"
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

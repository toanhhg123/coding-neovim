-- Điều phối Spring JVM -> chờ JDWP sẵn sàng -> DAP attach; Stop hủy cả bước chờ.
local M = { timeout_ms = 60000 }

local function notify(message)
  vim.notify(message, vim.log.levels.WARN, { title = "Debug" })
end

local function java_client(project)
  if not project then return nil end
  local module = vim.uv.fs_realpath(project.module) or vim.fs.normalize(project.module)
  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    local root = client.config and client.config.root_dir
    root = root and (vim.uv.fs_realpath(root) or vim.fs.normalize(root))
    if root and (module == root or module:sub(1, #root + 1) == root .. "/") then return client end
  end
end

local function cancel()
  local pending = M.pending
  M.pending = nil
  if pending and pending.timer then
    pending.timer:stop()
    pending.timer:close()
  end
  return pending
end

function M.attach(project)
  if M.pending then return notify("Đang chờ JVM debug; dùng Space j q để hủy") end
  project = project or require("util.spring").project()
  local client = java_client(project)
  if not client then return notify("Cần jdtls của project hiện tại: bật LSP rồi đợi import xong") end
  local dap = require("dap")
  if dap.session() then return notify("Đang có phiên debug; dừng trước bằng Space j q") end
  if not dap.adapters.java then require("jdtls").setup_dap({ hotcodereplace = "auto" }) end
  if not dap.adapters.java then return notify("Chưa có Java debug adapter") end
  dap.run({
    type = "java", request = "attach", name = "Attach Spring Boot: " .. project.module,
    hostName = "127.0.0.1", port = require("util.spring").debug_port,
    cwd = client.config.root_dir,
    _coding_nvim_project = project,
  })
end

local function wait_ready(pending, handle)
  pending.deadline = vim.uv.hrtime() + M.timeout_ms * 1000000
  pending.timer = vim.uv.new_timer()
  local function consume(text)
    if M.pending ~= pending then return end
    -- Chỉ đọc output sau marker của lần chạy này, tránh attach nhầm log JVM cũ.
    local last, from = nil, 1
    while true do
      local pos = text:find(pending.marker, from, true)
      if not pos then break end
      last, from = pos, pos + #pending.marker
    end
    if last then
      pending.seen_marker = true
      text = text:sub(last + #pending.marker)
    elseif not pending.seen_marker then return end
    for line in text:gmatch("[^\n]+") do
      local address = line:match("Listening for transport dt_socket at address:%s*(%S+)")
      if address and tonumber(address:match("(%d+)$")) == require("util.spring").debug_port then
        cancel()
        M.attach(pending.project)
        return
      end
    end
  end
  pending.timer:start(0, 200, vim.schedule_wrap(function()
    if M.pending ~= pending then return end
    if vim.uv.hrtime() >= pending.deadline then
      cancel()
      return notify("Hết thời gian chờ JVM debug; xem log build hoặc attach bằng <leader>da")
    end
    if handle.kind == "term" then
      if not vim.api.nvim_buf_is_valid(handle.buf) then
        cancel()
        return notify("Terminal debug đã đóng")
      end
      consume(handle.output or table.concat(vim.api.nvim_buf_get_lines(handle.buf, 0, -1, false), "\n"))
    elseif not pending.reading then
      pending.reading = true
      vim.system({ "tmux", "capture-pane", "-p", "-J", "-S", "-2000", "-t", handle.id }, { text = true }, vim.schedule_wrap(function(result)
        pending.reading = false
        if M.pending ~= pending then return end
        if result.code ~= 0 then
          cancel()
          return notify("Không đọc được output tmux pane debug")
        end
        consume(result.stdout or "")
      end))
    end
  end))
end

function M.start()
  local spring = require("util.spring")
  local project = spring.project()
  if not java_client(project) then return notify("Debug cần jdtls của project hiện tại; bật LSP rồi đợi import xong") end
  local dap = require("dap")
  if M.pending or dap.session() then return notify("Đang có phiên debug hoặc đang chờ JVM; dừng trước bằng Space j q") end
  if not dap.adapters.java then require("jdtls").setup_dap({ hotcodereplace = "auto" }) end
  if not dap.adapters.java then return notify("Chưa có Java debug adapter") end
  local pending = { project = project, marker = "coding-nvim-debug-" .. tostring(vim.uv.hrtime()) }
  M.pending = pending
  spring.run_debug({
    marker = pending.marker,
    can_start = function() return M.pending == pending end,
    on_cancel = function() if M.pending == pending then cancel() end end,
    on_started = function(started_project, handle)
      if M.pending ~= pending then return end
      pending.project = started_project
      wait_ready(pending, handle)
    end,
  })
end

function M.stop()
  local pending = cancel()
  local dap = package.loaded.dap -- Stop app bình thường không cần nạp DAP.
  local session = dap and dap.session()
  if session then
    dap.terminate({ disconnect_args = { terminateDebuggee = true } })
    local project = session.config and session.config._coding_nvim_project
    if project then require("util.spring").stop(project, true) end
  elseif pending then
    require("util.spring").stop(pending.project, true)
  else
    require("util.spring").stop()
  end
end

return M

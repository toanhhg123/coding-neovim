-- lua/plugins/debug.lua — Debug qua nvim-dap (chỉ nạp khi bấm phím debug)
-- Java cần LSP đang bật: jdtls cung cấp debug adapter (<leader>cl để bật).

local function dap(fn, ...)
  local args = { ... }
  return function() require("dap")[fn](unpack(args)) end
end

--- Tiếp tục/bắt đầu debug; với Java thì nạp danh sách main class từ jdtls trước.
local function continue()
  local d = require("dap")
  if d.session() or vim.bo.filetype ~= "java" then return d.continue() end
  if #vim.lsp.get_clients({ name = "jdtls", bufnr = 0 }) == 0 then
    return vim.notify("Debug Java cần LSP: bật bằng <leader>cl rồi đợi jdtls import xong", vim.log.levels.WARN, { title = "Debug" })
  end
  require("jdtls.dap").setup_dap_main_class_configs({ on_ready = function() d.continue() end })
end

--- Attach vào app đang chạy ở chế độ debug (<leader>jD).
local function attach()
  require("util.debug").attach()
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<leader>db", dap("toggle_breakpoint"), desc = "Breakpoint" },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Điều kiện: " }, function(value)
            if value then require("dap").set_breakpoint(value) end
          end)
        end,
        desc = "Breakpoint có điều kiện",
      },
      { "<leader>dc", continue, desc = "Bắt đầu / tiếp tục" },
      { "<leader>da", attach, desc = "Attach app đang chạy (cổng 5005)" },
      { "<leader>dn", dap("step_over"), desc = "Step over" },
      { "<leader>di", dap("step_into"), desc = "Step into" },
      { "<leader>do", dap("step_out"), desc = "Step out" },
      { "<leader>dl", dap("run_last"), desc = "Chạy lại lần debug trước" },
      { "<leader>dr", dap("repl_toggle"), desc = "REPL" },
      { "<leader>dq", function() require("util.debug").stop() end, desc = "Dừng debug / app" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Bật/tắt giao diện debug" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "x" }, desc = "Xem giá trị biểu thức" },
      -- Cùng phím với IntelliJ
      { "<F9>", continue, desc = "Debug: tiếp tục" },
      { "<F8>", dap("step_over"), desc = "Debug: step over" },
      { "<F7>", dap("step_into"), desc = "Debug: step into" },
      { "<S-F8>", dap("step_out"), desc = "Debug: step out" },
      { "<F20>", dap("step_out"), desc = "Debug: step out (Shift+F8 qua tmux)" },
    },
    config = function()
      local d, ui = require("dap"), require("dapui")
      ui.setup()
      require("nvim-dap-virtual-text").setup({})

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

      d.listeners.before.attach.dapui_config = function() ui.open() end
      d.listeners.before.launch.dapui_config = function() ui.open() end
      d.listeners.before.event_terminated.dapui_config = function() ui.close() end
      d.listeners.before.event_exited.dapui_config = function() ui.close() end
    end,
  },
}

-- lua/plugins/ai.lua — AI CLI trong session (toggleterm)
-- Chạy claude/codex/... ngay trong Neovim: nhiều session, giữ session khi ẩn,
-- gửi context, review thay đổi AI. Logic ở lua/util/ai.lua.

local function ai()
  return require("util.ai")
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermSelect", "ToggleTermToggleAll" },
    keys = {
      -- --- Bật/tắt session AI (giữ session giữa các lần bật) ---
      { "<leader>ac", function() ai().toggle("claude") end, desc = "Claude" },
      { "<leader>ax", function() ai().toggle("codex") end, desc = "Codex" },
      { "<leader>ag", function() ai().toggle("gemini") end, desc = "Gemini" },
      { "<leader>aC", function() ai().claude_continue() end, desc = "Claude: tiếp tục session trước" },

      -- --- Nhiều session ---
      { "<leader>an", function() ai().new_session() end, desc = "Mở session AI mới" },
      { "<leader>as", function() ai().sessions() end, desc = "Xem TOÀN BỘ session (mở/ẩn) + nhảy tới" },

      -- --- Gửi context sang AI ---
      { "<leader>af", function() ai().send_file() end, desc = "Gửi file hiện tại (@path)" },
      { "<leader>al", function() ai().send_file_line() end, desc = "Gửi @path:dòng" },
      { "<leader>av", function() ai().send_selection() end, mode = "v", desc = "Gửi vùng chọn (@path:range)" },

      -- --- Review & trợ giúp ---
      { "<leader>ar", function() ai().review_changes() end, desc = "Xem AI vừa update gì (diff)" },
      { "<leader>a?", function() ai().show_keys() end, desc = "Xem phím thao tác AI" },

      -- --- Terminal thường (chạy test/build cạnh AI) ---
      { "<leader>at", "<cmd>ToggleTerm direction=float<CR>", desc = "Terminal (float)" },
      { "<leader>aT", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Terminal (dưới)" },
    },
    opts = {
      open_mapping = [[<c-\>]], -- Ctrl-\ bật/tắt terminal nhanh ở mọi chế độ
      direction = "float",
      float_opts = { border = "curved" },
      persist_mode = true, -- nhớ chế độ (insert/normal) của từng terminal
      persist_size = true,
      close_on_exit = false,
      shade_terminals = false,
      start_in_insert = true,
      auto_scroll = true,
    },
  },
}

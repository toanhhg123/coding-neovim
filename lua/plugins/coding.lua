-- lua/plugins/coding.lua — tiện ích gõ code nhẹ (autopairs)
-- Tự đóng ngoặc/quote khi gõ. Nhẹ, không cần keymap, không đụng startup.

return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter", -- chỉ nạp khi bắt đầu gõ -> khỏi ảnh hưởng startup
    opts = {
      check_ts = true,          -- dùng treesitter để đóng ngoặc thông minh theo ngữ cảnh
      disable_filetype = { "TelescopePrompt", "grug-far" },
      fast_wrap = {},           -- Alt-e: bọc nhanh phần còn lại của dòng vào ngoặc
    },
  },
}

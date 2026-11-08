-- coding-neovim — entrypoint
-- Cấu hình nhẹ, cross-OS cho đọc code / search / code + tmux.
-- Thứ tự nạp: leader phải set TRƯỚC khi lazy.nvim khởi động.

-- 1) Options + keymaps + autocmds cơ bản (không phụ thuộc plugin)
require("config.options")
require("config.keymaps")
-- Mặc định dùng phím Vim/Space, không cần profile bàn phím của terminal.
-- Bộ Cmd tùy chọn: require("config.intellij") trong lua/config/local.lua.
require("config.autocmds")
vim.cmd.colorscheme("iterm") -- colors/iterm.lua, cần có trước khi plugin UI nạp

-- 2) Bootstrap plugin manager (lazy.nvim) + nạp thư mục lua/plugins/
require("config.lazy")

-- 3) Config override riêng từng máy (không commit — xem .gitignore)
pcall(require, "config.local")

-- lua/config/lazy.lua — bootstrap & cấu hình lazy.nvim (plugin manager)

-- 1) Tự cài lazy.nvim nếu chưa có (cross-OS: dùng stdpath, không hardcode)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Không clone được lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nNhấn phím bất kỳ để thoát...", "MoreMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- 2) Setup: tự nạp mọi file trong lua/plugins/
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = true,   -- mặc định lazy-load (nhẹ, khởi động nhanh)
    version = false, -- dùng commit mới nhất, không pin theo tag
  },
  install = {
    -- colorscheme dùng khi cài lần đầu; sẽ thay bằng scheme thật ở Bước 2
    colorscheme = { "habamax" },
  },
  ui = { border = "rounded" },
  checker = {
    enabled = true,   -- tự kiểm tra update plugin...
    notify = false,   -- ...nhưng không làm phiền bằng thông báo
  },
  change_detection = { notify = false },
  performance = {
    rtp = {
      -- Tắt bớt plugin built-in không cần -> khởi động nhanh hơn
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "netrwPlugin",
      },
    },
  },
})

-- 3) Phím mở giao diện quản lý plugin
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<CR>", { desc = "Mở Lazy (quản lý plugin)" })

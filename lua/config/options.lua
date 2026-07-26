-- lua/config/options.lua — vim options cơ bản
-- Nguyên tắc: nhẹ, cross-OS, tối ưu cho đọc code.

-- Leader phải set trước khi plugin nạp keymap. Đặt sớm nhất có thể.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- === Giao diện & đọc code ===
opt.number = true            -- số dòng
opt.relativenumber = true    -- số dòng tương đối (nhảy nhanh bằng {count}j/k)
opt.cursorline = true        -- highlight dòng hiện tại
opt.signcolumn = "yes"       -- luôn hiện cột dấu (git/diagnostic) -> không giật layout
opt.wrap = false             -- không xuống dòng tự động (đọc code dài dễ hơn)
opt.scrolloff = 8            -- giữ 8 dòng đệm trên/dưới con trỏ
opt.sidescrolloff = 8
opt.termguicolors = true     -- màu 24-bit (cần cho colorscheme đẹp)
opt.showmode = false         -- statusline sẽ hiện mode, không cần dòng -- INSERT --

-- === Tìm kiếm ===
opt.ignorecase = true        -- không phân biệt hoa/thường khi search...
opt.smartcase = true         -- ...trừ khi gõ có chữ hoa
opt.incsearch = true
opt.hlsearch = true

-- === Thụt lề (mặc định nhẹ; treesitter/LSP sẽ tinh chỉnh theo filetype) ===
opt.expandtab = true         -- tab -> spaces
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.autoindent = true

-- === Split ===
opt.splitright = true        -- split dọc mở sang phải
opt.splitbelow = true        -- split ngang mở xuống dưới

-- === Clipboard (cross-OS) ===
-- unnamedplus dùng chung clipboard hệ thống. macOS/Linux (xclip/wl-clipboard)/WSL đều nhận.
opt.clipboard = "unnamedplus"

-- === File & undo ===
opt.undofile = true          -- lưu undo qua các lần mở file
opt.swapfile = false
opt.backup = false
opt.autoread = true          -- tự đọc lại file khi bị đổi bên ngoài (AI CLI sửa file)
opt.updatetime = 250         -- phản hồi nhanh hơn (CursorHold, git blame...)
opt.timeoutlen = 400         -- chờ chuỗi phím (which-key hiện gợi ý)

-- === Trải nghiệm ===
opt.mouse = "a"              -- bật chuột (tiện resize split, scroll)
opt.completeopt = "menu,menuone,noselect"
opt.confirm = true           -- hỏi thay vì báo lỗi khi thoát mà chưa lưu
opt.list = true              -- hiện ký tự ẩn (tab/trailing space) để đọc code rõ
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Ký tự fill: ẩn dấu ~ ở cuối buffer cho gọn (giữ mặc định cho fold)
opt.fillchars = { eob = " " }

-- === Fold (dùng treesitter sau, tạm để mở sẵn) ===
opt.foldlevel = 99
opt.foldlevelstart = 99

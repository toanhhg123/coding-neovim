-- lua/config/keymaps.lua — keymap toàn cục (không thuộc plugin nào)
-- Keymap của plugin sẽ nằm trong file plugin tương ứng.
-- leader = Space (đã set trong options.lua)

local map = vim.keymap.set

-- === Cơ bản ===
-- Bỏ highlight tìm kiếm
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Xoá highlight tìm kiếm" })

-- Lưu file nhanh
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Lưu file" })

-- === Di chuyển giữa split & tmux pane ===
-- Ctrl-h/j/k/l do vim-tmux-navigator đảm nhận (xem lua/plugins/tmux.lua)
-- -> nhảy liền mạch cả trong Neovim lẫn sang tmux pane.

-- Resize split bằng phím mũi tên
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Tăng chiều cao split" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Giảm chiều cao split" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Giảm chiều rộng split" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Tăng chiều rộng split" })

-- === Buffer ===
-- (S-h / S-l chuyển tab do bufferline đảm nhận — xem lua/plugins/ui.lua)
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Đóng buffer/tab hiện tại" })

-- === Di chuyển & chỉnh sửa tiện tay ===
-- Giữ con trỏ giữa màn hình khi nhảy nửa trang / tìm kiếm
map("n", "<C-d>", "<C-d>zz", { desc = "Nửa trang xuống (giữa màn hình)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Nửa trang lên (giữa màn hình)" })
map("n", "n", "nzzzv", { desc = "Kết quả tìm kế tiếp (giữa màn hình)" })
map("n", "N", "Nzzzv", { desc = "Kết quả tìm trước (giữa màn hình)" })

-- Di chuyển dòng đang chọn lên/xuống (visual mode)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Đẩy dòng xuống" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Đẩy dòng lên" })

-- Giữ nội dung clipboard khi paste đè trong visual mode
map("v", "p", '"_dP', { desc = "Paste không nuốt clipboard" })

-- Giữ vùng chọn sau khi thụt lề
map("v", "<", "<gv", { desc = "Thụt trái, giữ chọn" })
map("v", ">", ">gv", { desc = "Thụt phải, giữ chọn" })

-- === Terminal: về normal mode dễ hơn ===
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal -> normal mode" })

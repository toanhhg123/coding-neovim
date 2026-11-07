-- lua/config/intellij.lua — phím tắt theo IntelliJ IDEA (macOS)
-- Terminal không truyền được Cmd, nên profile iTerm (iterm/coding-neovim.json) đổi Cmd+phím
-- thành Alt+phím, tức <M-...> ở đây. Bảng đối chiếu đầy đủ nằm trong README.

local map = vim.keymap.set

local function esc_to_normal(fn)
  return function()
    vim.cmd.stopinsert()
    fn()
  end
end

local function telescope(picker, opts)
  return function() require("telescope.builtin")[picker](opts or {}) end
end

local function spring(fn)
  return function() require("util.spring")[fn]() end
end

--- Gán một hành động cho nhiều dạng phím (qua tmux, Shift+F6 tới Neovim là <F18>).
local function keys(list, fn, desc, mode)
  for _, key in ipairs(list) do
    map(mode or "n", key, fn, { desc = desc })
  end
end

--- Hành động cần LSP: chưa có client thì báo rõ thay vì im lặng.
local function lsp(fn)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
      return vim.notify("File này chưa có LSP (hoặc LSP đang tắt: <leader>cl)", vim.log.levels.WARN)
    end
    fn()
  end
end

-- ===== Điều hướng =====
keys({ "<M-b>" }, lsp(function() require("telescope.builtin").lsp_definitions() end), "Cmd+B: nhảy tới định nghĩa")
keys({ "<M-I>" }, lsp(function() require("telescope.builtin").lsp_implementations() end), "Cmd+Alt+B: implementations")
keys({ "<M-u>" }, lsp(function() vim.lsp.buf.typehierarchy("supertypes") end), "Cmd+U: class cha / interface")
keys({ "<M-F7>", "<F55>" }, lsp(function() require("telescope.builtin").lsp_references() end), "Alt+F7: tìm nơi dùng")
keys({ "<F1>" }, lsp(vim.lsp.buf.hover), "F1: xem tài liệu")
keys({ "<M-p>" }, lsp(vim.lsp.buf.signature_help), "Cmd+P: tham số của hàm")
map("i", "<M-p>", vim.lsp.buf.signature_help, { desc = "Cmd+P: tham số của hàm" })
keys({ "<F2>" }, function() vim.diagnostic.jump({ count = 1, float = true }) end, "F2: lỗi kế tiếp")
keys({ "<S-F2>", "<F14>" }, function() vim.diagnostic.jump({ count = -1, float = true }) end, "Shift+F2: lỗi trước")
keys({ "<M-(>" }, "<C-o>", "Cmd+[: quay lại vị trí trước")
keys({ "<M-)>" }, "<C-i>", "Cmd+]: tới vị trí sau")

-- ===== Tìm kiếm =====
keys({ "<M-o>" }, function()
  if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then return require("telescope.builtin").find_files() end
  require("telescope.builtin").lsp_dynamic_workspace_symbols({ symbols = { "class", "interface", "enum", "struct" } })
end, "Cmd+O: tìm class")
keys({ "<M-O>" }, telescope("find_files"), "Cmd+Shift+O: tìm file")
keys({ "<M-Y>" }, lsp(function() require("telescope.builtin").lsp_dynamic_workspace_symbols() end), "Cmd+Alt+O: tìm symbol")
keys({ "<M-e>" }, telescope("buffers", { sort_mru = true, ignore_current_buffer = true }), "Cmd+E: file gần đây")
keys({ "<M-f>" }, telescope("current_buffer_fuzzy_find"), "Cmd+F: tìm trong file")
keys({ "<M-F>" }, telescope("live_grep"), "Cmd+Shift+F: tìm trong project")
keys({ "<M-r>" }, function()
  require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
end, "Cmd+R: thay thế trong file")
keys({ "<M-R>" }, function() require("grug-far").open() end, "Cmd+Shift+R: thay thế trong project")

-- ===== Cửa sổ công cụ =====
keys({ "<M-1>" }, "<cmd>Neotree toggle reveal<CR>", "Cmd+1: cây thư mục")
keys({ "<M-9>" }, "<cmd>DiffviewOpen<CR>", "Cmd+9: thay đổi git")
keys({ "<M-m>" }, "<cmd>AerialNavToggle<CR>", "Cmd+F12: cấu trúc file")
keys({ "<M-c>" }, "<cmd>bdelete<CR>", "Cmd+F4: đóng tab")
keys({ "<M-{>" }, "<cmd>BufferLineCyclePrev<CR>", "Cmd+Shift+[: tab trước")
keys({ "<M-}>" }, "<cmd>BufferLineCycleNext<CR>", "Cmd+Shift+]: tab sau")

-- ===== Sửa code =====
keys({ "<M-s>" }, "<cmd>write<CR>", "Cmd+S: lưu")
map("i", "<M-s>", "<cmd>write<CR>", { desc = "Cmd+S: lưu" })
keys({ "<M-z>" }, "u", "Cmd+Z: hoàn tác")
map("i", "<M-z>", "<cmd>undo<CR>", { desc = "Cmd+Z: hoàn tác" })
keys({ "<M-Z>" }, "<C-r>", "Cmd+Shift+Z: làm lại")
map("i", "<M-Z>", "<cmd>redo<CR>", { desc = "Cmd+Shift+Z: làm lại" })
keys({ "<M-a>" }, "ggVG", "Cmd+A: chọn tất cả")
map("n", "<M-/>", "gcc", { remap = true, desc = "Cmd+/: comment dòng" })
map("x", "<M-/>", "gc", { remap = true, desc = "Cmd+/: comment vùng chọn" })
map("i", "<M-/>", "<Esc>gcca", { remap = true, desc = "Cmd+/: comment dòng" })
map("n", "<M-d>", "<cmd>t.<CR>", { desc = "Cmd+D: nhân đôi dòng" })
map("x", "<M-d>", ":t'><CR>gv", { silent = true, desc = "Cmd+D: nhân đôi vùng chọn" })
map("i", "<M-d>", "<cmd>t.<CR>", { desc = "Cmd+D: nhân đôi dòng" })
map("n", "<M-x>", '"_dd', { desc = "Cmd+Backspace: xoá dòng" })
map("x", "<M-x>", '"_d', { desc = "Cmd+Backspace: xoá vùng chọn" })
map("i", "<M-x>", '<cmd>normal! "_dd<CR>', { desc = "Cmd+Backspace: xoá dòng" })
map("n", "<M-J>", "<cmd>move .+1<CR>==", { desc = "Alt+Shift+Down: chuyển dòng xuống" })
map("n", "<M-K>", "<cmd>move .-2<CR>==", { desc = "Alt+Shift+Up: chuyển dòng lên" })
map("x", "<M-J>", ":move '>+1<CR>gv=gv", { silent = true, desc = "Alt+Shift+Down: chuyển dòng xuống" })
map("x", "<M-K>", ":move '<-2<CR>gv=gv", { silent = true, desc = "Alt+Shift+Up: chuyển dòng lên" })
-- Cmd+W: chọn rộng dần theo cú pháp (an/in có sẵn của Neovim 0.12)
map("n", "<M-w>", "van", { remap = true, desc = "Cmd+W: chọn theo cú pháp" })
map("x", "<M-w>", "an", { remap = true, desc = "Cmd+W: chọn rộng hơn" })
map("x", "<M-W>", "in", { remap = true, desc = "Cmd+Shift+W: chọn hẹp lại" })

-- ===== Refactor & sinh code =====
keys({ "<M-CR>" }, lsp(vim.lsp.buf.code_action), "Alt+Enter: sửa nhanh")
map("x", "<M-CR>", vim.lsp.buf.code_action, { desc = "Alt+Enter: sửa nhanh" })
map("i", "<M-CR>", esc_to_normal(vim.lsp.buf.code_action), { desc = "Alt+Enter: sửa nhanh" })
keys({ "<S-F6>", "<F18>" }, lsp(vim.lsp.buf.rename), "Shift+F6: đổi tên")
keys({ "<M-L>" }, lsp(function() vim.lsp.buf.format({ async = true }) end), "Cmd+Alt+L: format")
keys({ "<M-n>" }, lsp(function()
  vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
end), "Cmd+N: sinh code (getter, constructor...)")
keys({ "<M-i>" }, lsp(function()
  if vim.bo.filetype == "java" then return require("jdtls").organize_imports() end
  vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" }, diagnostics = {} }, apply = true })
end), "Ctrl+Alt+O: sắp xếp import")

-- ===== Chạy, test, debug =====
keys({ "<S-F10>", "<F22>" }, spring("run"), "Shift+F10: chạy app")
keys({ "<S-F9>", "<F21>" }, spring("run_debug"), "Shift+F9: chạy app chế độ debug")
keys({ "<M-q>" }, spring("stop"), "Cmd+F2: dừng app")
keys({ "<M-t>" }, spring("test_class"), "Cmd+Shift+F10: chạy test class")
keys({ "<M-T>" }, spring("toggle_test"), "Cmd+Shift+T: nhảy class <-> test")
keys({ "<M-8>" }, function() require("dap").toggle_breakpoint() end, "Cmd+F8: breakpoint")

# coding-neovim — Design Document

> Cấu hình Neovim **nhẹ, cross-OS**, tối ưu cho việc **đọc code, điều hướng, search**
> và **tự học, tự viết code** (không dùng công cụ AI), phối hợp với **tmux**.

---

## 1. Triết lý & phạm vi

Đây là môi trường để **tự học và tự viết code**, trọng tâm là JS/TS và Java/Spring Boot.
Công cụ nặng (LSP, debug) chỉ nạp khi cần, nên Neovim vẫn là một **"code cockpit" nhẹ, di động**:

- 🪶 **Nhẹ & nhanh**: khởi động < 100ms, lazy-load tối đa, ít plugin nặng.
- 🌍 **Cross-OS**: chạy giống nhau trên macOS / Linux / WSL. Không phụ thuộc binary khó cài.
- 🔀 **Di chuyển session mượt**: nhảy qua lại giữa các ngữ cảnh **BE / FE / job** (dùng tmux).
- 🔎 **Search mạnh**: tìm file, tìm từ khoá, tìm symbol trong thư mục lớn cực nhanh.
- 📖 **Dễ đọc code**: highlight tốt, điều hướng definition/reference, đọc diff, đọc git blame.
- 🎓 **Tự học**: mọi thao tác do người dùng tự làm, repo không tích hợp công cụ AI.

### Không nằm trong phạm vi
- Tích hợp công cụ AI vào config (AI CLI, plugin AI). Mặc định có sẵn của thư viện thì giữ nguyên, không can thiệp.
- Plugin cần license hoặc tải backend đóng gói riêng.
- Format-on-save, linter bắt buộc.

---

## 2. Nguyên tắc thiết kế

| Nguyên tắc | Ý nghĩa thực tế |
|---|---|
| **Nhẹ trước, tính năng sau** | Mỗi plugin phải trả lời được: "có xứng với thời gian khởi động không?" |
| **Portable** | Không hardcode path tuyệt đối; ưu tiên tool có sẵn / dễ cài qua Mason |
| **Muscle memory** | Keymap nhất quán, namespace rõ ràng, dùng `which-key` để không phải nhớ |
| **tmux là bạn** | Neovim lo *trong* file; tmux lo *giữa* các session/pane. Điều hướng liền mạch |
| **Đọc > Viết** | Tối ưu cho việc *hiểu* codebase nhanh hơn là gõ nhiều |

---

## 3. Kiến trúc & cấu trúc thư mục

```
~/.config/nvim/   (repo này symlink tới đây)
├── init.lua                 # entrypoint: nạp config + bootstrap lazy.nvim
├── lua/
│   ├── config/
│   │   ├── options.lua       # vim options (số dòng, clipboard, autoread, ...)
│   │   ├── keymaps.lua       # keymap toàn cục (không thuộc plugin nào)
│   │   └── autocmds.lua      # auto-reload file, yank highlight, ...
│   └── plugins/
│       ├── ui.lua            # colorscheme, statusline, which-key
│       ├── navigation.lua    # telescope/fzf, file explorer, flash
│       ├── treesitter.lua    # highlight + textobjects
│       ├── lsp.lua           # LSP tối giản (navigation-focused)
│       ├── git.lua           # gitsigns, diffview, (neogit tùy chọn)
│       ├── java.lua          # jdtls + Spring LS
│       ├── debug.lua         # nvim-dap (chỉ nạp khi debug)
│       ├── completion.lua    # blink.cmp
│       ├── backend.lua       # dadbod + curl.nvim
│       └── terminal.lua      # terminal nhanh (toggleterm)
├── DESIGN.md                # tài liệu này
└── README.md                # hướng dẫn cài đặt & phím tắt
```

**Package manager**: `lazy.nvim` — lazy-load theo event/filetype/keymap.

---

## 4. Các trụ cột tính năng

### 4.1 Search & Navigation (trọng tâm)
- **`telescope.nvim`** (hoặc `fzf-lua` nếu ưu tiên tốc độ tối đa):
  - Tìm file theo tên
  - Live grep (tìm từ khoá trong toàn bộ thư mục) — cần `ripgrep`
  - Tìm symbol, buffer, help, recent files
- **`flash.nvim`**: nhảy con trỏ tới bất kỳ đâu trên màn hình bằng vài phím.
- **File explorer nhẹ**: `oil.nvim` (edit thư mục như buffer) hoặc `neo-tree` (cây truyền thống).
- Dependency ngoài: **`ripgrep`** (grep nhanh), **`fd`** (tìm file nhanh) — cross-OS, dễ cài.

### 4.2 Đọc code
- **`nvim-treesitter`**: highlight chính xác + indent + textobjects (chọn hàm/khối nhanh).
- **LSP tối giản** (`nvim-lspconfig` + `mason.nvim`): chỉ bật cái nhẹ, dùng cho
  `gd` (definition), `gr` (references), `K` (hover), `gi` (implementation).
  → Không bật format-on-save, không ép diagnostics gắt (IDE chính lo phần đó).
- **`trouble.nvim`** (tùy chọn): xem danh sách references/diagnostics gọn.

### 4.3 Git — đọc & review nhanh
- **`gitsigns.nvim`**: dấu thay đổi ở gutter, nhảy hunk, blame dòng, stage hunk.
- **`diffview.nvim`**: xem diff toàn branch (`main...HEAD`), file history.
- Mục tiêu: **review nhanh trước khi commit/push**, không thay thế git workflow chính.

### 4.4 Terminal
- **`toggleterm.nvim`**: terminal float/split bật-tắt tức thì (`Ctrl-\`, `<leader>tt`).
- **Auto-reload**: file đổi bên ngoài (git pull, đổi nhánh) → Neovim tự nạp lại.

### 4.5 tmux integration (giữa các session)
- **`vim-tmux-navigator`**: dùng `Ctrl-h/j/k/l` để nhảy liền mạch giữa
  **Neovim split** và **tmux pane** — không phân biệt ranh giới.
- Config tmux được version-control trong repo tại `tmux/` (symlink tới
  `~/.config/tmux/tmux.conf`), kèm script `tmux/scripts/tmux-sessionizer`.
- Gợi ý workflow tmux:
  - Mỗi **project/ngữ cảnh** = 1 tmux session (`be`, `fe`, `job`).
  - Dùng `tmux switch-client` / `sessionizer` (fzf) để nhảy giữa BE/FE/job trong 1-2 phím.
  - Trong mỗi session: pane trái = Neovim, pane phụ = logs / test.

---

## 5. Bố cục phím tắt (namespace)

`leader` = `Space`. Dùng `which-key` để hiện gợi ý.

| Prefix | Nhóm | Ví dụ |
|---|---|---|
| `<leader>f` | **Find/Search** | `ff` file, `fg` grep, `fb` buffer, `fs` symbol |
| `<leader>g` | **Git** | `gd` diffview, `gb` blame, `gh` hunk history |
| `<leader>t` | **Terminal** | `tt` nổi, `tT` bên dưới |
| `<leader>e` | **Explorer** | `e` toggle file tree |
| `<leader>b` | **Buffer** | chuyển/đóng buffer |
| `g` `[` `]` | **Navigation** | `gd` def, `gr` refs, `]c`/`[c` hunk, `]d`/`[d` diagnostic |
| `Ctrl-h/j/k/l` | **tmux/split** | nhảy giữa pane & split |

> Tham chiếu keymap kiểu IntelliJ (search everywhere, find-in-files, go-to-definition)
> sẽ được map tương ứng và ghi rõ trong README.

---

## 6. Cross-OS checklist

| Yêu cầu | Cách xử lý |
|---|---|
| Clipboard hoạt động mọi OS | `set clipboard=unnamedplus`; ghi chú tool clipboard cho từng OS |
| Không phụ thuộc path tuyệt đối | Dùng `vim.fn.stdpath()`, biến môi trường |
| Binary ngoài (rg, fd, node...) | Cài qua package manager OS / Mason; README liệt kê rõ |
| Font & icon | Dùng Nerd Font; có fallback khi thiếu icon |
| WSL | Ghi chú clipboard & path riêng cho WSL trong README |

---

## 7. Lộ trình build (từng bước)

Chúng ta build **tăng dần**, mỗi bước chạy được & commit riêng:

- [x] **Bước 0** — Khởi tạo repo, DESIGN.md, README skeleton
- [x] **Bước 1** — `init.lua` + bootstrap lazy.nvim + `options`/`keymaps`/`autocmds` cơ bản
- [~] **Bước 2** — which-key + lualine + bufferline (còn colorscheme)
- [x] **Bước 3** — Search & Navigation (telescope + fzf-native) ← trọng tâm
- [x] **Bước 4** — Treesitter nhánh `main` (highlight + textobjects, cần Neovim 0.12)
- [x] **Bước 5** — Git (gitsigns + diffview)
- [x] **Bước 6** — Terminal (toggleterm) + auto-reload (đã bỏ AI CLI)
- [x] **Bước 7** — tmux navigator + config tmux + sessionizer BE/FE/job
- [x] **Bước 8** — LSP tối giản (mason + lspconfig, navigation-focused)
- [x] colorscheme (Tokyonight trong suốt) + file explorer (neo-tree) + markdown preview
- [x] nvim-jdtls cho Java/Spring (Java 21 + Lombok) + toggle bật/tắt toàn bộ LSP (mặc định TẮT)
- [x] Extra — grug-far (search & replace project) · aerial (outline treesitter) · nvim-autopairs · git-conflict
- [x] Spring Boot — jdtls + Spring LS, chạy app/test (`util/spring.lua`), nvim-dap, blink.cmp, dadbod, curl.nvim
- [ ] còn lại (tùy chọn) — trouble, harpoon, flash

---

## 8. Tiêu chí "xong tốt"

- ✅ Khởi động nhanh (`nvim --startuptime`) — mục tiêu < 100ms.
- ✅ Copy repo sang máy/OS khác → chạy được sau khi cài vài binary liệt kê sẵn.
- ✅ Từ lúc mở Neovim tới lúc grep ra 1 từ khoá trong project < 3 giây thao tác.
- ✅ Nhảy BE ↔ FE ↔ job qua tmux trong ≤ 2 phím.

# coding-neovim — Design Document

> Cấu hình Neovim **nhẹ, cross-OS**, tối ưu cho việc **đọc code, điều hướng, search**
> và **coding cùng AI CLI** (Claude, Codex, ...), phối hợp với **tmux**.

---

## 1. Triết lý & phạm vi

Đây **không** phải một full IDE. Việc check lỗi / debug / develop nặng đã có IDE riêng lo.
Neovim ở đây đóng vai trò một **"code cockpit" nhẹ, di động**:

- 🪶 **Nhẹ & nhanh**: khởi động < 100ms, lazy-load tối đa, ít plugin nặng.
- 🌍 **Cross-OS**: chạy giống nhau trên macOS / Linux / WSL. Không phụ thuộc binary khó cài.
- 🔀 **Di chuyển session mượt**: nhảy qua lại giữa các ngữ cảnh **BE / FE / job** (dùng tmux).
- 🔎 **Search mạnh**: tìm file, tìm từ khoá, tìm symbol trong thư mục lớn cực nhanh.
- 📖 **Dễ đọc code**: highlight tốt, điều hướng definition/reference, đọc diff, đọc git blame.
- 🤖 **AI CLI trong tầm tay**: mở `claude` / `codex` ngay trong session, gửi context nhanh.

### Không nằm trong phạm vi (để riêng cho IDE chính)
- Debugger nặng (DAP), test runner phức tạp, linter/formatter bắt buộc.
- Language tooling đầy đủ cho mọi ngôn ngữ. Chỉ giữ LSP **read-only-friendly**
  (go-to-definition, hover, references) — không ép format/lint.

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
│       └── ai.lua            # toggleterm + AI CLI, (avante tùy chọn)
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

### 4.4 AI CLI trong session
- **`toggleterm.nvim`**: terminal float/split bật-tắt tức thì, giữ session:
  - `<leader>ac` → `claude`
  - `<leader>ax` → `codex`
  - `<leader>at` → terminal trống (chạy lệnh nhanh)
- **Auto-reload**: khi AI sửa file trên đĩa → Neovim tự nạp lại (autoread + checktime).
- **Gửi context**: keymap gửi `path:line` của file đang mở sang session AI.
- **`avante.nvim`** (tùy chọn, giai đoạn sau): hỏi/refactor inline, nhận diff.

### 4.5 tmux integration (giữa các session)
- **`vim-tmux-navigator`**: dùng `Ctrl-h/j/k/l` để nhảy liền mạch giữa
  **Neovim split** và **tmux pane** — không phân biệt ranh giới.
- Config tmux được version-control trong repo tại `tmux/` (symlink tới
  `~/.config/tmux/tmux.conf`), kèm script `tmux/scripts/tmux-sessionizer`.
- Gợi ý workflow tmux:
  - Mỗi **project/ngữ cảnh** = 1 tmux session (`be`, `fe`, `job`).
  - Dùng `tmux switch-client` / `sessionizer` (fzf) để nhảy giữa BE/FE/job trong 1-2 phím.
  - Trong mỗi session: pane trái = Neovim, pane phải = AI CLI / logs / test.

---

## 5. Bố cục phím tắt (namespace)

`leader` = `Space`. Dùng `which-key` để hiện gợi ý.

| Prefix | Nhóm | Ví dụ |
|---|---|---|
| `<leader>f` | **Find/Search** | `ff` file, `fg` grep, `fb` buffer, `fs` symbol |
| `<leader>g` | **Git** | `gd` diffview, `gb` blame, `gh` hunk history |
| `<leader>a` | **AI** | `ac` claude, `ax` codex, `af` gửi file/context |
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
- [x] **Bước 4** — Treesitter (highlight + textobjects)
- [x] **Bước 5** — Git (gitsigns + diffview)
- [x] **Bước 6** — AI CLI (toggleterm + claude/codex, nhiều session) + auto-reload
- [x] **Bước 7** — tmux navigator + config tmux + sessionizer BE/FE/job
- [ ] **Bước 8** — LSP tối giản (navigation-focused), chỉ khi cần
- [ ] còn lại — colorscheme, file explorer, (tùy chọn) avante inline, trouble

---

## 8. Tiêu chí "xong tốt"

- ✅ Khởi động nhanh (`nvim --startuptime`) — mục tiêu < 100ms.
- ✅ Copy repo sang máy/OS khác → chạy được sau khi cài vài binary liệt kê sẵn.
- ✅ Từ lúc mở Neovim tới lúc grep ra 1 từ khoá trong project < 3 giây thao tác.
- ✅ Nhảy BE ↔ FE ↔ job qua tmux trong ≤ 2 phím.
- ✅ Mở `claude`/`codex` và quay lại code không mất session, file tự cập nhật.

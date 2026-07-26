# coding-neovim

Cấu hình Neovim **nhẹ, cross-OS**, tối ưu cho **đọc code, điều hướng, search** và
**coding cùng AI CLI** (Claude, Codex, ...) trong workflow **tmux**.

> 📖 Xem [DESIGN.md](DESIGN.md) để hiểu triết lý, kiến trúc và lộ trình build.

---

## Trạng thái

🚧 **Đang xây dựng** — build tăng dần theo lộ trình trong DESIGN.md.

- [x] Bước 0 — Khởi tạo repo & tài liệu
- [x] Bước 1 — Bootstrap lazy.nvim + config cơ bản (options/keymaps/autocmds) — startup ~18ms
- [x] Bước 2 — UI nền tảng: which-key + lualine + bufferline + colorscheme (Tokyonight, trong suốt) ✅
- [x] Bước 3 — Search & Navigation (Telescope + fzf-native) ✅
- [x] Bước 4 — Treesitter (highlight + textobjects) ✅
- [x] Bước 8 — LSP tối giản (mason + lspconfig, navigation-focused) ✅
- [x] Extra — File explorer (neo-tree) · Markdown preview ✅
- [x] Bước 5 — Git (gitsigns + diffview) ✅
- [x] Bước 6 — AI CLI (toggleterm: claude/codex, nhiều session, gửi context) ✅
- [x] Bước 7 — tmux (vim-tmux-navigator + config mới + sessionizer BE/FE/job) ✅
- [ ] ... (xem DESIGN.md §7)

### tmux

Config tmux được version-control trong repo (`tmux/`), symlink tới `~/.config/tmux/tmux.conf`.
Prefix mặc định: **`Ctrl-t`**.

> 📖 Phím tắt tmux đầy đủ: [tmux/KEYBINDINGS.md](tmux/KEYBINDINGS.md)

| Phím | Chức năng |
|---|---|
| `Ctrl-h/j/k/l` | Nhảy liền mạch giữa **Neovim split ↔ tmux pane** |
| `Ctrl-f` hoặc `prefix f` | **Sessionizer**: fzf chọn project → tạo/switch session (BE/FE/job) |
| `prefix s` | Danh sách session đang có |
| `prefix \|` / `prefix -` | Split dọc / ngang (mở ở đúng thư mục hiện tại) |
| `prefix h/j/k/l` | Resize pane · `prefix m` zoom pane |
| `prefix r` | Reload config |

- **Session bền**: tmux-resurrect + continuum tự lưu mỗi 15' và khôi phục khi mở lại.
- **Sessionizer** tìm project trong `~/develop ~/projects ~/work ~/code`
  (đổi bằng biến `TMUX_SESSIONIZER_PATHS`). Cần `fzf` (+ `fd` nếu có).
- Đã bật `focus-events` (Neovim autoread trong tmux) + true color.

### AI CLI

AI CLI chạy dạng **tmux pane bên phải**. Mỗi lần bấm mở **1 pane mới** (không
cướp focus khỏi Neovim), thêm **cột mới bên phải, cạnh nhau** (full-height).
> ⚠️ Cần chạy Neovim **bên trong tmux**.

| Phím | Chức năng |
|---|---|
| `Space a c` | Claude (pane mới) · `Space a x` Codex · `Space a g` Gemini |
| `Space a C` | Claude: **tiếp tục session trước** (`--continue`) |
| `Space a s` | **Xem toàn bộ session AI** + nhảy tới session chọn |
| `Space a q` | Đóng tất cả session AI |
| `Space a f` | Gửi file hiện tại (`@path`) sang AI pane gần nhất |
| `Space a l` | Gửi `@path:dòng` hiện tại |
| `Space a v` | (visual) Gửi vùng chọn `@path:range` |
| `Space a r` | **Xem AI vừa update gì** (mở diff) |
| `Space a ?` | Xem bảng phím thao tác AI |
| `Space a t` / `Space a T` | Terminal scratch trong nvim (float / dưới) |
| `Ctrl-\` | Bật/tắt terminal scratch nhanh |

- Nhảy vào/ra AI pane bằng `Ctrl-h/j/k/l` (vim-tmux-navigator).
- Bề rộng cột AI ~40%, đổi ở `M.width_ratio` trong `lua/util/ai.lua`.
- File do AI sửa trên đĩa → Neovim **tự nạp lại** (autoread + focus-events).
- Gửi context **không tự submit** — bạn xem/sửa rồi tự Enter.

### File explorer (neo-tree)

| Phím | Chức năng |
|---|---|
| `Space e` | Bật/tắt cây thư mục (tự hiện file đang mở) |
| `Space E` | Hiện (reveal) file hiện tại trong cây |
| `Space g e` | Xem git status dạng cây (float) |

Trong cây: `l`/`Enter` mở · `h` đóng nhánh · `P` xem preview · `a` thêm · `d` xoá · `r` đổi tên · `?` xem toàn bộ phím.

### Đọc code (Treesitter)

Highlight chính xác theo cây cú pháp cho JS/TS, Java, HTML/CSS, JSON/YAML... (25 parser).

| Phím | Chức năng |
|---|---|
| `Ctrl-Space` | Mở rộng vùng chọn theo cú pháp (bấm tiếp để rộng thêm) · `BS` thu lại |
| `af` / `if` | Chọn cả hàm / thân hàm |
| `ac` / `ic` | Chọn cả class / thân class |
| `aa` / `ia` | Chọn tham số |
| `]f` / `[f` | Nhảy hàm kế tiếp / trước |
| `]t` / `[t` | Nhảy class kế tiếp / trước |

> `af`/`if`/`ac`/`ic`/`aa` dùng kèm toán tử: `daf` xoá cả hàm, `vic` chọn thân class, `cia` sửa tham số...

### LSP (điều hướng & hiểu code)

Tối giản, tập trung **đọc/hiểu code** — không format-on-save, không ép lint.
Server tự cài qua `:Mason`. Đã có: Lua, JS/TS, HTML/CSS, Tailwind, JSON, YAML, Bash, Java (cơ bản).

| Phím | Chức năng |
|---|---|
| `gd` | Nhảy tới **định nghĩa** (Telescope) |
| `gr` | **References** (nơi dùng) |
| `gi` / `gy` | Implementations / Type definition |
| `K` | **Hover** — xem type/doc |
| `gl` | Xem diagnostic dòng hiện tại |
| `]d` / `[d` | Diagnostic kế tiếp / trước |
| `Space r n` | Đổi tên (rename) toàn bộ |
| `Space c a` | Code action (sửa nhanh) |
| `Space c f` | Format (thủ công, không tự động) |
| `Space c d` | Danh sách diagnostic (Telescope) |
| `Space c l` | **Bật/tắt TOÀN BỘ LSP** |

Bật/tắt toàn bộ LSP còn có lệnh: `:LspToggle` · `:LspEnable` · `:LspDisable`
(tắt = dừng mọi client kể cả jdtls + chặn tự attach; bật = gắn lại các buffer đang mở).

> ⚙️ **Mặc định LSP TẮT** khi khởi động (đọc code nhẹ, không giật). Bật khi cần
> điều hướng/hiểu code bằng `Space c l` hoặc `:LspEnable`. Đổi mặc định ở
> `M.enabled` trong `lua/util/lsp.lua`.

- Quản lý server: `:Mason` (cài/gỡ). Xem trạng thái LSP: `:checkhealth lsp`.
- **Java / Spring**: qua `nvim-jdtls` (chạy bằng Java 21), cấu hình trong
  `lua/plugins/java.lua`. Lần đầu mở file `.java` jdtls sẽ **import project
  (Maven/Gradle) — mất ~1-2 phút** tải sources/dependencies; sau đó `gd`/`K`/`gr`
  hoạt động bình thường. Đổi đường dẫn JDK trong file đó nếu máy khác.
- **Lombok**: jdtls cần lombok.jar làm javaagent (hiểu getter/setter/builder sinh tự động).
  Đặt jar tại `~/.local/share/nvim/lombok.jar`. Lấy nhanh từ maven cache:
  ```bash
  cp ~/.m2/repository/org/projectlombok/lombok/*/lombok-*.jar ~/.local/share/nvim/lombok.jar
  # hoặc tải: curl -L https://projectlombok.org/downloads/lombok.jar -o ~/.local/share/nvim/lombok.jar
  ```
  Thiếu jar thì jdtls vẫn chạy, chỉ là không hiểu code Lombok.

### Markdown

| Phím (trong file `.md`) | Chức năng |
|---|---|
| `Space m r` | Render markdown **trong editor** (bật/tắt) — heading, bảng, code, checkbox |
| `Space m p` | Preview trên **trình duyệt** (live, cuộn đồng bộ) |

> render-markdown bật sẵn khi mở file `.md`. markdown-preview tải binary khi cài lần đầu.

### Git

| Phím | Chức năng |
|---|---|
| `]c` / `[c` | Nhảy tới hunk (thay đổi) kế tiếp / trước |
| `Space g p` | Xem trước thay đổi của hunk |
| `Space g s` / `Space g r` | Stage / bỏ thay đổi hunk (dùng được ở visual) |
| `Space g S` | Stage cả file · `Space g u` undo stage |
| `Space g b` | Bật/tắt blame theo dòng · `Space g B` blame chi tiết |
| `Space g d` | **Diff các thay đổi chưa commit** |
| `Space g D` | Diff so với base branch (`origin/HEAD...HEAD`) |
| `Space g h` / `Space g H` | Lịch sử file hiện tại / toàn repo |
| `Space g c` | Đóng diffview |

Trong diffview: `Tab`/`Shift-Tab` chuyển file, `]c`/`[c` nhảy hunk, `q` để đóng.

### Phím search (Telescope)

| Phím | Chức năng |
|---|---|
| `<space><space>` / `<space>ff` | Tìm file |
| `<space>fg` | **Grep từ khoá toàn project** |
| `<space>fw` | Grep từ dưới con trỏ (hoặc vùng chọn) |
| `<space>/` | Tìm trong file hiện tại |
| `<space>fo` | File mở gần đây |
| `<space>fb` | Danh sách buffer |
| `<space>fr` | Mở lại kết quả tìm trước |
| `<space>fk` | Tra cứu phím tắt |

Trong ô tìm: `Ctrl-j/k` di chuyển, `Ctrl-q` gửi kết quả ra quickfix, `Esc` đóng.

### UI

- **Colorscheme**: Tokyonight, **nền trong suốt** (thấy nền iTerm phía sau). Đổi tông
  ở `style` trong `lua/plugins/colorscheme.lua` (`night`/`storm`/`moon`/`day`).
  Transparent áp dụng bền kể cả khi đổi sang colorscheme khác.
- **which-key**: bấm `Space` rồi chờ ~0.3s → hiện bảng gợi ý phím theo nhóm (Find/Git/AI...).
  `Space ?` → xem phím tắt riêng của buffer hiện tại.
- **lualine**: statusline hiện mode · nhánh git · diff · diagnostic · file · vị trí dòng:cột.
- **bufferline**: thanh tab các file đang mở ở trên cùng.

| Phím | Tab (file đang mở) |
|---|---|
| `Shift-h` / `Shift-l` | Tab trước / sau |
| `Space 1..5` | Nhảy tới tab số 1..5 |
| `Space b d` | Đóng tab hiện tại |
| `Space b o` | Đóng các tab khác |
| `Space b p` | Ghim/bỏ ghim tab |
| `Space b h` / `Space b l` | Đóng tab bên trái / phải |

---

## Yêu cầu (dependencies)

Sẽ được bổ sung dần khi build. Dự kiến:

| Tool | Mục đích | Cài |
|---|---|---|
| Neovim ≥ 0.10 | Editor | `brew install neovim` / `apt` / ... |
| `ripgrep` | Live grep | `brew install ripgrep` |
| `fd` | Tìm file | `brew install fd` |
| Nerd Font | Icon | https://www.nerdfonts.com |
| `git` | Git integration | — |
| `tmux` ≥ 3.3 | Session BE/FE/job | `brew install tmux` |
| `fzf` | Sessionizer | `brew install fzf` |
| `node` | Một số LSP | — |
| `claude` / `codex` CLI | AI trong session | theo hướng dẫn từng tool |

---

## Cài đặt

> Sẽ hoàn thiện sau khi có Bước 1.

```bash
# Backup config cũ (nếu có)
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true

# Clone & symlink
git clone <repo-url> ~/develop/coding-neovim
ln -s ~/develop/coding-neovim ~/.config/nvim

# Mở nvim, lazy.nvim sẽ tự cài plugin
nvim
```

---

## Phím tắt

> Bảng đầy đủ sẽ cập nhật khi các plugin được thêm. Xem namespace trong DESIGN.md §5.

| Prefix | Nhóm |
|---|---|
| `<leader>f` | Find / Search |
| `<leader>g` | Git |
| `<leader>a` | AI CLI |
| `Ctrl-h/j/k/l` | Nhảy giữa split & tmux pane |

`leader` = `Space`.

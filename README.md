# coding-neovim

Cấu hình Neovim **nhẹ, cross-OS** để **tự học và tự viết code**: đọc code, điều hướng,
search và lập trình trong workflow **tmux**. Không dùng công cụ AI.

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
- [x] Bước 7 — tmux (vim-tmux-navigator + config mới + sessionizer BE/FE/job) ✅
- [x] Extra — Search&Replace (grug-far) · Outline (aerial) · autopairs · git-conflict ✅
- [x] Spring Boot — jdtls + Spring LS · chạy app/test · debug · completion · database · curl ✅
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

### Terminal

| Phím | Chức năng |
|---|---|
| `Ctrl-\` | Bật/tắt terminal nhanh |
| `Space t t` / `Space t T` | Terminal nổi / bên dưới |

### File explorer (neo-tree)

| Phím | Chức năng |
|---|---|
| `Space e` | Bật/tắt cây thư mục (tự hiện file đang mở) |
| `Space E` | Hiện (reveal) file hiện tại trong cây |
| `Space g e` | Xem git status dạng cây (float) |

Trong cây: `l`/`Enter` mở · `h` đóng nhánh · `P` xem preview · `a` thêm · `d` xoá · `r` đổi tên · `?` xem toàn bộ phím.

### Đọc code (Treesitter)

Highlight chính xác theo cây cú pháp cho JS/TS, Java, HTML/CSS, JSON/YAML... (24 parser).
Dùng `nvim-treesitter` nhánh `main` (bắt buộc với Neovim 0.12), cần `tree-sitter-cli`.

| Phím | Chức năng |
|---|---|
| `Ctrl-Space` | Chọn theo cú pháp (bấm tiếp để rộng thêm) · `BS` thu lại — dựa trên `an`/`in` có sẵn của Neovim 0.12 |
| `af` / `if` | Chọn cả hàm / thân hàm |
| `ac` / `ic` | Chọn cả class / thân class |
| `aa` / `ia` | Chọn tham số |
| `]f` / `[f` | Nhảy hàm kế tiếp / trước |
| `]t` / `[t` | Nhảy class kế tiếp / trước |

> `af`/`if`/`ac`/`ic`/`aa` dùng kèm toán tử: `daf` xoá cả hàm, `vic` chọn thân class, `cia` sửa tham số...

### LSP (điều hướng & hiểu code)

Tối giản, tập trung **đọc/hiểu code** — không format-on-save, không ép lint.
Server tự cài qua `:Mason`. Đã có: Lua, JS/TS, HTML/CSS, Tailwind, JSON, YAML, Bash, Java, Spring, XML/pom, Docker.

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

> ⚙️ **Mặc định LSP BẬT**: server tự chạy khi mở file đúng loại, vd jdtls khi mở `.java`. Tắt tạm bằng
> `Space c l` hoặc `:LspDisable` (không lưu lại khi mở Neovim lần sau). Đổi mặc định ở `M.enabled`
> trong `lua/util/lsp.lua`.

- Quản lý server: `:Mason` (cài/gỡ). Xem trạng thái LSP: `:checkhealth lsp`.
- **Java / Spring**: xem mục [Spring Boot](#spring-boot) bên dưới.

### Spring Boot

Nhóm phím `Space j`. Phần lớn **không cần LSP**: chạy trực tiếp bằng wrapper của project
(`mvnw`/`gradlew`, không có thì `mvn`/`gradle`) trong tmux pane dưới Neovim, ngoài tmux thì mở
terminal split. `JAVA_HOME` tự đặt đúng version trong `pom.xml`/`build.gradle`.

| Phím | Chức năng | Cần LSP |
|---|---|---|
| `Space j r` / `Space j R` | Chạy app (nhớ profile đã chọn) / chọn lại profile | |
| `Space j D` | Chạy app ở chế độ debug (cổng 5005) | |
| `Space j q` | Dừng app | |
| `Space j t` / `Space j n` | Test class hiện tại / method dưới con trỏ | |
| `Space j T` | Test toàn bộ | |
| `Space j m` | Lệnh Maven/Gradle: `dependency:tree`, `flyway:*`, `package`... | |
| `Space j a` | Nhảy class ↔ test (chưa có test thì mở khung JUnit 5, chưa lưu) | |
| `Space j e` / `Space j b` | Tìm endpoint / bean | |
| `Space j y` | Mở file trong `src/main/resources` | |
| `Space j k` | Docker (lazydocker) | |
| `Space j o` | Sắp xếp import | ✓ |
| `Space j v` / `Space j C` | Tách biến / hằng số (dùng được ở visual) | ✓ |
| `Space j x` | Tách method (visual) | ✓ |
| `Space j U` | Cập nhật project sau khi sửa `pom.xml` | ✓ |
| `Space j s` | Tra bean/endpoint qua Spring LS | ✓ |
| `Space c i` / `Space c I` | Ai gọi hàm này / hàm này gọi gì | ✓ |
| `Space c h` / `Space c H` | Class con, implement / class cha, interface | ✓ |

**Tạo file Java:** mở một file `.java` trống là tự có `package` (theo đường dẫn sau `src/main/java` hoặc
`src/test/java`) và `class` theo tên file. Tạo bằng neo-tree (`a`, file mở luôn) hay `:e` đều được, không cần LSP.
Nội dung chưa lưu, `:w` để lưu.

Khi LSP đang bật:
- **jdtls** chạy bằng JDK mới nhất có trên máy (**jdtls 1.63 cần Java 25**, không khởi động được
  trên Java 21); project vẫn biên dịch đúng version của nó. JDK được tự dò từ sdkman, JVM hệ thống.
- **Lombok** dùng jar có sẵn trong package jdtls của Mason, không cần tải thêm.
- **Spring LS** gợi ý `application.yml`/`.properties`. Cần đang có jdtls: mở một file `.java` trước.
  Khi bật LSP sẽ thấy dòng "Embedded Spring Tools MCP server started": đây là mặc định của Spring LS,
  chỉ nhận kết nối nội bộ, không ảnh hưởng gì khi code.
- Lần đầu mở project, jdtls cần import. `buktour_service` mất khoảng 40 giây.

### Debug (nvim-dap)

Java cần bật LSP và đợi jdtls import xong.

| Phím | Chức năng |
|---|---|
| `Space d b` / `Space d B` | Breakpoint / có điều kiện |
| `Space d a` | **Attach vào app** đang chạy từ `Space j D` |
| `Space d c` hoặc `F9` | Bắt đầu / tiếp tục (chọn main class) |
| `F8` / `F7` / `Shift-F8` | Step over / into / out (giống IntelliJ) · cũng có `Space d n/i/o` |
| `Space d T` / `Space d N` | Debug test class / test method |
| `Space d e` | Xem giá trị biểu thức |
| `Space d u` / `Space d r` | Bật/tắt giao diện debug / REPL |
| `Space d l` / `Space d q` | Chạy lại lần trước / dừng debug |

### Gợi ý code (blink.cmp)

Trong Insert: `Enter` nhận gợi ý, `Ctrl-j/k` di chuyển, `Tab` qua ô tiếp theo của snippet.
LSP tắt thì vẫn gợi ý từ path, snippet và buffer. File SQL có gợi ý theo database đang kết nối.

### Database (dadbod) & gọi API (curl.nvim)

| Phím | Chức năng |
|---|---|
| `Space D d` | Bật/tắt giao diện database |
| `Space D a` | Thêm kết nối, vd `postgresql://user@localhost:5432/db` |
| `Space D f` | Gắn file SQL hiện tại vào một kết nối |
| `Space h h` / `Space h g` | Bảng curl của project / dùng chung |
| `Space h c` / `Space h q` | Chọn bộ request đã lưu / đóng bảng |

- Kết nối DB lưu ở thư mục data của Neovim, không nằm trong repo. Cần client của DB, vd `psql`.
- Bảng curl: viết lệnh `curl` ở khung trái, `Enter` để chạy, kết quả ở khung phải.

### Markdown

| Phím (trong file `.md`) | Chức năng |
|---|---|
| `Space m r` | Render markdown **trong editor** (bật/tắt) — heading, bảng, code, checkbox |
| `Space m p` | Preview trên **trình duyệt** (live, cuộn đồng bộ) |

> render-markdown bật sẵn khi mở file `.md`. markdown-preview chạy bằng `node` (cài dependency khi cài plugin).

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
| `Space g x` | **Liệt kê merge conflict** ra quickfix |

Trong diffview: `Tab`/`Shift-Tab` chuyển file, `]c`/`[c` nhảy hunk, `q` để đóng.

**Resolve merge conflict** (git-conflict) — chỉ hiệu lực trong file có dấu `<<<<<<<`:

| Phím | Chức năng |
|---|---|
| `co` | Chọn phần **của mình** (current) |
| `ct` | Chọn phần **của họ** (incoming) |
| `cb` | Giữ **cả hai** |
| `c0` | **Bỏ cả hai** |
| `]x` / `[x` | Nhảy conflict kế tiếp / trước |

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

### Search & Replace toàn project (grug-far)

Tìm & **thay thế hàng loạt** qua nhiều file (ripgrep). Mở 1 buffer chuyên dụng:
gõ **Search / Replace / Files-filter** → xem preview → apply.

| Phím | Chức năng |
|---|---|
| `Space s r` | Mở Search & Replace toàn project |
| `Space s w` | ... với **từ dưới con trỏ** điền sẵn |
| `Space s f` | ... giới hạn trong **file hiện tại** |
| `Space s` (visual) | ... với **vùng chọn** điền sẵn |

Trong buffer grug-far: gõ vào ô Search/Replace, kết quả tự hiện. `Space r` để **apply**, `Space q` đưa ra quickfix, `Space c` đóng (dòng header luôn hiện đủ phím). Hỗ trợ regex & flag ripgrep.

### Outline cấu trúc file (aerial)

Danh sách **class / function / method** để nhảy nhanh trong file dài — chạy bằng
**treesitter** nên **dùng được cả khi LSP tắt**.

| Phím | Chức năng |
|---|---|
| `Space c o` | Bật/tắt panel outline (bên phải) |
| `Space c O` | Popup điều hướng nhanh (nav) |
| `[o` / `]o` | Nhảy symbol trước / kế tiếp |

### UI

- **Colorscheme**: Tokyonight, **nền trong suốt** (thấy nền iTerm phía sau). Đổi tông
  ở `style` trong `lua/plugins/colorscheme.lua` (`night`/`storm`/`moon`/`day`).
  Transparent áp dụng bền kể cả khi đổi sang colorscheme khác.
- **which-key**: bấm `Space` rồi chờ ~0.3s → hiện bảng gợi ý phím theo nhóm (Find/Git/Java...).
  `Space ?` → xem phím tắt riêng của buffer hiện tại.
- **lualine**: statusline hiện mode · nhánh git · diff · diagnostic · file · vị trí dòng:cột.
- **bufferline**: thanh tab các file đang mở ở trên cùng.
- **autopairs**: tự đóng ngoặc/quote theo ngữ cảnh treesitter. `Alt-e` bọc nhanh phần còn lại của dòng vào ngoặc.

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
| Neovim ≥ 0.12 | Editor (aerial/treesitter cần 0.12) | `brew install neovim` / `apt` / ... |
| `tree-sitter-cli` ≥ 0.26.1 + C compiler | Build parser treesitter (**không** cài qua npm) | `brew install tree-sitter-cli` |
| `ripgrep` | Live grep | `brew install ripgrep` |
| `fd` | Tìm file | `brew install fd` |
| Nerd Font | Icon | https://www.nerdfonts.com |
| `git` | Git integration | — |
| `tmux` ≥ 3.3 | Session BE/FE/job | `brew install tmux` |
| `fzf` | Sessionizer | `brew install fzf` |
| `node` | Một số LSP | — |
| JDK 25 + JDK của project | Chạy jdtls / biên dịch | `sdk install java` |
| `jq` | Kết quả curl.nvim | `brew install jq` |
| `lazydocker` | Docker (tùy chọn) | `brew install lazydocker` |
| `psql` | Database Postgres (tùy chọn) | `brew install libpq` |

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
| `<leader>s` | Search / Replace (grug-far) |
| `<leader>g` | Git |
| `<leader>t` | Terminal |
| `<leader>c` | Code / LSP / Outline |
| `<leader>j` | Java / Spring |
| `<leader>d` | Debug |
| `<leader>D` | Database |
| `<leader>h` | HTTP (curl) |
| `Ctrl-h/j/k/l` | Nhảy giữa split & tmux pane |

`leader` = `Space`.

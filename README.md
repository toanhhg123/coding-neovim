# coding-neovim

Cấu hình Neovim **nhẹ, cross-OS** để **tự học và tự viết code**: đọc code, điều hướng,
search và lập trình trong workflow **tmux**. Không dùng công cụ AI.

> 📖 Xem [DESIGN.md](DESIGN.md) để hiểu triết lý, kiến trúc và lộ trình build.

---

## Trạng thái

🚧 **Đang xây dựng** — build tăng dần theo lộ trình trong DESIGN.md.

- [x] Bước 0 — Khởi tạo repo & tài liệu
- [x] Bước 1 — Bootstrap lazy.nvim + config cơ bản (options/keymaps/autocmds) — startup ~18ms
- [x] Bước 2 — UI nền tảng: which-key + lualine + bufferline + colorscheme theo iTerm (trong suốt) ✅
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
| `prefix f` | **Sessionizer**: fzf chọn project → tạo/switch session (BE/FE/job) |
| `prefix s` | Danh sách session đang có |
| `prefix \|` / `prefix -` | Split dọc / ngang (mở ở đúng thư mục hiện tại) |
| `prefix h/j/k/l` | Resize pane · `prefix m` zoom pane |
| `prefix r` | Reload config |

- **Session bền**: tmux-resurrect + continuum tự lưu mỗi 15' và khôi phục khi mở lại.
- **Sessionizer** tìm project trong `~/develop ~/projects ~/work ~/code`
  (đổi bằng biến `TMUX_SESSIONIZER_PATHS`). Cần `fzf` (+ `fd` nếu có).
- Đã bật `focus-events` (Neovim autoread trong tmux) + true color.

### Phím tắt Vim (mặc định)

Dùng được với profile **Default** của iTerm và các terminal khác, không cần chuyển phím `Cmd`.
Nhấn `Esc` để về Normal mode rồi bấm lần lượt, ví dụ `Space` → `f` → `f` để tìm file.
`Space` là leader; chữ hoa cần giữ `Shift`. Bấm `Space` rồi chờ để xem which-key.

**Quên phím?** Nhấn `Esc` → `Space ?` để mở bảng tra nhanh, rồi gõ tên việc muốn làm:
`debug`, `test`, `import`, `format`, `doi ten` (tìm tiếng Việt không dấu cũng được).
`Ctrl-j/k` hoặc mũi tên để chọn, `Enter` chạy hành động, `Esc` đóng bảng và quay lại code.
Bảng chỉ hiển thị phím Normal mode đang có hiệu lực trong file hiện tại, có cả phím Java/LSP
sau khi server attach. Có thể mở bằng `Space f k`, `:Keymaps` hoặc lọc sẵn với `:Keymaps test`.
Muốn xem gợi ý theo nhóm thì bấm `Space` rồi chờ; `Space f ?` xem các phím riêng của buffer.

| Phím | Chức năng |
|---|---|
| `Space ?` / `Space f k` | Tra nhanh keymap theo tên hành động |
| `Space f f` / `Space Space` | Tìm file |
| `Space f t` | Tìm class/type (chưa có LSP thì tìm file) |
| `Space f o` | File gần đây, kể cả file vừa đóng |
| `Space f g` | Tìm nội dung toàn project |
| `Space f s` / `Space f S` | Symbol trong file / toàn project |
| `Space f c` | Tìm lệnh / hành động |
| `Space f l` / `25G` | Tới dòng:cột / tới dòng 25 |
| `/từ_khóa` rồi `Enter`, `n` / `N` | Tìm trong file, kết quả tiếp / trước |
| `gd` / `gr` / `gi` / `gy` | Định nghĩa / nơi dùng / implementation / khai báo kiểu |
| `gS` | Method cha trong Java / class cha ở ngôn ngữ khác |
| `K` / `Space c p` | Tài liệu / thông tin tham số |
| `Ctrl-o` / `Ctrl-i` | Quay lại / đi tiếp vị trí |
| `Space w` / `u` / `Ctrl-r` | Lưu / undo / redo |
| `gcc` / chọn vùng rồi `gc` | Comment dòng / vùng chọn |
| `yyp` / chọn vùng rồi `Space c y` | Nhân đôi dòng / đúng vùng chọn |
| `ggVG` / `van` | Chọn tất cả / chọn theo cú pháp; Visual dùng `an`/`in` để rộng/thu lại |
| `Space r n` / `Space c a` | Đổi tên / sửa nhanh |
| `Space c f` / `Space c g` | Format / sinh code |
| `Space j o` / `Space j a` | Sắp xếp import / nhảy class ↔ test |
| `Space j r` / `Space j R` / `Space j q` | Chạy app / chọn profile / dừng app hoặc debug |
| `Space j t` / `Space j n` / `Space j T` | Test class / method / toàn bộ |
| `Space j D` / `Space d b` | Chạy debug và tự attach / breakpoint |
| `Space d c` / `Space d n` / `Space d i` / `Space d o` | Tiếp tục / step over / into / out |
| `Space d e` / `Space d q` | Xem biểu thức / dừng debug |
| `Space e` / `Space b d` / `Shift-h/l` | Cây file / đóng buffer / buffer trước-sau |
| `Ctrl-f` / `Ctrl-b` | Cuộn một trang xuống / lên (tmux không chiếm `Ctrl-f`) |

### Phím tắt IntelliJ (tùy chọn)

Bộ này **không nạp mặc định**. Chỉ bật nếu muốn dùng lại các phím `Cmd`: thêm vào
`lua/config/local.lua` (file riêng từng máy, không commit):

```lua
require("config.intellij")
```

Cần thêm profile iTerm trong repo để đổi `Cmd+phím` thành chuỗi Neovim nhận được.
Nếu dùng profile Default, iTerm vẫn xử lý các phím Cmd của nó; hãy dùng bộ phím Vim ở trên.

Cài đặt tùy chọn: chép profile rồi chọn `coding-neovim` cho tab iTerm dùng bộ phím Cmd.

```bash
cp iterm/coding-neovim.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/
```

| Phím | Chức năng | Phím | Chức năng |
|---|---|---|---|
| `Cmd+B` | Tới định nghĩa | `Cmd+O` | Tìm class |
| `Cmd+Alt+B` | Implementations | `Cmd+Shift+O` | Tìm file |
| `Alt+F7` | Tìm nơi dùng | `Cmd+Alt+O` | Tìm symbol |
| `Cmd+U` | Method cha (Java) / class cha | `Cmd+E` | File gần đây, kể cả đã đóng |
| `F1` | Xem tài liệu | `Cmd+F` | Tìm trong file |
| `Cmd+P` | Tham số của hàm | `Cmd+Shift+F` | Tìm trong project |
| `F2` / `Shift+F2` | Lỗi kế tiếp / trước | `Cmd+R` | Thay thế trong file |
| `Cmd+[` / `Cmd+]` | Lùi / tiến vị trí | `Cmd+Shift+R` | Thay thế trong project |
| `Alt+Enter` | Sửa nhanh | `Cmd+1` | Cây thư mục |
| `Shift+F6` | Đổi tên | `Cmd+9` | Thay đổi git |
| `Cmd+Alt+L` | Format | `Cmd+F12` | Cấu trúc file |
| `Ctrl+Alt+O` | Sắp xếp import | `Cmd+F4` | Đóng tab |
| `Cmd+N` | Sinh code | `Cmd+Shift+[` / `]` | Tab trước / sau |
| `Cmd+/` | Comment | `Shift+F10` | Chạy app |
| `Cmd+D` | Nhân đôi dòng / đúng vùng chọn | `Shift+F9` | Chạy app và tự attach debugger |
| `Cmd+Backspace` | Xoá dòng | `Cmd+F2` | Dừng app / debugger / hủy chờ JVM |
| `Alt+Shift+Up/Down` | Chuyển dòng | `Cmd+Shift+F10` | Chạy test class |
| `Cmd+W` / `Cmd+Shift+W` | Chọn rộng ra / hẹp lại | `Cmd+Shift+T` | Nhảy class ↔ test |
| `Cmd+S` | Lưu | `Cmd+F8` | Breakpoint |
| `Cmd+Z` / `Cmd+Shift+Z` | Hoàn tác / làm lại | `F7` `F8` `F9` `Shift+F8` | Into / over / tiếp tục / out |
| `Cmd+A` | Chọn tất cả | `Cmd+Shift+A` | Tìm lệnh / hành động |
| `Cmd+G` / `Cmd+Shift+G` | Kết quả tìm tiếp / trước | `Cmd+L` | Tới dòng hoặc `dòng:cột` |
| `Cmd+Shift+B` | Tới khai báo kiểu | | |

Lưu ý:
- Các phím điều hướng, tìm kiếm, Run/Debug dùng được từ Normal và Insert; khi cần sẽ thoát Insert.
- `Cmd+F` mở tìm kiếm `/` (regex Vim); `Cmd+G/Shift+G` tiếp tục cùng từ khóa. Tìm fuzzy trong file vẫn có `Space /`.
- Đây là keymap tùy biến: giữ `Cmd+W/Shift+W` để chọn cú pháp và `Shift+F10/F9` để Run/Debug.
- Không có `Shift Shift` (terminal không nhận được) và các phím `Ctrl` trùng với tmux hoặc Vim.
- Trong profile này các phím trên không còn làm việc của iTerm: `Cmd+W` không đóng tab, `Cmd+D` không chia pane,
  `Cmd+F` không tìm trong iTerm. Ngoài Neovim chúng gửi `Alt+phím`, vd trong zsh `Cmd+B` lùi một từ.
  `Cmd+C`, `Cmd+V`, `Cmd+T`, `Cmd+Q` giữ nguyên. Muốn đổi lại, chọn lại profile `Default`.
- `F1`, `F2`... trên bàn phím Mac có thể cần giữ `fn`.

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
| `Space j D` | Chạy app debug, chờ JVM và tự attach (cổng 5005) | ✓ |
| `Space j q` | Dừng app / debugger, hủy chờ attach | |
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
`src/test/java`) và `class` theo tên file. Trong `src/main`, khung đổi theo hậu tố tên file:

| Hậu tố | Khung |
|---|---|
| `Controller` | `@RestController` |
| `Service` | `@Service` |
| `Repository` | `@Repository` + `interface` |
| `Config`, `Configuration` | `@Configuration` |
| `Component` | `@Component` |

Controller và Service có thêm `@RequiredArgsConstructor` nếu project dùng Lombok.
 Tạo bằng neo-tree (`a`, file mở luôn) hay `:e` đều được, không cần LSP.
Nội dung chưa lưu, `:w` để lưu.

`package-info.java` và `module-info.java` được giữ trống để tự viết descriptor.
App/test chạy riêng theo từng module; lệnh dừng app chỉ tác động đến module của file hiện tại.

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
`Space j D` tự attach khi JVM báo JDWP sẵn sàng; chờ tối đa 60 giây.
`Space j q` hủy bước chờ hoặc dừng phiên hiện tại. Nếu build lâu hơn timeout,
xem log rồi attach thủ công bằng `Space d a`.

| Phím | Chức năng |
|---|---|
| `Space d b` / `Space d B` | Breakpoint / có điều kiện |
| `Space d a` | **Attach thủ công** vào JVM đang debug ở cổng 5005 |
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
| `<space>?` / `<space>fk` | Tra keymap theo tên hành động (Normal mode) |

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

- **Colorscheme**: `colors/iterm.lua`, lấy từ bảng màu profile iTerm, nền trong suốt. Đổi profile thì sửa bảng `c`
  đầu file. Terminal khác iTerm vẫn dùng được, chỉ là màu theo bảng này.
- **which-key**: bấm `Space` rồi chờ ~0.3s → hiện bảng gợi ý phím theo nhóm (Find/Git/Java...).
  `Space ?` → bảng tra keymap có tìm kiếm; `Space f ?` → phím tắt riêng của buffer hiện tại.
- **lualine**: chỉ có chữ, không nền: mode · nhánh git · file · diagnostic · filetype · dòng:cột.
- **bufferline**: tab các file đang mở, tab hiện tại chữ sáng, không viền. Ẩn khi chỉ có 1 file.
- **autopairs**: tự đóng ngoặc/quote theo ngữ cảnh treesitter. Trong Insert, `Ctrl-g` rồi `w` để bọc nhanh phần còn lại của dòng vào ngoặc.

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

`install.sh` cài sẵn các công cụ này, trừ Nerd Font và `psql`; `lazydocker` chỉ cài trên macOS:

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

Một lệnh, cho macOS (cần [Homebrew](https://brew.sh)) hoặc Debian/Ubuntu:

```bash
curl -fsSL https://raw.githubusercontent.com/toanhhg123/coding-neovim/main/install.sh | bash
```

Script [install.sh](install.sh) làm lần lượt:

1. Cài công cụ: Neovim ≥ 0.12, tree-sitter-cli, ripgrep, fd, fzf, tmux, Node ≥ 22, jq, git, JDK 21 và 25.
   macOS dùng Homebrew. Ubuntu dùng apt, còn Neovim, tree-sitter, Node, JDK 25 tải bản chính thức vào `~/.local`.
2. Clone repo vào `~/develop/coding-neovim` (đã có thì `git pull`).
3. Tạo symlink `~/.config/nvim`, `~/.config/tmux/tmux.conf`, `~/.config/tmux/scripts`.
   Config cũ ở các chỗ đó được đổi tên thành `*.bak-<thời gian>`, không bị xoá.
4. Cài plugin tmux, plugin Neovim (đúng version trong `lazy-lock.json`), parser treesitter, LSP qua Mason.
5. Chỉ khi đặt `INSTALL_ITERM_PROFILE=1`: thêm profile iTerm `coding-neovim` cho bộ phím Cmd tùy chọn.

Chạy lại bao nhiêu lần cũng được, bước nào đã xong thì bỏ qua. Lần đầu mất khoảng 5–10 phút.

Tuỳ chọn (đặt trước `bash`, vd `curl ... | SKIP_JAVA=1 bash`):

| Biến | Tác dụng |
|---|---|
| `CODING_NVIM_DIR=~/code/nvim` | Đổi thư mục clone |
| `SKIP_DEPS=1` | Không cài công cụ hệ thống, tự cài trước |
| `SKIP_JAVA=1` | Không cài JDK |
| `INSTALL_ITERM_PROFILE=1` | Cài profile iTerm cho bộ phím Cmd tùy chọn; mặc định không cài |

Muốn đọc script trước khi chạy:

```bash
git clone https://github.com/toanhhg123/coding-neovim.git ~/develop/coding-neovim
~/develop/coding-neovim/install.sh
```

Distro Linux khác: script vẫn liên kết config và cài plugin, nhưng bạn tự cài công cụ ở bước 1.

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
| `Cmd+...` | Bộ phím IntelliJ tùy chọn, xem mục [Phím tắt IntelliJ](#phím-tắt-intellij-tùy-chọn) |
| `Ctrl-h/j/k/l` | Nhảy giữa split & tmux pane |

`leader` = `Space`.

## Kiểm tra thay đổi

Cần Neovim ≥ 0.12 và Python 3. Chạy từ thư mục repo:

```bash
python3 -m unittest discover -s tests -v
```

Regression test kiểm tra startup mặc định không nạp Cmd, xung đột leader, shortcut theo mode,
vùng chọn UTF-8/dòng/khối, lịch sử file đã đóng và bộ IntelliJ tùy chọn. Có test output
terminal thật ở cửa sổ hẹp, debug sẵn sàng/timeout/hủy, exit code của setup và nâng cấp
Tree-sitter CLI trên macOS/Linux. Test chạy offline với LSP/DAP và công cụ cài đặt giả lập.
Nếu có tmux, test dùng server riêng để kiểm tra `Ctrl-f` và sessionizer; file/config bộ cài
chỉ được tạo trong thư mục tạm.
Test bảng tra keymap kiểm tra nhóm phím, tìm không dấu, ưu tiên buffer-local và các lệnh mở bảng;
nếu Telescope/plenary đã cài, có thêm test bấm Enter trong picker thật để chạy đúng hành động.

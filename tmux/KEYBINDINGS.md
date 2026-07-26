# tmux — Phím tắt

Tham chiếu đầy đủ phím tắt tmux của cấu hình này (`tmux/tmux.conf`).

> **Prefix = `Ctrl-t`** (viết tắt: `⟨p⟩`). Ví dụ `⟨p⟩ |` nghĩa là bấm `Ctrl-t` rồi bấm `|`.
> Phím ghi `(no prefix)` bấm trực tiếp, không cần prefix.

---

## 🔀 Điều hướng pane (không cần prefix)

| Phím | Chức năng |
|---|---|
| `Ctrl-h` | Sang pane/split **trái** (liền mạch Neovim ↔ tmux) |
| `Ctrl-j` | Xuống pane/split **dưới** |
| `Ctrl-k` | Lên pane/split **trên** |
| `Ctrl-l` | Sang pane/split **phải** |

> Nhờ `vim-tmux-navigator`: khi con trỏ đang trong Neovim thì nhảy giữa split của
> Neovim; tới mép thì tự nhảy sang tmux pane kế bên.

## 📁 Session / Project (BE / FE / job)

| Phím | Chức năng |
|---|---|
| `Ctrl-f` **(no prefix)** | **Sessionizer**: fzf chọn project → tạo/switch session |
| `⟨p⟩ f` | Sessionizer (như trên, qua prefix) |
| `⟨p⟩ s` | Danh sách **session** đang có → chọn để switch |
| `⟨p⟩ $` | Đổi tên session hiện tại |
| `⟨p⟩ d` | Detach (thoát khỏi tmux, session vẫn chạy nền) |
| `⟨p⟩ (` / `⟨p⟩ )` | Session trước / sau |

## 🪟 Window (tab)

| Phím | Chức năng |
|---|---|
| `⟨p⟩ c` | Tạo window mới (ở đúng thư mục hiện tại) |
| `⟨p⟩ 1..9` | Nhảy tới window số 1..9 |
| `⟨p⟩ n` / `⟨p⟩ p` | Window sau / trước |
| `⟨p⟩ w` | Danh sách window → chọn |
| `⟨p⟩ ,` | Đổi tên window |
| `⟨p⟩ &` | Đóng window (hỏi xác nhận) |

## 🔲 Pane

| Phím | Chức năng |
|---|---|
| `⟨p⟩ \|` | Split **dọc** (pane mới bên phải, đúng thư mục hiện tại) |
| `⟨p⟩ -` | Split **ngang** (pane mới bên dưới, đúng thư mục hiện tại) |
| `⟨p⟩ h/j/k/l` | **Resize** pane (giữ prefix, bấm lặp được) |
| `⟨p⟩ m` | **Zoom** pane (phóng to full màn hình / thu về) |
| `⟨p⟩ x` | Đóng pane hiện tại (hỏi xác nhận) |
| `⟨p⟩ z` | Zoom pane (mặc định tmux, tương đương `m`) |
| `⟨p⟩ {` / `⟨p⟩ }` | Đổi vị trí pane với pane trước / sau |
| `⟨p⟩ Space` | Đổi layout pane (even-h, even-v, main...) |
| `⟨p⟩ q` | Hiện số thứ tự pane (bấm số để nhảy) |

## 📋 Copy mode (cuộn & copy — kiểu vim)

| Phím | Chức năng |
|---|---|
| `⟨p⟩ [` | Vào **copy mode** (để cuộn lên đọc lịch sử) |
| `h/j/k/l`, `w`, `b`, `G`, `gg` | Di chuyển kiểu vim (trong copy mode) |
| `/` , `?` | Tìm xuôi / ngược |
| `v` | Bắt đầu bôi chọn |
| `y` | Copy vùng chọn (vào clipboard hệ thống) rồi thoát |
| `q` hoặc `Esc` | Thoát copy mode |
| `⟨p⟩ ]` | Paste vùng vừa copy |

## 💾 Session persistence (resurrect / continuum)

| Phím | Chức năng |
|---|---|
| `⟨p⟩ Ctrl-s` | **Lưu** toàn bộ session ra đĩa (thủ công) |
| `⟨p⟩ Ctrl-r` | **Khôi phục** session đã lưu |

> `continuum` tự lưu mỗi **15 phút** và tự khôi phục khi mở tmux (đã bật sẵn).

## ⚙️ Khác

| Phím | Chức năng |
|---|---|
| `⟨p⟩ r` | **Reload** config (`tmux.conf`) |
| `⟨p⟩ t` | Hiện đồng hồ |
| `⟨p⟩ ?` | Xem **toàn bộ** phím tắt tmux hiện có |
| `⟨p⟩ :` | Nhập lệnh tmux (command prompt) |
| `⟨p⟩ Ctrl-t` | Gửi `Ctrl-t` thật xuống chương trình (vì prefix chiếm C-t) |

---

## Ghi chú

- Prefix mặc định của tmux là `Ctrl-b`; ở đây đổi thành **`Ctrl-t`**. Muốn đổi lại,
  sửa dòng `set -g prefix` trong `tmux/tmux.conf` rồi `⟨p⟩ r`.
- Sessionizer tìm project trong `~/develop ~/projects ~/work ~/code`. Đổi bằng
  biến môi trường `TMUX_SESSIONIZER_PATHS="~/a ~/b"`.
- Muốn tra cứu nhanh ngay trong tmux: `⟨p⟩ ?`.

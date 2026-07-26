# coding-neovim

Cấu hình Neovim **nhẹ, cross-OS**, tối ưu cho **đọc code, điều hướng, search** và
**coding cùng AI CLI** (Claude, Codex, ...) trong workflow **tmux**.

> 📖 Xem [DESIGN.md](DESIGN.md) để hiểu triết lý, kiến trúc và lộ trình build.

---

## Trạng thái

🚧 **Đang xây dựng** — build tăng dần theo lộ trình trong DESIGN.md.

- [x] Bước 0 — Khởi tạo repo & tài liệu
- [x] Bước 1 — Bootstrap lazy.nvim + config cơ bản (options/keymaps/autocmds) — startup ~18ms
- [~] Bước 2 — UI nền tảng: which-key + lualine ✅ (colorscheme để sau)
- [x] Bước 3 — Search & Navigation (Telescope + fzf-native) ✅
- [ ] ... (xem DESIGN.md §7)

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

- **which-key**: bấm `Space` rồi chờ ~0.3s → hiện bảng gợi ý phím theo nhóm (Find/Git/AI...).
  `Space ?` → xem phím tắt riêng của buffer hiện tại.
- **lualine**: statusline hiện mode · nhánh git · diff · diagnostic · file · vị trí dòng:cột.

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

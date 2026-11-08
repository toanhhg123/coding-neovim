#!/usr/bin/env bash
# install.sh — cài coding-neovim lên máy mới bằng 1 lệnh (macOS hoặc Debian/Ubuntu)
#
#   curl -fsSL https://raw.githubusercontent.com/toanhhg123/coding-neovim/main/install.sh | bash
#
# Chạy lại nhiều lần cũng được: bước nào đã xong thì bỏ qua.
# Biến môi trường tuỳ chọn:
#   CODING_NVIM_DIR   thư mục clone repo (mặc định ~/develop/coding-neovim)
#   CODING_NVIM_REPO  địa chỉ git của repo
#   SKIP_DEPS=1       không cài công cụ hệ thống (Neovim, ripgrep, Node...)
#   SKIP_JAVA=1       không cài JDK
#   INSTALL_ITERM_PROFILE=1  cài profile Cmd tùy chọn (mặc định dùng phím Vim)

set -euo pipefail

REPO_URL="${CODING_NVIM_REPO:-https://github.com/toanhhg123/coding-neovim.git}"
DIR="${CODING_NVIM_DIR:-$HOME/develop/coding-neovim}"
SKIP_DEPS="${SKIP_DEPS:-0}"
SKIP_JAVA="${SKIP_JAVA:-0}"
INSTALL_ITERM_PROFILE="${INSTALL_ITERM_PROFILE:-0}"
NVIM_MIN="0.12.0"
TREE_SITTER_MIN="0.26.1"
NODE_MIN=22
STAMP="$(date +%Y%m%d-%H%M%S)"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"
NOTES=()

info() { printf '\n\033[36m==> %s\033[0m\n' "$*"; }
ok() { printf '\033[32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[33m  !\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# So sánh version dạng 0.12.4: trả về 0 nếu $1 >= $2
ver_ge() {
  local IFS=.
  local -a a b
  read -r -a a <<<"$1"
  read -r -a b <<<"$2"
  local i x y
  for i in 0 1 2; do
    x="${a[i]:-0}"
    y="${b[i]:-0}"
    if ((10#$x > 10#$y)); then return 0; fi
    if ((10#$x < 10#$y)); then return 1; fi
  done
  return 0
}

nvim_ok() { have nvim && ver_ge "$(nvim --version | head -1 | sed -E 's/^NVIM v([0-9.]+).*/\1/')" "$NVIM_MIN"; }
node_ok() { have node && (($(node -p 'process.versions.node.split(".")[0]') >= NODE_MIN)); }
tree_sitter_ok() {
  have tree-sitter || return 1
  local version
  version="$(tree-sitter --version 2>/dev/null)" || return 1
  version="$(printf '%s\n' "$version" | sed -nE 's/^tree-sitter ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')"
  [ -n "$version" ] && ver_ge "$version" "$TREE_SITTER_MIN"
}

# Toàn bộ nằm trong main: khi chạy kiểu "curl | bash", bash đọc hết script trước khi chạy,
# nên lệnh con có đọc stdin cũng không nuốt mất phần còn lại.
main() {

case "$(uname -s)" in
  Darwin) PLATFORM=mac ;;
  Linux) PLATFORM=linux ;;
  *) die "Chưa hỗ trợ $(uname -s): cần macOS hoặc Linux" ;;
esac
case "$(uname -m)" in
  x86_64 | amd64) ARCH=x64 ;;
  arm64 | aarch64) ARCH=arm64 ;;
  *) die "Chưa hỗ trợ CPU $(uname -m)" ;;
esac

# ============================================================
# 1. Công cụ hệ thống
# ============================================================
install_mac() {
  have brew || die "Cần Homebrew trước: https://brew.sh"
  xcode-select -p >/dev/null 2>&1 || warn "Chưa có Xcode Command Line Tools (cần để build plugin): xcode-select --install"
  local pkgs=(git neovim tree-sitter-cli ripgrep fd fzf tmux node jq lazydocker)
  [ "$SKIP_JAVA" = 1 ] || pkgs+=(openjdk@25 openjdk@21)
  local missing=()
  local p
  for p in "${pkgs[@]}"; do
    brew list --versions "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    brew install "${missing[@]}"
  fi
  nvim_ok || brew upgrade neovim
  tree_sitter_ok || brew upgrade tree-sitter-cli
  node_ok || brew upgrade node
  ok "Homebrew: ${pkgs[*]}"
}

# Linux: tải bản phát hành chính thức vào ~/.local khi apt không có bản đủ mới
download() { curl -fsSL --retry 3 "$1"; }

install_linux() {
  have apt-get || {
    warn "Không phải Debian/Ubuntu: tự cài neovim >= $NVIM_MIN, tree-sitter-cli, ripgrep, fd, fzf, tmux, node >= $NODE_MIN, jq, git, JDK 21 + 25"
    return
  }
  local sudo=""
  [ "$(id -u)" = 0 ] || sudo="sudo"
  $sudo apt-get update -qq
  $sudo apt-get install -y -qq git curl unzip tar xz-utils build-essential ripgrep fd-find fzf tmux jq >/dev/null
  if [ "$SKIP_JAVA" != 1 ]; then
    $sudo apt-get install -y -qq openjdk-21-jdk >/dev/null || warn "apt không có openjdk-21-jdk"
  fi
  mkdir -p "$LOCAL_BIN" "$LOCAL_OPT"
  export PATH="$LOCAL_BIN:$PATH"

  # Ubuntu đặt tên fd là fdfind
  if ! have fd && have fdfind; then ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"; fi

  if ! nvim_ok; then
    local name="nvim-linux-$([ "$ARCH" = x64 ] && echo x86_64 || echo arm64)"
    download "https://github.com/neovim/neovim/releases/latest/download/$name.tar.gz" | tar -xz -C "$LOCAL_OPT"
    ln -sf "$LOCAL_OPT/$name/bin/nvim" "$LOCAL_BIN/nvim"
  fi

  if ! tree_sitter_ok; then
    local zip
    zip="$(mktemp)"
    download "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-$ARCH.zip" >"$zip"
    unzip -o -q "$zip" tree-sitter -d "$LOCAL_BIN"
    chmod +x "$LOCAL_BIN/tree-sitter"
    rm -f "$zip"
    hash -r # bỏ cache executable cũ trong PATH sau khi cài vào ~/.local/bin
  fi

  if ! node_ok; then
    local file
    file="$(download https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt | awk -v a="linux-$ARCH.tar.xz" '$2 ~ a"$" {print $2}')"
    [ -n "$file" ] || die "Không tìm được bản Node cho linux-$ARCH"
    rm -rf "$LOCAL_OPT/node"
    mkdir -p "$LOCAL_OPT/node"
    download "https://nodejs.org/dist/latest-v24.x/$file" | tar -xJ -C "$LOCAL_OPT/node" --strip-components=1
    local b
    for b in node npm npx; do ln -sf "$LOCAL_OPT/node/bin/$b" "$LOCAL_BIN/$b"; done
  fi

  # jdtls cần Java 25: apt thường chưa có, tải Temurin vào thư mục mà config tự dò
  local jdk25="$HOME/.local/share/jdks/temurin-25"
  if [ "$SKIP_JAVA" != 1 ] && [ ! -x "$jdk25/bin/java" ]; then
    mkdir -p "$jdk25"
    download "https://api.adoptium.net/v3/binary/latest/25/ga/linux/$([ "$ARCH" = x64 ] && echo x64 || echo aarch64)/jdk/hotspot/normal/eclipse" |
      tar -xz -C "$jdk25" --strip-components=1
  fi

  # Thêm ~/.local/bin vào PATH cho các lần mở shell sau
  local rc line='export PATH="$HOME/.local/bin:$PATH"'
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -qF "$line" "$rc"; then
      printf '\n# coding-neovim\n%s\n' "$line" >>"$rc"
      NOTES+=("Đã thêm ~/.local/bin vào PATH trong $rc, mở shell mới để có hiệu lực")
    fi
  done
  ok "Công cụ hệ thống (bản tải thêm nằm ở ~/.local)"
}

if [ "$SKIP_DEPS" = 1 ]; then
  info "Bỏ qua cài công cụ hệ thống (SKIP_DEPS=1)"
else
  info "Cài công cụ hệ thống"
  "install_$PLATFORM"
fi
nvim_ok || die "Cần Neovim >= $NVIM_MIN"
have git || die "Cần git"
tree_sitter_ok || die "Cần tree-sitter-cli >= $TREE_SITTER_MIN (kiểm tra tree-sitter --version và PATH)"
node_ok || warn "Node < $NODE_MIN hoặc chưa cài: một số LSP (TypeScript, YAML) sẽ không chạy"

# ============================================================
# 2. Lấy repo
# ============================================================
info "Repo: $DIR"
if [ -d "$DIR/.git" ]; then
  if [ -z "$(git -C "$DIR" status --porcelain)" ]; then
    git -C "$DIR" pull --ff-only -q && ok "Đã cập nhật" || warn "Không pull được, giữ nguyên bản hiện có"
  else
    warn "Repo có thay đổi chưa commit, bỏ qua pull"
  fi
else
  mkdir -p "$(dirname "$DIR")"
  git clone -q "$REPO_URL" "$DIR"
  ok "Đã clone"
fi

# ============================================================
# 3. Liên kết config (sao lưu bản cũ nếu khác)
# ============================================================
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    ok "$dst (đã có)"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    NOTES+=("Config cũ được sao lưu: $dst.bak-$STAMP")
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "$dst -> $src"
}

info "Liên kết config"
link "$DIR" "$HOME/.config/nvim"
link "$DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link "$DIR/tmux/scripts" "$HOME/.config/tmux/scripts"

# ============================================================
# 4. Plugin tmux
# ============================================================
info "Plugin tmux"
# Clone thẳng các @plugin trong tmux.conf: không cần tmux server đang chạy
local plugins="$HOME/.config/tmux/plugins" spec name
while read -r spec; do
  name="${spec##*/}"
  if [ -d "$plugins/$name" ]; then
    ok "$name (đã có)"
  else
    git clone -q --depth 1 "https://github.com/$spec" "$plugins/$name" && ok "$name" ||
      NOTES+=("Không clone được plugin tmux $spec: mở tmux rồi bấm Ctrl-t I")
  fi
done < <(sed -nE "s/^set -g @plugin '([^']+)'.*/\1/p" "$DIR/tmux/tmux.conf")

# ============================================================
# 5. Plugin Neovim, parser, LSP
# ============================================================
info "Plugin Neovim (theo lazy-lock.json)"
nvim --headless "+Lazy! restore" +qa </dev/null
ok "Đã cài plugin"

info "Parser treesitter + LSP qua Mason (lần đầu mất vài phút)"
nvim --headless -c "luafile $DIR/scripts/setup.lua" </dev/null
ok "Đã cài parser và LSP"

# ============================================================
# 6. Profile iTerm tùy chọn (phím Vim mặc định không cần bước này)
# ============================================================
if [ "$INSTALL_ITERM_PROFILE" = 1 ] && [ "$PLATFORM" = mac ] && [ -d "/Applications/iTerm.app" ]; then
  info "Profile iTerm"
  PROFILES="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  mkdir -p "$PROFILES"
  cp "$DIR/iterm/coding-neovim.json" "$PROFILES/"
  ok "Đã thêm profile coding-neovim"
  NOTES+=("Bộ phím Cmd tùy chọn: require(\"config.intellij\") trong lua/config/local.lua và chọn profile iTerm coding-neovim")
fi

info "Xong"
for note in ${NOTES[@]+"${NOTES[@]}"}; do warn "$note"; done
printf '\nMở Neovim bằng lệnh: nvim (nên chạy trong tmux)\n'
}

main "$@"

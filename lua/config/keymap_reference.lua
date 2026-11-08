-- Lệnh Vim gốc không xuất hiện đầy đủ trong API mapping. Đây chỉ là danh mục tra cứu,
-- không đăng ký lại phím; runtime/buffer-local luôn được ưu tiên khi có override.
local entries = {}
local function add(modes, group, definitions)
  if type(modes) == "string" then modes = { modes } end
  for _, mode in ipairs(modes) do
    for _, definition in ipairs(definitions) do
      entries[#entries + 1] = {
        mode = mode, group = group, lhs = definition[1], desc = definition[2],
        keywords = definition[3] or "", guide = definition[4],
      }
    end
  end
end

add("n", "Window / Split", {
  { "<C-w>v", "Chia màn hình dọc: trái / phải", "split vertical vsplit chia doi man hinh" },
  { "<C-w>s", "Chia màn hình ngang: trên / dưới", "split horizontal chia doi man hinh" },
  { "<C-w>n", "Mở ô ngang với buffer mới", "new window split" },
  { "<C-w>h", "Chuyển sang ô bên trái", "window focus pane left chuyen o" },
  { "<C-w>j", "Chuyển sang ô bên dưới", "window focus pane down chuyen o" },
  { "<C-w>k", "Chuyển sang ô bên trên", "window focus pane up chuyen o" },
  { "<C-w>l", "Chuyển sang ô bên phải", "window focus pane right chuyen o" },
  { "<C-w>w", "Chuyển sang ô kế tiếp", "window focus cycle chuyen o" },
  { "<C-w>p", "Quay về ô vừa dùng", "window previous chuyen o" },
  { "<C-w>t", "Chuyển tới ô đầu tiên", "window top chuyen o" },
  { "<C-w>b", "Chuyển tới ô cuối cùng", "window bottom chuyen o" },
  { "<C-w>q", "Đóng ô hiện tại; ô cuối sẽ thoát Neovim", "quit close window dong o" },
  { "<C-w>c", "Đóng ô hiện tại (cần ít nhất 2 ô)", "close window dong o" },
  { "<C-w>o", "Chỉ giữ ô hiện tại", "only window close others" },
  { "<C-w>=", "Chia đều kích thước các ô", "equal resize window" },
  { "<C-w>+", "Tăng chiều cao ô", "resize height increase" },
  { "<C-w>-", "Giảm chiều cao ô", "resize height decrease" },
  { "<C-w>>", "Tăng chiều rộng ô", "resize width increase" },
  { "<C-w><", "Giảm chiều rộng ô", "resize width decrease" },
  { "<C-w>_", "Tối đa chiều cao ô", "maximize height window" },
  { "<C-w>|", "Tối đa chiều rộng ô", "maximize width window" },
  { "<C-w>H", "Đưa ô sang mép trái", "move window layout left" },
  { "<C-w>J", "Đưa ô xuống mép dưới", "move window layout down" },
  { "<C-w>K", "Đưa ô lên mép trên", "move window layout up" },
  { "<C-w>L", "Đưa ô sang mép phải", "move window layout right" },
  { "<C-w>r", "Xoay vị trí các ô", "rotate windows" },
  { "<C-w>x", "Đổi vị trí ô với ô kế tiếp", "exchange swap windows" },
  { "<C-w>T", "Tách ô hiện tại sang tab mới", "window move tab" },
})

add("n", "Movement / Navigation", {
  { "h", "Sang trái một ký tự", "left cursor" }, { "j", "Xuống một dòng", "down cursor" },
  { "k", "Lên một dòng", "up cursor" }, { "l", "Sang phải một ký tự", "right cursor" },
  { "w", "Tới đầu từ kế tiếp", "word next" }, { "b", "Về đầu từ trước", "word previous" },
  { "e", "Tới cuối từ", "word end" }, { "ge", "Về cuối từ trước", "word previous end" },
  { "0", "Tới đầu dòng", "line start" }, { "^", "Tới ký tự đầu tiên khác khoảng trắng", "line first nonblank" },
  { "$", "Tới cuối dòng", "line end" }, { "gg", "Tới đầu file", "file top first" },
  { "G", "Tới cuối file (thêm số phía trước để tới dòng đó)", "file bottom line number" },
  { "%", "Nhảy giữa ngoặc tương ứng", "matching bracket parenthesis" },
  { "{", "Về đoạn văn trước", "paragraph previous" }, { "}", "Tới đoạn văn sau", "paragraph next" },
  { "<C-o>", "Quay lại vị trí trước", "jump back history" },
  { "<C-i>", "Đi tiếp vị trí trong jumplist", "jump forward history" },
  { "g;", "Về vị trí chỉnh sửa trước", "change previous edit" },
  { "g,", "Tới vị trí chỉnh sửa tiếp", "change next edit" },
  { "f", "Tìm ký tự phía trước trên dòng", "find character", "Bấm f rồi ký tự cần tìm; F tìm ngược." },
  { "F", "Tìm ký tự phía sau trên dòng", "find character backward", "Bấm F rồi ký tự cần tìm." },
  { "t", "Tới ngay trước ký tự trên dòng", "till character", "Bấm t rồi ký tự cần tìm; T tìm ngược." },
  { "T", "Tới ngay sau ký tự tìm ngược trên dòng", "till character backward", "Bấm T rồi ký tự cần tìm." },
  { ";", "Lặp lại tìm ký tự f/F/t/T", "repeat character find" },
  { ",", "Lặp tìm ký tự theo chiều ngược", "reverse character find" },
})

add("n", "Scroll / View", {
  { "<C-f>", "Cuộn xuống một trang", "page forward scroll" },
  { "<C-b>", "Cuộn lên một trang", "page backward scroll" },
  { "<C-d>", "Cuộn xuống nửa trang", "half page down" },
  { "<C-u>", "Cuộn lên nửa trang", "half page up" },
  { "<C-e>", "Cuộn màn hình xuống một dòng", "scroll screen down" },
  { "<C-y>", "Cuộn màn hình lên một dòng", "scroll screen up" },
  { "zz", "Đưa dòng hiện tại ra giữa màn hình", "center cursor" },
  { "zt", "Đưa dòng hiện tại lên đầu màn hình", "top cursor" },
  { "zb", "Đưa dòng hiện tại xuống cuối màn hình", "bottom cursor" },
  { "H", "Tới đầu vùng đang hiển thị", "screen high" },
  { "M", "Tới giữa vùng đang hiển thị", "screen middle" },
  { "L", "Tới cuối vùng đang hiển thị", "screen low" },
})

add("n", "Edit / Clipboard", {
  { "i", "Vào Insert trước con trỏ", "insert type" }, { "a", "Vào Insert sau con trỏ", "append type" },
  { "I", "Vào Insert ở đầu nội dung dòng", "insert beginning" },
  { "A", "Vào Insert ở cuối dòng", "append end" },
  { "o", "Thêm dòng bên dưới và vào Insert", "open line below" },
  { "O", "Thêm dòng bên trên và vào Insert", "open line above" },
  { "x", "Xóa ký tự dưới con trỏ", "delete character" },
  { "dd", "Xóa / cắt dòng hiện tại", "delete cut line" },
  { "D", "Xóa từ con trỏ tới cuối dòng", "delete line end" },
  { "cc", "Thay nội dung dòng và vào Insert", "change line" },
  { "C", "Thay nội dung tới cuối dòng", "change end line" },
  { "ciw", "Thay từ dưới con trỏ", "change inner word" },
  { "diw", "Xóa từ dưới con trỏ", "delete inner word" },
  { "yiw", "Copy từ dưới con trỏ", "yank copy word" },
  { "yy", "Copy dòng hiện tại", "yank line" },
  { "yyp", "Nhân đôi dòng hiện tại", "duplicate line copy paste" },
  { "p", "Dán sau con trỏ / dưới dòng", "paste put" },
  { "P", "Dán trước con trỏ / trên dòng", "paste put before" },
  { '"+y', "Copy vào clipboard hệ thống", "system clipboard yank", 'Chọn vùng rồi bấm "+y, hoặc "+yy để copy cả dòng.' },
  { '"+p', "Dán từ clipboard hệ thống", "system clipboard paste" },
  { "u", "Hoàn tác", "undo" }, { "<C-r>", "Làm lại", "redo" },
  { ".", "Lặp lại thao tác sửa vừa rồi", "repeat change" },
  { "J", "Nối dòng hiện tại với dòng dưới", "join lines" },
  { ">>", "Thụt dòng sang phải", "indent line" },
  { "<<", "Thụt dòng sang trái", "unindent line" },
  { "==", "Căn thụt lề dòng hiện tại", "reindent line" },
  { "gg=G", "Căn thụt lề toàn bộ file", "reindent file" },
  { "~", "Đổi hoa / thường ký tự", "toggle case" },
  { "r", "Thay một ký tự", "replace character", "Bấm r rồi ký tự thay thế." },
  { "R", "Vào chế độ ghi đè ký tự", "replace mode" },
})

add("n", "Select / Text Objects", {
  { "v", "Chọn vùng theo ký tự", "visual character selection" },
  { "V", "Chọn vùng theo dòng", "visual line selection" },
  { "<C-v>", "Chọn khối chữ nhật", "visual block selection" },
  { "ggVG", "Chọn toàn bộ file", "select all" },
  { "viw", "Chọn từ dưới con trỏ", "visual inner word" },
  { 'vi"', "Chọn nội dung trong nháy kép", "visual quoted string" },
  { "vi(", "Chọn nội dung trong ngoặc tròn", "visual parentheses" },
  { "vi{", "Chọn nội dung trong ngoặc nhọn", "visual braces block" },
  { "gv", "Chọn lại vùng Visual vừa dùng", "reselect visual" },
  { "van", "Chọn node cú pháp (cần parser)", "syntax treesitter select" },
})

add("n", "Find / Search", {
  { "/", "Tìm trong file theo chiều xuôi", "search regex", "Bấm /, nhập từ khóa hoặc regex, rồi Enter; n/N chuyển kết quả." },
  { "?", "Tìm trong file theo chiều ngược", "search backward regex", "Bấm ?, nhập từ khóa hoặc regex, rồi Enter." },
  { "n", "Kết quả tìm tiếp theo", "search next" },
  { "N", "Kết quả tìm trước đó", "search previous" },
  { "*", "Tìm từ dưới con trỏ theo chiều xuôi", "search word forward" },
  { "#", "Tìm từ dưới con trỏ theo chiều ngược", "search word backward" },
  { ":nohlsearch<CR>", "Tắt highlight tìm kiếm", "clear search highlight" },
  { ":%s/", "Thay thế nội dung trong toàn file", "substitute replace regex", "Gõ :%s/cũ/mới/gc rồi Enter để xác nhận từng lần thay." },
})

add("n", "File / Buffer / Tab", {
  { ":w<CR>", "Lưu file hiện tại", "write save file" },
  { ":wa<CR>", "Lưu tất cả buffer đã sửa", "write save all" },
  { ":q<CR>", "Đóng ô / thoát khi còn một ô", "quit close" },
  { ":wq<CR>", "Lưu rồi đóng ô", "write quit save close" },
  { ":e ", "Mở file theo đường dẫn", "edit open file", "Gõ :e đường/dẫn rồi Enter; Tab gợi ý đường dẫn." },
  { ":ls<CR>", "Liệt kê buffer", "list buffers" },
  { ":bnext<CR>", "Buffer kế tiếp", "buffer next" },
  { ":bprevious<CR>", "Buffer trước đó", "buffer previous" },
  { ":bdelete<CR>", "Đóng buffer hiện tại", "buffer delete close" },
  { "<C-^>", "Đổi qua lại với file vừa dùng", "alternate buffer file" },
  { ":tabnew<CR>", "Tạo tab Neovim mới", "new tab" },
  { "gt", "Tab Neovim kế tiếp", "next tab" },
  { "gT", "Tab Neovim trước đó", "previous tab" },
  { ":tabclose<CR>", "Đóng tab Neovim hiện tại", "close tab" },
})

add("n", "Fold / Quickfix", {
  { "za", "Mở / đóng fold hiện tại", "toggle fold" },
  { "zo", "Mở fold hiện tại", "open fold" }, { "zc", "Đóng fold hiện tại", "close fold" },
  { "zR", "Mở tất cả fold", "open all folds" }, { "zM", "Đóng tất cả fold", "close all folds" },
  { ":copen<CR>", "Mở danh sách quickfix", "quickfix open errors results" },
  { ":cclose<CR>", "Đóng danh sách quickfix", "quickfix close" },
  { ":cnext<CR>", "Mục quickfix tiếp theo", "quickfix next error" },
  { ":cprevious<CR>", "Mục quickfix trước đó", "quickfix previous error" },
})

add("n", "Marks / Macros / Help", {
  { "m", "Đặt mark để quay lại vị trí", "mark bookmark", "Bấm m rồi một chữ, ví dụ ma; quay lại bằng `a." },
  { "`", "Quay lại vị trí mark", "jump mark", "Bấm dấu ` rồi tên mark, ví dụ `a." },
  { "q", "Bắt đầu / kết thúc ghi macro", "record macro", "Bấm qa để ghi vào a; q để dừng; @a để chạy." },
  { "@", "Chạy macro trong register", "execute macro", "Bấm @ rồi tên register, ví dụ @a; @@ để chạy lại." },
  { "@@", "Chạy lại macro vừa dùng", "repeat macro" },
  { ":", "Mở dòng lệnh Vim", "command ex", "Bấm : rồi nhập lệnh; Enter để chạy, Esc để hủy." },
  { ":help ", "Tra tài liệu Neovim", "help documentation", "Gõ :help tên-phím hoặc tên-lệnh rồi Enter." },
})

add("i", "Insert / Completion", {
  { "<Esc>", "Về Normal mode", "escape normal" },
  { "<C-w>", "Xóa từ phía trước con trỏ", "delete previous word" },
  { "<C-u>", "Xóa phần đã gõ trên dòng", "delete current input line" },
  { "<C-t>", "Tăng thụt lề dòng", "indent", "Insert: Ctrl-t tăng thụt lề; trong tmux, bấm Ctrl-t hai lần để gửi phím này." },
  { "<C-d>", "Giảm thụt lề dòng", "unindent" },
  { "<C-n>", "Gợi ý từ / mục completion kế tiếp", "completion next" },
  { "<C-p>", "Gợi ý từ / mục completion trước", "completion previous" },
  { "<C-y>", "Nhận completion; ngoài menu copy ký tự từ dòng trên", "accept completion copy above" },
  { "<C-e>", "Đóng completion; ngoài menu copy ký tự từ dòng dưới", "cancel completion copy below" },
  { "<C-x><C-f>", "Gợi ý đường dẫn file", "file path completion" },
  { "<C-r>", "Chèn nội dung một register", "insert register paste", "Trong Insert, bấm Ctrl-r rồi tên register; Ctrl-r + lấy clipboard." },
  { "<C-o>", "Chạy một lệnh Normal rồi trở lại Insert", "one normal command" },
  { "<C-g>u", "Bắt đầu một nhóm undo mới", "undo break" },
})

add("x", "Visual / Selection", {
  { "<Esc>", "Hủy chọn vùng, về Normal", "escape selection" },
  { "o", "Đổi đầu đang điều khiển của vùng chọn", "selection endpoint swap" },
  { "y", "Copy vùng chọn", "yank copy selection" },
  { "d", "Xóa / cắt vùng chọn", "delete cut selection" },
  { "c", "Thay vùng chọn rồi vào Insert", "change selection" },
  { "p", "Dán đè vùng chọn", "paste replace selection" },
  { ">", "Thụt vùng chọn sang phải", "indent selection" },
  { "<", "Thụt vùng chọn sang trái", "unindent selection" },
  { "=", "Căn thụt lề vùng chọn", "reindent selection" },
  { "u", "Chuyển vùng chọn thành chữ thường", "lowercase selection" },
  { "U", "Chuyển vùng chọn thành chữ hoa", "uppercase selection" },
  { "an", "Mở rộng vùng chọn theo cú pháp", "syntax expand selection" },
  { "in", "Thu hẹp vùng chọn theo cú pháp", "syntax shrink selection" },
})

add({ "x", "o" }, "Text Objects", {
  { "iw", "Bên trong một từ", "inner word" }, { "aw", "Cả từ và khoảng trắng", "around word" },
  { 'i"', "Bên trong nháy kép", "inner quoted string" }, { 'a"', "Cả cặp nháy kép", "around quoted string" },
  { "i'", "Bên trong nháy đơn", "inner quoted string" }, { "a'", "Cả cặp nháy đơn", "around quoted string" },
  { "i(", "Bên trong ngoặc tròn", "inner parentheses" }, { "a(", "Cả cặp ngoặc tròn", "around parentheses" },
  { "i{", "Bên trong ngoặc nhọn", "inner braces block" }, { "a{", "Cả cặp ngoặc nhọn", "around braces block" },
  { "ip", "Bên trong đoạn văn", "inner paragraph" }, { "ap", "Cả đoạn văn", "around paragraph" },
})

add("c", "Command Line", {
  { "<CR>", "Chạy lệnh / tìm kiếm đang gõ", "enter execute command search" },
  { "<Esc>", "Hủy dòng lệnh / tìm kiếm", "escape cancel" },
  { "<C-b>", "Tới đầu dòng lệnh", "command beginning" },
  { "<C-a>", "Chèn tất cả kết quả completion vào dòng lệnh", "command completion all matches" },
  { "<C-e>", "Tới cuối dòng lệnh", "command end" },
  { "<C-w>", "Xóa từ phía trước", "command delete word" },
  { "<C-u>", "Xóa từ con trỏ về đầu dòng", "command clear" },
  { "<Up>", "Lệnh / tìm kiếm trước trong lịch sử", "history previous" },
  { "<Down>", "Lệnh / tìm kiếm sau trong lịch sử", "history next" },
  { "<Tab>", "Gợi ý lệnh / đường dẫn", "command completion" },
  { "<C-r>", "Chèn register vào dòng lệnh", "command register paste", "Trong dòng lệnh, Ctrl-r rồi tên register; Ctrl-r Ctrl-w chèn từ dưới con trỏ." },
})

add("t", "Terminal", {
  { "<C-\\><C-n>", "Thoát nhập terminal, về Normal mode", "terminal escape normal" },
})

return entries

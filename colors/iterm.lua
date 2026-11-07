-- colors/iterm.lua — colorscheme lấy từ bảng màu của profile iTerm
-- Nền trong suốt để thấy độ mờ của iTerm. Đổi profile thì chỉ cần sửa bảng `c`.

vim.cmd.highlight("clear")
vim.g.colors_name = "iterm"
vim.o.background = "dark"

local c = {
  fg = "#dcdcdc",
  gray = "#686868",     -- ANSI 8
  dim = "#8a8f96",      -- comment: sáng hơn ANSI 8 cho dễ đọc
  silver = "#c7c7c7",   -- ANSI 7
  black = "#14191e",    -- ANSI 0
  line = "#232931",     -- dòng con trỏ, nền của danh sách chọn
  border = "#3a4048",   -- đường viền
  red = "#dd7975",      -- ANSI 9
  green = "#58e790",    -- ANSI 10
  yellow = "#c7c400",   -- ANSI 3
  blue = "#a7abf2",     -- ANSI 12 (ANSI 4 quá tối để làm màu chữ)
  magenta = "#e17ee1",  -- ANSI 13
  cyan = "#00c5c7",     -- ANSI 6
  selection = "#b3d7ff", -- màu bôi đen của iTerm
}

-- Màu trong terminal của Neovim giống hệt iTerm
for i, color in ipairs({
  "#14191e", "#b43c2a", "#00c200", "#c7c400", "#2744c7", "#c040be", "#00c5c7", "#c7c7c7",
  "#686868", "#dd7975", "#58e790", "#ece100", "#a7abf2", "#e17ee1", "#60fdff", "#ffffff",
}) do
  vim.g["terminal_color_" .. (i - 1)] = color
end

local groups = {
  -- Giao diện: mọi nền đều trong suốt
  Normal = { fg = c.fg },
  NormalNC = { fg = c.fg },
  NormalFloat = { fg = c.fg },
  FloatBorder = { fg = c.border },
  FloatTitle = { fg = c.cyan, bold = true },
  Pmenu = { fg = c.fg },
  PmenuSel = { bg = c.line, fg = c.fg, bold = true },
  PmenuSbar = {},
  PmenuThumb = { bg = c.border },
  Cursor = { fg = c.black, bg = c.fg },
  CursorLine = { bg = c.line },
  CursorColumn = { bg = c.line },
  ColorColumn = { bg = c.line },
  LineNr = { fg = c.gray },
  CursorLineNr = { fg = c.cyan, bold = true },
  SignColumn = {},
  FoldColumn = { fg = c.border },
  Folded = { fg = c.gray },
  EndOfBuffer = {},
  NonText = { fg = c.border },
  Whitespace = { fg = c.border },
  SpecialKey = { fg = c.border },
  WinSeparator = { fg = c.border },
  VertSplit = { fg = c.border },
  StatusLine = { fg = c.gray },
  StatusLineNC = { fg = c.gray },
  TabLine = { fg = c.gray },
  TabLineFill = {},
  TabLineSel = { fg = c.fg, bold = true },
  Title = { fg = c.cyan, bold = true },
  Visual = { fg = c.black, bg = c.selection },
  VisualNOS = { fg = c.black, bg = c.selection },
  Search = { fg = c.black, bg = c.yellow },
  CurSearch = { fg = c.black, bg = c.cyan, bold = true },
  IncSearch = { link = "CurSearch" },
  Substitute = { link = "Search" },
  MatchParen = { fg = c.cyan, bold = true, underline = true },
  Directory = { fg = c.fg },
  MsgArea = {},
  ModeMsg = { fg = c.cyan },
  MoreMsg = { fg = c.green },
  Question = { fg = c.cyan },
  ErrorMsg = { fg = c.red },
  WarningMsg = { fg = c.yellow },
  QuickFixLine = { bg = c.line, bold = true },
  WildMenu = { link = "PmenuSel" },

  -- Cú pháp: ít màu, biến và dấu câu giữ màu chữ thường cho dễ đọc
  Comment = { fg = c.dim, italic = true },
  Constant = { fg = c.yellow },
  String = { fg = c.green },
  Character = { fg = c.green },
  Number = { fg = c.yellow },
  Boolean = { fg = c.yellow },
  Float = { fg = c.yellow },
  Identifier = { fg = c.fg },
  Function = { fg = c.blue },
  Statement = { fg = c.magenta },
  Keyword = { fg = c.magenta },
  Conditional = { fg = c.magenta },
  Repeat = { fg = c.magenta },
  Label = { fg = c.magenta },
  Exception = { fg = c.magenta },
  Operator = { fg = c.silver },
  PreProc = { fg = c.magenta },
  Include = { fg = c.magenta },
  Define = { fg = c.magenta },
  Macro = { fg = c.cyan },
  Type = { fg = c.cyan },
  StorageClass = { fg = c.magenta },
  Structure = { fg = c.cyan },
  Special = { fg = c.cyan },
  Delimiter = { fg = c.silver },
  Tag = { fg = c.cyan },
  Underlined = { fg = c.blue, underline = true },
  Todo = { fg = c.yellow, bold = true },
  Error = { fg = c.red },

  -- Treesitter
  ["@variable"] = { fg = c.fg },
  ["@variable.parameter"] = { fg = c.fg },
  ["@variable.member"] = { fg = c.fg },
  ["@variable.builtin"] = { fg = c.magenta },
  ["@property"] = { fg = c.fg },
  ["@module"] = { fg = c.fg },
  ["@constant"] = { fg = c.fg },
  ["@constant.builtin"] = { fg = c.yellow },
  ["@attribute"] = { fg = c.yellow },
  ["@type.builtin"] = { fg = c.magenta },
  ["@function.builtin"] = { fg = c.blue },
  ["@constructor"] = { fg = c.cyan },
  ["@tag"] = { fg = c.cyan },
  ["@tag.attribute"] = { fg = c.fg },
  ["@tag.delimiter"] = { fg = c.gray },
  ["@punctuation"] = { fg = c.silver },
  ["@markup.heading"] = { fg = c.cyan, bold = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.link"] = { fg = c.blue },
  ["@markup.link.url"] = { fg = c.blue, underline = true },
  ["@markup.raw"] = { fg = c.green },
  ["@markup.list"] = { fg = c.magenta },

  -- LSP: jdtls có vài loại token Neovim chưa gán sẵn
  ["@lsp.type.annotation"] = { link = "@attribute" },
  ["@lsp.type.modifier"] = { link = "Keyword" },
  ["@lsp.type.namespace"] = { link = "@module" },
  LspReferenceText = { bg = c.line },
  LspReferenceRead = { bg = c.line },
  LspReferenceWrite = { bg = c.line },
  LspInlayHint = { fg = c.gray },
  LspSignatureActiveParameter = { fg = c.cyan, bold = true },

  -- Diagnostic
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.cyan },
  DiagnosticHint = { fg = c.gray },
  DiagnosticOk = { fg = c.green },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.cyan },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.gray },

  -- Diff & git
  DiffAdd = { bg = "#1d3327" },
  DiffChange = { bg = c.line },
  DiffDelete = { bg = "#3a2323", fg = c.red },
  DiffText = { bg = "#2c4150" },
  Added = { fg = c.green },
  Changed = { fg = c.yellow },
  Removed = { fg = c.red },
  GitSignsAdd = { fg = c.green },
  GitSignsChange = { fg = c.yellow },
  GitSignsDelete = { fg = c.red },

  -- Telescope
  TelescopeNormal = { fg = c.fg },
  TelescopeBorder = { fg = c.border },
  TelescopeTitle = { fg = c.gray },
  TelescopePromptPrefix = { fg = c.cyan },
  TelescopeSelection = { bg = c.line, bold = true },
  TelescopeSelectionCaret = { fg = c.cyan, bg = c.line },
  TelescopeMatching = { fg = c.cyan, bold = true },

  -- which-key
  WhichKey = { fg = c.cyan },
  WhichKeyGroup = { fg = c.magenta },
  WhichKeyDesc = { fg = c.fg },
  WhichKeySeparator = { fg = c.gray },
  WhichKeyNormal = { fg = c.fg },
  WhichKeyBorder = { fg = c.border },
  WhichKeyTitle = { fg = c.gray },

  -- neo-tree
  NeoTreeNormal = { fg = c.fg },
  NeoTreeNormalNC = { fg = c.fg },
  NeoTreeEndOfBuffer = {},
  NeoTreeWinSeparator = { fg = c.border },
  NeoTreeCursorLine = { bg = c.line },
  NeoTreeRootName = { fg = c.gray, bold = true },
  NeoTreeDirectoryName = { fg = c.fg },
  NeoTreeDirectoryIcon = { fg = c.cyan },
  NeoTreeFileName = { fg = c.fg },
  NeoTreeFileIcon = { fg = c.gray },
  NeoTreeIndentMarker = { fg = c.border },
  NeoTreeExpander = { fg = c.gray },
  NeoTreeDotfile = { fg = c.gray },
  NeoTreeGitAdded = { fg = c.green },
  NeoTreeGitModified = { fg = c.yellow },
  NeoTreeGitDeleted = { fg = c.red },
  NeoTreeGitConflict = { fg = c.red, bold = true },
  NeoTreeGitUntracked = { fg = c.green },
  NeoTreeGitIgnored = { fg = c.gray },
  NeoTreeTitleBar = { fg = c.gray },
  NeoTreeFloatBorder = { fg = c.border },

  -- Gợi ý code
  BlinkCmpMenu = { fg = c.fg },
  BlinkCmpMenuBorder = { fg = c.border },
  BlinkCmpDocBorder = { fg = c.border },
  BlinkCmpSignatureHelpBorder = { fg = c.border },
  BlinkCmpLabelMatch = { fg = c.cyan, bold = true },
  BlinkCmpKind = { fg = c.gray },

  -- Markdown
  RenderMarkdownCode = { bg = c.line },
  RenderMarkdownCodeInline = { bg = c.line },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end

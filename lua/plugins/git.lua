-- lua/plugins/git.lua — Git: đọc & review nhanh
-- gitsigns: dấu thay đổi ở gutter, nhảy/stage hunk, blame
-- diffview:  xem diff toàn branch + lịch sử file (review trước khi push)

return {
  -- ============================================================
  -- gitsigns: thay đổi ở gutter + thao tác hunk
  -- ============================================================
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      current_line_blame = false, -- tắt mặc định; bật/tắt bằng <leader>gb
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- --- Nhảy giữa các hunk (thay đổi) ---
        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.nav_hunk("next") end)
          return "<Ignore>"
        end, "Hunk kế tiếp")
        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.nav_hunk("prev") end)
          return "<Ignore>"
        end, "Hunk trước")

        -- --- Xem / stage / reset hunk ---
        map("n", "<leader>gp", gs.preview_hunk, "Xem trước thay đổi (hunk)")
        map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Bỏ thay đổi hunk")
        map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage vùng chọn")
        map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset vùng chọn")
        map("n", "<leader>gS", gs.stage_buffer, "Stage cả file")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")

        -- --- Blame ---
        map("n", "<leader>gb", gs.toggle_current_line_blame, "Bật/tắt blame theo dòng")
        map("n", "<leader>gB", function() gs.blame_line({ full = true }) end, "Blame dòng (chi tiết)")

        -- --- Text object: thao tác trên nguyên hunk (vd: dih, vih) ---
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Chọn hunk")
      end,
    },
  },

  -- ============================================================
  -- diffview: xem diff branch + lịch sử file (review)
  -- ============================================================
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff: thay đổi chưa commit" },
      { "<leader>gD", "<cmd>DiffviewOpen origin/HEAD...HEAD<CR>", desc = "Diff: so với base branch" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Lịch sử file hiện tại" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Lịch sử toàn repo" },
      { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "Đóng diffview" },
    },
    opts = {
      enhanced_diff_hl = true, -- highlight diff dễ đọc hơn
      view = {
        merge_tool = { layout = "diff3_mixed" },
      },
    },
  },

  -- ============================================================
  -- git-conflict: highlight & resolve merge conflict (khi review/rebase)
  -- ============================================================
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader>gx", "<cmd>GitConflictListQf<CR>", desc = "Conflict: liệt kê (quickfix)" },
    },
    opts = {
      default_mappings = true,   -- co/ct/cb/c0 + ]x/[x (chỉ hiệu lực trong buffer có conflict)
      disable_diagnostics = false,
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
    -- co=chọn phần mình, ct=chọn phần họ, cb=cả hai, c0=không cái nào; ]x/[x nhảy conflict
  },
}

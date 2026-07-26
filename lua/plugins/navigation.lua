-- lua/plugins/navigation.lua — Search & Navigation (trọng tâm)
-- Telescope: tìm file, live grep (từ khoá), buffer, symbol...
-- Cần binary ngoài: ripgrep (grep), fd (tìm file). make (build fzf-native).

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        -- Sort bằng C native -> nhanh hơn hẳn trên repo lớn
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    -- Keymap dưới namespace <leader>f (Find). which-key (Bước 2) sẽ hiện gợi ý.
    keys = {
      -- --- Tìm file ---
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Tìm file" },
      { "<leader><leader>", "<cmd>Telescope find_files<CR>", desc = "Tìm file (nhanh)" },
      { "<leader>fF", "<cmd>Telescope find_files hidden=true no_ignore=true<CR>", desc = "Tìm file (kể cả ẩn/ignore)" },
      { "<leader>fo", "<cmd>Telescope oldfiles<CR>", desc = "File gần đây" },

      -- --- Tìm từ khoá (grep) ---
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep từ khoá (toàn project)" },
      { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Grep từ dưới con trỏ" },
      { "<leader>fw", "<cmd>Telescope grep_string<CR>", mode = "v", desc = "Grep vùng chọn" },
      { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Tìm trong file hiện tại" },

      -- --- Buffer & điều hướng ---
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Danh sách buffer" },
      { "<leader>fr", "<cmd>Telescope resume<CR>", desc = "Mở lại kết quả tìm trước" },

      -- --- Trợ giúp & khám phá ---
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Trợ giúp (help)" },
      { "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Danh sách phím tắt" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Danh sách lệnh" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Symbol trong file (cần LSP)" },
    },
    opts = function()
      local actions = require("telescope.actions")
      return {
        defaults = {
          prompt_prefix = "  ",
          selection_caret = " ",
          path_display = { "truncate" }, -- rút gọn path dài
          sorting_strategy = "ascending", -- kết quả từ trên xuống
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = { prompt_position = "top", preview_width = 0.55 },
            width = 0.9,
            height = 0.85,
          },
          -- Bỏ qua thư mục nặng khi grep/tìm file
          file_ignore_patterns = {
            "node_modules", "%.git/", "dist/", "build/", "target/",
            "%.class", "%.jar", "%.lock",
          },
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case",
            "--hidden", "--glob", "!**/.git/*",
          },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<Esc>"] = actions.close, -- Esc đóng luôn (không về normal mode telescope)
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist, -- gửi kết quả ra quickfix
              ["<C-u>"] = false, -- để C-u xoá dòng prompt thay vì scroll preview
            },
          },
        },
        pickers = {
          find_files = {
            -- fd: tìm nhanh, tôn trọng .gitignore nhưng vẫn thấy file ẩn cần thiết
            find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
          },
          buffers = {
            sort_mru = true,          -- buffer vừa dùng lên đầu
            ignore_current_buffer = true,
            mappings = {
              i = { ["<C-d>"] = require("telescope.actions").delete_buffer },
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("fzf")
    end,
  },
}

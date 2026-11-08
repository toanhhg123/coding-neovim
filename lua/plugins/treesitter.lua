-- lua/plugins/treesitter.lua — highlight code theo cây cú pháp + textobjects
-- Dùng nhánh `main` (nhánh `master` đã đóng băng và lỗi trên Neovim 0.12).
-- Cần: tree-sitter-cli (>= 0.26.1, cài qua package manager, KHÔNG qua npm) + C compiler.
-- Plugin này không hỗ trợ lazy-load; highlight do Neovim chạy, nên startup vẫn nhẹ.

local parsers = require("util.parsers")

-- Bật highlight + indent cho buffer nếu có parser; thiếu parser thì tự cài (nếu được hỗ trợ).
local function attach(buf, lang)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if not pcall(vim.treesitter.start, buf, lang) then return false end
  if lang ~= "yaml" then -- indent yaml của treesitter hay lệch
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  return true
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.install(parsers) -- đã cài rồi thì không làm gì

      local pending = {}
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or vim.bo[ev.buf].buftype == "nofile" then return end
          if attach(ev.buf, lang) ~= false then return end
          -- Filetype lạ: tự cài parser một lần rồi bật lại
          if pending[lang] or not vim.tbl_contains(ts.get_available(), lang) then return end
          pending[lang] = true
          ts.install(lang):await(function() vim.schedule(function() attach(ev.buf, lang) end) end)
        end,
      })

      -- Chọn vùng tăng dần theo cú pháp: dựa trên `an`/`in` có sẵn của Neovim 0.12
      vim.keymap.set("n", "<C-Space>", "van", { remap = true, desc = "Bắt đầu chọn theo cú pháp" })
      vim.keymap.set("x", "<C-Space>", "an", { remap = true, desc = "Mở rộng vùng chọn" })
      vim.keymap.set("x", "<BS>", "in", { remap = true, desc = "Thu hẹp vùng chọn" })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local function select(query)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end
      end
      for keys, def in pairs({
        af = { "@function.outer", "Chọn cả hàm" },
        ["if"] = { "@function.inner", "Chọn thân hàm" },
        ac = { "@class.outer", "Chọn cả class" },
        ic = { "@class.inner", "Chọn thân class" },
        aa = { "@parameter.outer", "Chọn tham số" },
        ia = { "@parameter.inner", "Chọn nội dung tham số" },
      }) do
        vim.keymap.set({ "x", "o" }, keys, select(def[1]), { desc = def[2] })
      end

      -- Nhảy tới hàm/class (tránh ]c/[c vì gitsigns đang dùng cho hunk)
      local function move(fn, query)
        return function()
          require("nvim-treesitter-textobjects.move")[fn](query, "textobjects")
        end
      end
      for keys, def in pairs({
        ["]f"] = { "goto_next_start", "@function.outer", "Hàm kế tiếp" },
        ["[f"] = { "goto_previous_start", "@function.outer", "Hàm trước" },
        ["]t"] = { "goto_next_start", "@class.outer", "Class kế tiếp" },
        ["[t"] = { "goto_previous_start", "@class.outer", "Class trước" },
      }) do
        vim.keymap.set({ "n", "x", "o" }, keys, move(def[1], def[2]), { desc = def[3] })
      end
    end,
  },
}

-- lua/plugins/colorscheme.lua — colorscheme + nền trong suốt (khớp iTerm)
-- transparent = nền iTerm (màu/độ mờ) xuyên qua Neovim.

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- nạp trước mọi plugin khác
    init = function()
      -- Đảm bảo TRONG SUỐT bền vững: sau mỗi lần :colorscheme, clear nền các
      -- nhóm nền chính (phòng khi đổi sang colorscheme khác không tự transparent).
      local grp = vim.api.nvim_create_augroup("transparent_bg", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = grp,
        callback = function()
          for _, g in ipairs({
            "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle",
            "SignColumn", "FoldColumn", "LineNr", "CursorLineNr", "EndOfBuffer",
            "MsgArea", "TelescopeNormal", "TelescopeBorder", "WhichKeyFloat",
            "NeoTreeNormal", "NeoTreeNormalNC",
          }) do
            pcall(vim.api.nvim_set_hl, 0, g, { bg = "none" })
          end
        end,
      })
    end,
    opts = {
      style = "night", -- night | storm | moon | day. Đổi tại đây nếu thích tông khác
      transparent = true, -- nền trong suốt -> thấy iTerm phía sau
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
